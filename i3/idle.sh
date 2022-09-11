#!/usr/bin/env bash

xscreensaver -no-splash &

# Only exported variables can be used within the timer's command.
export SCREEN_OFF='xset dpms force off'
export LOCK='i3lock --indicator --screen=1 --ignore-empty-password --color=00000000 --radius 250 \
    --ring-color=bd93f9aa --inside-color=bd93f955 \
    --ringver-color=50fa7baa --insidever-color=50fa7b55 \
    --ringwrong-color=ff5555aa --insidewrong-color=ff555555 \
    --keyhl-color=f1fa8cff --bshl-color=ffb86cff \
    --verif-text="Verifying..." --wrong-text="Bad Password" --noinput-text="..."'

export RELOCK_DELAY=10
export SCREENSAVER_DELAY=120
export LOCK_DELAY=180
export SUSPEND_DELAY=300

# Run xidlehook
xidlehook \
    `# Don't lock when there's a fullscreen application` \
    --not-when-fullscreen \
    `# Don't lock when there's audio playing` \
    --not-when-audio \
    `# If woken while already locked then screen off again after 10 seconds` \
    --timer ${RELOCK_DELAY} \
      'echo 1; pgrep i3lock && $SCREEN_OFF' \
      'echo 1.1' \
    `# Else run xscreensaver after 3 minutes, for 3 minutes, screen off and lock (and screen off again because i3lock wakes the screen)` \
    --timer ${SCREENSAVER_DELAY} \
      'echo 2; pgrep i3lock || xscreensaver-command -activate; sleep $LOCK_DELAY; if [[ $(pgrep xscreensaver | wc -l) > 2 ]]; then xscreensaver-command -deactivate; $SCREEN_OFF; $LOCK; $SCREEN_OFF; fi' \
      'echo 2.1' \
    `# Finally, suspend after 10 minutes` \
    --timer ${SUSPEND_DELAY} \
      'echo 3; systemctl suspend' \
      'echo 3.1'
