#!/usr/bin/env bash

# in-place substitution for toggling tray in waybar
CONFIG_PATH="$HOME/.config/waybar/config.jsonc"
sed -i 's#^\s*//\("tray",\)#\1#;t;s#^\s*\("tray",\)#//\1#' $CONFIG_PATH
killall -SIGUSR2 waybar
