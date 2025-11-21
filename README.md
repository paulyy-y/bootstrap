## bootstrap

Bootstrap scripts for setting up development environments on Linux and Windows with common CLI tools and sensible defaults. Includes helper functions for local network scanning and basic k3s install workflows.

---

## Linux (Debian/Ubuntu) - `bootstrap.sh`

### What it does
- Installs CLI tools via `apt`: git, git-filter-repo, git-lfs, curl, make, vim, neovim, tmux, zsh, ranger, tldr, fzf, nmap, avahi-utils, open-iscsi, nfs-common, net-tools, htop
- Removes `cdrom:` entries from `/etc/apt/sources.list` (avoids apt update errors on minimal installs)
- Sets up Zsh with plugins (autosuggestions, syntax highlighting)
- Configures Zsh with:
  - Custom prompt with git branch status
  - FZF integration (Ctrl+R for history, Ctrl+T for file search)
  - Unix-style keybindings (Ctrl+A/E for beginning/end of line)
  - Aliases: `vim -> nvim`, `ll -> ls -lah`, `l -> ls -lh`
  - Git aliases: `g`, `gs`, `ga`, `gc`, `gp`, `gl`
- Generates an `ed25519` SSH keypair (uses your global git email if available)
- Sets global git default branch name to `main` and `core.autocrlf=false`

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

---

## Windows (PowerShell) - `bootstrap.ps1`

### What it does
- Installs tools via `winget`: Git, Neovim, FZF
- Installs PowerShell modules: PSFzf, PSReadLine
- Configures PowerShell profile with:
  - FZF integration (Ctrl+R for history, Ctrl+T for file search)
  - Inline prediction/autocomplete (ghost text)
  - Unix/Emacs-style keybindings:
    - `Ctrl+A` - Beginning of line
    - `Ctrl+E` - Accept suggestion or end of line
    - `Ctrl+D` - Exit if line empty, else delete char
    - `Ctrl+K` - Kill to end of line
    - `Ctrl+U` - Kill to beginning of line
    - `Ctrl+W` - Kill word backward
  - Custom prompt with git branch status
  - Aliases: `vim -> nvim`
  - ls aliases: `ll` (with hidden files), `l` (short)
  - Git aliases: `g`, `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, `gb`, `gco`, `gpl`, `gst`
- Sets global git default branch name to `main` and `core.autocrlf=input`

### Requirements
- Windows 10/11
- PowerShell 5.1+ or PowerShell 7+ (pwsh)
- `winget` (Windows Package Manager) - usually pre-installed on Windows 11
- Run as current user (no admin required for most operations)

### Usage
```powershell
git clone https://github.com/yourname/bootstrap.git
cd bootstrap
.\bootstrap.ps1
```

The script runs in user context and configures your PowerShell profile automatically.

### Undo/adjustments (Linux)
- Remove auto-start of zsh:
  - From `~/.bashrc` or `~/.zshrc`, delete the line `exec zsh -l`
- Adjust zsh settings: edit `~/.zshrc` to modify aliases, keybindings, or prompt as desired

### Undo/adjustments (Windows)
- The PowerShell profile is managed in sections marked with `# --- Minimal Setup START ---` and `# --- Minimal Setup END ---`
- To remove all configuration: edit `$PROFILE` and delete the section between these markers
- To customize: edit `$PROFILE` and modify the configuration block (note: running bootstrap again will replace it)

---

## Optional helpers (Linux only)

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

### License
See `LICENSE`.