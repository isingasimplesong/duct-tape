#!/usr/bin/env bash

declare -A URLS

URLS=(
  ["google"]="https://www.google.com/search?q="
  ["Brave Search"]="https://search.brave.com/search?q="
  ["Arch Wiki"]="https://wiki.archlinux.org/title/"
  ["youtube"]="https://www.youtube.com/results?search_query="
  ["imdb"]="http://www.imdb.com/find?ref_=nv_sr_fn&q="
  ["rottentomatoes"]="https://www.rottentomatoes.com/search/?search="
)

# List for rofi
gen_list() {
  for i in "${!URLS[@]}"; do
    echo "$i"
  done
}

main() {
  # Pass the list to rofi
  platform=$( (gen_list) | rofi -dmenu -matching fuzzy -no-custom -location 0 -p "Search > ")

  if [[ -n "$platform" ]]; then
    query=$( (echo) | rofi -dmenu -matching fuzzy -location 0 -p "Query > ")

    if [[ -n "$query" ]]; then
      url=${URLS[$platform]}$query
      xdg-open "$url"
    else
      exit
    fi

  else
    exit
  fi
}

main

exit 0
