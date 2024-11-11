#!/usr/bin/env bash

if [ -z "$IQAIR_API_KEY" ]; then
    echo "Erreur : IQAIR_API_KEY variable d'environnement non définie."
    exit 1
fi

country="Canada"
state="Quebec"
city="Montreal"

icons_path="$HOME/dotfiles/misc/icons"

response=$(curl --silent --location -g "http://api.airvisual.com/v2/city?city=$city&state=$state&country=$country&key=${IQAIR_API_KEY}")

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
    icon="$icons_path/green-circle.png"
    ;;
yellow)
    icon="$icons_path/yellow-circle.png"
    ;;
orange)
    icon="$icons_path/orange-circle.png"
    ;;
red)
    icon="$icons_path/red-circle.png"
    ;;
purple)
    icon="$icons_path/purple-circle.png"
    ;;
maroon)
    icon="$icons_path/maroon-circle.png"
    ;;
esac

notify-send "AQI à $city" \
    "$aqius - Air $aqi_description" \
    --urgency=low \
    --icon="$icon"
