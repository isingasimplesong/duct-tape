#!/usr/bin/env bash

# Récupère les meilleurs miroirs
mirrors=$(curl -s "https://archlinux.org/mirrorlist/?country=CA&country=US&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -)

# Sauvegarde l'ancien miroir
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# Ecrit la nouvelle liste de miroirs avec les permissions nécessaires
echo "$mirrors" | sudo tee /etc/pacman.d/mirrorlist >/dev/null

# Affiche un message de confirmation
echo "Mirrorlist updated. New mirrors are:"
cat /etc/pacman.d/mirrorlist
