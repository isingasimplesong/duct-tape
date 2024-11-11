#!/usr/bin/env bash

COUNTRY="Canada"
STATE="Quebec"
CITY="Montreal"
SECRETS_FILE=~/dotfiles/zsh/secrets
source $SECRETS_FILE
ICONS_PATH="/home/mathieu/dotfiles/misc/icons"

response=$(curl --silent --location -g "http://api.airvisual.com/v2/city?city=$CITY&state=$STATE&country=$COUNTRY&key=${IQAIR_API_KEY}")

status=$(echo "$response" | jq -r '.status')
if [ "$status" != "success" ]; then
    echo "Erreur : Echec de la requête à l'API. Statut: $(echo $response | jq -r '.data.message')"
    exit 1
fi

aqius=$(echo "$response" | jq -r '.data.current.pollution.aqius')

get_aqi_description() {
    local aqi=$1
    if ((aqi <= 50)); then
        echo "très pur" "green"
    elif ((aqi <= 100)); then
        echo "pur" "yellow"
    elif ((aqi <= 150)); then
        echo "peu sain" "orange"
    elif ((aqi <= 200)); then
        echo "non sain" "red"
    elif ((aqi <= 300)); then
        echo "très pollué" "purple"
    else
        echo "dangereux" "maroon"
    fi
}

read aqi_description aqi_color <<<$(get_aqi_description "$aqius")

case $aqi_color in
green)
    icon="$ICONS_PATH/green-circle.png"
    ;;
yellow)
    icon="$ICONS_PATH/yellow-circle.png"
    ;;
orange)
    icon="$ICONS_PATH/orange-circle.png"
    ;;
red)
    icon="$ICONS_PATH/red-circle.png"
    ;;
purple)
    icon="$ICONS_PATH/purple-circle.png"
    ;;
maroon)
    icon="$ICONS_PATH/maroon-circle.png"
    ;;
esac

notify-send "AQI à $CITY" \
    "$aqius - Air $aqi_description" \
    --urgency=low \
    --icon="$icon"
