#!/usr/bin/env bash

source ~/dotfiles/zsh/secrets
COINGECKO_API_ENDPOINT="https://api.coingecko.com/api/v3/simple/price"
CRYPTOCURRENCY="bitcoin"
CURRENCY="cad"

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

notify-send "BTC/CAD" "$(printf 'Mes Bitcoins valent %.2f CAD' "$total_value")"
