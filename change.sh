#!/usr/bin/env bash
# change - convertisseur de devises utilisant l'API exchangerate-api.com

set -euo pipefail

readonly API_BASE="https://api.exchangerate-api.com/v4/latest"

usage() {
    cat <<EOF
Usage: change --in AMOUNT CURRENCY --out CURRENCY

Convertit un montant d'une devise à une autre au taux du jour.

Options:
  --in AMOUNT CURRENCY   Montant et devise source (ex: 78 CAD)
  --out CURRENCY         Devise cible (ex: USD)
  -h, --help            Affiche cette aide

Exemple:
  change --in 78 CAD --out USD
  # Output: 78 CAD = 55.23 USD

Source des taux: exchangerate-api.com (gratuit, pas de clé requise)
EOF
    exit 0
}

if [[ $# -eq 0 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

# Parse arguments
amount=""
from_currency=""
to_currency=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    --in)
        amount="$2"
        from_currency="$3"
        shift 3
        ;;
    --out)
        to_currency="$2"
        shift 2
        ;;
    *)
        echo "Erreur: argument inconnu '$1'" >&2
        echo "Utilisez -h pour l'aide" >&2
        exit 1
        ;;
    esac
done

# Validation
if [[ -z "$amount" ]] || [[ -z "$from_currency" ]] || [[ -z "$to_currency" ]]; then
    echo "Erreur: arguments manquants" >&2
    usage
fi

# Fetch rates
response=$(curl -sf "${API_BASE}/${from_currency}" || {
    echo "Erreur: impossible de récupérer les taux pour $from_currency" >&2
    exit 1
})

# Extract rate (using jq if available, otherwise grep/sed)
if command -v jq &>/dev/null; then
    rate=$(echo "$response" | jq -r ".rates.${to_currency}")
else
    rate=$(echo "$response" | grep -oP "\"${to_currency}\":\K[0-9.]+")
fi

if [[ -z "$rate" ]] || [[ "$rate" == "null" ]]; then
    echo "Erreur: devise $to_currency non trouvée" >&2
    exit 1
fi

# Calculate (force LC_NUMERIC=C pour utiliser le point comme séparateur)
result=$(LC_NUMERIC=C bc -l <<<"$amount * $rate")
result=$(LC_NUMERIC=C printf "%.2f" "$result")

echo "${result}"
