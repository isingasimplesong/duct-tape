#!/usr/bin/env bash

if [ -f /tmp/keepawake.lock ] && kill -0 $(cat /tmp/keepawake.lock) 2>/dev/null; then
    echo '{"text": "󰄯", "tooltip": "Idle inhibited", "class": "keepawake"}'
else
    echo '{"text": "󰄰", "tooltip": "Idle not inhibited", "class": "no-keepawake"}'
fi
