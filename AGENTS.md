# AGENTS.md

Governs how AI coding agents work in this repository. Tool-agnostic — every
agent follows these rules.

> After copying this pack: replace every `CHANGE_ME` with your project facts.
> Agents treat this file as binding.

## Reporting style — brevity first (highest priority)

Lead with the single most important thing in the first line. Default to a few
lines. Do NOT open with framing or a multi-section report unless the user asks
for detail or a real completion report is required. When in doubt, shorter.
**Repo brevity always wins.**

**Operational requirements are the headline, never buried.** If a change needs
a restart, migration, or env var — say that first.

## Language & status reports

See [AGENT_OPERATING_RULES.md](./AGENT_OPERATING_RULES.md). Short version:
reply in the language the person writes in (team mostly Russian);
**GitHub Issues** (title, body, checklist, agent comments) in **Russian**;
code, commits, and repo docs in English; terse senior-engineer tone.

## Model Policy

Use **Cursor Grok 4.5 high (Not Fast)** for most tasks. Paid/premium models
only for critical work: DB migrations, payments/money, security/secrets, hard
architecture. Mechanical steps (`/ship`, routine edits) — cheapest model.
Full policy: `.cursor/rules/model-policy.mdc`.

## Repo Rules

- **Branches.** `feature/N-<slug>` — one ticket, one branch; `dev` — shared
  integration line. Never commit on `dev` or `main` directly.
- **Always cut the ticket branch from fresh `dev`** and
  `git pull --rebase --autostash origin dev` before continuing.
- **Commit cadence**: `.cursor/rules/git-cadence.mdc` — local commits after
  ~3 meaningful edits; every commit body references `#N`.
- **Pushing is gated**: `/ship` (`scripts/agent/ship.sh`) pushes the ticket
  branch and fast-forwards `dev`, only with a passing verify record for the
  current HEAD. Never push unverified work.
- **Parallel agents**: one ticket per agent; prefer separate worktrees.
  Never mix another ticket's files into your commits.
- Conventional Commits (`feat`/`fix`/`test`/`chore`/`refactor`/`docs`/`perf`).
  Subject ≤50 chars. Scopes: `api`, `bot`, `web`, `scripts`.
- Tickets live as **GitHub Issues** on this repository (`mylifeitsbest/tg-support-system`).
  Issue text in **Russian**. Titles: `[ N ] Краткий заголовок` right after
  create. Every commit references `#N` (`Closes #N` / `Refs #N`).
- **Issues are flat** — no sub-issues by default. Plan = checklist in the
  body. If too big, create more flat issues linked with `#N`. Do not cram
  unrelated work into one ticket; do not spawn tiny low-level tickets.
- Stage only the ticket's files. Never revert the owner's unrelated dirty work.

## Forbidden Without Explicit Human Confirmation

- Editing/renaming/deleting **existing** migrations that already shipped
  (append-only; guard: `scripts/agent/check-migrations-append-only.sh`).
- Running migrations or destructive SQL against a **live** DB without backup
  + explicit OK.
- Committing `.env`, tokens, keys, `.db`, or log files. Never print secrets.
- Touching payment-provider keys, bot tokens, wallet keys — stop and ask.
- Deleting/renaming files outside the current ticket's scope.

## Services (quick map)

Fill this table (also mirror in **project-atlas**):

| Service | Runtime | Port | Notes |
| --- | --- | --- | --- |
| `api/` | FastAPI REST + SQLite | `make api` | 8000 | stdout |
| `bot/` | aiogram 3 Telegram bot | `make bot` | — | stdout |
| `web/` | Vue 3 Mini App (operator UI) | `make web` | 5173 | stdout |

## Agentic Workflow Commands

| When the request is to… | Use |
| --- | --- |
| plan a ticket | **`/pplan`** |
| implement a planned ticket | **`/work`** |
| check before shipping | **`/verify`** |
| ship / push to integration | **`/ship`** |
| small urgent fix end-to-end | **`/do-all`** |

Cycle: `/pplan` → `/work` → `/verify` → `/ship`.
Every command report ends with the next command and issue number.
Same chat is fine for one ticket; fresh chat when switching tickets.
Ticket id = GitHub issue number. All GitHub access via `gh`.

### Open questions → chat (hard rule)

Product/tech decisions the human must make are **blocking**:

- Before writing a `/pplan` body: if context is insufficient — **ask in chat
  first**. Do not publish a checklist full of TBD.
- Chat wording: plain language; prefer short A/B options.
- `/work` must **refuse** until answers are in chat and recorded in the issue.
- The agent must **never** invent answers or pick defaults for the human.

## Board, labels, assignee, blockers, Priority

Status moves only via `scripts/agent/board.sh N <status>` (Windows:
`board.ps1`). **Done** cards must land at the **top** of Done.

**Priority:** `scripts/agent/priority.sh N <level>` (Windows: `priority.ps1`) —
issue Fields → Priority (Urgent / High / Medium / Low). Do **not** use Labels
`priority:*`. Skill: **board-priority**.
Defaults: `bug` → Urgent, `enhancement` → Medium, `later` → Low.

| Command | Status | Other writes |
| --- | --- | --- |
| `/pplan N` | `ready` (or `backlog` if `later`) | type label; Priority |
| `/work N` | `in-progress` | `--add-assignee @me`; refuse if open blockers |
| `/verify N` | unchanged | none |
| `/ship N` | `done` | remove `in-progress` |
| `/do-all N` | same sequence | small urgent only |

Type labels: `bug`, `enhancement`, `later`. `blocked` signals open blockers.

## Skills

- **board-priority** — Status board + Fields Priority
- **do-all** — small urgent full cycle to `/ship`
- **project-atlas** — repo map (fill after copy)
- **code-style-*** / **code-verify-*** — adapt to your stack

## Token Efficiency

Read only what the ticket needs. Prefer diffs. Ask only when irreversible,
security-relevant, or blocked on missing info.

---

## Answer the question that was asked (binding)

Include **only** what was asked. If the honest answer is "none," say "none".
Off-list alternatives only after the direct answer, clearly marked.
