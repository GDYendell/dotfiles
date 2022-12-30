# Monitor layout

## Monitor Layout
# Main + Secondary on top
# xrandr --output DisplayPort-0 --pos 0x1080 --output HDMI-A-0 --pos 960x0 --output HDMI-A-1 --same-as DisplayPort-0
# xrandr --output DisplayPort-0 --pos 0x1080 --output HDMI-A-0 --pos 960x0 --output HDMI-A-1 --off
# Work | Main + Secondary Right
# xrandr --output DP-0 --mode 3440x1440 --pos 0x0 --rotate normal --panning 3440x1440 --primary --output DP-2 --mode 1920x1200 --rotate left --pos 3440x0 --panning 1920x1200

# Enable Status Bar
# ~/dotfiles/i3/polybar.sh

# Set Background
# feh --bg-fill ~/Pictures/HomerStarrySky.jpg
# display -window root ~/Pictures/Wallpapers/Nebula3.jpg

# Enable Compositor
# picom -b -c --active-opacity 0.98 --inactive-opacity 0.95 --backend GLX --vsync --config ~/dotfiles/config/picom

# Run xidlehook for screen timeout and suspend
# ~/dotfiles/i3/idle.sh

# Run conky
# conky

# Mouse sensitivity
# xinput --set-prop "Logitech G502 HERO Gaming Mouse" "libinput Accel Speed" 1
