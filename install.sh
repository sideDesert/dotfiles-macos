#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

link() {
  local src="$DOTFILES_DIR/$1"
  local dst="$CONFIG_DIR/$1"

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "⚠️  Backing up existing directory: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  echo "🔗 Linking $dst -> $src"
  ln -sfn "$src" "$dst"
}

# --------------------------------------------------
# Install packages
# --------------------------------------------------

brew install --cask nikitabobko/tap/aerospace
brew install btop
brew install neovim
brew install tmux
brew install --cask raycast
brew tap FelixKratz/formulae
brew install sketchybar
brew install yazi
brew install --cask zed
brew install tmux
brew tap FelixKratz/formulae
brew install borders

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
