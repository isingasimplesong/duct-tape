#!/usr/bin/env bash

# Vérifier si ImageMagick est installé
if ! command -v convert &>/dev/null; then
    echo "ImageMagick n'est pas installé"
    exit 1
fi

input_dir="$HOME/Images/walls"
output_dir="$HOME/Images/walls_converted"

mkdir -p "$output_dir"

# Compteur pour le renommage séquentiel
count=1

# Parcourir tous les fichiers PNG, WebP et JPG dans le répertoire d'entrée
find "$input_dir" -type f \( -iname "*.png" -o -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \) | while read file; do
    # Générer le nouveau nom de fichier
    new_name=$(printf "wall-%04d.webp" "$count")

    # Convertir et renommer le fichier
    magick "$file" "$output_dir/$new_name"

    echo "Converti : $file -> $output_dir/$new_name"

    # Incrémenter le compteur
    ((count++))
done

echo "Conversion terminée. Les nouveaux fichiers sont dans $output_dir"
