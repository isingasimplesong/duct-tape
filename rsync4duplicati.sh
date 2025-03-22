#!/usr/bin/env bash

CONF="/home/mathieu/.config/rsync4duplicati.conf"

if [ ! -f "$CONF" ]; then
  echo "Configuration file not found!"
  exit 1
fi

source "$CONF"

MOUNT_POINT="$BACKUP_MOUNT_POINT"
DEST="$BACKUP_DESTINATION"
SOURCE="$BACKUP_SOURCE"
EXCLUDE="$EXCLUDE_FILE"
LOG_FILE="$BACKUP_LOG_FILE"
USER_KEY="$PUSHOVER_USER_KEY"
API_TOKEN="$PUSHOVER_API_TOKEN"
SIZE="$LOGROTATE_MAX_SIZE"

# log function
log_message() {
  if [[ -z "$1" && -z "$2" ]]; then
    echo "" >>"$LOG_FILE"
  else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1 - $2" >>"$LOG_FILE"
  fi
}

# check prerequisites
for file in "$SOURCE" "$EXCLUDE"; do
  if [ ! -f "$file" ]; then
    log_message "ERROR" "Required file $file not found!"
    exit 1
  fi
done

if [[ -z "${PUSHOVER_USER_KEY:-}" || -z "${PUSHOVER_API_TOKEN:-}" ]]; then
  log_message "ERROR" "Pushover credentials missing"
  exit 1
fi

# rotate log if > $SIZE
log_rotate() {
  if [ -f "$LOG_FILE" ]; then
    local filesize
    filesize=$(stat -c%s "$LOG_FILE")
    local max_size=$((SIZE * 1024 * 1024))
    if [ "$filesize" -ge "$max_size" ]; then
      # remove older log
      if [ -f "${LOG_FILE%.log}.5.gz" ]; then
        rm -f "${LOG_FILE%.log}.5.gz"
      fi
      # rotate files
      for i in $(seq 4 -1 1); do
        if [ -f "${LOG_FILE%.log}.${i}.gz" ]; then
          mv "${LOG_FILE%.log}.${i}.gz" "${LOG_FILE%.log}.$((i + 1)).gz"
        fi
      done
      # zip current log and clean it
      gzip -c "$LOG_FILE" >"${LOG_FILE%.log}.1.gz"
      : >"$LOG_FILE"
    fi
  fi
}

log_rotate

# Pushover notification
send_pushover_notification() {
  curl -s \
    --form-string "token=$API_TOKEN" \
    --form-string "user=$USER_KEY" \
    --form-string "message=$1" \
    --form-string "title=$NOTIFY_TITLE" \
    https://api.pushover.net/1/messages.json
}

if ! mountpoint -q "$MOUNT_POINT"; then
  log_message "ERROR" "$MOUNT_POINT is missing !"
  log_message "" ""
  send_pushover_notification "$HOST : Échec de rsync4duplicati : $MOUNT_POINT is missing"
  exit 1
fi

log_message "START" "Running Rsync backup..."

# rsync
while IFS= read -r src_path; do

  RSYNC_OUTPUT=$(rsync -axs --delete \
    --exclude-from "$EXCLUDE" "$src_path" "$DEST" 2>&1)

  rsync_exit_code=$?
  if [ $rsync_exit_code -eq 0 ]; then
    log_message "OK" "Successfully synced $src_path"
  else
    log_message "ERROR" "Rsync failed for $src_path: $RSYNC_OUTPUT"
    log_message "" ""
    send_pushover_notification "$HOST : Échec de rsync4duplicati pour $src_path: $RSYNC_OUTPUT"
  fi
done <"$SOURCE"

log_message "END" "Rsync complete !"
log_message "" ""
