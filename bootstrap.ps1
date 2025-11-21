<#
.SYNOPSIS
    Windows PowerShell Bootstrap (Robust Version)
    - Manual Install: LF (from GitHub)
    - Winget Install: Git, Neovim, FZF, Ripgrep, Bat, Fd, Zoxide
    - Configures: Smart Prompt, Unix Keybindings, Tool Aliases
#>

$ErrorActionPreference = "Stop"
Write-Host "--- Starting Setup (User Context) ---" -ForegroundColor Cyan

# --- 1. Setup User Bin Directory (For manual installs) ---
$UserBin = "$env:USERPROFILE\bin"
if (-not (Test-Path $UserBin)) {
    New-Item -ItemType Directory -Force -Path $UserBin | Out-Null
    Write-Host "Created local bin directory: $UserBin"
}

# Add to Path Permanently (User Scope) if missing
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$UserBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$UserBin", "User")
    $env:Path += ";$UserBin"
    Write-Host "Added $UserBin to User Path." -ForegroundColor Green
}

# --- 2. Install LF Manually (Since Winget failed) ---
if (-not (Get-Command lf -ErrorAction SilentlyContinue)) {
    Write-Host "Installing LF (Manual Download)..." -ForegroundColor Yellow
    try {
        $lfZip = "$UserBin\lf.zip"
        # Download latest release
        Invoke-WebRequest -Uri "https://github.com/gokcehan/lf/releases/latest/download/lf-windows-amd64.zip" -OutFile $lfZip

        # Extract
        Expand-Archive -Path $lfZip -DestinationPath $UserBin -Force

        # Cleanup
        Remove-Item $lfZip -Force
        Write-Host "LF Installed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to download LF. You may need to install it manually."
    }
} else {
    Write-Host "LF is already installed." -ForegroundColor Green
}

# --- 3. Install Standard Tools (Winget) ---
function Install-Winget {
    param([string]$Id, [string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $Name..."
        winget install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements
        # Refresh path hack
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

Install-Winget -Id "Git.Git" -Name "git"
Install-Winget -Id "Neovim.Neovim" -Name "nvim"
Install-Winget -Id "junegunn.fzf" -Name "fzf"
Install-Winget -Id "BurntSushi.ripgrep.MSVC" -Name "rg"  # Grep replacement
Install-Winget -Id "sharkdp.bat" -Name "bat"            # Cat replacement
Install-Winget -Id "sharkdp.fd" -Name "fd"              # Find replacement
Install-Winget -Id "ajeetdsouza.zoxide" -Name "zoxide"  # CD replacement

# --- 4. Install Modules ---
Write-Host "Checking Modules..." -ForegroundColor Yellow
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

$modules = @("PSFzf", "PSReadLine")
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Installing $mod..."
        Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
    }
}

# --- 5. Configure Profile (Wipe & Replace) ---
Write-Host "Updating Profile: $PROFILE" -ForegroundColor Yellow
if (-not (Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force | Out-Null }

$MinimalConfig = @"

# --- Minimal Setup START ---
# (Managed by bootstrap script)

Import-Module PSFzf
Import-Module PSReadLine

# 1. Tool Init (Zoxide / Starship if used)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# 2. Fuzzy Find
Set-PSFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# 3. Ghost Text & Completion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle Inline
Set-PSReadLineOption -Colors @{ "InlinePrediction" = [ConsoleColor]::DarkGray }

Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function NextWord

# 4. Unix Keybindings
Set-PSReadLineKeyHandler -Key Ctrl+a -Function BeginningOfLine

# Smart Ctrl+E (Accept suggestion -> EOL)
Set-PSReadLineKeyHandler -Key Ctrl+e -ScriptBlock {
    try {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion()
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    } catch {
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

Set-PSReadLineKeyHandler -Key Ctrl+k -Function KillLine
Set-PSReadLineKeyHandler -Key Ctrl+u -Function BackwardKillLine
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord

# Smart Ctrl+D (EOF or Delete)
Set-PSReadLineKeyHandler -Key Ctrl+d -ScriptBlock {
    try {
        `$line = `$null
        `$cursor = `$null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]`$line, [ref]`$cursor)
        if (`$line.Length -eq 0) { [Environment]::Exit(0) }
        else { [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar() }
    } catch {
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar()
    }
}

# 5. Aliases
Set-Alias vim nvim
`$env:GIT_EDITOR = "nvim"

# Tool Mappings
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias cat bat
    `$env:BAT_THEME = "OneHalfDark"
}
if (Get-Command lf -ErrorAction SilentlyContinue) { Set-Alias ranger lf }
if (Get-Command rg -ErrorAction SilentlyContinue) { Set-Alias grep rg }

# List aliases
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

# 6. Custom Prompt
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
$Pattern = "(?s)# --- Minimal Setup START ---.*?# --- Minimal Setup END ---"

if ($CurrentContent -match $Pattern) {
    Write-Host "Existing configuration found. Replaced." -ForegroundColor Magenta
    $NewContent = $CurrentContent -replace $Pattern, $MinimalConfig
    Set-Content -Path $PROFILE -Value $NewContent
} else {
    Write-Host "Appending to profile." -ForegroundColor Green
    Add-Content -Path $PROFILE -Value $MinimalConfig
}

# --- 6. Configure Neovim ---
$NvimConfigDir = "$env:LOCALAPPDATA\nvim"
$NvimInit = "$NvimConfigDir\init.vim"

if (-not (Test-Path $NvimConfigDir)) {
    New-Item -ItemType Directory -Force -Path $NvimConfigDir | Out-Null
}

# Create/update init.vim with line numbers (using LF line endings)
$NvimConfig = @"
set number
set numberwidth=4
"@

# Convert to LF line endings and write with UTF8NoBOM
$NvimConfigLF = $NvimConfig -replace "`r`n", "`n" -replace "`r", "`n"
[System.IO.File]::WriteAllText($NvimInit, $NvimConfigLF, [System.Text.UTF8Encoding]::new($false))
Write-Host "Configured Neovim with line numbers." -ForegroundColor Green

# --- 7. Git Config ---
git config --global init.defaultBranch main
git config --global core.autocrlf input

Write-Host "`n--- Success! ---" -ForegroundColor Cyan
Write-Host "Installed: lf (Manual), rg, bat, fd, z, nvim, fzf"
Write-Host "Please restart your Terminal."
Read-Host "Press Enter to exit..."