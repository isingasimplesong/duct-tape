#!/usr/bin/env bash

# result=$(ticker print --config ~/Coffre/portfolio.yaml | jq -r '.[] | "\(.symbol | sub("-CAD"; "")): \((.value | tonumber * 100 | floor) / 100 // 0)"')
#
# if [ $? -ne 0 ]; then
#     notify-send "Error" "Failed to get data"
#     exit 1
# fi
#
set -euo pipefail

CFG="$HOME/Coffre/portfolio.yaml"
DATA_DIR="$HOME/.local/share/portfolio"
LATEST="$DATA_DIR/latest.json"

mkdir -p "$DATA_DIR"

# 1) Récupération JSON depuis ticker
raw_json="$(ticker print --config "$CFG" 2>/dev/null || true)"
if [[ -z "${raw_json:-}" ]]; then
    notify-send "Portfolio" "Erreur: impossible d'obtenir les données (ticker)"
    exit 1
fi

# 2) Normalisation via jq
norm_json="$(
    jq -n --argjson arr "$raw_json" '
    [ $arr[]? |
      { symbol: (.symbol | sub("-CAD$"; "")),
        value: ((.value | tonumber) // 0)
      }
    ]'
)"

# 3) Lignes actuelles et total (LABEL:\t\tVALEUR)
lines_now="$(jq -r '.[] | "\(.symbol):\t\t\((.value*100|floor)/100)"' <<<"$norm_json")"
total_now="$(jq -r '[ .[] | .value ] | add // 0 | (. * 100 | floor) / 100' <<<"$norm_json")"

# 4) Charger le snapshot précédent s'il existe
have_prev=false
prev_date=""
prev_data="[]"
if [[ -f "$LATEST" ]]; then
    have_prev=true
    prev_date="$(jq -r '.asof // empty' "$LATEST" 2>/dev/null || true)"
    prev_data="$(jq '.data // []' "$LATEST" 2>/dev/null || echo '[]')"
fi

# 5) Deltas en % (par symbole + total) si précédent dispo
if $have_prev; then
    lines_with_delta="$(
        jq -r --argjson prev "$prev_data" '
      def valOf(arr; sym): (arr[]? | select(.symbol == sym) | .value) // 0;

      . as $now
      | .[]
      | .symbol as $s | .value as $v
      | (valOf($prev; $s)) as $p
      | ( if $p == 0 then null else (($v - $p) / $p * 100) end ) as $pct
      | ($v*100|floor)/100 as $vfmt
      | ( if $pct == null
          then "\($s):\t\t\($vfmt) (n/a%)"
          else ( (($pct*100)|floor)/100 ) as $pf
               | "\($s):\t\t\($vfmt) (\(if $pf>0 then "+" + ($pf|tostring) else ($pf|tostring) end)%)"
        end )
    ' <<<"$norm_json"
    )"

    total_prev="$(jq -r '[ .[] | .value ] | add // 0' <<<"$prev_data")"
    if awk "BEGIN{exit !($total_prev==0)}"; then
        total_pct_fmt="n/a%"
    else
        total_pct="$(jq -nr --arg a "$total_now" --arg b "$total_prev" '
      (((($a|tonumber) - ($b|tonumber)) / ($b|tonumber)) * 100 * 100 | floor) / 100
    ')"
        if awk "BEGIN{exit !($total_pct>0)}"; then
            total_pct_fmt="+$total_pct%"
        else
            total_pct_fmt="$total_pct%"
        fi
    fi

    prev_date_fmt="$(date -d "$prev_date" +'%y-%m-%d %H:%M' 2>/dev/null || echo "$prev_date")"
else
    lines_with_delta="$lines_now"
    total_pct_fmt=""
    prev_date_fmt=""
fi

# 6) Notification (ligne vide avant Total + date sur ligne séparée)
if $have_prev; then
    body="\r$lines_with_delta

Total:\t\t$total_now ($total_pct_fmt)
\r
Depuis:\t\t$prev_date_fmt"
else
    body="\r$lines_with_delta

Total:\t\t$total_now"
fi

notify-send "Portfolio" "$body"

# 7) Sauvegarde snapshot courant
now_iso="$(date +"%F %T")"
ts="$(date +"%Y%m%d%H%M%S")"
out_file="$DATA_DIR/$ts.json"

jq -n --arg asof "$now_iso" --argjson data "$norm_json" '{asof:$asof, data:$data}' >"$out_file"
ln -sfn "$(basename "$out_file")" "$LATEST"
# notify-send "Portfolio" "$result"
