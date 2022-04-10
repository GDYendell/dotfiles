# Monitor layout

## Main + Secondary on top
# xrandr --output DisplayPort-0 --pos 0x1080 --output HDMI-A-0 --pos 960x0 --output HDMI-A-1 --same-as DisplayPort-0
xrandr --output DisplayPort-0 --pos 0x1080 --output HDMI-A-0 --pos 960x0 --output HDMI-A-1 --off

# Enable Status Bar
~/dotfiles/i3/polybar.sh

# Set Background
feh --bg-fill ~/Pictures/HomerStarrySky.jpg

# Enable Compositor
picom -b -c --active-opacity 0.98 --inactive-opacity 0.95 --backend GLX --vsync --config ~/.config/picom.conf

# Start xscreensaver
xscreensaver -no-splash

# Mouse sensitivity
xinput --set-prop "Logitech G502 HERO Gaming Mouse" "libinput Accel Speed" 1
