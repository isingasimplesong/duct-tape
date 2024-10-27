#!/usr/bin/env bash

options=$(cat <<-END
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

selected=$(echo -e "$options" | rofi -i -dmenu -p "Carnet :")

case "$selected" in
    "Nouvelle note")
       kitty -e /home/mathieu/.local/bin/note-new.sh
        ;;
    "Depuis un modèle")
        kitty -e /home/mathieu/.local/bin/note-new-from-template.sh
        ;;
    "Journal")
        kitty -e /home/mathieu/.local/bin/note-journal.sh
        ;;
    "Journaux récents")
        kitty -e /home/mathieu/.local/bin/note-dailies.sh
        ;;
    "Chercher dans le contenu")
        kitty -e /home/mathieu/.local/bin/note-grep.sh
        ;;
    "Chercher par nom")
        kitty -e /home/mathieu/.local/bin/note-quick-switch.sh
        ;;
    "Chercher par tags")
        kitty -e /home/mathieu/.local/bin/note-search-by-tags.sh
        ;;
    "Réviser Inbox")
       kitty -e nvim ~/Notes/inbox/*
        ;;
    "Todo")
       kitty -e nvim ~/Notes/all/Todo.md
        ;;
    "Accueil")
       kitty -e nvim ~/Notes/all/Home.md
        ;;
    *)
        echo "Option non valide ou annulée."
        ;;
esac

