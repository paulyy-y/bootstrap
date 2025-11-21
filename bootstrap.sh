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

# Remove cdrom from sources.list, if any
sudo sed -i '/cdrom:/d' /etc/apt/sources.list

# Update package lists first
sudo apt update

# Install required packages
# apt install is idempotent (it won't reinstall if already present)
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
    htop

# --- ZSH PLUGIN SETUP ---
echo "Setting up Zsh plugins..."
PLUGIN_DIR="$HOME/zsh-plugins"
mkdir -p "$PLUGIN_DIR"

install_or_update_plugin() {
    local repo_url=$1
    local dest_dir=$2

    if [ -d "$dest_dir" ]; then
        echo "Plugin exists: $(basename "$dest_dir"). Updating..."
        # We silence the output here to keep it clean
        git -C "$dest_dir" pull --quiet || echo "Failed to update $(basename "$dest_dir")"
    else
        echo "Installing plugin: $(basename "$dest_dir")..."
        git clone -c core.autocrlf=false "$repo_url" "$dest_dir" --quiet
    fi
}

install_or_update_plugin "https://github.com/zsh-users/zsh-autosuggestions" "$PLUGIN_DIR/zsh-autosuggestions"
install_or_update_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$PLUGIN_DIR/zsh-syntax-highlighting"


# --- WRITE .ZSHRC (WITH CONFIRMATION) ---
write_zshrc() {
    cat > "$HOME/.zshrc" << 'EOF'
# --- 1. History Settings ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# --- 2. The Prompt (With Git Status) ---
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
# %b = branch, %u = unstaged changes, %c = staged changes
zstyle ':vcs_info:git:*' formats '%F{240}(%F{magenta}%b%F{240})%f '
zstyle ':vcs_info:*' enable git

# The Prompt: user dir (git) $
autoload -U colors && colors
PROMPT='%F{green}%n%f %F{blue}%~%f ${vcs_info_msg_0_}$ '

# --- 3. Native Tab Completion ---
autoload -Uz compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive tab completion
compinit

# --- 4. Fuzzy Find (FZF) ---
# Try standard locations for FZF bindings
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
elif [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# --- 5. Aliases & Utilities ---
export EDITOR=nvim
alias vim=nvim
alias ll="ls -lah --color=auto"
alias l="ls -lh --color=auto"
alias grep="grep --color=auto"

# Git Aliases
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

# --- 6. Key Bindings ---
bindkey '^E' end-of-line
bindkey '^A' beginning-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3~" delete-char

# --- 7. Plugins (Autosuggest + Syntax Highlight) ---
if [ -f ~/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    bindkey '^[[C' autosuggest-accept
fi

if [ -f ~/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
EOF
}

# Check if .zshrc exists
if [ -f "$HOME/.zshrc" ]; then
    echo ""
    echo "WARNING: A .zshrc file already exists."
    read -p "Do you want to replace it? (Existing file will be backed up) [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        TIMESTAMP=$(date +%s)
        BACKUP_FILE="$HOME/.zshrc.backup.$TIMESTAMP"
        echo "Backing up current .zshrc to $BACKUP_FILE"
        mv "$HOME/.zshrc" "$BACKUP_FILE"
        echo "Writing new .zshrc..."
        write_zshrc
    else
        echo "Skipping .zshrc update. Your existing config is untouched."
    fi
else
    echo "No existing .zshrc found. Writing new configuration..."
    write_zshrc
fi

# --- SHELL SWITCHING ---
# Check if RC_FILE is distinct from zshrc (to avoid circular exec if user is already in Zsh)
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

ensure_ssh_key

echo "Setup complete!"
echo "If you updated the config, run: source ~/.zshrc"