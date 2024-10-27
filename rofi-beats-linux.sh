#!/usr/bin/env bash

# This script provides a simple way to listen to various radio stations using
# the mpv media player. It displays a menu with a list of radio stations, and
# allows the user to select one using the rofi application launcher. Upon
# selecting a station, a notification will be sent with the station's name,
# and the station will start playing using mpv with specified volume level.

# If the script is run while a station is already playing, it will stop the
# currently playing station.

# The script supports a variety of radio stations, that can easily be adjusted to user's preferences

# Note: This script requires mpv and rofi to be installed.

# add more args here according to preference
ARGS="--volume=50"

notification(){
# change the icon to whatever you want. Make sure your notification server
# supports it and already configured.

# Now it will receive argument so the user can rename the radio title
# to whatever they want

	notify-send "On écoute: " "$@" --icon=media-tape
}

menu(){
	printf "1. FIP\n"
	printf "2. ICI Première\n"
	printf "3. FIP Nouveautés\n"
	printf "4. FIP Jazz\n"
	printf "5. FIP Groove\n"
	printf "6. FIP Reggae\n"
	printf "7. FIP Monde\n"
	printf "8. P4k1d3rm!\n"
	printf "9. TSF Jazz\n"
	printf "11. France Culture\n"
	printf "12. France Info\n"
	printf "13. France Inter\n"
	printf "14. France Musique\n"
	printf "15. RFI Monde\n"
	printf "16. Radio Ouistiti\n"
	printf "17. Lofi Girl - Beats to sleep\n"
	printf "18. Lofi Girl - Beats to relax/study\n"
	printf "19. Synthwave - Retrowave - Retro Electro Livestream\n"
}

main() {
	choice=$(menu | rofi -dmenu | cut -d. -f1)

	case $choice in
		1)
			notification "FIP 📻🎶";
            URL="http://icecast.radiofrance.fr/fip-hifi.aac"

			break
			;;
		2)
			notification "ICI Première 📻";
            URL="http://cbcmp3.ic.llnwd.net/stream/cbcmp3_P-2QMTL0_MTL"
			break
			;;
		3)
			notification "FIP Nouveautés 📻🎶";
            URL="http://direct.fipradio.fr/live/fip-webradio5.mp3"
			break
			;;
		4)
			notification "FIP Jazz 📻🎶";
            URL="http://direct.fipradio.fr/live/fip-webradio2.mp3"
			break
			;;
		5)
			notification "FIP Groove 📻🎶";
            URL="http://direct.fipradio.fr/live/fip-webradio3.mp3"
			break
			;;
		6)
			notification "FIP Reggae 📻🎶";
            URL="http://direct.fipradio.fr/live/fip-webradio6.mp3"
			break
			;;
		7)
			notification "FIP Monde 📻🌍🎶";
            URL="http://direct.fipradio.fr/live/fip-webradio4.mp3"
			break
			;;
		8)
			notification "P4k1D3rm! 📻🎶";
            URL="https://www.youtube.com/watch?v=iiXtSKQCa4s"
			break
			;;
		9)
			notification "TSF Jazz 📻🎶";
            URL="http://tsfjazz.ice.infomaniak.ch/tsfjazz-high"
			break
			;;
		10)
			notification "HOT 97 New York 📻🎶";
            URL="https://24883.live.streamtheworld.com/KVEGFM.mp3"
			break
			;;
		11)
			notification "France culture 📻";
            URL="http://icecast.radiofrance.fr/franceculture-hifi.aac"
			break
			;;
		12)
			notification "France Info 📻";
            URL="http://icecast.radiofrance.fr/franceinfo-hifi.aac"
			break
			;;
		13)
			notification "France Inter 📻";
            URL="http://icecast.radiofrance.fr/franceinter-hifi.aac"
			break
			;;
		14)
			notification "France Musique 📻🎶";
            URL="http://icecast.radiofrance.fr/francemusique-hifi.aac"
			break
			;;
		15)
			notification "RFI Monde 📻";
            URL="http://live02.rfi.fr/rfimonde-96k.mp3"
			break
			;;
		16)
			notification "Radio Ouistiti 📻🎶";
            URL="http://ouistiti.stream2net.eu:8100/;"
			break
			;;
		17)
			notification "Lofi Girl - beats to sleep 📻🎶";
            URL="https://www.youtube.com/watch?v=rUxyKA_-grg"
			break
			;;
		18)
			notification "Lofi Girl - beats to relax/study 📻🎶";
            URL="https://www.youtube.com/watch?v=jfKfPfyJRdk"
			break
			;;
		19)
			notification "Synthwave - Retrowave - Retro Electro Livestream 📻🎶";
            URL="https://www.youtube.com/watch?v=9P23oE6ekwQ"
			break
			;;
	esac
    # run mpv with args and selected url
    # added title arg to make sure the pkill command kills only this instance of mpv
    mpv --no-video $ARGS --title="radio-mpv" $URL
}

pkill -f radio-mpv || main
