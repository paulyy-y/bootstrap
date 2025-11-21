#!/bin/bash

# Ensure script is run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run with bash" >&2
    exit 1
fi

# Exit on any error
set -e

# Detect shell configuration file (for the 'exec zsh' hook)
detect_rc_file() {
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

RC_FILE=$(detect_rc_file)

handle_interrupt() {
    echo -e "\nScript interrupted by user"
    cleanup
}

handle_error() {
    echo "Error occurred in setup script at line $1"
    cleanup
}

cleanup() {
    echo "Cleaning up..."
}

ensure_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_path="$ssh_dir/id_ed25519"
    local public_key_path="${key_path}.pub"

    if [ -f "$key_path" ] && [ -f "$public_key_path" ]; then
        echo "SSH key already exists at $key_path (Skipping)"
        return
    fi

    echo "Generating new SSH key at $key_path"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    local git_email
    git_email=$(git config --global user.email 2>/dev/null || true)

    local user_part host_part default_email email
    user_part=${USER:-$(whoami)}
    host_part=$(hostname -f 2>/dev/null || hostname || echo "localhost")
    default_email="${user_part}@${host_part}"
    email=${git_email:-$default_email}

    ssh-keygen -t ed25519 -a 100 -N "" -f "$key_path" -C "$email"
    chmod 600 "$key_path"
    chmod 644 "$public_key_path"

    echo "SSH key generated."
}

# Set up signal handling
trap 'handle_interrupt' SIGINT SIGTERM
trap 'handle_error $LINENO' ERR

# Remove cdrom from sources.list if present (Debian fix)
sudo sed -i '/cdrom:/d' /etc/apt/sources.list

# Update package lists
sudo apt update

# Install required packages
# Added: zoxide, ripgrep, bat, fd-find
sudo apt install -y \
    git \
    git-filter-repo \
    git-lfs \
    curl \
    openssh-client \
    make \
    vim \
    neovim \
    tmux \
    zsh \
    ranger \
    tldr \
    fzf \
    nmap \
    avahi-utils \
    open-iscsi \
    nfs-common \
    net-tools \
    htop \
    zoxide \
    ripgrep \
    bat \
    fd-find

# --- ZSH PLUGIN SETUP ---
echo "Setting up Zsh plugins..."
PLUGIN_DIR="$HOME/zsh-plugins"
mkdir -p "$PLUGIN_DIR"

install_or_update_plugin() {
    local repo_url=$1
    local dest_dir=$2

    if [ -d "$dest_dir" ]; then
        # Update quietly
        git -C "$dest_dir" pull --quiet || echo "Failed to update $(basename "$dest_dir")"
    else
        echo "Installing plugin: $(basename "$dest_dir")..."
        git clone -c core.autocrlf=false "$repo_url" "$dest_dir" --quiet
    fi
}

install_or_update_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
install_or_update_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$PLUGIN_DIR/zsh-syntax-highlighting"


# --- CONFIGURE .ZSHRC (BLOCK REPLACEMENT) ---
ZSHRC_PATH="$HOME/.zshrc"

# Create file if it doesn't exist
if [ ! -f "$ZSHRC_PATH" ]; then
    touch "$ZSHRC_PATH"
    echo "Created $ZSHRC_PATH"
fi

# 1. Define the content block
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

# 4. Tool Initializations (Modern Unix)
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

# 7. Key Bindings (Unix/Emacs)
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

# 2. Remove existing block if present
if grep -q "# --- Minimal Setup START ---" "$ZSHRC_PATH"; then
    echo "Updating existing Minimal Setup block in .zshrc..."
    # Use sed to delete lines between START and END (inclusive)
    sed -i '/# --- Minimal Setup START ---/,/# --- Minimal Setup END ---/d' "$ZSHRC_PATH"
else
    echo "Adding Minimal Setup block to .zshrc..."
fi

# 3. Append the new block
echo "$ZSH_BLOCK" >> "$ZSHRC_PATH"


# --- SHELL SWITCHING ---
if [ "$RC_FILE" != "$HOME/.zshrc" ]; then
    if ! grep -Fq 'exec zsh' "$RC_FILE"; then
        echo 'exec zsh -l' >>"$RC_FILE"
        echo "Added 'exec zsh -l' to $RC_FILE"
    else
        echo "'exec zsh' already present in $RC_FILE"
    fi
fi

# Set git default branch
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
set relativenumber
set numberwidth=4
NVIMEOF

echo "Configured Neovim with line numbers."

ensure_ssh_key

echo "Setup complete!"
echo "Tools installed: zoxide (z), ripgrep (rg), bat (cat), fd, ranger"
echo "Run: source ~/.zshrc"