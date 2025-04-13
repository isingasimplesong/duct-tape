#!/usr/bin/env bash

LOCKFILE="/tmp/keepawake.lock"

print_help() {
  cat <<EOF
Usage: keepalive [OPTION]

  -a, --awake         Prevent idle by starting a background inhibitor
  -i, --allow-idle    Stop inhibitor and allow idle
  -t, --toggle        Toggle inhibition state
  -h, --help          Show this help message
EOF
}

is_inhibited() {
  [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")" 2>/dev/null
}

start_inhibit() {
  if is_inhibited; then
    echo "Already keeping awake (PID $(cat "$LOCKFILE"))"
    exit 0
  fi

  systemd-inhibit --what=idle --who=keepawake --why="Prevent idle" tail -f /dev/null &
  echo $! >"$LOCKFILE"
  echo "Idle inhibition started (PID $!)"
}

stop_inhibit() {
  if [ -f "$LOCKFILE" ]; then
    PID=$(cat "$LOCKFILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" && echo "Stopped idle inhibition (PID $PID)"
    else
      echo "No active inhibitor (stale lock)"
    fi
    rm -f "$LOCKFILE"
  else
    echo "No idle inhibitor running"
  fi
}

toggle_inhibit() {
  if is_inhibited; then
    stop_inhibit
  else
    start_inhibit
  fi
}

case "$1" in
-a | --awake) start_inhibit ;;
-i | --allow-idle) stop_inhibit ;;
-t | --toggle) toggle_inhibit ;;
-h | --help | "") print_help ;;
*)
  echo "Unknown option: $1"
  print_help
  exit 1
  ;;
esac
