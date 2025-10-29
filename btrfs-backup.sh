#!/usr/bin/env bash

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Config
SOURCE="/home"
LOCAL_DEST="/snapshots"
DEST="/run/media/mathieu/ext_ssd/backups"
KEEP_LOCAL=10   # Nombre de snapshots locaux à conserver
KEEP_DISTANT=31 # Nombre de snapshots distant à conserver
# KEEP_DAILY=7  # Rétention des snapshots distants
# KEEP_WEEKLY=4
# KEEP_MONTHLY=6
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
SNAPSHOT_NAME="$DATE"
LAST_RUN_FILE="$DEST/.last_run"
LAST_SNAPSHOT_FILE="$DEST/.last_snapshot"

get_age_days() {
    local file=$1
    local file_time=$(date -r "$file" +%s)
    local current_time=$(date +%s)
    echo $(((current_time - file_time) / 86400))
}

if ! mountpoint -q "$DEST/.."; then
    echo "Erreur: Le disque externe n'est pas monté sur $DEST"
    exit 1
fi

# Vérifier la dernière exécution
if [ -f "$LAST_RUN_FILE" ]; then
    last_run=$(cat "$LAST_RUN_FILE")
    days_since_last_run=$((($(date +%s) - $(date -d "$last_run" +%s)) / 86400))
    if [ $days_since_last_run -gt 7 ]; then
        echo "Attention: $days_since_last_run jours se sont écoulés depuis la dernière sauvegarde."
    fi
else
    echo "Première exécution détectée."
fi

# Créer un nouveau snapshot en lecture seule de /home
if sudo btrfs subvolume snapshot -r "$SOURCE" "$LOCAL_DEST/$SNAPSHOT_NAME"; then
    echo "Snapshot local créé avec succès: $LOCAL_DEST/$SNAPSHOT_NAME"
else
    echo "Erreur lors de la création du snapshot local"
    exit 1
fi

# Envoyer le snapshot vers la destination
if [ -f "$LAST_SNAPSHOT_FILE" ]; then
    last_snapshot=$(cat "$LAST_SNAPSHOT_FILE")
    if [ -d "$LOCAL_DEST/$last_snapshot" ]; then
        echo "Envoi d'un snapshot incrémentiel..."
        if sudo btrfs send -p "$LOCAL_DEST/$last_snapshot" "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
            echo "Snapshot incrémental envoyé avec succès vers $DEST/$SNAPSHOT_NAME"
        else
            echo "Erreur lors de l'envoi du snapshot incrémentiel. Tentative d'envoi complet..."
            if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
                echo "Snapshot complet envoyé avec succès vers $DEST/$SNAPSHOT_NAME"
            else
                echo "Erreur lors de l'envoi du snapshot complet"
                sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
                exit 1
            fi
        fi
    else
        echo "Le snapshot précédent n'existe pas localement. Envoi d'un snapshot complet..."
        if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
            echo "Snapshot complet envoyé avec succès vers $DEST/$SNAPSHOT_NAME"
        else
            echo "Erreur lors de l'envoi du snapshot complet"
            sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
            exit 1
        fi
    fi
else
    echo "Aucun snapshot précédent trouvé. Envoi d'un snapshot complet..."
    if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
        echo "Snapshot complet envoyé avec succès vers $DEST/$SNAPSHOT_NAME"
    else
        echo "Erreur lors de l'envoi du snapshot complet"
        sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
        exit 1
    fi
fi

# Mettre à jour les fichiers de suivi
date +"%Y-%m-%d %H:%M:%S" >"$LAST_RUN_FILE"
echo "$SNAPSHOT_NAME" >"$LAST_SNAPSHOT_FILE"

# Fonction de nettoyage des snapshots locaux
cleanup_local_snapshots() {
    echo "Nettoyage des snapshots locaux..."
    local snapshots=($(ls -1d "$LOCAL_DEST"/20*_*-*-* | sort -r))
    local count=0
    for snapshot in "${snapshots[@]}"; do
        if [ $count -ge $KEEP_LOCAL ]; then
            echo "Suppression du snapshot local: $snapshot"
            sudo btrfs subvolume delete "$snapshot"
        fi
        count=$((count + 1))
    done
}

# Fonction de nettoyage des snapshots sur la destination
cleanup_remote_snapshots() {
    echo "Nettoyage des snapshots distants..."
    cd "$DEST" || exit

    local snapshots=($(ls -1d 20*_*-*-* | sort -r))

    for snapshot in "${snapshots[@]}"; do
        local age=$(get_age_days "$snapshot")

        # Supprimer tous les snapshots plus vieux que 31 jours
        if [ $age -gt $KEEP_DISTANT ]; then
            echo "Suppression du snapshot distant: $snapshot"
            sudo btrfs subvolume delete "$snapshot"
        fi
    done
}

# Exécuter le nettoyage
cleanup_local_snapshots
cleanup_remote_snapshots

echo "Sauvegarde et nettoyage terminés"
