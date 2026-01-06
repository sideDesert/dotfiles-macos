#!/bin/bash

# $1 is the SID passed from the items loop (e.g., 1, 2, 3)
# $FOCUSED_WORKSPACE is the variable sent by AeroSpace's trigger
source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on \
                         background.color=$ACCENT_COLOR \
                         label.color=$ITEM_BG_COLOR
else
    sketchybar --set "$NAME" background.drawing=off \
                         label.color=$WHITE
    			 background.color=$ITEM_BG_COLOR
fi
