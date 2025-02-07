# Monitor layout
# ~/arandr/home-default.sh
# ~/arandr/work.sh

# Keybindings
xmodmap ~/.Xmodmap

# Enable Status Bar
# ~/i3/polybar.sh

# Set Background
# feh --bg-fill ~/Pictures/HomerStarrySky.jpg
# display -window root ~/Pictures/Wallpapers/Nebula3.jpg

# Enable Compositor
# picom -b -c --active-opacity 0.98 --inactive-opacity 0.95 --backend GLX --vsync --config ~/.config/picom

# Run xidlehook for screen timeout and suspend
# ~/i3/idle.sh

# Run dunst for notifications
dunst &

# Run conky
# conky

# Mouse sensitivity
xinput --set-prop "Logitech G502 HERO Gaming Mouse" "Coordinate Transformation Matrix" 3.0 0 0 0 3.0 0 0 0 1
