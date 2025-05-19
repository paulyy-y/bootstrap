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

# Function to handle cleanup
cleanup() {
    local exit_code=$?
    echo -e "\nCleaning up..."
    # Clean up any partial git-secrets installation
    rm -rf ~/bootstrap/git-secrets
    # Remove partial downloads
    rm -f ~/bootstrap/bfg.jar.tmp
    echo "Cleanup complete"
    exit $exit_code
}

# Function to handle interruption
handle_interrupt() {
    echo -e "\nScript interrupted by user"
    cleanup
}

# Function to handle errors
handle_error() {
    echo "Error occurred in setup script at line $1"
    cleanup
}

# Set up signal handling
trap 'handle_interrupt' SIGINT SIGTERM
trap 'handle_error $LINENO' ERR

mkdir -p ~/bootstrap/
sudo apt install make

# Git-secrets
if [ ! -d "/usr/local/bin/git-secrets" ]; then
    echo "Installing git-secrets..."
    # Clean up any previous failed install attempts
    rm -rf ~/bootstrap/git-secrets
    git clone https://github.com/awslabs/git-secrets.git ~/bootstrap/git-secrets
    sudo make install -C ~/bootstrap/git-secrets
    rm -rf ~/bootstrap/git-secrets
else
    echo "git-secrets is already installed"
fi

# BFG Repo Cleaner
if [ ! -f ~/bootstrap/bfg.jar ]; then
    echo "Downloading BFG Repo Cleaner..."
    # Download to temporary file first
    wget https://repo1.maven.org/maven2/com/madgag/bfg/1.13.2/bfg-1.13.2.jar -O ~/bootstrap/bfg.jar.tmp
    # Move to final location only if download successful
    mv ~/bootstrap/bfg.jar.tmp ~/bootstrap/bfg.jar
fi

# Add BFG alias if not already present
if ! grep -q "alias bfg='java -jar ~/bootstrap/bfg.jar'" "$RC_FILE"; then
    echo "Adding BFG alias to $RC_FILE..."
    echo "alias bfg='java -jar ~/bootstrap/bfg.jar'" >> "$RC_FILE"
    # Source the RC file if possible
    if [ -f "$RC_FILE" ]; then
        echo "Reloading shell configuration..."
        source "$RC_FILE" 2>/dev/null || true
    fi
else
    echo "BFG alias already exists in $RC_FILE"
fi

sudo apt install git-filter-repo
sudo apt install git
sudo apt install vim