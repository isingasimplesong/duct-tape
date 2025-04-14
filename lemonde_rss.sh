#!/bin/bash

# Dépendances : curl, xmlstarlet, notify-send

URL="https://www.lemonde.fr/rss/une.xml"

# Récupère le flux RSS
feed=$(curl -s "$URL")

# Extrait les titres des items (limité à 5 pour éviter le spam)
titles=$(echo "$feed" | xmlstarlet sel -t -m '//item' -v 'title' -n | head -n 5)

# Envoie une notification par titre
while IFS= read -r title; do
    notify-send -t 15000 "Le Monde" "$title"
    sleep 1 # petite pause pour éviter les notifications simultanées
done <<<"$titles"
