# /pplan TICKET

`TICKET` is a GitHub issue number (e.g. `42`) on **this repository**
(use `gh` against the current remote; do not hardcode another repo).
If the user described a feature instead of giving a number, create the issue
first (`gh issue create --title "<краткий заголовок>" --body "<контекст>"`),
then **immediately** set the title to include the number at the front:
`gh issue edit N --title "[ N ] <краткий заголовок>"` (spaces around `N`, as
in `[ 42 ] Починить логин`). **Issue title, body, and plan checklist are
Russian** (code/commits/repo docs stay English). Lead the report with that
titled issue and continue.

Write the implementation plan into the issue itself. **No implementation in
this step.**

1. Confirm `gh auth status` is authenticated. If not, stop and ask the user
   to run `gh auth login` (see `docs/agent-workflow.md`) — don't improvise
   another storage for the plan.
2. Load the **project-atlas** skill if the ticket spans more than one service.
3. Read the issue (`gh issue view N`). Understand scope and acceptance
   criteria. If the title is missing the `[ N ] ` prefix, add it with
   `gh issue edit N --title "[ N ] <остаток заголовка>"` (Russian title).
4. Plan the work as small, verifiable steps.
5. **Default: one rich story issue, NO sub-issues** (see AGENTS.md Repo
   Rules). Write the plan INTO the issue body **in Russian**: short context,
   a markdown checklist (`- [ ] шаг`), then notes / open questions. Merge
   with what is already in the body — never overwrite recorded decisions.
   Update with `gh issue edit N --body-file <file>`.
6. **Ops checkboxes (required when the plan touches runtime paths).** If the
   plan includes an alembic migration or changes code of a running service,
   the last checklist items must be the operational steps, phrased so they
   are ticked after being done — e.g.
   `- [ ] Применить миграцию на live DB (сначала бэкап) — отметить вручную после.`
7. If the ticket is too large for one story, split it into SEPARATE FLAT
   issues, each self-contained with its own checklist, linked with `#N`
   "related" refs — never sub-issues under a master. Each new issue gets the
   `[ N ] ` title prefix after create (same as above; Russian titles).
8. **Board + labels + blockers + Priority** (after the body is written):
   - Type label — pick exactly one from the plan:
     - `bug` — something broken;
     - `enhancement` — new behaviour (default when unclear);
     - `later` — parked / "на будущее", not startable yet.
     Apply with `gh issue edit N --add-label <name>` (and remove the other
     two type labels if present).
   - **Priority** (required): `scripts/agent/priority.sh N <level>`
     (Windows: `powershell -File scripts/agent/priority.ps1 N <level>`).
     Sets issue sidebar **Fields → Priority** (Urgent / High / Medium / Low).
     Do **not** use Labels `priority:*`. Skill: **board-priority**.
     Defaults: `bug` → `urgent`, `enhancement` → `medium`, `later` → `low`.
   - Dependencies — when this ticket truly cannot start before another:
     `gh issue edit N --add-blocked-by M`, add a `Blocked by #M` line under
     Notes (Russian ok, e.g. `Блокируется #M`), and `--add-label blocked`.
     Clear `blocked` when no open blockers remain.
   - Move the card: `scripts/agent/board.sh N ready` (`later` stays in
     Backlog instead — `scripts/agent/board.sh N backlog`).
     Windows: `board.ps1`.
9. Report what was written. Do not write code.
10. End the report with the next step: `/work N` (or "waiting on #M" when
    blocked). Same chat is fine for this ticket; suggest a fresh chat only
    if the user is about to switch to a different issue.