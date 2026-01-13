#!/usr/bin/env bash

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Config
SOURCE="/home"
LOCAL_DEST="/snapshots"
DEST="/run/media/mathieu/ext_ssd/backups"
KEEP_LOCAL=10   # Number of local snapshots to keep
KEEP_DISTANT=31 # Number of remote snapshots to keep
# KEEP_DAILY=7  # Remote snapshot retention
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
    echo "Error: External drive is not mounted at $DEST"
    exit 1
fi

# Check last run
if [ -f "$LAST_RUN_FILE" ]; then
    last_run=$(cat "$LAST_RUN_FILE")
    days_since_last_run=$((($(date +%s) - $(date -d "$last_run" +%s)) / 86400))
    if [ $days_since_last_run -gt 7 ]; then
        echo "Warning: $days_since_last_run days have passed since the last backup."
    fi
else
    echo "First run detected."
fi

# Create a new read-only snapshot of /home
if sudo btrfs subvolume snapshot -r "$SOURCE" "$LOCAL_DEST/$SNAPSHOT_NAME"; then
    echo "Local snapshot created successfully: $LOCAL_DEST/$SNAPSHOT_NAME"
else
    echo "Error while creating local snapshot"
    exit 1
fi

# Send the snapshot to the destination
if [ -f "$LAST_SNAPSHOT_FILE" ]; then
    last_snapshot=$(cat "$LAST_SNAPSHOT_FILE")
    if [ -d "$LOCAL_DEST/$last_snapshot" ]; then
        echo "Sending an incremental snapshot..."
        if sudo btrfs send -p "$LOCAL_DEST/$last_snapshot" "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
            echo "Incremental snapshot sent successfully to $DEST/$SNAPSHOT_NAME"
        else
            echo "Error sending incremental snapshot. Attempting full send..."
            if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
                echo "Full snapshot sent successfully to $DEST/$SNAPSHOT_NAME"
            else
                echo "Error sending full snapshot"
                sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
                exit 1
            fi
        fi
    else
        echo "Previous snapshot does not exist locally. Sending a full snapshot..."
        if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
            echo "Full snapshot sent successfully to $DEST/$SNAPSHOT_NAME"
        else
            echo "Error sending full snapshot"
            sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
            exit 1
        fi
    fi
else
    echo "No previous snapshot found. Sending a full snapshot..."
    if sudo btrfs send "$LOCAL_DEST/$SNAPSHOT_NAME" | sudo btrfs receive "$DEST"; then
        echo "Full snapshot sent successfully to $DEST/$SNAPSHOT_NAME"
    else
        echo "Error sending full snapshot"
        sudo btrfs subvolume delete "$LOCAL_DEST/$SNAPSHOT_NAME"
        exit 1
    fi
fi

# Update tracking files
date +"%Y-%m-%d %H:%M:%S" >"$LAST_RUN_FILE"
echo "$SNAPSHOT_NAME" >"$LAST_SNAPSHOT_FILE"

# Local snapshot cleanup function
cleanup_local_snapshots() {
    echo "Cleaning up local snapshots..."
    local snapshots=($(ls -1d "$LOCAL_DEST"/20*_*-*-* | sort -r))
    local count=0
    for snapshot in "${snapshots[@]}"; do
        if [ $count -ge $KEEP_LOCAL ]; then
            echo "Deleting local snapshot: $snapshot"
            sudo btrfs subvolume delete "$snapshot"
        fi
        count=$((count + 1))
    done
}

# Remote snapshot cleanup function
cleanup_remote_snapshots() {
    echo "Cleaning up remote snapshots..."
    cd "$DEST" || exit

    local snapshots=($(ls -1d 20*_*-*-* | sort -r))

    for snapshot in "${snapshots[@]}"; do
        local age=$(get_age_days "$snapshot")

        # Delete all snapshots older than KEEP_DISTANT days
        if [ $age -gt $KEEP_DISTANT ]; then
            echo "Deleting remote snapshot: $snapshot"
            sudo btrfs subvolume delete "$snapshot"
        fi
    done
}

# Run cleanup
cleanup_local_snapshots
cleanup_remote_snapshots

echo "Backup and cleanup complete"
