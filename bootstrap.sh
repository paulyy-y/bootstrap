#!/bin/bash

# Ensure script is run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run with bash" >&2
    exit 1
fi

# Exit on any error
set -e

# Detect shell configuration file
detect_rc_file() {
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

RC_FILE=$(detect_rc_file)
echo "Detected shell configuration file: $RC_FILE"

handle_interrupt() {
    echo -e "\nScript interrupted by user"
    cleanup
}

# Function to handle errors
handle_error() {
    echo "Error occurred in setup script at line $1"
    cleanup
}

# Function to cleanup
cleanup() {
    echo "Cleaning up..."
}

ensure_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_path="$ssh_dir/id_ed25519"
    local public_key_path="${key_path}.pub"

    if [ -f "$key_path" ] && [ -f "$public_key_path" ]; then
        echo "SSH key already exists at $key_path"
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

    echo "SSH key generated. Public key:"
    cat "$public_key_path"
}

# Set up signal handling
trap 'handle_interrupt' SIGINT SIGTERM
trap 'handle_error $LINENO' ERR

# Remove cdrom from sources.list, if any. This is to workaround Debian default install list.
sudo sed -i '/cdrom:/d' /etc/apt/sources.list

# Update package lists first
sudo apt update

# Install required packages
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
    fish \
    ranger \
    tldr \
    fzf \
    nmap \
    avahi-utils \
    open-iscsi \
    nfs-common \
    net-tools \
    htop

# Add 'exec fish' to the end of the RC_FILE if not already present
if ! grep -Fxq 'exec fish' "$RC_FILE"; then
    echo 'exec fish' >>"$RC_FILE"
    echo "Added 'exec fish' to $RC_FILE"
else
    echo "'exec fish' already present in $RC_FILE"
fi

fish -c 'set -Ux EDITOR nvim'
fish -c 'alias --save vim=nvim'
fish -c 'alias --save ll="ls -la"'
fish -c 'set -U fish_greeting ""'

git config --global init.defaultBranch main

ensure_ssh_key