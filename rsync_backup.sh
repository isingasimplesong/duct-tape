#!/usr/bin/env bash

# Rsync backup script for linux, with dry-run, log rotation, locking, and pushover notification (on failure only)

set -euo pipefail

CONF="${RSYNC_CONF:-$HOME/.config/rsync_backup.conf}"
LOCKFILE="/tmp/rsync_backup.lock"
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--help]

Options:
  --dry-run        Simulate the rsync backup without modifying any files
  --help, -h       Show this help message and exit

Description:
  This script performs an rsync-based backup based on paths listed in a source file.
  It supports log rotation, pushover notifications (only on failure), and ensures only one instance runs at a time.
  It's written with linux in mind. On Mac OS or *BSD, you'd probably have to make a few adjustments

Configuration:
  The script expects a configuration file exporting the following variables:

    BACKUP_MOUNT_POINT     # mount point where backup destination is available
    BACKUP_DESTINATION     # destination directory for rsync backup
    BACKUP_SOURCE_FILE     # file listing source paths to back up (one per line)
    EXCLUDE_FILE           # rsync exclude patterns (one per line)
    BACKUP_LOG_FILE        # path to log file
    LOGROTATE_MAX_SIZE     # max log file size in MB before rotation

  Optional (for pushover notifications):

    PUSHOVER_USER_KEY
    PUSHOVER_API_TOKEN
    NOTIFY_TITLE           # (optional) title shown in push notifications

Default configuration file path: \$HOME/.config/rsync_backup.conf
Example configuration file : https://log.2027a.net/posts/sauvegardes-avec-rsync/#le-fichier-de-configuration

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run)
        DRY_RUN=1
        shift
        ;;
    --help | -h)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

if [ ! -f "$CONF" ]; then
    echo "Configuration file not found: $CONF"
    exit 1
fi

source "$CONF"

# Check required commands
missing_cmds=()
for cmd in rsync mountpoint curl gzip stat flock; do
    command -v "$cmd" >/dev/null || missing_cmds+=("$cmd")
done
if [ "${#missing_cmds[@]}" -ne 0 ]; then
    echo "Missing command(s): ${missing_cmds[*]}"
    exit 1
fi

# Check required vars
required_vars=(BACKUP_MOUNT_POINT BACKUP_DESTINATION BACKUP_SOURCE_FILE EXCLUDE_FILE BACKUP_LOG_FILE LOGROTATE_MAX_SIZE)
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Missing required variable in config: $var"
        exit 1
    fi
done

# Optional pushover
HAS_PUSHOVER=0
if [[ -n "${PUSHOVER_USER_KEY:-}" && -n "${PUSHOVER_API_TOKEN:-}" ]]; then
    HAS_PUSHOVER=1
fi

# Functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1 - $2" >>"$BACKUP_LOG_FILE"
}

notify_pushover() {
    [ "$HAS_PUSHOVER" -eq 1 ] || return
    curl -s \
        --form-string "token=$PUSHOVER_API_TOKEN" \
        --form-string "user=$PUSHOVER_USER_KEY" \
        --form-string "message=$1" \
        --form-string "title=${NOTIFY_TITLE:-rsync_backup}" \
        https://api.pushover.net/1/messages.json >/dev/null
}

log_rotate() {
    local max_size=$((LOGROTATE_MAX_SIZE * 1024 * 1024))
    if [ -f "$BACKUP_LOG_FILE" ] && [ "$(stat -c%s "$BACKUP_LOG_FILE")" -ge "$max_size" ]; then
        for i in 3 2 1; do
            [ -f "${BACKUP_LOG_FILE%.log}.$i.gz" ] && mv "${BACKUP_LOG_FILE%.log}.$i.gz" "${BACKUP_LOG_FILE%.log}.$((i + 1)).gz"
        done
        gzip -c "$BACKUP_LOG_FILE" >"${BACKUP_LOG_FILE%.log}.1.gz"
        : >"$BACKUP_LOG_FILE"
    fi
}

run_rsync() {
    local failures=0
    local success=0

    while IFS= read -r src_path || [[ -n "$src_path" ]]; do
        [ -z "$src_path" ] && continue
        [ ! -e "$src_path" ] && log "SKIP" "Path not found: $src_path" && continue

        if [ "$DRY_RUN" -eq 1 ]; then
            #rsync_args=(-anx --delete --exclude-from "$EXCLUDE_FILE" "$src_path" "$BACKUP_DESTINATION")
            rsync_args=(-anx --delete --inplace --no-inc-recursive --exclude-from "$EXCLUDE_FILE" "$src_path" "$BACKUP_DESTINATION")
        else
            #rsync_args=(-axs --delete --exclude-from "$EXCLUDE_FILE" "$src_path" "$BACKUP_DESTINATION")
            rsync_args=(-axs --delete --inplace --no-inc-recursive --exclude-from "$EXCLUDE_FILE" "$src_path" "$BACKUP_DESTINATION")
        fi

        RSYNC_OUTPUT=$(rsync "${rsync_args[@]}" 2>&1)
        rsync_exit=$?

        if [ $rsync_exit -eq 0 ]; then
            log "OK" "Synced: $src_path"
            success=$((success + 1))
        else
            log "ERROR" "Failed: $src_path: $RSYNC_OUTPUT"
            failures=$((failures + 1))
        fi
    done <"$BACKUP_SOURCE_FILE"

    echo "$success success, $failures failure(s)"
    return $failures
}

main() {
    log_rotate

    # Secure lockfile creation
    umask 0077
    if ! touch "$LOCKFILE" 2>/dev/null; then
        echo "Error: Cannot create lockfile at $LOCKFILE" >&2
        exit 1
    fi

    # Open the lock file and assign it to FD9
    exec 9>"$LOCKFILE" || {
        echo "Error: Cannot open lockfile: $LOCKFILE" >&2
        exit 1
    }

    # Try to acquire the lock on FD9
    if ! flock -n 9; then
        echo "Another backup is already running (lockfile in use)." >&2
        exit 1
    fi

    # Ensure lockfile is deleted on exit
    cleanup() {
        rm -f "$LOCKFILE"
    }
    trap cleanup EXIT

    [ ! -f "$BACKUP_SOURCE_FILE" ] && log "ERROR" "Missing source file" && exit 1
    [ ! -f "$EXCLUDE_FILE" ] && log "ERROR" "Missing exclude file" && exit 1

    if ! mountpoint -q "$BACKUP_MOUNT_POINT"; then
        log "ERROR" "Mount point $BACKUP_MOUNT_POINT not found"
        notify_pushover "Backup failed: $BACKUP_MOUNT_POINT not mounted"
        exit 1
    fi

    log "START" "Rsync backup started (dry-run=$DRY_RUN)"
    result=$(run_rsync)
    status=$?

    log "END" "Backup complete. $result"
    if [ $status -ne 0 ]; then
        notify_pushover "Rsync backup failed: $result"
    fi

    echo "$result"
    exit $status
}

main
