#!/usr/bin/env bash
set -euo pipefail

# Sync Zed config between dotfiles and Windows %APPDATA%\Zed when running under WSL.
# Windows Zed can't use stow symlinks, so keep two real copies and copy explicitly.
#
#   zed.sh               show which files differ and the diff (- windows, + dotfiles); copies nothing
#   zed.sh to-dotfiles   copy Windows -> dotfiles
#   zed.sh to-windows    copy dotfiles -> Windows

[[ -n "${WSL_DISTRO_NAME:-}" ]] || exit 0

files=(keymap.json settings.json tasks.json)

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
dotfiles_dir="$(readlink -f "$script_dir/../.config/zed")"
appdata="$(cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r')"
windows_dir="$(wslpath "$appdata")/Zed"

case "${1:-}" in
  "") mode=status ;;
  to-dotfiles) mode=to-dotfiles ;;
  to-windows) mode=to-windows ;;
  *) echo "usage: $0 [to-dotfiles|to-windows]" >&2; exit 2 ;;
esac

for f in "${files[@]}"; do
  dot="$dotfiles_dir/$f"
  win="$windows_dir/$f"

  if cmp -s "$dot" "$win"; then
    echo "$f: in sync"
    continue
  fi

  case "$mode" in
    status)
      echo "$f: differs"
      git --no-pager diff --no-index --color "$win" "$dot" || true
      ;;
    to-dotfiles)
      cp "$win" "$dot"
      echo "$f: windows -> dotfiles"
      ;;
    to-windows)
      mkdir -p "$windows_dir"
      cp "$dot" "$win"
      echo "$f: dotfiles -> windows"
      ;;
  esac
done
