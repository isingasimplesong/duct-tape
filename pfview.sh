#!/usr/bin/env bash

result=$(ticker print --config ~/Coffre/portfolio.yaml | jq -r '.[] | "\(.symbol | sub("-CAD"; "")): \((.value | tonumber * 100 | floor) / 100 // 0)"')

if [ $? -ne 0 ]; then
    notify-send "Error" "Failed to fetch data"
    exit 1
fi

LC_NUMERIC=C
notify-send "Portfolio" "$result"
