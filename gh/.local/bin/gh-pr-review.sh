#!/usr/bin/env bash
# Add comments to a pending GitHub PR review, so they can be submitted from the
# GitHub UI as a single review. Never posts a comment directly.
set -euo pipefail

STATE_FILE=.gh-pr-review
# The draft lives in the repository rather than /tmp, so that editors which
# resolve paths against the open workspace can follow the path that is printed.
DRAFT_FILE=.gh-pr-review-draft.md
DRAFT_SEPARATOR=---

usage() {
    cat <<'EOF'
Usage:
  gh-pr-review --review <pr>                 Start (or reuse) a pending review
  gh-pr-review --comment <location> [body]   Add a comment to the pending review
  gh-pr-review --suggest <location>          Add a suggested change
  gh-pr-review --status                      Show the tracked PR

<location> is path:line or path:start-end, as shown in the PR diff.

A comment body is taken from the remaining arguments, from stdin if they are a
single "-", or from a draft file if they are omitted. A suggestion is always
written in a draft file, seeded with a suggestion block holding the lines being
commented on, which can be edited and commented around.

The path of the draft file is printed so that it can be opened in an editor. It
holds a header naming the location being commented on; everything below the
separator is read back as the body once you save.
EOF
}

exit_with_message() {
    echo "gh-pr-review: $*" >&2
    exit 1
}

repo_root() {
    git rev-parse --show-toplevel || exit_with_message "not in a git repository"
}

state_path() {
    echo "$(repo_root)/$STATE_FILE"
}

# Sets OWNER, REPO and PR from the "owner/repo#pr" state file. Must be called
# directly rather than in a subshell, so that its failures exit the script.
load_state() {
    local path state
    path=$(state_path)
    [[ -f $path ]] || exit_with_message "no review in progress; run --review <pr> first"
    state=$(<"$path")
    [[ $state =~ ^([^/]+)/([^#]+)#([0-9]+)$ ]] || exit_with_message "malformed $STATE_FILE: $state; run --review again"
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]}
    PR=${BASH_REMATCH[3]}
}

# Echoes the node id of the caller's pending review, or nothing if there is none.
pending_review_id() {
    local owner=$1 repo=$2 pr=$3
    gh api graphql \
        -f owner="$owner" -f repo="$repo" -F pr="$pr" \
        -f query='
            query($owner: String!, $repo: String!, $pr: Int!) {
                viewer { login }
                repository(owner: $owner, name: $repo) {
                    pullRequest(number: $pr) {
                        reviews(last: 100, states: PENDING) {
                            nodes { id author { login } }
                        }
                    }
                }
            }' \
        --jq '.data as $d
              | $d.repository.pullRequest.reviews.nodes[]
              | select(.author.login == $d.viewer.login)
              | .id' | head -n1
}

cmd_review() {
    local pr=${1-}
    [[ $pr =~ ^[0-9]+$ ]] || exit_with_message "--review needs a PR number"

    local owner repo
    read -r owner repo < <(gh repo view --json owner,name --jq '"\(.owner.login) \(.name)"')

    local review_id
    review_id=$(pending_review_id "$owner" "$repo" "$pr")
    if [[ -n $review_id ]]; then
        echo "Reusing existing pending review on $owner/$repo#$pr"
    else
        gh api --silent --method POST "repos/$owner/$repo/pulls/$pr/reviews"
        echo "Started pending review on $owner/$repo#$pr"
    fi

    echo "$owner/$repo#$pr" >"$(state_path)"
}

# Sets FILE_PATH, LINE and START_LINE (empty unless a range was given) from a
# "path:line" or "path:start-end" location. Call directly, not in a subshell.
parse_location() {
    local location=${1-} lines
    FILE_PATH=${location%:*}
    lines=${location##*:}
    [[ -n $FILE_PATH && $FILE_PATH != "$location" ]] ||
        exit_with_message "bad location: $location (want path:line or path:start-end)"

    if [[ $lines =~ ^([0-9]+)-([0-9]+)$ ]]; then
        START_LINE=${BASH_REMATCH[1]}
        LINE=${BASH_REMATCH[2]}
        ((START_LINE < LINE)) || exit_with_message "bad range: $lines (start must be before end)"
    elif [[ $lines =~ ^[0-9]+$ ]]; then
        START_LINE=
        LINE=$lines
    else
        exit_with_message "bad location: $location (want path:line or path:start-end)"
    fi
}

# Returns once $1 has been written to. The file is polled rather than watched,
# because inotify does not see writes made through the 9p mount that Windows
# editors reach WSL over.
wait_for_save() {
    local file=$1 before
    before=$(stat -c '%Y %s' "$file")
    while [[ $(stat -c '%Y %s' "$file") == "$before" ]]; do
        sleep 0.3
    done
    # Let a save that arrives in several writes finish before it is read back.
    sleep 0.3
}

# Echoes the location being commented on, in the form it was given in.
location_label() {
    echo "$FILE_PATH:${START_LINE:+$START_LINE-}$LINE"
}

# Echoes a body drafted in the draft file, seeded with $1 below a header naming
# the location. The path is printed for opening in an editor, and everything
# after the header is read back once the draft is saved. The terminal is
# addressed directly, because this runs inside a command substitution.
draft_body() {
    local template=$1 draft
    # /dev/tty exists even with no controlling terminal, so test opening it.
    { : >/dev/tty; } 2>/dev/null || exit_with_message "no terminal available to prompt on"

    draft=$(repo_root)/$DRAFT_FILE
    printf 'Commenting on `%s`\nEnter comment below and save to submit. Save without changes to discard.\n%s\n%s' \
        "$(location_label)" "$DRAFT_SEPARATOR" "$template" >"$draft"
    trap 'rm -f "$draft"; exit 130' INT

    printf 'Commenting on %s\nDraft: %s\nEdit and save to submit. Ctrl-C to abort.\n' \
        "$(location_label)" "$DRAFT_FILE" >/dev/tty
    wait_for_save "$draft"

    # The range runs from the first separator to the end, so a body containing
    # one keeps it; dropping the first line drops the separator itself.
    sed -n "/^$DRAFT_SEPARATOR\$/,\$p" "$draft" | tail -n +2
}

# Removes the draft, which is only done once its body has been posted, so that
# the writing survives a failure to post it.
discard_draft() {
    rm -f "$(repo_root)/$DRAFT_FILE"
}

# Echoes the body given as arguments, read from stdin for "-", or drafted in the
# draft file if there are no arguments.
read_body() {
    if (($# == 0)); then
        draft_body ""
    elif [[ $* == "-" ]]; then
        cat
    else
        echo "$*"
    fi
}

# Sets REVIEW_ID from the pending review of the loaded state. Called before a
# comment is drafted, so that a missing review is reported before the writing
# rather than after it.
load_review_id() {
    REVIEW_ID=$(pending_review_id "$OWNER" "$REPO" "$PR")
    [[ -n $REVIEW_ID ]] ||
        exit_with_message "No pending review on $OWNER/$REPO#$PR; run --review $PR first"
}

# Adds a thread at the parsed location to the pending review of the loaded state.
add_thread() {
    local body=$1

    # The start of a range is only declared when there is one, because GitHub
    # rejects a startLine equal to line.
    local start_decl="" start_input="" start_arg=()
    if [[ -n $START_LINE ]]; then
        start_decl=', $startLine: Int!'
        start_input='startLine: $startLine, startSide: RIGHT,'
        start_arg=(-F startLine="$START_LINE")
    fi

    gh api graphql --silent \
        -f reviewId="$REVIEW_ID" -f path="$FILE_PATH" -F line="$LINE" -f body="$body" \
        "${start_arg[@]}" \
        -f query='
            mutation($reviewId: ID!, $path: String!, $line: Int!, $body: String!'"$start_decl"') {
                addPullRequestReviewThread(input: {
                    pullRequestReviewId: $reviewId,
                    path: $path,
                    line: $line,
                    side: RIGHT,
                    '"$start_input"'
                    body: $body
                }) { thread { id } }
            }'
}

cmd_comment() {
    parse_location "${1-}"
    shift || true
    load_state
    load_review_id

    local body
    body=$(read_body "$@")
    if [[ -z $body ]]; then
        discard_draft
        exit_with_message "empty comment body"
    fi

    add_thread "$body"
    discard_draft
    echo "Commented on $FILE_PATH:${START_LINE:+$START_LINE-}$LINE in $OWNER/$REPO#$PR"
}

cmd_suggest() {
    parse_location "${1-}"
    (($# <= 1)) || exit_with_message "--suggest takes only <location>; the suggestion is written in an editor"
    load_state
    load_review_id

    # The block is seeded with the lines being commented on, taken from the
    # working tree, so it is only correct if that is checked out at the PR head.
    local source=$(repo_root)/$FILE_PATH code=""
    if [[ -f $source ]]; then
        code=$(sed -n "${START_LINE:-$LINE},${LINE}p" "$source")
        [[ -n $code ]] || echo "gh-pr-review: $FILE_PATH has no such lines" >&2
    else
        echo "gh-pr-review: no $FILE_PATH in the working tree" >&2
    fi

    # The body is used verbatim, so that prose can be written around the block.
    local template=$'```suggestion\n'"$code"$'\n```' body
    body=$(draft_body "$template")
    if [[ -z $body || $body == "$template" ]]; then
        discard_draft
        exit_with_message "empty suggestion"
    fi

    add_thread "$body"
    discard_draft
    echo "Suggested a change to $FILE_PATH:${START_LINE:+$START_LINE-}$LINE in $OWNER/$REPO#$PR"
}

cmd_status() {
    load_state
    if [[ -n $(pending_review_id "$OWNER" "$REPO" "$PR") ]]; then
        echo "Pending review on $OWNER/$REPO#$PR"
    else
        echo "Tracking $OWNER/$REPO#$PR, but it has no pending review"
    fi
}

case ${1-} in
    --review) shift; cmd_review "$@" ;;
    --comment) shift; cmd_comment "$@" ;;
    --suggest) shift; cmd_suggest "$@" ;;
    --status) cmd_status ;;
    -h | --help) usage ;;
    *) usage >&2; exit 1 ;;
esac
