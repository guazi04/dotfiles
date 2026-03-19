# dotfiles

Cross-platform terminal configuration for macOS and Windows — clone the repo and run the installer for your OS.

---

## macOS

### Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/guazi04/dotfiles.git ~/dotfiles

# 2. Run installer (interactive proxy setup runs first)
cd ~/dotfiles && ./install.sh
```

The installer will guide you through proxy setup before downloading anything.
You need a Shadowsocks server and ClashX installed as the client.

### What's Included

| File | Description |
|------|-------------|
| `config/zshrc` | Zsh config with oh-my-zsh, Powerlevel10k, aliases, modern CLI tool integration |
| `config/tmux.conf` | Tmux config with Catppuccin Mocha theme, vim-style navigation |
| `config/p10k.zsh` | Powerlevel10k prompt theme config |
| `config/clash/config.yaml.example` | ClashX config template (fill in your server info) |
| `install.sh` | Automated installer (idempotent, safe to re-run) |
| `uninstall.sh` | Remove symlinks and restore backups |

### Installed by `install.sh`

**Tools** (via Homebrew): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `tmux` `gh` `node`

**uv** (official installer): Python package manager ([astral.sh/uv](https://astral.sh/uv))

**Bun** (official installer): JavaScript runtime ([bun.sh](https://bun.sh))

**Zsh**: oh-my-zsh + Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting + zsh-completions

**Font**: MesloLGS Nerd Font

### After Install

1. Set terminal font to **MesloLGS Nerd Font Mono** (14pt)
2. Open a new terminal — Powerlevel10k wizard will auto-start

### Proxy Setup

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

### Python (uv)

`uv` is the default Python package manager (`UV_PYTHON_PREFERENCE=managed`).

| Alias | Command |
|-------|---------|
| `pip` | `uv pip` |
| `venv` | `uv venv` |
| `pyi` | `uv pip install` |
| `pyu` | `uv pip install --upgrade` |

### GitHub CLI

The installer runs `gh auth login` interactively. Token is managed by gh's keyring — no environment variable needed.

### Secrets

`~/.secrets` holds machine-specific keys (git-ignored, `chmod 600`). The installer creates it interactively if it doesn't exist; an existing file is never overwritten.

Currently managed:

- `INTSIG_API_KEY` — prompted during install
- `GITHUB_TOKEN` — managed by `gh` keyring (do not set as env var)

### Uninstall

```bash
cd ~/dotfiles && ./uninstall.sh
```

---

## Windows

### Prerequisites

- **PowerShell 7+** (pwsh) is required. Windows PowerShell 5.1 is NOT supported.
  ```powershell
  winget install Microsoft.PowerShell
  ```
- Do **not** run the installer as Administrator — it installs to your user profile only.

### Quick Start

```powershell
# 1. Clone this repo
git clone https://github.com/guazi04/dotfiles.git $env:USERPROFILE\dotfiles

# 2. Run installer with pwsh (interactive proxy setup runs first)
cd $env:USERPROFILE\dotfiles; pwsh -File .\install.ps1
```

The installer auto-detects local proxy on common ports (1081, 7890, 10808, 1080) before downloading.

### What's Included

| File | Description |
|------|-------------|
| `config/powershell_profile.ps1` | PowerShell profile with Oh My Posh, aliases, modern CLI tool integration |
| `config/oh-my-posh-theme.omp.json` | Oh My Posh prompt theme with Catppuccin Mocha colors |
| `config/windows-terminal-catppuccin.json` | Catppuccin Mocha color scheme for Windows Terminal |
| `install.ps1` | Automated installer (idempotent, safe to re-run) |
| `uninstall.ps1` | Remove config files and restore backups |

### Installed by `install.ps1`

**Tools** (via Scoop): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `gh` `nodejs`

**Oh My Posh**: Prompt theme engine with Catppuccin Mocha theme ([ohmyposh.dev](https://ohmyposh.dev))

**uv** (official installer): Python package manager ([astral.sh/uv](https://astral.sh/uv))

**Bun** (official installer): JavaScript runtime ([bun.sh](https://bun.sh))

**Font**: MesloLGS Nerd Font (via Scoop)

### After Install

1. The installer tries to auto-configure Windows Terminal (`settings.json`) with:
   - `"colorScheme": "Catppuccin Mocha"`
   - `"font.face": "MesloLGS Nerd Font"`
   - `"font.size": 14`
2. If auto-configuration is skipped/failed, apply it manually:
   Open WT Settings → click "Open JSON file" at bottom-left → merge into `"schemes"` array:
   ```jsonc
   {
     "schemes": [
       // ... existing schemes ...
       // paste contents of config/windows-terminal-catppuccin.json here
     ]
   }
   ```
3. Open a new PowerShell window to see the new prompt

### Proxy Setup

The installer auto-detects a local proxy by trying ports `1081`, `7890`, `10808`, `1080` in order. The first port that responds is used. No manual configuration needed.

Works with any proxy tool: Shadowsocks, Clash Verge, v2ray, etc.

Manual proxy control in the shell:

```powershell
pon           # auto-detect proxy port
pon -Port 1081  # use specific port
poff          # disable proxy
```

### Python (uv)

Same aliases as macOS:

| Alias | Command |
|-------|---------|
| `pip` | `uv pip` |
| `venv` | `uv venv` |
| `pyi` | `uv pip install` |
| `pyu` | `uv pip install --upgrade` |

### Uninstall

```powershell
cd $env:USERPROFILE\dotfiles; .\uninstall.ps1
```
