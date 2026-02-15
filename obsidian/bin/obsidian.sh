#!/usr/bin/env bash

syncthing > ~/logs/syncthing-$(date +"%Y%m%d_%H%M%S").log 2>&1 &

/usr/bin/obsidian $@ > ~/logs/obsidian-$(date +"%Y%m%d_%H%M%S").log 2>&1

pkill syncthing
