#!/usr/bin/env bash

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

selected=$(echo -e "$options" | rofi -i -dmenu -p "Carnet :" | tr -d '\n')

case "$selected" in
"Nouvelle note")
    kitty -e /home/mathieu/.local/bin/note.sh new
    ;;
"Depuis un modèle")
    kitty -e /home/mathieu/.local/bin/note.sh new-from-template
    ;;
"Journal")
    kitty -e /home/mathieu/.local/bin/note.sh journal
    ;;
"Journaux récents")
    kitty -e /home/mathieu/.local/bin/note.sh dailies
    ;;
"Chercher dans le contenu")
    kitty -e /home/mathieu/.local/bin/note.sh grep
    ;;
"Chercher par nom")
    kitty -e /home/mathieu/.local/bin/note.sh quick-switch
    ;;
"Chercher par tags")
    kitty -e /home/mathieu/.local/bin/note.sh search-by-tags
    ;;
"Réviser Inbox")
    kitty -e /home/mathieu/.local/bin/note.sh inbox
    ;;
"Todo")
    kitty -e nvim ~/Notes/all/Todo.md
    kitty -e /home/mathieu/.local/bin/note.sh todo
    ;;
"Accueil")
    kitty -e /home/mathieu/.local/bin/note.sh home
    ;;
*)
    echo "Option non valide ou annulée."
    ;;
esac
