#!/usr/bin/env bash

MOUNT_POINT="/backups"
DEST="/backups/radium"
SOURCE="/home/mathieu/.config/rsync/in-rsync4duplicati.txt"
EXCLUDE="/home/mathieu/.config/rsync/ex-rsync4duplicati.txt"
LOG_FILE="/home/mathieu/.local/logs/rsync4duplicati.log"
NOTIFY_TITLE="Rsync"

source /root/secrets
USER_KEY="$PUSHOVER_USER_KEY"
API_TOKEN="$PUSHOVER_API_TOKEN"

# Fonction pour logger
log_message() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1 - $2" >> "$LOG_FILE"
}

# Fonction pour envoyer une notification Pushover
send_pushover_notification() {
    curl -s \
      --form-string "token=$API_TOKEN" \
      --form-string "user=$USER_KEY" \
      --form-string "message=$1" \
      --form-string "title=$NOTIFY_TITLE" \
      https://api.pushover.net/1/messages.json
}

# Vérification du point de montage
if ! mountpoint -q "$MOUNT_POINT"; then
    log_message "ERROR" "Point de montage $MOUNT_POINT absent"
    send_pushover_notification "Échec de rsync4duplicati : /backups non monté"
    exit 1
fi

# rsync
while IFS= read -r ligne
do
  echo "$ligne"
  if rsync -r -t -p -o -g -x --progress --delete -l -z -s --exclude-from "$EXCLUDE" "$ligne" "$DEST"; then
    log_message "OK" "Rsync réussi pour $ligne"
  else
    ERROR_MSG=$(rsync -r -t -p -o -g -x --progress --delete -l -z -s --exclude-from "$EXCLUDE" "$ligne" "$DEST" 2>&1)
    log_message "ERROR" "Rsync échoué pour $ligne: $ERROR_MSG"
    send_pushover_notification "Échec de rsync4duplicati pour $ligne: voir le log pour plus de détails"
  fi
done < "$SOURCE"
