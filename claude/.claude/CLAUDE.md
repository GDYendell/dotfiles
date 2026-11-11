## Questions

When a message asks for an explanation, assessment, or recommendation rather than a change, answer
it and stop. Do not edit code. This covers "why", "how does", "should we", "is it possible", "what
does" — including when the answer is that a change is needed.

A request to show, demonstrate, build, or prove something is not a question. Do it.

Tool calls needed to answer are allowed: reading, searching, read-only commands, and scratch files
outside the repo. Never modify tracked files to illustrate a point — build a standalone
reproduction in the scratchpad instead. Code in the reply illustrates the answer; do not apply it.

Do not announce which mode you are in. Just answer.

## File paths

When referencing files, give the full path relative to the repo root in `path:line` form to create
clickable links.

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for
it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the
  relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch
  hops grep can't follow. Name a file or symbol in the query to read its current line-numbered
  source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Delegation

Delgate high-token tasks to keep the context clean for the lead agent: searching, exploring,
prasing logs, command output, creating examples to prove behaviour. Spending tokens in a throwaway
session saves context in the main session where the important work is done: design, review,
summarising, which reduces cost (even with the same model, sub-agents do not necessarily have to be
weaker models).

### Manual Exploration

Where codegraph is not available, warn and then fall back to a Haiku sub-agent for token heavy
reads, e.g. using multiple tool calls, grepping codebase, understanding structure.

### Testing

Only run checks/tests inline if checking return status or filtering the output to few lines / a
pattern. For anything more delegate to a Haiku agent and ask for a concise summary. Provide test
command, working directory and what to look for. 

### Edits

Small, focused edits can be done inline.

For mechanical edits across multiple files, use sed where possible and if absoulately necessary
python (but do not use it to replace large blocks of text). For mechanical edits that don't fit
into a find-replace, delegate to a Haiku sub-agent.

For any larger or more complicated changes; write a plan, confirm with the user and then use the
`/execute-plan` skill to have one-or-more Sonnet sub-agents do the edits.

### Fork vs fresh

Fresh subagent (default, Haiku where possible) for self-contained tasks: searching, tests,
logs. Fork when the task depends on conversation context that would be lossy to brief.

### Sidequests

If a tangent needs my input or will span many turns, don't delegate or do it inline.
Suggest running `/sidequest`.

Keep the current plan in the task list so it survives tangents and compaction.

## Tools

- rg (not grep)
- fd (not find)
