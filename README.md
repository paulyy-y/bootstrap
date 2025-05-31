# bootstrap

A simple shell script to bootstrap your development environment on Debian-based systems. Installs essential tools, configures your shell, and sets up useful aliases and defaults.

## Features
- Installs packages like: git, git-filter-repo, git-lfs, curl, make, vim, neovim, tmux, fish, ranger, tldr, fzf, htop
- Configures your shell to use `fish` by default
- Sets up useful aliases and environment variables
- Cleans up unnecessary `cdrom` entries from apt sources

## Requirements
- Debian-based Linux distribution (e.g., Debian, Ubuntu)
   - Tested on Debian 12
- `bash` shell to run the script
- `sudo` privileges

## Usage
```sh
bash bootstrap.sh
```

The script will:
1. Remove any `cdrom` entries from `/etc/apt/sources.list`
2. Update your package lists
3. Install the required packages
4. Set `fish` as your default shell in your RC file
5. Set up some handy aliases and environment variables in `fish`

After running, your shell will switch to `fish` by default. You may need to restart your terminal for all changes to take effect.

## Website
[bootstrap.paulyy.com](https://bootstrap.paulyy.com)

## Contributing
Fork your own version and make your changes 😌
