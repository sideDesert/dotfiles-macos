#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=2 \
                      icon=􀧓  \
                      icon.font="SF Pro:Semibold:12.0" \
                      label.font="SF Pro:Semibold:12.0" \
                      background.drawing=off \
                      y_offset=0 \
                      padding_bottom=2 \
                      script="$PLUGIN_DIR/cpu.sh"
