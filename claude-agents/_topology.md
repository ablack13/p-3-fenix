# Shared agent vocabulary — wings/rooms/drawers topology

This file is **NOT** auto-loaded by Claude Code subagents. Each subagent embeds its own copy of the vocabulary inside its `.md` file. This file exists as the canonical reference: when you edit one agent, copy any topology changes here to all three agent files.

Files that contain a copy of this vocabulary:

- `module-auditor.md`
- `module-discoverer.md`
- `freshness-scanner.md`

If you change a definition below, update all three. The agents must speak the same language for their outputs to compose cleanly in the main agent.

---

## The palace metaphor

- **Palace** = the project's full documentation. Rooted at `docs/` (shared) and `<module-path>/docs/` (per-module).
- **Wing** = one module's documentation. Lives at `<module-path>/docs/`. Has a `README.md` (wing root), a `rooms/` folder, and a `drawers/` folder.
- **Room** = a subsystem inside a module. One markdown file at `<wing>/rooms/<name>.md`. Standard names: `di`, `persistence`, `network`, `ui-android`, `ui-ios`, `public-api`. Custom names allowed if they describe a coherent subsystem.
- **Drawer** = a single-concern leaf doc — one class, one config, one migration. Lives at `<wing>/drawers/<DrawerName>.md`. Loadable standalone without its room.
- **Index** = the root `docs/hint_index_map.md`. Lists every wing, its rooms, its notable drawers, and cross-wing dependencies. Authoritative for topology.

## Identifier conventions

When agents reference parts of the palace in their output:

| Thing | Format |
|---|---|
| Wing | Module name (`practice`) or full path (`modules/practice/docs/`) |
| Room | Wing-relative path: `rooms/di.md` |
| Drawer | Wing-relative path: `drawers/PracticeModule.md` |
| Index entry | "the `practice` entry in `hint_index_map.md`" |

The main agent uses these conventions to merge subagent outputs without reformatting.

## Frontmatter contract

Rooms and drawers:

```yaml
---
documents:
  - <repo-relative source path>
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---
```

Wing READMEs: no frontmatter required.
Index (`hint_index_map.md`): has `Last index review:` line, not full frontmatter.

## Nature classification (used by `module-auditor`)

When classifying impact on a room or drawer:

| Value | Meaning |
|---|---|
| `rewrite` | Major prose changes; large source refactor or behavior shift |
| `minor-update` | Small edits; signature change, added method, renamed parameter |
| `xref-only` | Prose unchanged but cross-references need adjustment |
| `restamp-only` | Source touched but prose still accurate (formatting, internal refactor, test-only) |

## Severity hint (used by `freshness-scanner`)

When suggesting how to handle a stale doc:

| Value | Meaning |
|---|---|
| `restamp-only` | Source commits look cosmetic — bump `last_reviewed_commit` and move on |
| `update-likely` | Source commits indicate real change — prose probably needs editing |
| `needs-review` | Ambiguous; human judgment required |

## Recommendation values (used by `module-discoverer`)

When recommending a wing's status:

| Value | When |
|---|---|
| `NEW WING` | No existing docs; module has public surface |
| `PARTIAL (add rooms)` | Wing README exists but no rooms |
| `ALREADY HAS DOCS` | Wing exists and has rooms |
| `SKIP (internal only)` | No public surface; module is internal |

---

## Why subagents embed vocabulary instead of including it

Claude Code subagents run in fresh context windows. They see only:

1. Their own `.md` file (system prompt).
2. The input message the main agent passes them.

They cannot read other files at startup, including this one. So the topology vocabulary must live inside each agent file directly — duplication is the price of context isolation.

This is by design. Subagents have clean context for fast, focused work. The duplication cost is small (~1 KB per agent) and you only update it when you change the topology itself, which should be rare.
