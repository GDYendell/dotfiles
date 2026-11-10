---
name: devlog
description: Write a dev journal checkpoint for the work done in this conversation since the last checkpoint, and append it to today's Obsidian daily note. Use only when the user runs /devlog or asks to log, journal or checkpoint the session.
argument-hint: [extra notes]
allowed-tools: Bash(~/.local/bin/devlog-note *), AskUserQuestion
---

!`~/.local/bin/devlog-note context`

If the "Today's note" line shows `MISSING:` (or there is an error), reply with one line telling
the user to create today's daily note in Obsidian first, then stop. Do not draft anything.

If it shows `OUTBOX:`, there is no vault on this machine. Carry on as normal: `append` writes the
entry to a file in that directory instead, and prints its path.

## 1. Scope

Cover the user's turns since the last `/devlog` checkpoint in this conversation. If there is none,
cover everything since the start of the conversation (or since the last `/clear`). If part of the
range was compacted, work from the summary and say so in the entry: "(earlier turns compacted)".

## 2. Draft

Write in plain, normal prose, whatever response style is active in the conversation.

- **Prompts:** the user's own words, in full. Fix only typos, grammar and punctuation; keep their
  phrasing and voice. Never shorten, paraphrase or truncate them. The only exception is content
  they pasted in (logs, code, command output), which becomes `[pasted <what>]`.
  Fold trivial follow-ups ("yes", "do it", "try again") into the turn before.
- **Outcome per prompt:** one factual line: what was found, decided, proposed or changed.
- **Files:** files created or edited in the range, repo-relative.
- **Summary:** 2–4 lines at the top: what the user was trying to do, what changed in their
  understanding, where it stands now. Work in their answers from step 3 and any arguments, keeping
  their wording. This is what they will re-read later, so make it worthwhile.
- **Lessons:** a recap of questions the user asked and their answer, if its usefulness will
  outlive this session. Flatten follow-up questions into one entry.

## 3. Ask

Use `AskUserQuestion` for 1–2 reflection questions that fit this checkpoint. For example: why an
approach was chosen or ruled out, what is still unclear or open, what was surprising, what is next.
Pick the ones the conversation does not already answer.

For each question, offer 2–3 concise guesses at the user's answer based on the conversation, plus
a "Skip" option. The user may pick a guess or type their own via "Other".

If arguments were passed (`$ARGUMENTS`), treat them like answers and work them into the summary.

Ask before writing the summary, so the answers can shape it.

## 4. Append

Pipe the entry as JSON to `~/.local/bin/devlog-note append` with a quoted heredoc
(`<<'EOF'`). The script handles the heading, time, repo, callouts, quoting and layout, so the
strings are plain text: no markdown quoting, no `>` prefixes. Do not use Write or Edit on the note.

```json
{
  "topic": "<short topic>",
  "summary": "<summary>",
  "lessons": [{"q": "<question>", "a": "<answer>"}],
  "files": ["<repo-relative path>"],
  "turns": [{"prompt": "<cleaned prompt, newlines kept>", "outcome": "<one line>"}]
}
```

`summary` and `turns` are required. Use empty arrays (or leave the key out) for no lessons or no
files, and that section is left out. If the script reports an error, nothing was written: fix
the JSON and run it again.

Then reply with one line confirming the checkpoint heading that was written (and the outbox file
path, if it went to the outbox).
