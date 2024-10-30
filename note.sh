#!/usr/bin/env bash

cd ~/Notes || exit

open_with_o-nvim() {
    local action=$1
    nvim +"autocmd VimEnter * Obsidian${action}" all/Todo.md
}

case "$1" in
"dailies")
    open_with_o-nvim "Dailies"
    ;;
"grep")
    open_with_o-nvim "Search"
    ;;
"journal")
    open_with_o-nvim "Today"
    ;;
"new-from-template")
    open_with_o-nvim "NewFromTemplate"
    ;;
"new")
    open_with_o-nvim "New"
    ;;
"quick-switch")
    open_with_o-nvim "QuickSwitch"
    ;;
"search-by-tags")
    open_with_o-nvim "Tags"
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
