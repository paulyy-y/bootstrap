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
    htop

# Add 'exec fish' to the end of the RC_FILE if not already present
if ! grep -Fxq 'exec fish' "$RC_FILE"; then
    echo 'exec fish' >>"$RC_FILE"
    echo "Added 'exec fish' to $RC_FILE"
else
    echo "'exec fish' already present in $RC_FILE"
fi

fish -c 'set -U EDITOR nvim'
fish -c 'alias --save vim=nvim'
fish -c 'alias --save ll="ls -la"'
fish -c 'set -U fish_greeting ""'