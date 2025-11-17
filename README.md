## bootstrap

Bootstrap a fresh Debian/Ubuntu machine with common CLI tools and sensible defaults. Includes helper functions for local network scanning and basic k3s install workflows.

### What it does
- Installs CLI tools via `apt`: git, git-filter-repo, git-lfs, curl, make, vim, neovim, tmux, fish, ranger, tldr, fzf, nmap, avahi-utils, open-iscsi, nfs-common, net-tools, htop
- Removes `cdrom:` entries from `/etc/apt/sources.list` (avoids apt update errors on minimal installs)
- Appends `exec fish` to your detected shell rc file (`~/.bashrc` or `~/.zshrc`) if not already present
- Configures fish:
  - `EDITOR` set to `nvim` (universal var)
  - Saves aliases: `vim -> nvim`, `ll -> ls -la`
  - Removes fish greeting
- Sets global git default branch name to `main`

Note: This does not change your login shell; it simply runs fish from your rc file.

### Requirements
- Debian/Ubuntu (or any distro with `apt`)
- `sudo` privileges
- Run with `bash`

### Usage
```bash
git clone https://github.com/yourname/bootstrap.git
cd bootstrap
bash bootstrap.sh
```

If prompted for your password, it is required for `apt` and file changes under `/etc`.

### Optional helpers
- `functions.sh` provides a simple local network scan:
```bash
source ./functions.sh
scan_local_network
```

- `k3s_setup_functions.sh` provides minimal helpers for installing k3s:
```bash
export K3S_TOKEN="your-shared-token"
# For joining or pointing to an existing server:
export SERVER_IP="10.0.0.10"

source ./k3s_setup_functions.sh
# Install a server pointing to an existing server:
k3s_install_server
# OR initialize a new cluster server (no SERVER_IP needed):
k3s_install_cluster_server
# OR install an agent that joins an existing server:
k3s_install_agent
```

### Undo/adjustments
- Remove auto-start of fish:
  - From `~/.bashrc` or `~/.zshrc`, delete the line `exec fish`
- Adjust fish settings: open `~/.config/fish/` to edit/remove saved aliases or universal variables as desired

### License
See `LICENSE`.