#!/usr/bin/env bash
# Check out a PR with its changes left unstaged, for review in a diff viewer.
# Usage: ./checkout-pr-diff.sh [--full] <pr-number>
#        ./checkout-pr-diff.sh --list <pr-number>
#        ./checkout-pr-diff.sh --round <pr-number> <round|first..last>
# Each run records the head it checked out under refs/review-pr/<pr>/<n> and
# diffs against the head recorded by the previous run, so that a second review
# only shows what has been pushed since the first. --full diffs against the base
# branch instead, showing the whole PR. --round checks out a recorded round
# again, without recording anything, to see a past review's diff a second time.
# Leaves HEAD detached, so no local branch is created or moved, and a branch
# checked out in another worktree is no obstacle.
# When done: git checkout -f <branch>
set -euo pipefail

# Marks messages from this script, so that they stand out among git's output.
say() {
    echo "--- $*"
}

is_number() {
    case ${1-} in
        '' | *[!0-9]*) return 1 ;;
    esac
}

usage() {
    say "Usage: $0 [--full] <pr-number>" >&2
    say "       $0 --list <pr-number>" >&2
    say "       $0 --round <pr-number> <round|first..last>" >&2
    exit 1
}

# Options are read wherever they appear, so that they can follow the PR number
# as readily as precede it.
full=false
mode=review
operands=()
while [ $# -gt 0 ]; do
    case $1 in
        --full) full=true ;;
        --list) mode=list ;;
        --round) mode=round ;;
        -h | --help) usage ;;
        -*) say "Unknown option: $1" >&2 && usage ;;
        *) operands+=("$1") ;;
    esac
    shift
done

case $mode in
    round) [ "${#operands[@]}" -eq 2 ] || usage ;;
    *) [ "${#operands[@]}" -eq 1 ] || usage ;;
esac
pr=${operands[0]}
is_number "$pr" || usage
round_spec=${operands[1]-}

if [ "$mode" = list ]; then
    rounds=$(git for-each-ref --format='%(refname:lstrip=3) %(objectname:short) %(contents:subject)' \
        "refs/review-pr/$pr" | sort -V)
    if [ -z "$rounds" ]; then
        say "No reviews recorded for #$pr." >&2
        exit 1
    fi
    # When the review was run, and what it was diffed against, are held in the
    # reflog message; rounds recorded before that was added have none.
    echo "$rounds" | while read -r round sha subject; do
        printf '%s\t%s\t%s\t%s\n' "$round" "$sha" \
            "$(git log -g -1 --format='%gs' "refs/review-pr/$pr/$round" 2>/dev/null)" "$subject"
    done
    exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
    say "Working tree not clean - commit, stash or discard local changes first." >&2
    say "If this is a previous review, run: git checkout -f <branch>" >&2
    exit 1
fi

# Echoes the patch id of $1, which identifies a commit by the change it makes
# rather than by where it sits, and so survives a rebase.
patch_id() {
    git show "$1" | git patch-id --stable | cut -d' ' -f1
}

# Succeeds if $1 is a merge whose tree is the automatic merge of its parents, and
# so contributes no changes of its own. A merge that was resolved by hand differs
# from its replay, and holds edits that exist nowhere else.
is_clean_merge() {
    local auto
    local -a fields
    read -r -a fields < <(git rev-list --no-walk --parents "$1")
    # The first field is the commit itself, and merge-tree replays two parents,
    # so anything but an ordinary merge is left to be reviewed.
    [ "${#fields[@]}" -eq 3 ] || return 1
    # A merge that cannot be replayed is treated as hand-made, to be reviewed.
    auto=$(git merge-tree --write-tree "${fields[1]}" "${fields[2]}" 2>/dev/null) || return 1
    [ "$auto" = "$(git rev-parse "$1^{tree}")" ]
}

# Echoes the newest commit of the series ending at HEAD whose changes were
# already reviewed as part of the series ending at $1, or the base of HEAD's
# series if none of them were. Matching by patch id means a rebased or amended
# series is recognised, where comparing commit ids would find nothing in common.
reviewed_target() {
    local reviewed_head=$1 base_ref=$2 sha id target
    local -A reviewed=()

    while read -r sha; do
        id=$(patch_id "$sha")
        [ -n "$id" ] && reviewed[$id]=1
    done < <(git rev-list --no-merges "$(git merge-base "$base_ref" "$reviewed_head")..$reviewed_head")

    target=$(git merge-base "$base_ref" HEAD)
    while read -r sha; do
        if is_clean_merge "$sha"; then
            target=$sha
            continue
        fi
        [ -n "${reviewed[$(patch_id "$sha")]-}" ] || break
        target=$sha
    done < <(git rev-list --reverse "$target..HEAD")

    echo "$target"
}

if [ "$mode" = round ]; then
    # A round on its own means the changes it added, which start at the round
    # before it; round 1 starts at the base, as there is nothing before it.
    case $round_spec in
        *..*)
            from_round=${round_spec%%..*}
            to_round=${round_spec##*..}
            ;;
        *)
            from_round=
            to_round=$round_spec
            ;;
    esac
    # Checked before any arithmetic, which would read a word as a variable name.
    if ! is_number "$to_round" || { [ -n "$from_round" ] && ! is_number "$from_round"; }; then
        say "Bad round: $round_spec (want a round number or first..last)" >&2
        exit 1
    fi
    [ -n "$from_round" ] || from_round=$((to_round - 1))
    if [ "$to_round" -lt 1 ] || [ "$from_round" -ge "$to_round" ]; then
        say "Bad round: $round_spec (first must be before last)" >&2
        exit 1
    fi

    ref_dir=refs/review-pr/$pr
    # The later round is checked first, as it is the one that was asked for.
    for round in $to_round $from_round; do
        [ "$round" -eq 0 ] && continue
        if ! git rev-parse -q --verify "$ref_dir/$round" >/dev/null; then
            say "No round $round recorded for #$pr; see --list $pr." >&2
            exit 1
        fi
    done

    base=$(gh pr view "$pr" --json baseRefName -q .baseRefName)
    git fetch origin "$base"
    git checkout -q --detach "$ref_dir/$to_round"

    if [ "$from_round" -eq 0 ]; then
        reset_to=$(git merge-base "origin/$base" HEAD)
        say "Showing all of #$pr as at round $to_round:"
    else
        # The recorded heads are compared by patch id rather than diffed
        # directly, so that a rebase between rounds is not shown as changes.
        reset_to=$(reviewed_target "$ref_dir/$from_round" "origin/$base")
        say "Showing #$pr from round $from_round to round $to_round:"
    fi
    git --no-pager log --oneline "$reset_to..HEAD"
    git reset "$reset_to"
    exit 0
fi

# The PR head is fetched and checked out detached rather than through
# `gh pr checkout`, which needs a local branch: that fails when the branch is
# checked out in another worktree, and again when it has been force-pushed.
base=$(gh pr view "$pr" --json baseRefName -q .baseRefName)
git fetch origin "pull/$pr/head"
head=$(git rev-parse FETCH_HEAD)
git fetch origin "$base"
git checkout -q --detach "$head"

# Runs are numbered so that every reviewed head is kept and can be revisited.
ref_dir=refs/review-pr/$pr
last=$(git for-each-ref --format='%(refname)' "$ref_dir" | sort -V | tail -1)

if [ "$full" = true ] || [ -z "$last" ]; then
    reset_to=$(git merge-base "origin/$base" HEAD)
    say "Reviewing all of #$pr, against $base."
else
    reset_to=$(reviewed_target "$last" "origin/$base")
    if [ "$reset_to" = "$(git rev-parse HEAD)" ]; then
        say "Nothing pushed to #$pr since $last was reviewed; use --full to review it all." >&2
        exit 1
    fi
    say "Reviewing #$pr since ${reset_to:0:10}, recorded as $last:"
    git --no-pager log --oneline "$reset_to..HEAD"
fi

# Re-reviewing a head that is already recorded, which --full allows, would only
# repeat the round it was recorded as.
if [ -n "$last" ] && [ "$(git rev-parse "$last")" = "$(git rev-parse HEAD)" ]; then
    say "Head unchanged since $last, which stays the latest round."
else
    if [ -z "$last" ]; then
        next=1
    else
        next=$((${last##*/} + 1))
    fi
    # A reflog is only kept for a ref whose log file already exists, unless
    # core.logAllRefUpdates is turned on for every ref, so the file is created
    # here to record when each review ran without changing the repo's config.
    reflog=$(git rev-parse --git-common-dir)/logs/$ref_dir/$next
    mkdir -p "$(dirname "$reflog")"
    touch "$reflog"
    git update-ref -m "$(date '+%Y-%m-%d %H:%M') against ${reset_to:0:10}$([ "$full" = true ] && echo ' --full')" \
        "$ref_dir/$next" HEAD
    say "Recorded as $ref_dir/$next."
fi

git reset "$reset_to"
