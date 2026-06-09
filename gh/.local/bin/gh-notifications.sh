#!/usr/bin/env bash
#
# gh-notifications — prune GitHub PR notifications.
#
# Reads your GitHub notification inbox and acts on two kinds of notification:
#
#   Pull requests:
#     * MERGED or CLOSED  -> mark as done (clear from the inbox); they're over.
#     * review requests   -> if you are NOT the actual assigned reviewer (only
#                            pulled in via a team/group request), unsubscribe
#                            AND mark as done.
#     * everything else   -> keep (authored, assigned, @mentioned, commented…
#                            on still-OPEN PRs).
#
#   Deploy approvals (Actions "<user> requested your review to deploy …"):
#     * requested by someone else -> unsubscribe + mark as done (team reviewer).
#     * requested by you          -> keep.
#
# Within the review_requested set you are the "assigned reviewer" if your login
# is in the PR's currently-requested reviewers, OR you already reviewed it.
#
# It lists every PR with your status and the actual reviewers, then — if any are
# actionable — asks a single y/N before acting on ALL of them. Use --yes to skip
# the prompt (e.g. in scripts/cron).
#
# Acting mirrors the GitHub UI buttons:
#   * DELETE the thread subscription  (Unsubscribe — stops future notifications)
#   * DELETE the thread               (Mark as done — clears it from the inbox)
#
# Performance: PR state, reviewers and reviews for ALL candidate PRs are fetched
# in a single batched GraphQL query (not one REST call per PR), and the actions
# run in parallel.
#
# Requires: gh (authenticated; 'notifications' scope to unsubscribe/mark-done,
# 'repo' to read), jq.

set -euo pipefail

ASSUME_YES=0
INCLUDE_READ=0
PAR=8 # parallelism for the unsubscribe/mark-done DELETE calls

usage() {
  cat <<'EOF'
Usage: gh-notifications [--all] [--yes] [-h|--help]

  (no flags)   Scan your UNREAD notifications, list each PR with your reviewer
               status and the actual reviewers, then ask y/N before acting:
               merged PRs are marked done; review requests where you are not the
               assigned reviewer are unsubscribed + marked done.
  --all        Also include READ notifications. WARNING: GitHub's REST API has
               no concept of the web "Done"/archive state, so this resurfaces
               threads you cleared long ago (read == archived to the API). Use
               for a one-off backlog sweep; acting on them is harmless.
  -y, --yes    Skip the confirmation prompt and act on all actionable PRs.
  -h, --help   Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
  -y | --yes) ASSUME_YES=1 ;;
  --all) INCLUDE_READ=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 2
    ;;
  esac
  shift
done

command -v gh >/dev/null || {
  echo "error: gh not found" >&2
  exit 1
}
command -v jq >/dev/null || {
  echo "error: jq not found" >&2
  exit 1
}

# Colours, only when stdout is a terminal.
if [ -t 1 ]; then
  BOLD=$(printf '\033[1m')
  DIM=$(printf '\033[2m')
  RED=$(printf '\033[31m')
  GREEN=$(printf '\033[32m')
  YELLOW=$(printf '\033[33m')
  CYAN=$(printf '\033[36m')
  PURPLE=$(printf '\033[34m') # ANSI blue — maps to purple in many schemes
  RESET=$(printf '\033[0m')
else
  BOLD=
  DIM=
  RED=
  GREEN=
  YELLOW=
  CYAN=
  PURPLE=
  RESET=
fi

in_csv() { case ",$2," in *",$1,"*) return 0 ;; *) return 1 ;; esac }

# One /user call gives us both the token's OAuth scopes (response header) and our
# login (body) — no need for two requests.
USER_RESP=$(gh api -i user 2>/dev/null)
TOKEN_SCOPES=$(printf '%s' "$USER_RESP" | tr -d '\r' |
  awk -F': ' 'tolower($1)=="x-oauth-scopes"{print $2}')
ME=$(printf '%s' "$USER_RESP" | sed -n '/^{/,$p' | jq -r .login)

# Thread (un)subscribe / mark-done endpoints require the 'notifications' scope.
# 'repo' is enough to LIST but not to mutate, so detect this up front.
have_notif_scope=0
case ",${TOKEN_SCOPES// /}," in *,notifications,*) have_notif_scope=1 ;; esac
if [ "$have_notif_scope" -eq 0 ]; then
  echo "${YELLOW}warning:${RESET} your gh token lacks the 'notifications' scope, so" \
    "acting on notifications will fail." >&2
  echo "Grant it (interactive, opens a browser) with:" >&2
  echo "    ${BOLD}gh auth refresh -h github.com -s notifications${RESET}" >&2
  echo "${DIM}(listing still works; acting stays disabled until you grant it)${RESET}" >&2
  echo >&2
fi

echo "${BOLD}Authenticated as:${RESET} $ME"
echo

# Unread only by default == what is currently in the inbox. all=true also pulls
# read (and thus archived/"Done") threads. Query string goes in the path, not
# via -f (a -f flag flips gh to POST -> 404).
notif_path="/notifications"
[ "$INCLUDE_READ" -eq 1 ] && notif_path="/notifications?all=true"
NOTIFS=$(gh api --paginate "$notif_path")

# PR review notifications and Actions deployment-approval notifications. PRs are
# classified by reviewer/state (below); deploy approvals carry no run link, so
# they are classified by who requested them (the first token of the title).
ROWS=$(printf '%s' "$NOTIFS" |
  jq -r '.[]
      | select((.subject.type == "PullRequest" and .subject.url != null)
               or (.subject.type == "WorkflowRun" and .reason == "approval_requested"))
      | [.subject.type, .id, .reason, .repository.full_name, (.subject.title // ""), (.subject.url // "")]
      | @tsv') # url last: it's empty for deploys, and a trailing empty TSV
# field is safe (tab is IFS-whitespace, so mid-row empties would
# collapse and shift columns).

if [ -z "$ROWS" ]; then
  echo "${DIM}No actionable notifications in your inbox. Nothing to do.${RESET}"
  exit 0
fi

# Slurp into parallel arrays. T_* = pull requests, D_* = deploy approvals.
declare -a T_thread T_reason T_repo T_num T_title
declare -a D_thread D_repo D_title
n=0
dn=0
while IFS=$'\t' read -r ntype thread_id reason repo title url; do
  [ -n "$thread_id" ] || continue
  case "$ntype" in
  PullRequest)
    T_thread[n]=$thread_id
    T_reason[n]=$reason
    T_repo[n]=$repo
    T_num[n]=${url##*/}
    T_title[n]=$title
    n=$((n + 1))
    ;;
  WorkflowRun)
    D_thread[dn]=$thread_id
    D_repo[dn]=$repo
    D_title[dn]=$title
    dn=$((dn + 1))
    ;;
  esac
done <<<"$ROWS"

# Build ONE GraphQL query covering every PR notification, grouped by repo, one
# aliased pullRequest() node per PR (alias p<index>). Fetches PR state (to spot
# merged PRs), requested reviewers (users + teams) and review authors in a single
# round trip, replacing the old per-PR REST calls.
declare -A repo_prs
have_pr=0
for ((j = 0; j < n; j++)); do
  have_pr=1
  repo_prs[${T_repo[j]}]+=" $j"
done

declare -A RR_ok RR_state RR_reqme RR_doneme RR_revs
if [ "$have_pr" -eq 1 ]; then
  prf='state reviewRequests(first:100){nodes{requestedReviewer{__typename ... on User{login} ... on Team{slug}}}} reviews(first:100){nodes{author{login}}}'
  q="query {"
  rk=0
  for repo in "${!repo_prs[@]}"; do
    owner=${repo%%/*}
    name=${repo#*/}
    q+=" r${rk}: repository(owner: \"$owner\", name: \"$name\") {"
    for j in ${repo_prs[$repo]}; do
      q+=" p${j}: pullRequest(number: ${T_num[j]}) { $prf }"
    done
    q+=" }"
    rk=$((rk + 1))
  done
  q+=" }"

  if gql=$(gh api graphql -f query="$q" 2>/dev/null); then
    # jq emits unit-separated () fields. NOT tab-separated: tab is IFS
    # whitespace, so `read` would collapse runs and drop empty users/teams cells.
    while IFS=$'\037' read -r alias present state req_me done_me revdisp; do
      j=${alias#p}
      [ "$present" = "true" ] || continue # null PR node => leave undetermined
      RR_ok[$j]=1
      RR_state[$j]=$state
      RR_reqme[$j]=$req_me
      RR_doneme[$j]=$done_me
      RR_revs[$j]=$revdisp
    done < <(printf '%s' "$gql" | jq -r --arg ME "$ME" '
        .data[]? | to_entries[] |
          ([.value.reviewRequests.nodes[]?.requestedReviewer | select(.__typename=="User") | .login]) as $requ |
          ([.value.reviews.nodes[]?.author.login // empty] | unique) as $done |
          (($requ + $done) | unique) as $allu |
          .key
          + "" + ((.value != null) | tostring)
          + "" + (.value.state // "")
          + "" + (($requ | any(. == $ME)) | tostring)
          + "" + (($done | any(. == $ME)) | tostring)
          + "" + ((($allu | map(. as $u | $u + (if ($done | index($u)) then " (reviewed)" else "" end)))
                          + [.value.reviewRequests.nodes[]?.requestedReviewer | select(.__typename=="Team") | "@" + .slug])
                         | join(", "))')
  fi
fi

keep=0
unsub=0
resolved=0
deploy=0
unknown=0
failed=0
declare -a jobs # entries: "U:<thread>" (unsub+done) or "D:<thread>" (done)
declare -A label_of

for ((j = 0; j < n; j++)); do
  repo=${T_repo[j]}
  num=${T_num[j]}
  title=${T_title[j]}
  reason=${T_reason[j]}
  thread_id=${T_thread[j]}
  ok=${RR_ok[$j]:-0}
  state=${RR_state[$j]:-}
  pr_url="https://github.com/$repo/pull/$num"

  # Merged or closed PRs are complete regardless of why you were notified —
  # they're over and need nothing from you, so mark done.
  if [ "$ok" = 1 ] && { [ "$state" = "MERGED" ] || [ "$state" = "CLOSED" ]; }; then
    resolved=$((resolved + 1))
    st=${state,,}
    if [ "$state" = "MERGED" ]; then mc=$PURPLE; else mc=$CYAN; fi
    echo "${mc}✔ $st${RESET} ${BOLD}$repo · #$num${RESET} $title · ${DIM}$pr_url${RESET}"
    jobs+=("D:$thread_id")
    label_of[$thread_id]="$repo#$num"
    echo
    continue
  fi

  # Non-review-request notifications (open) are always kept.
  if [ "$reason" != "review_requested" ]; then
    keep=$((keep + 1))
    echo "${GREEN}✓ keep${RESET} ${BOLD}$repo · #$num${RESET} $title · ${DIM}$pr_url${RESET}"
    echo "    ${DIM}kept: reason=$reason${RESET}"
    echo
    continue
  fi

  # Couldn't resolve this PR via GraphQL — don't touch it.
  if [ "$ok" != 1 ]; then
    unknown=$((unknown + 1))
    echo "${YELLOW}?${RESET} ${BOLD}$repo#$num${RESET}  $title"
    echo "    ${YELLOW}could not read PR — left untouched${RESET}"
    echo
    continue
  fi

  is_reviewer=0
  why=
  if [ "${RR_reqme[$j]}" = "true" ]; then
    is_reviewer=1
    why="requested reviewer"
  elif [ "${RR_doneme[$j]}" = "true" ]; then
    is_reviewer=1
    why="already reviewed"
  fi

  # Full reviewers list (requested + already-reviewed, latter marked) built in jq.
  reviewers=${RR_revs[$j]}
  [ -n "$reviewers" ] || reviewers="${DIM}(none)${RESET}"

  if [ "$is_reviewer" -eq 1 ]; then
    keep=$((keep + 1))
    echo "${GREEN}✓ keep${RESET} ${BOLD}$repo · #$num${RESET} $title · ${DIM}$pr_url${RESET}"
    echo "    ${DIM}you: $why · reason=$reason${RESET}"
    echo "    reviewers: $reviewers"
  else
    unsub=$((unsub + 1))
    echo "${RED}✗ not reviewer${RESET} ${BOLD}$repo · #$num${RESET} $title · ${DIM}$pr_url${RESET}"
    echo "    ${DIM}reason=$reason${RESET}"
    echo "    reviewers: $reviewers"
    jobs+=("U:$thread_id")
    label_of[$thread_id]="$repo#$num"
  fi
  echo
done

# Deploy approvals: keep only deploys you requested yourself; clear the rest
# (requester != you), since you were pulled in as a team reviewer.
for ((k = 0; k < dn; k++)); do
  repo=${D_repo[k]}
  thread_id=${D_thread[k]}
  requester=${D_title[k]%% *}
  if [ "$requester" = "$ME" ]; then
    keep=$((keep + 1))
    echo "${GREEN}✓ keep${RESET} ${BOLD}$repo${RESET}  (deploy approval)"
    echo "    ${DIM}your own deploy request (requester=$requester)${RESET}"
  else
    deploy=$((deploy + 1))
    echo "${RED}✗ not your deploy${RESET} ${BOLD}$repo${RESET}  (deploy approval)"
    echo "    ${DIM}requested by $requester · thread=$thread_id${RESET}"
    jobs+=("U:$thread_id")
    label_of[$thread_id]="$repo (deploy by $requester)"
  fi
  echo
done

summary="${GREEN}$keep kept${RESET} · ${RED}$unsub not-reviewer${RESET} · ${CYAN}$resolved resolved${RESET} · ${RED}$deploy deploy${RESET}"
[ "$unknown" -gt 0 ] && summary="$summary · ${YELLOW}$unknown undetermined${RESET}"
echo "${BOLD}Summary:${RESET} $summary"

# Confirm once, then act on all actionable PRs. Unsubscribe (U) + mark-done for
# non-reviewers; mark-done only (D) for merged. DELETEs run in parallel (no bulk
# endpoint exists). The worker echoes a thread id only when one of its DELETEs
# fails.
acts=${#jobs[@]}
if [ "$acts" -gt 0 ]; then
  parts=
  [ "$unsub" -gt 0 ] && parts="$unsub to unsubscribe"
  [ "$resolved" -gt 0 ] && parts="${parts:+$parts, }$resolved resolved"
  [ "$deploy" -gt 0 ] && parts="${parts:+$parts, }$deploy deploy"

  do_apply=0
  if [ "$have_notif_scope" -eq 0 ]; then
    echo "${YELLOW}Cannot act — missing 'notifications' scope (see the note above).${RESET}"
  elif [ "$ASSUME_YES" -eq 1 ]; then
    do_apply=1
  else
    printf '%s' "${BOLD}Clear $acts notification(s) ($parts)? [y/N] ${RESET}"
    read -r reply || reply="" # EOF (e.g. cron, no stdin) -> empty -> declines
    echo
    case "$reply" in [yY] | [yY][eE][sS]) do_apply=1 ;; esac
  fi

  if [ "$do_apply" -eq 1 ]; then
    echo "${BOLD}Acting on $acts thread(s)…${RESET}"
    mapfile -t failed_ids < <(printf '%s\n' "${jobs[@]}" | xargs -P "$PAR" -I {} bash -c '
        job="{}"; tid="${job#*:}"
        case "$job" in
          U:*) gh api --silent -X DELETE "/notifications/threads/$tid/subscription" 2>/dev/null \
                 || { echo "$tid"; exit 0; } ;;
        esac
        gh api --silent -X DELETE "/notifications/threads/$tid" 2>/dev/null || echo "$tid"')
    failed=${#failed_ids[@]}
    for fid in "${failed_ids[@]}"; do
      [ -n "$fid" ] && echo "  ${YELLOW}FAILED${RESET} ${label_of[$fid]:-thread $fid}"
    done
    echo "${GREEN}Done:${RESET} $((acts - failed)) cleared$([ "$failed" -gt 0 ] && printf ', %s failed' "$failed")"
  else
    echo "${DIM}No changes made.${RESET}"
  fi
fi
