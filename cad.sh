#!/usr/bin/env bash

FRANKFURTER_API="https://api.frankfurter.app/latest?from=CAD&to=USD,EUR"

# Step 1: Fetch JSON data
response=$(curl -s "$FRANKFURTER_API")

# Step 2: Validate the HTTP request
if [ $? -ne 0 ] || [ -z "$response" ]; then
    notify-send "Error" "Failed to fetch data"
    exit 1
fi

# Step 3: Extract USD/EUR rates via jq
usd_rate=$(echo "$response" | jq -r '.rates.USD')
eur_rate=$(echo "$response" | jq -r '.rates.EUR')

# Step 4: Check for null or empty rates
if [ "$usd_rate" = "null" ] || [ -z "$usd_rate" ] ||
    [ "$eur_rate" = "null" ] || [ -z "$eur_rate" ]; then
    notify-send "Error" "Failed to parse data"
    exit 1
fi

# Step 5: Show the notification
LC_NUMERIC=C
notify-send "CAD Exchange Rate" "$(printf '\n1 CAD$ = %.2f USD\n       = %.2f EUR' "$usd_rate" "$eur_rate")"
