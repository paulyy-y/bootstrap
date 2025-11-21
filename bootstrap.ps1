<#
.SYNOPSIS
    Windows PowerShell Bootstrap (Idempotent / Replace Mode)
    - Runs as CURRENT USER
    - Installs: Git, Neovim, FZF
    - Configures: Replaces "Minimal Setup" block in Profile if it exists
    - Adds: Unix/Emacs keybindings (Ctrl+A, D, E, K, U, W)
#>

$ErrorActionPreference = "Stop"
Write-Host "--- Starting Setup (User Context) ---" -ForegroundColor Cyan

# --- 1. Install Tools (Winget) ---
function Install-Winget {
    param([string]$Id, [string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $Name..."
        winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

Install-Winget -Id "Git.Git" -Name "git"
Install-Winget -Id "Neovim.Neovim" -Name "nvim"
Install-Winget -Id "junegunn.fzf" -Name "fzf"

# --- 2. Install Modules (User Scope) ---
Write-Host "Checking Modules..." -ForegroundColor Yellow
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

$modules = @("PSFzf", "PSReadLine")
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Installing $mod..."
        Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
    }
}

# --- 3. Configure Profile (Wipe & Replace) ---
Write-Host "Updating Profile: $PROFILE" -ForegroundColor Yellow
if (-not (Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force | Out-Null }

# Define the Config Block with Explicit Markers
$MinimalConfig = @"

# --- Minimal Setup START ---
# (Managed by bootstrap script - Do not edit manually inside this block)

Import-Module PSFzf
Import-Module PSReadLine

# 1. Fuzzy Find (Ctrl+R / Ctrl+T)
Set-PSFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# 2. Ghost Text & Completion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle Inline
Set-PSReadLineOption -Colors @{ "InlinePrediction" = [ConsoleColor]::DarkGray }

Set-PSReadLineKeyHandler -Key RightArrow -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function NextWord

# 3. Unix Keybindings (Emulation)
Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine
# Ctrl+E: Accept suggestion if available, otherwise go to end of line
Set-PSReadLineKeyHandler -Key Ctrl+e -ScriptBlock {
    try {
        `$line = `$null
        `$cursor = `$null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]`$line, [ref]`$cursor)
        `$lineLengthBefore = `$line.Length

        # Try to accept suggestion
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion()

        # Check if line content changed (suggestion was accepted)
        `$newLine = `$null
        `$newCursor = `$null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]`$newLine, [ref]`$newCursor)

        # If line didn't change, go to end of line
        if (`$newLine.Length -eq `$lineLengthBefore) {
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
        }
    } catch {
        # Fallback: if error occurs, just go to end of line
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}
Set-PSReadLineKeyHandler -Key Ctrl+k -Function KillLine         # Cut to end
Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardKillLine # Cut to start
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord # Cut word

# Ctrl+D: Exit if line is empty, otherwise delete character under cursor
Set-PSReadLineKeyHandler -Key Ctrl+d -ScriptBlock {
    try {
        `$line = `$null
        `$cursor = `$null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]`$line, [ref]`$cursor)

        if (`$line.Length -eq 0) {
            # Line is empty, exit PowerShell
            [Environment]::Exit(0)
        } else {
            # Line has content, delete character under cursor (default behavior)
            [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar()
        }
    } catch {
        # Fallback: if error occurs, just delete char
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar()
    }
}

# 4. Aliases
Set-Alias vim nvim
`$env:GIT_EDITOR = "nvim"

# ls aliases (Unix-style)
function ll { Get-ChildItem -Force }
function l { Get-ChildItem }

# Git aliases
function g { git `$args }
function gs { git status }
function ga { git add `$args }
function gc { git commit -m `$args }
function gp { git push `$args }
function gl { git log --oneline --graph --decorate `$args }
function gd { git diff `$args }
function gb { git branch `$args }
function gco { git checkout `$args }
function gpl { git pull `$args }
function gst { git stash `$args }

# 5. Custom Prompt
function prompt {
    `$path = `$PWD.Path.Replace(`$HOME, "~")
    `$git = (git branch --show-current 2>`$null)
    if (`$git) { `$git = " [`$git]" }

    Write-Host ""
    Write-Host "`$env:USERNAME" -NoNewline -ForegroundColor Green
    Write-Host " `$path" -NoNewline -ForegroundColor Blue
    Write-Host "`$git" -NoNewline -ForegroundColor Magenta
    return " > "
}
# --- Minimal Setup END ---
"@

$CurrentContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

# Regex to match content between START and END markers (Non-greedy)
$Pattern = "(?s)# --- Minimal Setup START ---.*?# --- Minimal Setup END ---"

if ($CurrentContent -match $Pattern) {
    Write-Host "Existing configuration found. Replaced with new version." -ForegroundColor Magenta
    $NewContent = $CurrentContent -replace $Pattern, $MinimalConfig
    Set-Content -Path $PROFILE -Value $NewContent
} else {
    Write-Host "No existing configuration found. Appending to profile." -ForegroundColor Green
    Add-Content -Path $PROFILE -Value $MinimalConfig
}

# --- 4. Git Config ---
git config --global init.defaultBranch main
git config --global core.autocrlf input

Write-Host "`n--- Success! ---" -ForegroundColor Cyan
Write-Host "Please restart your Terminal."
Read-Host "Press Enter to exit..."