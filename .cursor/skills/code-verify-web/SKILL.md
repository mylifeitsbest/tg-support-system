---
name: code-verify-web
description: Pre-ship checklist for frontend changes — lint and build. Load during /verify when frontend paths changed.
---

# code-verify-web

Load during `/verify` when the frontend package changed
(CHANGE_ME path, e.g. `web/`).

## Checklist

Run from the frontend package directory:

1. **Lint** — `npm run lint` (or the script defined in package.json).
2. **Typecheck + build** — `npm run build` (or equivalent).

If `node_modules/` is missing or stale, install from the lockfile first
(`npm ci` / `pnpm i --frozen-lockfile` / …).

Pass = both commands succeed. Report pass/fail only, not full output,
unless something failed.
