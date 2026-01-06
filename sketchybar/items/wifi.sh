#!/bin/bash

sketchybar --add item wifi right \
           --set wifi update_freq=30 \
                         icon="􀙇" \
                         icon.font="SF Pro:Semibold:12.0" \
                         label.font="SF Pro:Semibold:12.0" \
                         background.drawing=off \
                         y_offset=0 \
                         padding_bottom=2 \
                         script="$PLUGIN_DIR/wifi.sh"

