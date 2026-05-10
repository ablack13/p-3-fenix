# /fx-agent — Agent management

Subcommand requested: $ARGUMENTS

Dispatch based on the first word of $ARGUMENTS.

---

## If $ARGUMENTS starts with `rules`

List all agent rules files with roles and edit paths.

1. Discover all rules files: `.claude/agents/*-rules.md`.
2. For each, find the matching agent definition and extract the `description:` from frontmatter.
3. Print:

```
Fenix agent rules

These files control agent behavior. Edit any to tune behavior without
modifying the structural agent definition.

| Agent              | Rules file                                       | Role |
|--------------------|--------------------------------------------------|------|
| architect          | .claude/agents/architect-rules.md                | Designs implementation plans (file-based, read-only on source) |
| worker             | .claude/agents/worker-rules.md                   | Executes approved plans (only writer of project code) |
| tester             | .claude/agents/tester-rules.md                   | Reviews worker output (file-based, read-only) |
| module-auditor     | .claude/agents/module-auditor-rules.md           | Per-module audit: detects stubs, fills them, finds stale docs |
| module-discoverer  | .claude/agents/module-discoverer-rules.md        | Per-module structure proposal for /fx-init |
| freshness-scanner  | .claude/agents/freshness-scanner-rules.md        | Frontmatter staleness check |
| reference-linker   | .claude/agents/reference-linker-rules.md         | Auto-link new files in reference/ |

Edit any file with your editor of choice.
Changes apply on the next subagent invocation — no restart.

To see structural definition (tools, output format), open <name>.md (without -rules).
```

4. Stop. Don't open files.

---

## If $ARGUMENTS starts with `list`

List all agents with tool access.

1. Discover `.claude/agents/*.md` excluding `*-rules.md` and `_topology.md`.
2. For each, parse frontmatter to extract name, tools, description.
3. Print as a table.

---

## If $ARGUMENTS is empty or unrecognized

Print:

```
Usage: /fx-agent <subcommand>

Subcommands:
  rules    List all agent rules files with edit paths.
  list     List all agents with their tool access.
```

---

## Constraints

- Read-only. Never modifies files.
- Don't open files for the developer — show paths.
