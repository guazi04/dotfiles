# dotfiles

macOS terminal configuration — clone the repo and run the installer.

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/guazi04/dotfiles.git ~/dotfiles

# 2. Run installer (interactive proxy setup runs first)
cd ~/dotfiles && ./install.sh
```

The installer will guide you through proxy setup before downloading anything.
You need a Shadowsocks server and ClashX installed as the client.

## What's Included

| File | Description |
|------|-------------|
| `config/zshrc` | Zsh config with oh-my-zsh, Powerlevel10k, aliases, modern CLI tool integration |
| `config/tmux.conf` | Tmux config with Catppuccin Mocha theme, vim-style navigation |
| `config/p10k.zsh` | Powerlevel10k prompt theme config |
| `config/clash/config.yaml.example` | ClashX config template (fill in your server info) |
| `install.sh` | Automated installer (idempotent, safe to re-run) |
| `uninstall.sh` | Remove symlinks and restore backups |

## Installed by `install.sh`

**Tools** (via Homebrew): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `tmux` `gh` `node`

**uv** (official installer): Python package manager ([astral.sh/uv](https://astral.sh/uv))

**Bun** (official installer): JavaScript runtime ([bun.sh](https://bun.sh))

**Zsh**: oh-my-zsh + Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting + zsh-completions

**Font**: MesloLGS Nerd Font

## After Install

1. Set terminal font to **MesloLGS Nerd Font Mono** (14pt)
2. Open a new terminal — Powerlevel10k wizard will auto-start

## Proxy Setup

The installer runs an interactive proxy setup as the very first step:

1. **Auto-detect**: Tests if proxy is already working at `127.0.0.1:7890`
2. **ClashX check**: Verifies ClashX is installed, shows download URL if not
3. **Config check**: Looks for existing config at `~/.config/clash/config.yaml`
4. **Guided creation**: If no config exists, walks you through entering Shadowsocks server details (address, port, password, cipher) and generates the config
5. **Verification**: Asks you to enable ClashX System Proxy, then verifies connectivity

**Requirements**: A Shadowsocks server. The installer will ask for:
- Server address (required)
- Port (default: 38883)
- Password (required)
- Cipher (default: chacha20-ietf-poly1305)

The generated config is written to `~/.config/clash/config.yaml` with `chmod 600`. It is **never** stored in the repo.

Manual proxy control in the shell:

```bash
pon   # enable proxy
poff  # disable proxy
```

## Python (uv)

`uv` is the default Python package manager (`UV_PYTHON_PREFERENCE=managed`).

| Alias | Command |
|-------|---------|
| `pip` | `uv pip` |
| `venv` | `uv venv` |
| `pyi` | `uv pip install` |
| `pyu` | `uv pip install --upgrade` |

## GitHub CLI

The installer runs `gh auth login` interactively. Token is managed by gh's keyring — no environment variable needed.

## Secrets

`~/.secrets` holds machine-specific keys (git-ignored, `chmod 600`). The installer creates it interactively if it doesn't exist; an existing file is never overwritten.

Currently managed:

- `INTSIG_API_KEY` — prompted during install
- `GITHUB_TOKEN` — managed by `gh` keyring (do not set as env var)

## Uninstall

```bash
cd ~/dotfiles && ./uninstall.sh
```
