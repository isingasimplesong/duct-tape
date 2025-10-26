#!/usr/bin/env bash
# Extrait les tickers d'une liste commentée et produit un array Python trié

awk '
  /^[[:space:]]*-/ {
    # Capture le premier mot après le tiret
    match($0, /-[[:space:]]+([A-Z0-9._-]+)/, arr)
    if (arr[1] != "") {
      tickers[arr[1]] = 1
    }
  }
  END {
    # Copie les clés dans un array indexé pour le tri
    n = 0
    for (ticker in tickers) {
      sorted[++n] = ticker
    }

    # Tri alphabétique (asort disponible en gawk)
    asort(sorted)

    printf "["
    for (i = 1; i <= n; i++) {
      if (i > 1) printf ", "
      printf "'\''%s'\''", sorted[i]
    }
    printf "]\n"
  }
' "$@"
