#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
info()  { echo -e "\033[0;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "This will remove symlinks and restore backups if available."
echo ""
read -rp "Continue? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

TARGETS=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.p10k.zsh")

LATEST_BACKUP=$(ls -dt "$HOME/.dotfiles-backup"/*/ 2>/dev/null | head -1)

for target in "${TARGETS[@]}"; do
  name="$(basename "$target")"
  if [[ -L "$target" ]]; then
    rm "$target"
    ok "Removed symlink $target"
    if [[ -n "${LATEST_BACKUP:-}" && -f "$LATEST_BACKUP/$name" ]]; then
      cp "$LATEST_BACKUP/$name" "$target"
      ok "Restored $name from backup"
    fi
  else
    warn "$target is not a symlink, skipping"
  fi
done

echo ""
echo -e "${GREEN}Uninstall complete.${NC} Installed tools (brew packages, oh-my-zsh, etc.) were NOT removed."
echo "To remove those manually:"
echo "  brew uninstall eza bat fd ripgrep fzf zoxide"
echo "  rm -rf ~/.oh-my-zsh"
echo ""
