#!/usr/bin/env bash
# Check out a PR with its changes left unstaged, for review in a diff viewer.
# Usage: ./review-pr.sh [--full] <pr-number>
# Each run records the head it checked out under refs/review-pr/<pr>/<n> and
# diffs against the head recorded by the previous run, so that a second review
# only shows what has been pushed since the first. --full diffs against the base
# branch instead, showing the whole PR.
# When done: git checkout -f <branch>
set -euo pipefail

full=false
if [ "${1-}" = "--full" ]; then
    full=true
    shift
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 [--full] <pr-number>" >&2
    exit 1
fi
pr=$1

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree not clean - commit, stash or discard local changes first." >&2
    echo "If this is a previous review, run: git checkout -f <branch>" >&2
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

gh pr checkout "$pr"
base=$(gh pr view --json baseRefName -q .baseRefName)
git fetch origin "$base"

# Runs are numbered so that every reviewed head is kept and can be revisited.
ref_dir=refs/review-pr/$pr
last=$(git for-each-ref --format='%(refname)' "$ref_dir" | sort -V | tail -1)

if [ "$full" = true ] || [ -z "$last" ]; then
    reset_to=$(git merge-base "origin/$base" HEAD)
    echo "Reviewing all of #$pr, against $base."
else
    reset_to=$(reviewed_target "$last" "origin/$base")
    if [ "$reset_to" = "$(git rev-parse HEAD)" ]; then
        echo "Nothing pushed to #$pr since $last was reviewed; use --full to review it all." >&2
        exit 1
    fi
    echo "Reviewing #$pr since ${reset_to:0:10}, recorded as $last:"
    git log --oneline "$reset_to..HEAD"
fi

if [ -z "$last" ]; then
    next=1
else
    next=$((${last##*/} + 1))
fi
git update-ref "$ref_dir/$next" HEAD

git checkout --detach
git reset "$reset_to"
