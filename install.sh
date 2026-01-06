#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# Paths
# --------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

# --------------------------------------------------
# Helpers
# --------------------------------------------------
install_formula() {
  brew list "$1" >/dev/null 2>&1 || brew install "$1"
}

install_cask() {
  brew list --cask "$1" >/dev/null 2>&1 || brew install --cask "$1"
}

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$CONFIG_DIR/$1"

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "⚠️  Backing up existing config: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  echo "🔗 Linking $dst -> $src"
  ln -sfn "$src" "$dst"
}

# --------------------------------------------------
# Install packages
# --------------------------------------------------
install_cask aerospace
install_formula btop
install_formula neovim
install_formula tmux
install_cask raycast

brew tap FelixKratz/formulae
install_formula sketchybar

install_formula yazi
install_cask zed

# --------------------------------------------------
# Create symlinks
# --------------------------------------------------
link aerospace
link nvim
link tmux
link raycast
link sketchybar
link yazi
link zed
link .tmux.conf

echo "✅ Dotfiles installation complete"
