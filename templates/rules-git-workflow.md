# Git & PR rules — ALWAYS active

<!-- Fenix v4: this file has NO `paths:` frontmatter ON PURPOSE. Unscoped rules
     load at session start like CLAUDE.md, so they apply to "prepare a PR
     description" and other requests that never read source files. Do not add
     `paths:` here — scoping this file is how git rules silently stop applying. -->

## Commits

- One logical change per commit. Imperative mood subject line.
- <commit message convention — e.g. Conventional Commits `<type>(<scope>): <summary>` — edit me>
- Never commit `.claude/settings.local.json` or `_claude_backup/`.

## PR / MR descriptions

- Title: <title convention — edit me>
- Body sections in order: `## Summary` / `## Changes` / `## Testing` / `## Risk`
- List affected modules explicitly.
- <tracker link convention — e.g. "Refs PROJ-XXXX in the footer" — edit me>

## Branches

- <branch naming — e.g. `feature/PROJ-XXXX-short-slug` — edit me>
