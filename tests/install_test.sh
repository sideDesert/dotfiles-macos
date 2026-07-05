#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export PATH="$TEST_ROOT/bin:$PATH"
mkdir -p "$HOME/.config/doom" "$TEST_ROOT/bin"

printf 'old doom config\n' >"$HOME/.config/doom/config.el"
printf 'old tmux config\n' >"$HOME/.tmux.conf"

cat >"$TEST_ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/bin/brew"

"$REPO_DIR/install.sh"

for config_name in aerospace btop doom nvim raycast sketchybar television yazi zed; do
  config_destination="$HOME/.config/$config_name"
  [ -L "$config_destination" ]
  [ "$(readlink "$config_destination")" = "$REPO_DIR/$config_name" ]
done

[ -L "$HOME/.tmux.conf" ]
[ "$(readlink "$HOME/.tmux.conf")" = "$REPO_DIR/.tmux.conf" ]

doom_backup=("$HOME/.config/doom.bak."*)
tmux_backup=("$HOME/.tmux.conf.bak."*)
[ "${#doom_backup[@]}" -eq 1 ]
[ "${#tmux_backup[@]}" -eq 1 ]
grep -q 'old doom config' "${doom_backup[0]}/config.el"
grep -q 'old tmux config' "${tmux_backup[0]}"

"$REPO_DIR/install.sh"

[ "$(find "$HOME/.config" -maxdepth 1 -name 'doom.bak.*' | wc -l | tr -d ' ')" -eq 1 ]
[ "$(find "$HOME" -maxdepth 1 -name '.tmux.conf.bak.*' | wc -l | tr -d ' ')" -eq 1 ]

echo "install test passed"
