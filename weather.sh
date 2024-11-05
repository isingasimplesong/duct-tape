#!/usr/bin/env bash
weather_cities="Montreal"
notify-send -t 6000 "$(curl -s "wttr.in/{$weather_cities}?format=4")"
