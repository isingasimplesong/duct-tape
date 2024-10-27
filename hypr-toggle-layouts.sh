#!/usr/bin/env bash
TOGGLE_PATH="/home/mathieu/.config/hypr/modules/envvar.conf"
sed -i 's/master/passeplat/;s/dwindle/master/;s/passeplat/dwindle/' $TOGGLE_PATH
