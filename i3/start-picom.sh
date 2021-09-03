#!/bin/bash
PICOM_PID=$(picom -b -c --active-opacity 0.95 --inactive-opacity 0.9 --backend GLX --vsync)
echo $PICOM_PID > ~/.config/i3/picom-pid.txt

