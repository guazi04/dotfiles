# dotfiles

macOS terminal configuration — one command to restore on any new Mac.

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/guazi04/dotfiles.git ~/dotfiles

# 2. Copy your ClashX config (not in repo — has credentials)
cp /path/to/your/clash/config.yaml ~/dotfiles/config/clash/config.yaml

# 3. Run installer (ClashX config is restored first, then prompts you to enable proxy)
cd ~/dotfiles && ./install.sh
```

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

**Tools** (via Homebrew): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `tmux` `gh` `node` `uv`

**Zsh**: oh-my-zsh + Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting + zsh-completions

**Font**: MesloLGS Nerd Font

## After Install

1. Set terminal font to **MesloLGS Nerd Font Mono** (14pt)
2. Open a new terminal — Powerlevel10k wizard will auto-start

## ClashX

Clash config contains proxy credentials and is **git-ignored**. On a new Mac:

1. Copy `config/clash/config.yaml.example` → `config/clash/config.yaml`
2. Fill in your actual server/password
3. Run `./install.sh` — it restores ClashX config first and waits for you to enable proxy before downloading everything else

## Proxy

Proxy is auto-detected at shell startup. If ClashX is running, it's enabled automatically; if not, nothing is set.

Manual control:

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

The installer runs `gh auth login` interactively. After that, `GITHUB_TOKEN` is exported automatically from `gh auth token` at shell startup — no manual config needed.

## Secrets

`~/.secrets` holds machine-specific keys (git-ignored). The installer creates it interactively if it doesn't exist; an existing file is never overwritten.

Currently managed:

- `INTSIG_API_KEY` — prompted during install
- `GITHUB_TOKEN` — managed by `gh auth login`, not stored in `~/.secrets`

## Uninstall

```bash
cd ~/dotfiles && ./uninstall.sh
```
