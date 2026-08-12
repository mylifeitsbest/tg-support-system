---
name: board-priority
description: Board Status + issue Fields Priority. Load when moving cards or setting Urgent/High/Medium/Low.
---

# board-priority

## Hard rule — Priority is issue **Fields**, not Labels

In the GitHub issue sidebar:

1. **Fields → Priority** (organization issue field) — **required**
2. **Projects → … → Priority** (project field) — optional mirror
3. **Labels `priority:*`** — **forbidden**; scripts remove them

If Fields still says «Choose an option» while Projects shows Urgent — **wrong**.
Re-run `priority.sh` / `priority.ps1` (needs `GraphQL-Features: issue_fields`).

## How to set

```bash
scripts/agent/priority.sh N urgent
# Windows:
powershell -File scripts/agent/priority.ps1 N urgent
```

Fill CHANGE_ME IDs in those scripts (see pack README).

## Defaults (`/pplan`)

| Type | Fields → Priority |
| --- | --- |
| `bug` | Urgent |
| `enhancement` | Medium |
| `later` | Low |

## Status (board columns)

`scripts/agent/board.sh N <status>` (Windows: `board.ps1`).
**Done** cards must land at the **top** of Done (scripts enforce this).
