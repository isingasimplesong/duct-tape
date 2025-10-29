#!/usr/bin/env bash

# displays & play a selection of audio streams
# requires mpv and rofi to be installed.

ARGS="--volume=50"

notification() {
	notify-send "On écoute: " "$@" --icon=media-tape
}

menu() {
	printf "1. FIP\n"
	printf "2. ICI Première\n"
	printf "3. FIP Nouveautés\n"
	printf "4. FIP Jazz\n"
	printf "5. FIP Groove\n"
	printf "6. FIP Reggae\n"
	printf "7. FIP Monde\n"
	printf "8. P4k1d3rm!\n"
	printf "9. TSF Jazz\n"
	printf "10. France Culture\n"
	printf "11. France Info\n"
	printf "12. France Inter\n"
	printf "13. France Musique\n"
	printf "14. RFI Monde\n"
	printf "15. Lofi Girl - Beats to relax/study\n"
	printf "16. Radio Nova\n"
}

main() {
	choice=$(menu | rofi -dmenu -p "Choisir un flux :" | cut -d. -f1)

	case $choice in
	1)
		notification "FIP 📻🎶"
		URL="http://icecast.radiofrance.fr/fip-hifi.aac"

		break
		;;
	2)
		notification "ICI Première 📻"
		URL="http://18683.live.streamtheworld.com/CBFFM_SRC.mp3"
		break
		;;
	3)
		notification "FIP Nouveautés 📻🎶"
		URL="http://direct.fipradio.fr/live/fip-webradio5.mp3"
		break
		;;
	4)
		notification "FIP Jazz 📻🎶"
		URL="http://direct.fipradio.fr/live/fip-webradio2.mp3"
		break
		;;
	5)
		notification "FIP Groove 📻🎶"
		URL="http://direct.fipradio.fr/live/fip-webradio3.mp3"
		break
		;;
	6)
		notification "FIP Reggae 📻🎶"
		URL="http://direct.fipradio.fr/live/fip-webradio6.mp3"
		break
		;;
	7)
		notification "FIP Monde 📻🌍🎶"
		URL="http://direct.fipradio.fr/live/fip-webradio4.mp3"
		break
		;;
	8)
		notification "P4k1D3rm! 📻🎶"
		URL="https://www.youtube.com/watch?v=YBpqIYaV1rM"
		break
		;;
	9)
		notification "TSF Jazz 📻🎶"
		URL="http://tsfjazz.ice.infomaniak.ch/tsfjazz-high"
		break
		;;
	10)
		notification "France culture 📻"
		URL="http://icecast.radiofrance.fr/franceculture-hifi.aac"
		break
		;;
	11)
		notification "France Info 📻"
		URL="http://icecast.radiofrance.fr/franceinfo-hifi.aac"
		break
		;;
	12)
		notification "France Inter 📻"
		URL="http://icecast.radiofrance.fr/franceinfo-midfi.mp3"
		break
		;;
	13)
		notification "France Musique 📻🎶"
		URL="http://icecast.radiofrance.fr/francemusique-hifi.aac"
		break
		;;
	14)
		notification "RFI Monde 📻"
		URL="http://live02.rfi.fr/rfimonde-96k.mp3"
		break
		;;
	15)
		notification "Lofi Girl - beats to relax/study 📻🎶"
		URL="https://www.youtube.com/watch?v=jfKfPfyJRdk"
		break
		;;
	16)
		notification "Radio Nova 📻🎶"
		URL="http://novazz.ice.infomaniak.ch/novazz-128.mp3"
		break
		;;
	esac
	# run mpv with args and selected url
	# added title arg to make sure the pkill command kills only this instance of mpv
	mpv --no-video "$ARGS" --title="radio-mpv" "$URL"
}

pkill -f radio-mpv || main
