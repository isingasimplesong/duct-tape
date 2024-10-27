#!/usr/bin/env bash

LAST_RUN=$(systemctl --user show snapshot-reminder.service --property=ExecMainExitTimestamp | cut -d= -f2)
CURRENT_TIME=$(date +%s)
LAST_RUN_SECONDS=$(date -d "$LAST_RUN" +%s)
TIME_DIFF=$((CURRENT_TIME - LAST_RUN_SECONDS))

if [ $TIME_DIFF -gt 86400 ]; then  # 86400 secondes = 24 heures
    systemctl --user start snapshot-reminder.service
fi
