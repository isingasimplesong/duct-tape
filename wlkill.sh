#!/usr/bin/env bash

# Obtenir l'ID de la fenêtre active
WINDOW_ID=$(hyprctl activewindow -j | jq '.address')

if [ -z "$WINDOW_ID" ]; then
    notify-send "Erreur" "Aucune fenêtre active trouvée"
    exit 1
fi

# Obtenir le PID du processus
PID=$(hyprctl clients -j | jq ".[] | select(.address == $WINDOW_ID) | .pid")

if [ -z "$PID" ]; then
    notify-send "Erreur" "Impossible de trouver le PID de la fenêtre"
    exit 1
fi

# Tuer le processus
kill -9 $PID

# Notifier l'utilisateur
notify-send "Fenêtre tuée" "PID: $PID"
