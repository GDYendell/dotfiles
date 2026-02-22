#!/usr/bin/env bash
set -euo pipefail

# Let elephant manage its own service
elephant service enable
systemctl --user start elephant.service

# Reload so systemd picks up the walker autostart drop-in
systemctl --user daemon-reload
systemctl --user start app-walker@autostart.service
