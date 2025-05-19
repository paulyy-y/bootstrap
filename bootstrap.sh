#!/bin/bash

# Ensure script is run with bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run with bash" >&2
    exit 1
fi

# Exit on any error
set -e

# Function to handle errors
handle_error() {
    echo "Error occurred in setup script at line $1"
    exit 1
}

# Set up error handling
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
    wget https://repo1.maven.org/maven2/com/madgag/bfg/1.13.2/bfg-1.13.2.jar -O ~/bootstrap/bfg.jar
fi

# Add BFG alias if not already present
if ! grep -q "alias bfg='java -jar ~/bootstrap/bfg.jar'" ~/.bashrc; then
    echo "Adding BFG alias to .bashrc..."
    echo "alias bfg='java -jar ~/bootstrap/bfg.jar'" >> ~/.bashrc
    source ~/.bashrc
else
    echo "BFG alias already exists in .bashrc"
fi

sudo apt install git-filter-repo
sudo apt install git
sudo apt install vim