#!/usr/bin/env bash
# in-place substitution for toggling layouts in hyprland
TOGGLE_PATH="/home/mathieu/.config/hypr/modules/envvar.conf"
sed -i 's/master/passeplat/;s/dwindle/master/;s/passeplat/dwindle/' $TOGGLE_PATH
notify-send "Layout toggled"
