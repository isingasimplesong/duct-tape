#!/usr/bin/env bash

# Vérifier si ImageMagick est installé
if ! command -v convert &>/dev/null; then
    echo "ImageMagick n'est pas installé"
    exit 1
fi

input_dir="$HOME/Images/woll"
output_dir="$HOME/Images/walls_converted"

# Variable pour définir le numéro de départ
start_count=1

# Traiter les arguments de ligne de commande
while getopts ":s:i:o:" opt; do
    case $opt in
    s) # Supprimer les zéros au début et convertir en nombre
        start_count=$(echo "$OPTARG" | sed 's/^0*//')
        # Si la chaîne était juste des zéros, utiliser 0
        if [ -z "$start_count" ]; then
            start_count=0
        fi
        ;;
    i)
        input_dir="$OPTARG"
        ;;
    o)
        output_dir="$OPTARG"
        ;;
    \?)
        echo "Option invalide: -$OPTARG" >&2
        echo "Usage: $0 [-s numéro_départ] [-i dossier_entrée] [-o dossier_sortie]" >&2
        echo "Note: Le numéro de départ peut être au format 00023" >&2
        exit 1
        ;;
    :)
        echo "L'option -$OPTARG requiert un argument." >&2
        echo "Usage: $0 [-s numéro_départ] [-i dossier_entrée] [-o dossier_sortie]" >&2
        exit 1
        ;;
    esac
done

mkdir -p "$output_dir"

# Compteur pour le renommage séquentiel, initialisé avec start_count
count=$start_count

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
