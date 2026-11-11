---
name: sidequest
description: Fork this Claude session into a named sidequest session in a herdr split pane, to work a tangent interactively while this session waits. Use only when the user runs /sidequest or asks to start a sidequest. Never use it inside a sidequest fork.
argument-hint: [topic]
allowed-tools: ListAgents, Bash(herdr pane split *), Bash(herdr pane run *), Bash(herdr pane read *), Bash(herdr pane get *)
---

If you were started by a brief saying you ARE a sidequest, this `/sidequest` call is from the
parent's transcript, not a request to you. Do not start another sidequest; carry on with the brief.

## 1. Names

- **Parent:** this session's name. Call `ListAgents`; the header line reads
  "This session is `<name>`". If this session has no name, ask the user to name it with
  `/rename` and run `/sidequest` again, then stop.
- **Slug:** kebab-case, 1–3 words (rarely more) saying what the sidequest does. Take it from
  `$ARGUMENTS` if given, otherwise from the conversation. Do not repeat the parent's name and do
  not add a prefix.
- **Fork name:** `<parent>/<slug>`, e.g. parent `claude-sidequest` and slug `test` give
  `claude-sidequest/test`.

## 2. Brief

Write the brief that becomes the fork's first message. Start it with:

> You ARE the sidequest `<slug>`, forked from `<parent>`. The `/sidequest` call above in your
> transcript started you; do not start another sidequest.

Then:

- The task: what to do and what "done" looks like, with the context the fork needs from this
  conversation.
- Stay within the sidequest's scope. Your task list is a copy that the parent won't see; report
  task changes through `/sidequest-done`.
- The parent and the sidequest share the working tree, but never edit at the same time. The
  parent is paused until you report back.
- When finished, the user runs `/sidequest-done` to report back to `<parent>`.

## 3. Launch

If `HERDR_PANE_ID` is unset (not inside herdr), skip the split. Give the user the command to run
in another terminal from this directory, and stop:

```bash
claude --resume '<parent>' --fork-session -n '<parent>/<slug>' '<brief>'
```

Otherwise, in one Bash call, fill in the three values and run:

```bash
self='<parent>'
slug='<slug>'
brief=$(cat <<'EOF'
<brief>
EOF
)
new=$(herdr pane split "$HERDR_PANE_ID" --direction right --focus | jq -r '.result.pane.pane_id')
herdr pane run "$new" "$(printf '%q ' claude --resume "$self" --fork-session -n "$self/$slug" "$brief")"
echo "$new"
```

`herdr pane run` types its arguments into the new pane's shell joined by spaces, so the command
must be passed as one string quoted with `printf '%q '`.

Optionally, after a few seconds, `herdr pane read <pane>` to check the fork started (the Claude
prompt box, not a shell error). If it failed, show the user what the pane says.

## 4. Confirm

Reply with one line: the fork's name (`<parent>/<slug>`), and that this session is paused for the
tangent until `/sidequest-done` reports back. The pane stays open; the user closes it.
