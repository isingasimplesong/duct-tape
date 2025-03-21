#!/usr/bin/env bash

COINGECKO_API_ENDPOINT="https://api.coingecko.com/api/v3/simple/price"
CRYPTOCURRENCY="bitcoin"
CURRENCY="cad"
SECRETS_FILE=~/dotfiles/zsh/secrets
source $SECRETS_FILE

# Fetching BTC/CAD value from CoinGecko API
response=$(curl -s "${COINGECKO_API_ENDPOINT}?ids=${CRYPTOCURRENCY}&vs_currencies=${CURRENCY}")

if [ $? -ne 0 ]; then
    notify-send "Error" "Failed to fetch data"
    exit 1
fi

btc_to_cad=$(echo "$response" | jq ".${CRYPTOCURRENCY}.${CURRENCY}")

if [ $? -ne 0 ]; then
    notify-send "Error" "Failed to parse data"
    exit 1
fi

total_value=$(echo "$MY_BTC_AMOUNT * $btc_to_cad" | bc -l)
LC_NUMERIC=C
notify-send "BTC/CAD" "$(printf 'Mes BTC = %.2f CAD' "$total_value")"
