# Freshness scanner rules

Behavioral rules for the `freshness-scanner` subagent.

---

## Staleness criteria

A doc is stale if:
- It has frontmatter with `documents:` and `last_reviewed_commit:`.
- For at least one path in `documents:`, `git log <last_reviewed_commit>..HEAD -- <path>` returns commits.

A doc is up-to-date if:
- All paths in `documents:` show empty `git log` since `last_reviewed_commit`.

A doc has missing frontmatter if:
- No frontmatter, or missing `documents:` or `last_reviewed_commit:`.
- `last_reviewed_commit` is invalid/unreachable in git history.

## Severity hints

Read commit messages from the `git log` output to inform the hint:

- `restamp-only` — commits look cosmetic. Patterns: "fix typo", "format", "rename for consistency", "update comment", "test:", "chore:", whitespace-only diffs.
- `update-likely` — commits indicate real change. Patterns: signature changes, new public methods, removed APIs, behavior changes, "refactor:" with non-trivial size.
- `needs-review` — can't tell from messages alone. Default for ambiguous cases.

Be honest. When in doubt, use `needs-review` rather than guess.

## Index-level freshness

The index (`hint_index_map.md`) is stale if:
- Wing entry points to a path that no longer exists.
- Wing's listed rooms/drawers don't match files on disk.
- A wing exists in `settings.gradle.kts` and has docs but isn't in the index.

The index doesn't track source files via `documents:`. Its freshness is structural integrity, not source coverage.

## Reference docs

References (`reference/**/*.md`) are scanned the same way as rooms and drawers. Their `documents:` field works identically.

If a reference has `documents: []` (empty) AND `applies_to_wings: "*"`, it's a project-wide concept doc with no specific source coverage. Mark as up-to-date if frontmatter is otherwise valid — there's nothing source-level to track.

## What NOT to do

- Don't edit any files.
- Don't update frontmatter.
- Don't try to fix issues you find — just report them.
- Don't classify based on file size or last-modified date. Only `git log` against `last_reviewed_commit` matters.
