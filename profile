# Edit /etc/profile to source this file, e.g.
# . ~/dotfiles/profile

if [[ "$(tty)" == "/dev/tty2" ]]; then
	echo "TTY2 -> i3"
        startx
fi
if [[ "$(tty)" == "/dev/tty3" ]]; then
	echo "TTY3 -> sway"
        sway
fi
if [[ "$(tty)" == "/dev/tty5" ]]; then
	echo "TTY5 -> SteamOS"
        gamescope -e -- steam -steamos -gamepadui
fi
