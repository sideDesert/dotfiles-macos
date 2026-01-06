#!/bin/bash

sketchybar --add item calendar right \
           --set calendar \
           update_freq=30 \
                         label.font="SF Pro:Semibold:12.0" \
                         background.drawing=off \
                         y_offset=0 \
                         padding_bottom=2 \
           script="$PLUGIN_DIR/calendar.sh"
