#!/usr/bin/env bash
set -euo pipefail

# New herdr workspace with shell, claude and lazygit tabs.
# Prompts for a directory (defaults to the active pane's cwd), then a name (defaults to its leaf).
# Bound to a type = "popup" [[keys.command]] in herdr config.toml.

read -erp "Directory: " -i "${HERDR_ACTIVE_PANE_CWD:-$HOME}" cwd
cwd="${cwd/#\~/$HOME}"
cwd="${cwd%/}"; cwd="${cwd:-/}"
[[ -d "$cwd" ]] || { echo "No such directory: $cwd" >&2; read -rsn1; exit 1; }
read -erp "Name: " -i "$(basename "$cwd")" name

ws=$(herdr workspace create --cwd "$cwd" --label "${name:-$(basename "$cwd")}" --focus)
ws_id=$(jq -r '.result.workspace.workspace_id' <<<"$ws")
herdr tab rename "$(jq -r '.result.tab.tab_id' <<<"$ws")" shell >/dev/null

for tab_name in claude lazygit; do
  tab=$(herdr tab create --workspace "$ws_id" --cwd "$cwd" --label "$tab_name" --no-focus)
  herdr pane run "$(jq -r '.result.root_pane.pane_id' <<<"$tab")" "$tab_name" >/dev/null
done
