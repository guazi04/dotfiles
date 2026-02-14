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

# ─── Step 0: ClashX proxy config (FIRST — everything else downloads faster) ─
info "Restoring ClashX config..."
CLASH_SRC="$DOTFILES_DIR/config/clash/config.yaml"
CLASH_DIR="$HOME/.config/clash"
if [[ -f "$CLASH_SRC" ]]; then
  mkdir -p "$CLASH_DIR"
  if [[ -f "$CLASH_DIR/config.yaml" && ! -L "$CLASH_DIR/config.yaml" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$CLASH_DIR/config.yaml" "$BACKUP_DIR/clash-config.yaml"
    warn "Backed up existing clash config"
  fi
  cp "$CLASH_SRC" "$CLASH_DIR/config.yaml"
  ok "ClashX config restored → ~/.config/clash/config.yaml"
  echo ""
  echo -e "  ${YELLOW}>>> Open ClashX now and enable System Proxy <<<${NC}"
  echo -e "  ${YELLOW}>>> Then press Enter to continue (proxy speeds up all downloads) <<<${NC}"
  echo ""
  read -rp "  Press Enter when proxy is ready (or Enter to skip)..."
  echo ""
else
  warn "ClashX config not found in dotfiles, skipping"
fi

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
BREW_PACKAGES=(eza bat fd ripgrep fzf zoxide tmux)
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

# ─── Step 4: Oh My Zsh ──────────────────────────────────────────────────────
info "Checking Oh My Zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  ok "Oh My Zsh already installed"
else
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── Step 5: Powerlevel10k ──────────────────────────────────────────────────
info "Checking Powerlevel10k..."
if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  ok "Powerlevel10k already installed"
else
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
  ok "Powerlevel10k installed"
fi

# ─── Step 6: Zsh plugins ────────────────────────────────────────────────────
info "Checking Zsh plugins..."
declare -A ZSH_PLUGINS=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  [zsh-completions]="https://github.com/zsh-users/zsh-completions"
)
for plugin in "${!ZSH_PLUGINS[@]}"; do
  if [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    ok "$plugin already installed"
  else
    info "Installing $plugin..."
    git clone "${ZSH_PLUGINS[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
    ok "$plugin installed"
  fi
done

# ─── Step 7: Symlink dotfiles ───────────────────────────────────────────────
info "Linking dotfiles..."

# Files to link: source → target
declare -A LINKS=(
  ["$DOTFILES_DIR/config/zshrc"]="$HOME/.zshrc"
  ["$DOTFILES_DIR/config/tmux.conf"]="$HOME/.tmux.conf"
  ["$DOTFILES_DIR/config/p10k.zsh"]="$HOME/.p10k.zsh"
)

mkdir -p "$BACKUP_DIR"

for src in "${!LINKS[@]}"; do
  target="${LINKS[$src]}"
  if [[ ! -f "$src" ]]; then
    warn "Source $src not found, skipping"
    continue
  fi
  # Backup existing file (if it's a real file, not already our symlink)
  if [[ -f "$target" && ! -L "$target" ]]; then
    cp "$target" "$BACKUP_DIR/$(basename "$target")"
    warn "Backed up $(basename "$target") → $BACKUP_DIR/"
  fi
  # Remove existing and create symlink
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
