#!/bin/bash
# Claude Code status line.
#
#   Opus 5 1M (medium) 7% $1.11 > cache 42m [CAVEMAN]
#
# Wired via ~/.claude/settings.json -> statusLine.command

json=$(cat)

# One field per line, so empty values stay in place without any IFS juggling.
mapfile -t f < <(printf '%s' "$json" | jq -r '
    .model.display_name // "?",
    .effort.level // "",
    .cost.total_cost_usd // 0,
    (.context_window.used_percentage // 0 | round),
    (.rate_limits.five_hour.used_percentage // 0 | round),
    (if .fast_mode then "fast" else "" end),
    .session_name // "",
    (.prompt_cache.warm | tostring),
    .prompt_cache.expires_at // "",
    .prompt_cache.recache_tokens_if_cold // "",
    .prompt_cache.ttl // "",
    .model.id // ""')

model=${f[0]}  effort=${f[1]}
cost=$(printf '%.2f' "${f[2]:-0}")
ctx_pct=${f[3]:-0}  rl5=${f[4]:-0}  fast=${f[5]}
session=${f[6]}
# warm is "true", "false" or "null" (no API response yet); `//` would swallow false.
cache_warm=${f[7]}  cache_exp=${f[8]}
recache_tokens=${f[9]}  cache_ttl=${f[10]}  model_id=${f[11]}

# API list price per MTok of input, for pricing a re-cache. Subscriptions pay
# in usage limits, not dollars, so treat this as a relative cost.
case $model_id in
    claude-fable-5*|claude-mythos-5*) input_price=10 ;;
    claude-opus-5-5*)                 input_price=4 ;;
    claude-opus-*)                    input_price=5 ;;
    claude-sonnet-5*)                 input_price=2 ;;
    claude-sonnet-4-6*)               input_price=3 ;;
    claude-haiku-5-5*)                input_price=0.10 ;;
    claude-haiku-4-5*)                input_price=1 ;;
    *)                                input_price= ;;
esac
# Cache writes cost 2x input on the 1h TTL, 1.25x on 5m.
[ "$cache_ttl" = "1h" ] && write_mult=2 || write_mult=1.25
recache_cost=
if [ -n "$recache_tokens" ] && [ -n "$input_price" ]; then
    recache_cost=$(awk -v t="$recache_tokens" -v p="$input_price" -v m="$write_mult" \
        'BEGIN { printf "%.2f", t / 1e6 * p * m }')
fi

# Long auto-generated names would crowd out everything else.
[ ${#session} -gt 40 ] && session="${session:0:39}…"

# "Opus 5 (1M context)" -> "Opus 5 1M"; keeps it short.
model=${model/ (1M context)/ 1M}

C_MODEL=$'\033[38;5;103m'; C_COST=$'\033[38;5;96m'; C_DIM=$'\033[38;5;240m'
C_WARN=$'\033[38;5;173m'
C_OK=$'\033[38;5;108m'; C_MID=$'\033[38;5;179m'; C_BAD=$'\033[38;5;167m'
C_SESSION=$'\033[38;5;110m'
R=$'\033[0m'

out="${C_MODEL}${model}${R}"
[ -n "$effort" ] && out+=" ${C_MODEL}(${effort})${R}"
[ -n "$fast" ] && out+=" ${C_WARN}${fast}${R}"

# Green under a quarter used, amber past that, red from half onwards.
graded() {
    if   [ "$1" -ge 50 ]; then printf '%s' "$C_BAD"
    elif [ "$1" -ge 25 ]; then printf '%s' "$C_MID"
    else                       printf '%s' "$C_OK"
    fi
}

out+=" > $(graded "$ctx_pct")${ctx_pct}%${R} > ${C_COST}\$${cost}${R}"
out+=" $(graded "$rl5")${rl5}%${R}"

# Prompt cache countdown: green with time to spare, amber under 10m, red once cold.
# expires_at can pass before Claude Code sends fresh data, so check the clock too.
# The dollar figure is what the next prompt pays to re-cache if the cache is cold.
cache=""
if [ "$cache_warm" = "true" ] && [ -n "$cache_exp" ]; then
    left=$(( cache_exp - $(date +%s) ))
    if   (( left <= 0 ));   then cache="${C_BAD}cache cold"
    elif (( left < 60 ));   then cache="${C_MID}cache ${left}s"
    elif (( left < 600 ));  then cache="${C_MID}cache $((left / 60))m"
    else                         cache="${C_OK}cache $((left / 60))m"
    fi
elif [ "$cache_warm" = "false" ]; then
    cache="${C_BAD}cache cold"
fi
if [ -n "$cache" ]; then
    [ -n "$recache_cost" ] && cache+=" \$${recache_cost}"
    out+=" > ${cache}${R}"
fi

[ -n "$session" ] && out+=" > ${C_SESSION}${session}${R}"

caveman="$HOME/.claude/hooks/caveman-statusline.sh"
[ -f "$caveman" ] && out+=" $(bash "$caveman")"

printf '%s' "$out"
