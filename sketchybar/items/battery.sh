#!/bin/bash

sketchybar --add item battery right \
           --set battery update_freq=120 \
                         icon.font="SF Pro:Semibold:12.0" \
                         label.font="SF Pro:Semibold:12.0" \
                         background.drawing=off \
                         y_offset=0 \
                         padding_bottom=2 \
                         script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
