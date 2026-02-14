# dotfiles

macOS terminal configuration — one command to restore on any new Mac.

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles

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

**Tools** (via Homebrew): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `tmux`

**Zsh**: oh-my-zsh + Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting + zsh-completions

**Font**: MesloLGS Nerd Font

## After Install

1. Set terminal font to **MesloLGS Nerd Font Mono** (14pt)
2. Open a new terminal — Powerlevel10k wizard will auto-start
3. Add secrets to `~/.secrets` (not tracked by git)

## ClashX

Clash config contains proxy credentials and is **git-ignored**. On a new Mac:

1. Copy `config/clash/config.yaml.example` → `config/clash/config.yaml`
2. Fill in your actual server/password
3. Run `./install.sh` — it restores ClashX config first and waits for you to enable proxy before downloading everything else

## Secrets

Machine-specific keys go in `~/.secrets` (git-ignored):

```bash
export INTSIG_API_KEY=your_key_here
```

## Uninstall

```bash
cd ~/dotfiles && ./uninstall.sh
```
