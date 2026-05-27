# linux-deploy-scripts

Scripts and config files to customize a fresh Linux machine into a comfortable working environment.
Supports **Debian/Ubuntu** (apt) and **CentOS/RHEL** (yum/dnf).

## Usage

```bash
./linux-deploy.sh          # interactive mode — prompts for each step
./linux-deploy.sh -s       # silent/script mode — no prompts, uses defaults
./linux-deploy.sh -s -u    # silent mode + OS upgrade
./linux-deploy.sh -h       # help
```

The script must be run from its own directory (so `configs/` is reachable).

## What it does

### System
- Detects the Linux distribution and selects the appropriate package manager
- Updates the package cache; optionally upgrades the OS
- Adds a convenience entry to `/etc/hosts`

### Packages

| Package | Debian/Ubuntu | CentOS/RHEL |
|---------|--------------|-------------|
| nmap, screen, htop, mc, bzip2, psmisc | ✓ | ✓ |
| zsh, autojump, fzf, bat | ✓ | ✓ (via EPEL) |
| grc, httpie, jq, curl, make | ✓ | ✓ (via EPEL) |
| python3-pygments | ✓ | ✓ (via EPEL) |
| molly-guard, ruby-albino | ✓ | — not available |
| eza (modern ls replacement) | ✓ (apt) | ✓ (binary from GitHub, arch-aware) |
| dnsutils / bind-utils | ✓ | ✓ |

On Debian/Ubuntu, `bat` is symlinked from `batcat` automatically.

### vim
- Installs vim with the [Solarized](https://ethanschoonover.com/solarized/) colour scheme
- Installs plugins via [vim-plug](https://github.com/junegunn/vim-plug)

### zsh
- Installs [Oh-my-zsh](https://ohmyz.sh) (skipped if already present)
- Installs [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
- Installs plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`
- Copies customized `zshrc` and `grc.zsh` (colourized command output)
- Optionally changes the default shell to zsh

### Root screen session (root only)
- Copies `screenrc` and `zprofile` to `/root/`
- After `su -`, zsh automatically starts or resumes a persistent `screen` session named `work`

### Docker (optional, default: skip)
- Adds the official Docker repository
- Installs `docker-ce`, `containerd`, `docker-buildx-plugin`, `docker-compose-plugin`
- Enables the Docker service and adds the current user to the `docker` group

### SSH hardening (optional, default: skip)
- Disables password authentication (`PasswordAuthentication no`)
- Disables root SSH login (`PermitRootLogin no`)
- Disables empty passwords (`PermitEmptyPasswords no`)
- Backs up `sshd_config` with a timestamp before any changes
- Validates the new config with `sshd -t` and auto-restores the backup on failure
- **Requires SSH keys to be in place before enabling — you will be locked out otherwise**

### Git
- Sets global `user.email` and `user.name` (prompted in interactive mode)

## Config files

| File | Description |
|------|-------------|
| `configs/zshrc` | zsh config with eza aliases, grc colours, fzf, p10k |
| `configs/p10kzsh` | powerlevel10k prompt config |
| `configs/grc.zsh` | grc colour wrappers for common commands |
| `configs/vimrc` | vim config |
| `configs/vim_colors_solarized.vim` | Solarized colour scheme for vim |
| `configs/screenrc` | screen status bar config (root) |
| `configs/zprofile` | auto-start/resume screen on login (root) |

## Other scripts

- `ubuntu-deploy.sh` — original Ubuntu-only script (kept for reference)
- `redhat-deploy.sh` — original RedHat/CentOS script (kept for reference)
