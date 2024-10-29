#!/usr/bin/env bash

cd ~/Notes || exit

open_with_obsidian() {
    local action=$1
    nvim +"autocmd VimEnter * Obsidian${action}" all/Todo.md
}

case "$1" in
"dailies")
    open_with_obsidian "Dailies"
    ;;
"grep")
    open_with_obsidian "Search"
    ;;
"journal")
    open_with_obsidian "Today"
    ;;
"new-from-template")
    open_with_obsidian "NewFromTemplate"
    ;;
"new")
    open_with_obsidian "New"
    ;;
"quick-switch")
    open_with_obsidian "QuickSwitch"
    ;;
"search-by-tags")
    open_with_obsidian "Tags"
    ;;
"todo")
    nvim all/Todo.md
    ;;
"home")
    nvim all/Home.md
    ;;
"inbox")
    nvim inbox/*
    ;;
*)
    echo "Usage: $(basename "$0") {dailies|grep|journal|new-from-template|new|quick-switch|search-by-tags|todo|home|inbox}"
    exit 1
    ;;
esac
