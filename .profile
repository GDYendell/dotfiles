# Source antidot environment variables
eval "$(antidot init)"

if [[ "$(tty)" == "/dev/tty2" ]]; then
  echo "TTY2 -> i3"
  startx
fi
if [[ "$(tty)" == "/dev/tty3" ]]; then
  echo "TTY3 -> sway"
  sway >~/logs/sway-$(date +"%Y%m%d_%H%M%S").log 2>&1
fi
if [[ "$(tty)" == "/dev/tty5" ]]; then
  echo "TTY5 -> SteamOS"
  gamescope -O HDMI-A-2,DP-1 -e -- steam -steamos -gamepadui
fi
