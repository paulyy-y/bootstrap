#!/bin/bash

# Ensure script is run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run with bash" >&2
    exit 1
fi

# 1. PRE-FLIGHT CHECKS
echo "--- Starting Setup ---"

# Check for internet/GitHub connectivity
echo "Checking connectivity to github.com..."
if ! curl -Is https://github.com > /dev/null; then
    echo "WARNING: Cannot reach GitHub. Plugin installation will likely fail."
    echo "Check your internet connection or proxy settings."
else
    echo "Connectivity OK."
fi

# Detect shell configuration file
detect_rc_file() {
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

RC_FILE=$(detect_rc_file)

ensure_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_path="$ssh_dir/id_ed25519"
    local public_key_path="${key_path}.pub"

    if [ -f "$key_path" ] && [ -f "$public_key_path" ]; then
        echo "SSH key already exists (Skipping)"
        return
    fi

    echo "Generating new SSH key..."
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    ssh-keygen -t ed25519 -a 100 -N "" -f "$key_path" -C "user@localhost" || echo "SSH key gen failed, ignoring..."
    chmod 600 "$key_path"
    chmod 644 "$public_key_path"
}

# Remove cdrom from sources.list (Debian fix)
if [ -f /etc/apt/sources.list ]; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list
fi

# Update package lists
echo "Updating apt..."
sudo apt update || echo "Apt update failed, trying to continue..."

# Install required packages
install_pkg() {
    sudo apt install -y "$1" || echo "WARNING: Failed to install $1"
}

echo "Installing packages..."
install_pkg "zsh"
install_pkg "git"
install_pkg "git-filter-repo"
install_pkg "git-lfs"
install_pkg "curl"
install_pkg "openssh-client"
install_pkg "make"
install_pkg "vim"
install_pkg "neovim"
install_pkg "tmux"
install_pkg "ranger"
install_pkg "tldr"
install_pkg "fzf"
install_pkg "nmap"
install_pkg "avahi-utils"
install_pkg "open-iscsi"
install_pkg "nfs-common"
install_pkg "net-tools"
install_pkg "htop"
install_pkg "zoxide"
install_pkg "ripgrep"
install_pkg "bat"
install_pkg "fd-find"
install_pkg "ca-certificates"

# --- ZSH PLUGIN SETUP ---
echo "Setting up Zsh plugins..."

PLUGIN_DIR="$HOME/zsh-plugins"
mkdir -p "$PLUGIN_DIR"

install_plugin() {
    local repo_url=$1
    local dest_dir=$2
    local name=$(basename "$dest_dir")

    echo "Processing plugin: $name"

    if [ -d "$dest_dir" ]; then
        echo "  Directory exists. Updating..."
        git -C "$dest_dir" pull --quiet || echo "  WARNING: Update failed for $name (Non-fatal)"
    else
        echo "  Cloning from $repo_url..."
        if git clone --verbose --progress "$repo_url" "$dest_dir"; then
            echo "  Success."
        else
            echo "  ERROR: Failed to clone $name."
            echo "  Attempting to disable SSL verify (temporary fix)..."
            git -c http.sslVerify=false clone "$repo_url" "$dest_dir" || echo "  STILL FAILED. Skipping plugin."
        fi
    fi
}

install_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "$PLUGIN_DIR/zsh-syntax-highlighting"


# --- CONFIGURE .ZSHRC ---
ZSHRC_PATH="$HOME/.zshrc"
if [ ! -f "$ZSHRC_PATH" ]; then touch "$ZSHRC_PATH"; fi

read -r -d '' ZSH_BLOCK << 'EOF'
# --- Minimal Setup START ---
# (Managed by bootstrap script)

# 1. History Settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# 2. The Prompt (With Git Status)
setopt PROMPT_SUBST
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{240}(%F{magenta}%b%F{240})%f '
zstyle ':vcs_info:*' enable git
autoload -U colors && colors
PROMPT='%F{green}%n%f %F{blue}%~%f ${vcs_info_msg_0_}$ '

# 3. Native Tab Completion
autoload -Uz compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
compinit

# 4. Tool Initializations
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
fi

# 5. Aliases & Utilities
export EDITOR=nvim
alias vim=nvim
alias ll="ls -lah --color=auto"
alias l="ls -lh --color=auto"

# Handle Bat (cat replacement) quirks
if command -v batcat > /dev/null; then
    alias bat="batcat"
    alias cat="batcat"
    export BAT_THEME="OneHalfDark"
elif command -v bat > /dev/null; then
    alias cat="bat"
    export BAT_THEME="OneHalfDark"
fi

# Handle Fd (find replacement) quirks
if command -v fdfind > /dev/null; then
    alias fd="fdfind"
fi

# Ripgrep
if command -v rg > /dev/null; then
    alias grep="rg"
else
    alias grep="grep --color=auto"
fi

# Git Aliases
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gd="git diff"
alias gco="git checkout"

# 6. Fuzzy Find (FZF)
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
elif [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# 7. Key Bindings
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3~" delete-char

# 8. Plugins
if [ -f ~/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    bindkey '^[[C' autosuggest-accept
fi

if [ -f ~/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
# --- Minimal Setup END ---
EOF

# Remove existing block
if grep -q "# --- Minimal Setup START ---" "$ZSHRC_PATH"; then
    sed -i '/# --- Minimal Setup START ---/,/# --- Minimal Setup END ---/d' "$ZSHRC_PATH"
fi

# Append the new block
echo "$ZSH_BLOCK" >> "$ZSHRC_PATH"


# --- SHELL SWITCHING ---
if [ "$RC_FILE" != "$HOME/.zshrc" ]; then
    if ! grep -Fq 'exec zsh' "$RC_FILE"; then
        echo 'exec zsh -l' >>"$RC_FILE"
        echo "Added 'exec zsh -l' to $RC_FILE"
    fi
fi

git config --global init.defaultBranch main

# --- Configure Neovim ---
NVIM_CONFIG_DIR="$HOME/.config/nvim"
NVIM_INIT="$NVIM_CONFIG_DIR/init.vim"

if [ ! -d "$NVIM_CONFIG_DIR" ]; then
    mkdir -p "$NVIM_CONFIG_DIR"
fi

# Create/update init.vim with line numbers
cat > "$NVIM_INIT" << 'NVIMEOF'
set number
set numberwidth=4
NVIMEOF

echo "Configured Neovim with line numbers."

ensure_ssh_key

echo ""
echo "Setup complete!"
echo "Run: source ~/.zshrc"