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

# Git-secrets
git clone https://github.com/awslabs/git-secrets.git ~/bootstrap/git-secrets
sudo make install -C ~/bootstrap/git-secrets
rm -r ~/bootstrap/git-secrets

# BFG Repo Cleaner
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.13.2/bfg-1.13.2.jar -O ~/bootstrap/bfg.jar
if [ -f ~/.zshrc ]; then
    echo "alias bfg='java -jar ~/bootstrap/bfg.jar'" >> ~/.zshrc
else
    echo "alias bfg='java -jar ~/bootstrap/bfg.jar'" >> ~/.bashrc
fi

sudo apt install git-filter-repo
sudo apt install git
sudo apt install vim