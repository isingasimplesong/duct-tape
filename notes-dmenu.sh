#!/usr/bin/env bash

run="kitty -e"
LOCAL_BIN=".local/bin"

options=$(
    cat <<-END
Nouvelle note
Depuis un modèle
Journal
Journaux récents
Chercher dans le contenu
Chercher dans le titre
Chercher par tags
Réviser Inbox
Todo
Accueil
END
)

selected=$(echo -e "$options" | rofi -i -dmenu -p "Notes :" | tr -d '\n')

case "$selected" in
"Nouvelle note")
    $run $HOME/$LOCAL_BIN/note.sh new
    ;;
"Depuis un modèle")
    $run $HOME/$LOCAL_BIN/note.sh new-from-template
    ;;
"Journal")
    $run $HOME/$LOCAL_BIN/note.sh journal
    ;;
"Journaux récents")
    $run $HOME/$LOCAL_BIN/note.sh dailies
    ;;
"Chercher dans le contenu")
    $run $HOME/$LOCAL_BIN/note.sh grep
    ;;
"Chercher dans le titre")
    $run $HOME/$LOCAL_BIN/note.sh quick-switch
    ;;
"Chercher par tags")
    $run $HOME/$LOCAL_BIN/note.sh search-by-tags
    ;;
"Réviser Inbox")
    $run $HOME/$LOCAL_BIN/note.sh inbox
    ;;
"Todo")
    $run nvim ~/Notes/all/Todo.md
    $run $HOME/$LOCAL_BIN/note.sh todo
    ;;
"Accueil")
    $run $HOME/$LOCAL_BIN/note.sh home
    ;;
*)
    echo "Option non valide ou annulée."
    ;;
esac
