#!/usr/bin/env bash
# =============================================================================
# dotfiles installer — one command to restore full macOS terminal setup
# Usage: curl -fsSL <raw-url>/install.sh | bash
#    or: cd ~/dotfiles && ./install.sh
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

# ─── Step 0: Proxy (FIRST — everything else downloads faster) ────────────────
CLASH_SRC="$DOTFILES_DIR/config/clash/config.yaml"
CLASH_DIR="$HOME/.config/clash"
CLASH_DEST="$CLASH_DIR/config.yaml"

setup_proxy() {
  if curl -sS --connect-timeout 3 --proxy http://127.0.0.1:7890 https://www.google.com >/dev/null 2>&1; then
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export all_proxy=socks5://127.0.0.1:7891
    ok "Proxy is working (http://127.0.0.1:7890)"
    return 0
  fi
  return 1
}

if setup_proxy; then
  ok "Proxy already active, skipping ClashX setup"
elif [[ -f "$CLASH_DEST" ]]; then
  ok "ClashX config already exists at $CLASH_DEST"
  echo ""
  echo -e "  ${YELLOW}Open ClashX and enable System Proxy, then press Enter${NC}"
  read -rp "  Press Enter when ready..."
  setup_proxy || warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
else
  if [[ ! -d "/Applications/ClashX.app" ]]; then
    echo ""
    echo -e "  ${RED}ClashX is NOT installed.${NC}"
    echo ""
    echo "  Download from: https://en.clashx.org/download/"
    echo "  Or search:     ClashX 1.118.0 dmg"
    echo ""
    read -rp "  Press Enter after installing ClashX (or Enter to skip)..."
  fi

  if [[ -f "$CLASH_SRC" ]]; then
    info "Restoring ClashX config from dotfiles..."
    mkdir -p "$CLASH_DIR"
    cp "$CLASH_SRC" "$CLASH_DEST"
    ok "Config restored → $CLASH_DEST"
  else
    warn "No ClashX config found (not in dotfiles, not on system)"
    echo ""
    echo "  To configure now, paste your config below (Ctrl+D when done),"
    echo "  or just press Ctrl+D to skip:"
    echo ""
    mkdir -p "$CLASH_DIR"
    if content=$(cat 2>/dev/null) && [[ -n "$content" ]]; then
      echo "$content" > "$CLASH_DEST"
      ok "Config written → $CLASH_DEST"
    else
      warn "Skipped — no config provided"
    fi
  fi

  if [[ -f "$CLASH_DEST" ]]; then
    echo ""
    echo -e "  ${YELLOW}Now open ClashX and enable System Proxy, then press Enter${NC}"
    read -rp "  Press Enter when ready (or Enter to skip)..."
    setup_proxy || warn "Proxy not reachable, continuing without proxy (downloads may be slow)"
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
BREW_PACKAGES=(eza bat fd ripgrep fzf zoxide tmux gh)
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    brew install "$pkg"
    ok "$pkg installed"
  fi
done

# ─── Step 3: Nerd Font ──────────────────────────────────────────────────────
info "Checking Nerd Font..."
if ls ~/Library/Fonts/MesloLGSNerdFont* &>/dev/null 2>&1; then
  ok "MesloLGS Nerd Font already installed"
else
  info "Installing MesloLGS Nerd Font..."
  brew install --cask font-meslo-lg-nerd-font
  ok "MesloLGS Nerd Font installed"
fi

# ─── Step 3.5: NVM + Bun ────────────────────────────────────────────────────
info "Checking NVM..."
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  ok "NVM already installed"
else
  info "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || true
  [[ -s "$HOME/.nvm/nvm.sh" ]] || fail "NVM installation failed. Check network/proxy and re-run."
  ok "NVM installed"
fi

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
)
LINK_DSTS=(
  "$HOME/.zshrc"
  "$HOME/.tmux.conf"
  "$HOME/.p10k.zsh"
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

# ─── Step 8: Create secrets template ────────────────────────────────────────
if [[ ! -f "$HOME/.secrets" ]]; then
  info "Creating ~/.secrets template..."
  cat > "$HOME/.secrets" << 'SECRETS_EOF'
# Machine-specific secrets — NOT tracked by git
# export INTSIG_API_KEY=your_key_here
# export GITHUB_TOKEN=your_token_here
SECRETS_EOF
  ok "~/.secrets template created (edit with your actual keys)"
else
  ok "~/.secrets already exists, not overwriting"
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
echo ""
echo "  3. Add your secrets to ~/.secrets"
echo "     e.g.: export INTSIG_API_KEY=your_key_here"
echo ""
echo "  Backups saved to: $BACKUP_DIR"
echo ""
