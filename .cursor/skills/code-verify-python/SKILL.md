---
name: code-verify-python
description: Pre-ship checklist for Python changes. Load during /verify when Python paths changed. Fill CHANGE_ME commands after integrating the pack.
---

# code-verify-python

Load during `/verify` when Python paths from **project-atlas** changed.

## Checklist

1. **Syntax gate** — compile changed areas:

   ```bash
   # CHANGE_ME: path to project python
   python -m compileall -q <changed top-level dirs>
   ```

2. **Tests, scoped to what changed** (CHANGE_ME — one row per service):

   | Changed | Run |
   | --- | --- |
   | `CHANGE_ME/**` | `CHANGE_ME` (e.g. `pytest -q`) |

   Final verify before ship must run the full suite of every changed service.

3. **Migration guard** (when migration paths changed):

   ```bash
   scripts/agent/check-migrations-append-only.sh origin/dev..HEAD
   ```

4. **Secrets guard** (always):

   ```bash
   scripts/agent/check-secrets.sh origin/dev..HEAD
   ```

5. **No live-DB side effects** — verify must not migrate live DBs or restart
   services as a side effect of checks.

Pass = every step above succeeded. Report pass/fail only, not full output,
unless something failed.
