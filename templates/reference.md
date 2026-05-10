---
documents:
  - <repo-relative source path>
  - <another source path if applicable>
applies_to_categories: [<category1>, <category2>]
applies_to_wings: [<wing1>, <wing2>]  # or "*" for project-wide
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---

# <Reference topic title>

<!--
Reference docs describe cross-cutting concerns — patterns, decisions, or conventions
that span multiple modules. They live at `reference/` (or `reference/<subfolder>/`)
and are NOT scoped to a single wing.

Frontmatter:
  documents — source files this doc covers (used for staleness checks).
              Empty list `[]` is allowed for purely conceptual docs.
  applies_to_categories — task-router categories that should pull this in when matched.
  applies_to_wings — wings the reference applies to. Use "*" for project-wide.

Auto-linking: if you drop a new file under `reference/` without frontmatter,
/fx-doc update will spawn the reference-linker subagent to propose values
for these fields. You approve before they're applied.
-->

## Overview

<2-4 sentences describing the topic at the project-wide level — what it is, why we do it this way>

## Pattern

<the convention, decision, or pattern itself — concrete enough to be applied>

```kotlin
// or whatever language — example code if helpful
```

## Rationale

<why this pattern exists, what alternatives were considered, what trade-offs were accepted>

## Application

How this applies across wings:

- **Wing X** — <how the pattern shows up in this wing, link to relevant room>
- **Wing Y** — <how the pattern shows up here>

## Anti-patterns

What NOT to do:

- <anti-pattern>
- <anti-pattern>

## See also

- `<wing>/docs/rooms/<room>.md` — wing-specific application
- `reference/<other-ref>.md` — related cross-cutting concern
