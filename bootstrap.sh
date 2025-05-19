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

# Set up signal handling
trap 'handle_interrupt' SIGINT SIGTERM
trap 'handle_error $LINENO' ERR

sudo apt install make
sudo apt install git-filter-repo
sudo apt install git
sudo apt install vim