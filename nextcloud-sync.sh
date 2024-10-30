#!/usr/bin/env bash

# Nextcloud server URL
NEXTCLOUD_URL="$NC_URL"

# User credentials
USERNAME="$NC_LOGIN"
PASSWORD="$NC_AUTH"

# Define local and remote directory pairs
SYNC_DIRS="$NC_DIRS"

# Function to sync a single directory
sync_directory() {
    local_dir=$1
    remote_path=$2

    echo "Syncing $local_dir to $remote_path"
    nextcloudcmd \
        --user "$USERNAME" \
        --password "$PASSWORD" \
        --non-interactive \
        --silent \
        --path "$remote_path" \
        "$local_dir" \
        "$NEXTCLOUD_URL"

    if [ $? -eq 0 ]; then
        echo "Sync completed successfully for $local_dir"
    else
        echo "Sync failed for $local_dir"
    fi
}

# Main script
echo "Starting Nextcloud synchronization"

for pair in "${SYNC_DIRS[@]}"; do
    IFS=':' read -r local_dir remote_path <<<"$pair"
    sync_directory "$local_dir" "$remote_path"
done

echo "Synchronization process completed"
