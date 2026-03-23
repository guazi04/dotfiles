#!/usr/bin/env bash
# =============================================================================
# dotfiles installer — restore full macOS terminal setup
# Usage: cd ~/dotfiles && ./install.sh
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ─── Pre-flight ──────────────────────────────────────────────────────────────
[[ "$(uname)" == "Darwin" ]] || fail "This script is for macOS only."

echo ""
echo "============================================"
echo "  dotfiles installer for macOS"
echo "============================================"
echo ""
info "Starting installation..."

# ─── Step 0: Proxy (FIRST — everything else downloads faster) ────────────────
CLASH_DIR="$HOME/.config/clash"
CLASH_DEST="$CLASH_DIR/config.yaml"
CLASH_EXAMPLE="$DOTFILES_DIR/config/clash/config.yaml.example"

# Step 0a: Test if proxy is already working
test_proxy() {
  local ports=(7890 1081 10808 1080)
  for port in "${ports[@]}"; do
    if curl -sS --max-time 3 --proxy "http://127.0.0.1:$port" http://www.gstatic.com/generate_204 >/dev/null 2>&1; then
      export http_proxy="http://127.0.0.1:$port"
      export https_proxy="http://127.0.0.1:$port"
      export all_proxy="socks5://127.0.0.1:$port"
      DETECTED_PROXY_PORT=$port
      return 0
    fi
  done
  return 1
}

detect_proxy_tool() {
  # Returns the name of the first detected proxy tool (installed, not necessarily running)
  [[ -d "/Applications/ClashX.app" ]]           && echo "ClashX"           && return 0
  [[ -d "/Applications/ClashX Pro.app" ]]        && echo "ClashX Pro"       && return 0
  [[ -d "/Applications/Clash Verge Rev.app" ]]   && echo "Clash Verge Rev"  && return 0
  [[ -d "/Applications/Clash Verge.app" ]]       && echo "Clash Verge"      && return 0
  [[ -d "/Applications/V2RayU.app" ]]            && echo "V2RayU"           && return 0
  [[ -d "/Applications/ShadowsocksX-NG.app" ]]   && echo "ShadowsocksX-NG" && return 0
  return 1
}

# Step 0d: Interactive config creation from SS server details
create_clash_config() {
  echo ""
  info "Interactive Shadowsocks config setup"
  echo -e "  ${BLUE}Enter your Shadowsocks server details:${NC}"
  echo ""

  # Server address (required)
  local ss_server=""
  while [[ -z "$ss_server" ]]; do
    read -rp "  Server address (required): " ss_server < /dev/tty
    [[ -z "$ss_server" ]] && echo -e "  ${RED}Server address is required.${NC}"
  done

  # Port (default: 38883)
  read -rp "  Port [38883]: " ss_port < /dev/tty
  ss_port="${ss_port:-38883}"

  # Password (required, hidden)
  local ss_password=""
  while [[ -z "$ss_password" ]]; do
    echo -ne "  Password (required, hidden): "
    read -rs ss_password < /dev/tty
    echo ""
    [[ -z "$ss_password" ]] && echo -e "  ${RED}Password is required.${NC}"
  done

  # Cipher (default: chacha20-ietf-poly1305)
  read -rp "  Cipher [chacha20-ietf-poly1305]: " ss_cipher < /dev/tty
  ss_cipher="${ss_cipher:-chacha20-ietf-poly1305}"

  # Proxy name (default: SS-proxy)
  read -rp "  Proxy name [SS-proxy]: " ss_name < /dev/tty
  ss_name="${ss_name:-SS-proxy}"

  # Generate config from template structure
  mkdir -p "$CLASH_DIR"
  cat > "$CLASH_DEST" <<CLASH_EOF
#---------------------------------------------------#
## 配置文件需要放置在 \$HOME/.config/clash/*.yaml

## 这份文件是clashX的基础配置文件，请尽量新建配置文件进行修改。
## 端口设置请在 菜单条图标->配置->更多配置 中进行修改

## 如果您不知道如何操作，请参阅 官方Github文档 https://dreamacro.github.io/clash/
#---------------------------------------------------#

mode: rule
log-level: info

proxies:
  - name: "${ss_name}"
    type: ss
    server: '${ss_server}'
    port: ${ss_port}
    cipher: '${ss_cipher}'
    password: '${ss_password}'
    udp: true

proxy-groups:
  - name: Proxy
    type: select
    proxies:
      - '${ss_name}'
      - DIRECT

rules:
  # Google 走代理
  - DOMAIN-SUFFIX,google.com,Proxy
  - DOMAIN-SUFFIX,googleapis.com,Proxy
  - DOMAIN-SUFFIX,gstatic.com,Proxy

  # 其他
  - DOMAIN-SUFFIX,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - DOMAIN-SUFFIX,intsig.net,DIRECT
  - MATCH,Proxy
CLASH_EOF

  chmod 600 "$CLASH_DEST"
  ok "Config written → $CLASH_DEST (chmod 600)"
}

# ── Main proxy setup flow ──

if test_proxy; then
  ok "Proxy is working (127.0.0.1:$DETECTED_PROXY_PORT)"
else
  # Step 0b: Detect installed proxy tools
  PROXY_TOOL=$(detect_proxy_tool) || true
  if [[ -n "$PROXY_TOOL" ]]; then
    warn "$PROXY_TOOL is installed but proxy is not reachable on ports 7890, 1081, 10808, 1080"
    echo ""
    echo -e "  ${YELLOW}Please start $PROXY_TOOL and enable System Proxy, then press Enter${NC}"
    read -rp "  Press Enter when ready (or Enter to skip)..." _ < /dev/tty
    if test_proxy; then
      ok "Proxy is working (127.0.0.1:$DETECTED_PROXY_PORT)"
    else
      warn "Proxy still not reachable, continuing without proxy (downloads may be slow)"
    fi
  else
    echo ""
    echo -e "  ${YELLOW}No proxy tool detected.${NC}"
    echo ""
    echo "  Recommended: Clash Verge Rev"
    echo "    Why: rule-based routing works with OpenCode and other development tools"
    echo "         (plain Shadowsocks-style global tunneling can break API routing)"
    echo ""
    echo "  Supported tools: Clash Verge Rev, ClashX, Clash Verge, V2RayU, ShadowsocksX-NG"
    echo ""
    if command -v brew &>/dev/null; then
      read -rp "  Auto-install Clash Verge Rev now via Homebrew? [Y/n] " install_clash_verge_rev < /dev/tty
      if [[ ! "$install_clash_verge_rev" =~ ^[Nn]$ ]]; then
        info "Installing Clash Verge Rev via Homebrew cask..."
        if brew install --cask clash-verge-rev; then
          ok "Clash Verge Rev installed"
        else
          warn "Auto-install failed. Download manually: https://github.com/clash-verge-rev/clash-verge-rev/releases"
        fi
      else
        warn "Skipped auto-install"
      fi
    else
      warn "Homebrew is not available yet in Step 0"
      echo "  Download Clash Verge Rev: https://github.com/clash-verge-rev/clash-verge-rev/releases"
    fi
    echo ""
    echo "  Next in Clash Verge Rev:"
    echo "    1) Open the app"
    echo "    2) Import or create a config"
    echo "       (you can use $CLASH_DEST after generating it below)"
    echo "    3) Enable System Proxy"
    echo ""
    read -rp "  Press Enter after installing a proxy tool (or Enter to skip)..." _ < /dev/tty
    # Re-detect after user potentially installed something
    PROXY_TOOL=$(detect_proxy_tool) || true
    if test_proxy; then
      ok "Proxy is working (127.0.0.1:$DETECTED_PROXY_PORT)"
    else
      warn "Proxy still not reachable, continuing without proxy (downloads may be slow)"
    fi
  fi

  # Step 0c: Check / create Clash config (for Clash-based tools)
  if [[ -n "$PROXY_TOOL" ]] && [[ "$PROXY_TOOL" == Clash* ]]; then
    if [[ -f "$CLASH_DEST" ]]; then
      ok "Clash config already exists at $CLASH_DEST"
      if ! test_proxy; then
        echo ""
        echo -e "  ${YELLOW}Open $PROXY_TOOL and enable System Proxy, then press Enter${NC}"
        read -rp "  Press Enter when ready..." _ < /dev/tty
        if test_proxy; then
          ok "Proxy is working (127.0.0.1:$DETECTED_PROXY_PORT)"
        else
          warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
        fi
      fi
    else
      echo ""
      echo -e "  ${YELLOW}No Clash config found at $CLASH_DEST${NC}"
      echo ""
      read -rp "  Create config from Shadowsocks server info? [Y/n] " create_config < /dev/tty
      if [[ ! "$create_config" =~ ^[Nn]$ ]]; then
        create_clash_config
        echo ""
        echo -e "  ${YELLOW}Now open $PROXY_TOOL and enable System Proxy, then press Enter${NC}"
        read -rp "  Press Enter when ready..." _ < /dev/tty
        if test_proxy; then
          ok "Proxy is working (127.0.0.1:$DETECTED_PROXY_PORT)"
        else
          warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
        fi
      else
        warn "Skipped proxy config — downloads may be slow"
        echo "  You can create the config later: cp $CLASH_EXAMPLE $CLASH_DEST"
      fi
    fi
  fi
fi
echo ""

# ─── Step 1: Homebrew ────────────────────────────────────────────────────────
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# ─── Step 2: CLI tools via Homebrew ──────────────────────────────────────────
info "Installing CLI tools..."
BREW_PACKAGES=(eza bat fd ripgrep fzf zoxide tmux gh node)
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    brew install "$pkg"
    ok "$pkg installed"
  fi
done

# ─── Step 3.5a: uv (Python package manager) ─────────────────────────────────
info "Checking uv..."
if command -v uv &>/dev/null; then
  ok "uv already installed"
else
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || true
  # Source env to get uv in PATH for this session
  [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
  command -v uv &>/dev/null || fail "uv installation failed. Check network/proxy and re-run."
  ok "uv installed"
fi

# ─── Step 3: Nerd Font ──────────────────────────────────────────────────────
info "Checking Nerd Font..."
if ls ~/Library/Fonts/MesloLGSNerdFont* &>/dev/null 2>&1; then
  ok "MesloLGS Nerd Font already installed"
else
  info "Installing MesloLGS Nerd Font..."
  brew install --cask font-meslo-lg-nerd-font
  ok "MesloLGS Nerd Font installed"
fi

# ─── Step 3.5: Clean up NVM (if present) ────────────────────────────────────
if [[ -d "$HOME/.nvm" ]]; then
  warn "Found legacy NVM installation at ~/.nvm"
  echo -e "  Node.js is now managed by Homebrew. NVM is no longer needed."
  echo ""
  read -rp "  Remove ~/.nvm? [y/N] " remove_nvm < /dev/tty
  if [[ "$remove_nvm" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.nvm"
    ok "Removed ~/.nvm"
  else
    warn "Kept ~/.nvm — you can remove it later with: rm -rf ~/.nvm"
  fi
fi

# ─── Step 3.5b: Bun ─────────────────────────────────────────────────────────
info "Checking Bun..."
if command -v bun &>/dev/null || [[ -x "$HOME/.bun/bin/bun" ]]; then
  ok "Bun already installed"
else
  info "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash || true
  [[ -x "$HOME/.bun/bin/bun" ]] || fail "Bun installation failed. Check network/proxy and re-run."
  ok "Bun installed"
fi

# ─── Step 4: Oh My Zsh ──────────────────────────────────────────────────────
info "Checking Oh My Zsh..."
if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  ok "Oh My Zsh already installed"
else
  rm -rf "$HOME/.oh-my-zsh"
  info "Installing Oh My Zsh..."
  KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
  [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail "Oh My Zsh installation failed. Check network/proxy and re-run."
  ok "Oh My Zsh installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── Step 5: Powerlevel10k ──────────────────────────────────────────────────
info "Checking Powerlevel10k..."
if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  ok "Powerlevel10k already installed"
else
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
  [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || fail "Powerlevel10k installation failed. Check network/proxy and re-run."
  ok "Powerlevel10k installed"
fi

# ─── Step 6: Zsh plugins ────────────────────────────────────────────────────
info "Checking Zsh plugins..."
ZSH_PLUGIN_NAMES=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
ZSH_PLUGIN_URLS=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  "https://github.com/zsh-users/zsh-completions"
)
for i in "${!ZSH_PLUGIN_NAMES[@]}"; do
  plugin="${ZSH_PLUGIN_NAMES[$i]}"
  url="${ZSH_PLUGIN_URLS[$i]}"
  if [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    ok "$plugin already installed"
  else
    info "Installing $plugin..."
    git clone "$url" "$ZSH_CUSTOM/plugins/$plugin" || true
    [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]] || { warn "$plugin installation failed, skipping"; continue; }
    ok "$plugin installed"
  fi
done

# ─── Step 7: Symlink dotfiles ───────────────────────────────────────────────
info "Linking dotfiles..."

LINK_SRCS=(
  "$DOTFILES_DIR/config/zshrc"
  "$DOTFILES_DIR/config/tmux.conf"
  "$DOTFILES_DIR/config/p10k.zsh"
  "$DOTFILES_DIR/config/bunfig.toml"
)
LINK_DSTS=(
  "$HOME/.zshrc"
  "$HOME/.tmux.conf"
  "$HOME/.p10k.zsh"
  "$HOME/.bunfig.toml"
)

mkdir -p "$BACKUP_DIR"

for i in "${!LINK_SRCS[@]}"; do
  src="${LINK_SRCS[$i]}"
  target="${LINK_DSTS[$i]}"
  if [[ ! -f "$src" ]]; then
    warn "Source $src not found, skipping"
    continue
  fi
  if [[ -f "$target" && ! -L "$target" ]]; then
    cp "$target" "$BACKUP_DIR/$(basename "$target")"
    warn "Backed up $(basename "$target") → $BACKUP_DIR/"
  fi
  rm -f "$target"
  ln -sf "$src" "$target"
  ok "Linked $(basename "$target")"
done

# ─── Step 8: Configure secrets ────────────────────────────────────────────
if [[ ! -f "$HOME/.secrets" ]]; then
  info "Setting up ~/.secrets..."
  echo ""

  # Define secrets: "VAR_NAME:Description"
  secrets_to_configure=(
    "INTSIG_API_KEY:Intsig API Key"
  )

  # Create file with restrictive permissions
  (
    umask 077
    echo "# Machine-specific secrets — NOT tracked by git" > "$HOME/.secrets"
    echo "" >> "$HOME/.secrets"
  )

  for secret_pair in "${secrets_to_configure[@]}"; do
    var_name="${secret_pair%%:*}"
    var_desc="${secret_pair##*:}"

    echo -ne "  ${BLUE}${var_desc}${NC}: "
    read -rs secret_value < /dev/tty
    echo ""

    if [[ -n "$secret_value" ]]; then
      printf 'export %s=%q\n' "$var_name" "$secret_value" >> "$HOME/.secrets"
    else
      printf '# export %s=your_key_here\n' "$var_name" >> "$HOME/.secrets"
      warn "Skipped $var_desc (edit ~/.secrets later)"
    fi
  done

  chmod 600 "$HOME/.secrets"
  echo ""
  ok "~/.secrets created (chmod 600)"
else
  ok "~/.secrets already exists, not overwriting"
fi

# ─── Step 8.5: GitHub CLI authentication ────────────────────────────────
info "Checking GitHub CLI authentication..."
if gh auth status &>/dev/null 2>&1; then
  ok "GitHub CLI already authenticated"
else
  warn "GitHub CLI is not authenticated"
  echo ""
  echo -e "  ${BLUE}Interactive login will help you authenticate with GitHub.${NC}"
  echo "  This is optional — you can configure it manually later."
  echo ""
  read -rp "  Run 'gh auth login' now? [y/N] " gh_login < /dev/tty
  if [[ "$gh_login" =~ ^[Yy]$ ]]; then
    info "Starting GitHub CLI authentication..."
    if gh auth login; then
      ok "GitHub CLI authentication completed"
    else
      warn "GitHub CLI authentication failed (network or proxy issue?)"
      echo "  You can authenticate manually later with: gh auth login"
    fi
  else
    info "Skipping GitHub CLI authentication — configure manually with: gh auth login"
  fi
fi

# ─── Step 9: Reload tmux if running ─────────────────────────────────────────
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
  tmux source-file ~/.tmux.conf 2>/dev/null && ok "tmux config reloaded" || true
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo -e "  ${GREEN}All done!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Set terminal font to 'MesloLGS Nerd Font Mono' (14pt)"
echo "     Terminal.app: Preferences → Profiles → Text → Font → Change"
echo "     iTerm2:       Preferences → Profiles → Text → Font"
echo ""
echo "  2. Open a NEW terminal window"
echo "     Powerlevel10k wizard will auto-start (or run: p10k configure)"
echo "  Backups saved to: $BACKUP_DIR"
echo ""
