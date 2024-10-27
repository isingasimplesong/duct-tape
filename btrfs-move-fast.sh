#!/usr/bin/env bash

# Vérifier les arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <source_pattern> <destination_directory>"
    exit 1
fi

# Le dernier argument est toujours la destination
DEST_DIR="${@: -1}"
# Tous les arguments sauf le dernier sont considérés comme des motifs source
SOURCE_PATTERNS=("${@:1:$#-1}")

# Créer le répertoire de destination s'il n'existe pas
mkdir -p "$DEST_DIR"

# Fonction pour déplacer rapidement un snapshot
move_snapshot_fast() {
    local src=$1
    local dest=$2
    local snapshot_name=$(basename "$src")

    echo "Déplacement rapide du snapshot $src vers $dest/$snapshot_name"

    # Créer un nouveau snapshot read-write à la destination
    sudo btrfs subvolume snapshot "$src" "$dest/$snapshot_name"

    if [ $? -eq 0 ]; then
        echo "Nouveau snapshot créé avec succès."

        # Supprimer l'ancien snapshot
        echo "Suppression de l'ancien snapshot..."
        sudo btrfs subvolume delete "$src"

        if [ $? -eq 0 ]; then
            echo "Ancien snapshot supprimé avec succès."
        else
            echo "Erreur lors de la suppression de l'ancien snapshot. Veuillez le supprimer manuellement."
        fi
    else
        echo "Erreur lors de la création du nouveau snapshot."
    fi
}

# Parcourir tous les motifs source
for pattern in "${SOURCE_PATTERNS[@]}"; do
    # Utiliser la commande find pour gérer les jokers
    while IFS= read -r -d $'\0' snapshot; do
        if [ -d "$snapshot" ]; then
            # Vérifier si c'est un sous-volume BTRFS
            if sudo btrfs subvolume show "$snapshot" &> /dev/null; then
                move_snapshot_fast "$snapshot" "$DEST_DIR"
            else
                echo "Ignoré: $snapshot n'est pas un sous-volume BTRFS."
            fi
        fi
    done < <(find "$(dirname "$pattern")" -maxdepth 1 -mindepth 1 -type d -name "$(basename "$pattern")" -print0)
done

echo "Opération terminée."
