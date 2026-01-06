#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------
# Paths
# --------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
APPLICATIONS_DIR="/Applications"

mkdir -p "$CONFIG_DIR"

# --------------------------------------------------
# Helpers
# --------------------------------------------------
install_formula() {
  brew list "$1" >/dev/null 2>&1 || brew install "$1"
}

install_cask() {
  local token="$1"
  local app_name="$2"

  # Skip if Homebrew already manages it
  if brew list --cask "$token" >/dev/null 2>&1; then
    return
  fi

  # Skip if app already exists on disk
  if [ -d "$APPLICATIONS_DIR/$app_name.app" ]; then
    echo "ℹ️  $app_name already exists, skipping install"
    return
  fi

  brew install --cask "$token"
}

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$CONFIG_DIR/$1"

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak"
  fi

  ln -sfn "$src" "$dst"
}

# --------------------------------------------------
# Taps
# --------------------------------------------------
brew tap nikitabobko/tap
brew tap FelixKratz/formulae

# --------------------------------------------------
# Installs
# --------------------------------------------------
install_cask nikitabobko/tap/aerospace AeroSpace
install_formula btop
install_formula neovim
install_formula tmux
install_cask raycast Raycast
install_formula sketchybar
install_formula yazi
install_cask zed Zed

# --------------------------------------------------
# Symlinks
# --------------------------------------------------
link aerospace
link nvim
link tmux
link raycast
link sketchybar
link yazi
link zed

echo "✅ Done"
