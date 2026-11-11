---
name: sidequest-done
description: Report a sidequest's outcome back to its parent session. Use only in a sidequest fork (a session started by /sidequest), when the user runs /sidequest-done or asks to report back to the parent session.
argument-hint: [extra notes]
allowed-tools: ListAgents, SendMessage, AskUserQuestion, Bash(git status *), Bash(git log *)
---

## 1. Summarise

Write a compact summary of the sidequest, for the parent session to act on:

- **Outcome:** what was found, decided or built, in 1–3 lines.
- **Decisions:** choices made and why, one line each.
- **Files changed:** repo-relative paths.
- **Commit:** hash and subject, if anything was committed.
- **Task changes:** items for the parent to add to or mark done in its task list. Your task list
  is a copy, so the parent won't see edits you made to it.
- **Open questions / follow-ups:** what the parent should pick up or decide.

If arguments were passed (`$ARGUMENTS`), work them into the summary.

## 2. Commit check

Consider only files this sidequest changed since it was forked. Ignore other uncommitted changes
in the working tree; they belong to the parent or the user. Run `git status --short` and check
whether any of the sidequest's files are uncommitted. If so, use `AskUserQuestion` to ask whether
to commit them before reporting. A `/rewind` in the parent can overwrite uncommitted sidequest
edits, so committing protects them. If the user says yes, commit only those files, and add the
hash to the summary.

## 3. Find the parent

The parent's name is this session's name minus its last `/<slug>` segment: `a/b` gives `a`, and a
nested fork `a/b/c` gives `a/b`. Get this session's name from the header line of `ListAgents`
("This session is `<name>`") and confirm the parent appears in the same listing. If this session
has no `/` in its name, or the parent is not listed, ask the user which session is the parent. Do
not guess.

## 4. Send

`SendMessage` the summary to the parent. End it with this note:

> Files listed above changed outside your session. Re-read them before editing.

## 5. Confirm

Reply with one line telling the user the report was sent to the parent and the pane can be closed.
