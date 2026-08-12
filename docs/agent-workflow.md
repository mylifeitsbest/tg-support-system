# Agent workflow

How AI agents ship ticket work. Binding rules:
[AGENTS.md](../AGENTS.md),
[AGENT_OPERATING_RULES.md](../AGENT_OPERATING_RULES.md).
Human onboarding: [onboarding.md](./onboarding.md).

Model: **Cursor Grok 4.5 high (Not Fast)** for most work
(`.cursor/rules/model-policy.mdc`).

## Branches

```text
feature/N-slug  →  dev
```

- **`feature/N-<slug>`** — one ticket, one branch. Agents only commit here.
- **`dev`** — shared integration line. `/ship` fast-forwards it.

(`main` is optional for this starter — use it if you want a release branch;
this pack does not include `/promote` or deploy.)

## The cycle

```text
/pplan N  →  /work N  →  /verify N  →  /ship N
```

- **`/pplan`** — plan checklist into issue `#N` (Russian). No code. Board → Ready.
- **`/work`** — refuse if blockers/open questions; cut branch from `dev`;
  implement; local commits with `#N`; no push. Board → In progress.
- **`/verify`** — scoped checks + secrets/migration guards.
  Writes `.agent/verify-status-N.json`. Board unchanged.
- **`/ship`** — verify-gated push + fast-forward `dev` via `ship.sh`.
  Board → Done (top of Done).

Small urgent: **`/do-all N`** — same cycle in one go.

## Board statuses

| Status | When |
| --- | --- |
| Backlog | Parked / `later` |
| Ready | After `/pplan` |
| In progress | After `/work` starts |
| In review | Optional; this starter usually skips straight to Done on `/ship` |
| Done | After `/ship` (newest finished at top) |

## Setup checklist

1. Copy pack files into your repo (see README).
2. `gh auth login` + `gh auth refresh -s project`.
3. Create GitHub Project board; fill `CHANGE_ME` in `board.sh` / `board.ps1`.
4. Fill Priority scripts if you use Fields Priority.
5. Fill `project-atlas` + code-style/verify skills for your stack.
6. `chmod +x scripts/agent/*.sh`.

## Runtime files (gitignored)

- `.agent/verify-status-N.json` — verify gate for `/ship`
- `.agent/commit-msg.txt` — ship message
- `.agent/ship.lock` — mutex so two agents never ship at once

## Guards

- `check-secrets.sh` — staged/diff scan for tokens and keys
- `check-migrations-append-only.sh` — configure globs for your migration paths
