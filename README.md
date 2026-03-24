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
Clash-based clients are strongly recommended (Clash Verge Rev first) because rule-based routing is required by tools like OpenCode.
Other clients are still detected, but may not work with all development tools.

### What's Included

| File | Description |
|------|-------------|
| `config/zshrc` | Zsh config with oh-my-zsh, Powerlevel10k, aliases, modern CLI tool integration |
| `config/tmux.conf` | Tmux config with Catppuccin Mocha theme, vim-style navigation |
| `config/p10k.zsh` | Powerlevel10k prompt theme config |
| `config/clash/config.yaml.example` | ClashX config template (fill in your server info) |
| `config/clash/config.meta.yaml.example` | Clash Meta (mihomo) template for Clash Verge Rev / Clash Verge |
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

1. **Auto-detect**: Scans local ports `7890`, `1081`, `10808`, `1080` — the first responding port is used
2. **Tool detection**: Checks for installed proxy tools (Clash Verge Rev, ClashX/ClashX Pro, Clash Verge, V2RayU, ShadowsocksX-NG)
3. **Guided startup**: If a tool is found but not running, prompts you to start it
4. **Client-aware config handling**:
   - **ClashX / ClashX Pro**: checks `~/.config/clash/config.yaml` and can generate/update it directly
   - **Clash Verge Rev / Clash Verge**: does **not** write to app-managed internal directories; offers to generate a Clash Meta config file for manual import
5. **Guided creation**: Prompts for Shadowsocks server details (address, port, password, cipher, name) and generates the matching config format for the detected client
6. **Verification**: Re-tests connectivity at key checkpoints after prompts

If no proxy tool is detected, the installer recommends Clash Verge Rev first.
- If Homebrew is already available, it offers auto-install via `brew install --cask clash-verge-rev`
- Otherwise it shows the official release download URL

**Primary recommendation (best compatibility):**
- Clash Verge Rev — https://github.com/clash-verge-rev/clash-verge-rev/releases
  - Clash-based rule routing is compatible with OpenCode and other development tools

**Also supported** (detected by installer, but may not work with all development tools):
- ClashX / ClashX Pro
- Clash Verge
- V2RayU
- ShadowsocksX-NG

Generated config output depends on the client:

- **ClashX / ClashX Pro**: `~/.config/clash/config.yaml` (`chmod 600`)
- **Clash Verge Rev / Clash Verge**: `~/Downloads/clash-meta-config.yaml` (`chmod 600`), then import in app via **Profiles → Local File**

Generated runtime config files are **never** stored in the repo.

Manual proxy control in the shell:

```bash
pon        # auto-detect proxy port (scans 7890, 1081, 10808, 1080)
pon 1081   # use specific port
poff       # disable proxy
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

The installer will guide you through proxy setup before downloading anything.
Clash-based clients are strongly recommended (Clash Verge Rev first) because rule-based routing is required by tools like OpenCode.
Other clients are still detected, but may not work with all development tools.

### What's Included

| File | Description |
|------|-------------|
| `config/powershell_profile.ps1` | PowerShell profile with Oh My Posh, aliases, modern CLI tool integration |
| `config/oh-my-posh-theme.omp.json` | Oh My Posh prompt theme with Catppuccin Mocha colors |
| `config/windows-terminal-catppuccin.json` | Catppuccin Mocha color scheme for Windows Terminal |
| `install.ps1` | Automated installer (idempotent, safe to re-run) |
| `uninstall.ps1` | Remove config files and restore backups |
| `config/wezterm.lua` | WezTerm config with Catppuccin Mocha theme, tmux-style keybindings, session persistence |

### Installed by `install.ps1`

**Tools** (via Scoop): `eza` `bat` `fd` `ripgrep` `fzf` `zoxide` `gh` `nodejs`

**WezTerm**: Terminal multiplexer with session persistence ([wezfurlong.org/wezterm](https://wezfurlong.org/wezterm))

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

### WezTerm (Terminal Multiplexer)

WezTerm provides tmux-like session persistence on Windows — your terminal sessions survive closing the window. Sessions are managed by a background mux server using Named Pipes.

**How it works:**
- **First launch**: WezTerm starts a background mux server and connects to it
- **Close window**: Sessions keep running in the background
- **Relaunch**: WezTerm reconnects to the existing mux server — all tabs and panes restored
- **Detach**: Press `CTRL+B`, then `d` to detach cleanly (window closes, sessions persist)

**Key bindings** (Leader = `CTRL+B`, same as tmux prefix):

| Key | Action |
|-----|--------|
| `Leader` + `\|` | Split pane horizontally |
| `Leader` + `-` | Split pane vertically |
| `Leader` + `c` | New tab |
| `Leader` + `h/j/k/l` | Navigate panes (vim-style) |
| `Leader` + `H/J/K/L` | Resize panes (5 units) |
| `Leader` + `1-9` | Switch to tab by number |
| `Leader` + `x` | Close current pane |
| `Leader` + `d` | Detach (session persists) |
| `Leader` + `r` | Reload config |

The status bar shows the workspace name (left) and date/time (right), matching the tmux layout.

### Proxy Setup

The installer runs an interactive proxy setup as the very first step:

1. **Auto-detect**: Scans local ports `7890`, `1081`, `10808`, `1080` — the first responding port is used
2. **Tool detection**: Checks for installed proxy tools (Clash Verge Rev / Clash Verge, v2rayN, Shadowsocks)
3. **Guided startup**: If a tool is found but not running, prompts you to start it
4. **Config check**: For Clash-based tools, looks for existing config at `~/.config/clash/config.yaml`
5. **Guided creation**: If no config exists, walks you through entering Shadowsocks server details (address, port, password, cipher) and generates the config
6. **Verification**: Re-tests connectivity at key checkpoints after prompts

If no proxy tool is detected, the installer recommends Clash Verge Rev first.
- If `winget` is available, it offers auto-install via `winget install --id ClashVergeRev.ClashVergeRev -e --accept-package-agreements --accept-source-agreements`
- Otherwise it shows the official release download URL

**Primary recommendation (best compatibility):**
- Clash Verge Rev — https://github.com/clash-verge-rev/clash-verge-rev/releases
  - Clash-based rule routing is compatible with OpenCode and other development tools

**Also supported** (detected by installer, but may not work with all development tools):
- v2rayN
- Shadowsocks

Manual proxy control in the shell:

```powershell
pon              # auto-detect proxy port (scans 7890, 1081, 10808, 1080)
pon -Port 1081   # use specific port
poff             # disable proxy
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
