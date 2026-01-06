#!/bin/bash

# This script is for the space_separator item
# $FOCUSED_WORKSPACE is the variable from the AeroSpace trigger

source "$CONFIG_DIR/colors.sh"

# Get app names in the focused workspace
apps=$(/opt/homebrew/bin/aerospace list-windows --workspace "$FOCUSED_WORKSPACE" --format "%{app-name}" 2>/dev/null)

# Format app names (comma-separated, limit to first 3 if too many)
app_list=""
if [ -n "$apps" ]; then
  app_count=$(echo "$apps" | wc -l | tr -d ' ')
  app_names=$(echo "$apps" | head -3 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
  if [ "$app_count" -gt 3 ]; then
    app_list="$app_names..."
  else
    app_list="$app_names"
  fi
else
  app_list=""
fi

# Update the separator label with app names
if [ -z "$app_list" ]; then
  # Empty app list: show only arrow with accent color, no background
  sketchybar --set "$NAME" label="" \
                           label.color=$WHITE \
                           icon.color=$ACCENT_COLOR \
                           icon.drawing_opacity=0.5 \
                           background.drawing=off
else
  # Non-empty app list: show app names with accent color, arrow with accent color, no background
  sketchybar --set "$NAME" label="$app_list" \
                           label.color=$ACCENT_COLOR \
                           label.padding_left=4 \
                           label.padding_right=6 \
                           icon.color=$ACCENT_COLOR \
                           background.drawing=off
fi
