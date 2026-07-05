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

backup_and_link() {
  local source_path="$1"
  local destination_path="$2"

  if [ -e "$destination_path" ] && [ ! -L "$destination_path" ]; then
    local backup_path_prefix="$destination_path.bak.$(date +%Y%m%d%H%M%S)"
    local backup_path="$backup_path_prefix"
    local backup_number=1

    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
      backup_path="$backup_path_prefix.$backup_number"
      backup_number=$((backup_number + 1))
    done

    mv "$destination_path" "$backup_path"
  fi

  ln -sfn "$source_path" "$destination_path"
}

link_config() {
  backup_and_link "$DOTFILES_DIR/$1" "$CONFIG_DIR/$1"
}

link_home_file() {
  backup_and_link "$DOTFILES_DIR/$1" "$HOME/$1"
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
link_config aerospace
link_config btop
link_config doom
link_config nvim
link_config raycast
link_config sketchybar
link_config television
link_config yazi
link_config zed
link_home_file .tmux.conf

echo "✅ Done"
