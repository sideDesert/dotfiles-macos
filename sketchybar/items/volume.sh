#!/bin/bash

sketchybar --add item volume right \
           --set volume \
                         icon.font="SF Pro:Semibold:12.0" \
                         label.font="SF Pro:Semibold:12.0" \
                         background.drawing=off \
                         y_offset=0 \
                         padding_bottom=2 \
           script="$PLUGIN_DIR/volume.sh" \
	   --subscribe volume volume_change \
