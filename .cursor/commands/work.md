# /work TICKET

`TICKET` is a GitHub issue number (e.g. `42`) on **this repository**.
Execute its plan. **Implementation only**, scoped strictly to the plan — the
checklist in the issue body.

1. If `TICKET` is missing, help pick one instead of making the user go look
   it up. List startable work only (current remote, no hardcoded `--repo`):

   ```
   gh issue list --state open --limit 30 \
     --json number,title,labels,blockedBy
   ```

   Present each as `[ N ] Title`, but **hide** issues that have the `later`
   label or any **open** blocker in `blockedBy`. Sort by issue
   **Fields → Priority** (Urgent → High → Medium → Low; bugs are Urgent).
   Ask the user to pick. Do not continue without a chosen ticket. If nothing
   is startable, say so and stop.
2. **Blocker gate** (even when the number was given):

   ```
   gh issue view N --json blockedBy,assignees,labels
   ```

   If any `blockedBy` node has `state == OPEN`, **stop** — report the
   blocker(s) and do not cut a branch or write code. Suggest waiting or
   finishing the blocker first.
3. Work on the ticket's own branch, cut from fresh `dev` — never commit on
   `main` or `dev` directly (AGENTS.md):

   ```
   git fetch origin dev
   git switch -c feature/N-<slug> origin/dev   # first time
   git switch feature/N-<slug>                 # already exists
   git pull --rebase --autostash origin dev    # existing branch: refresh
   ```

   The working tree often carries the owner's uncommitted changes — never
   revert them; `--autostash` keeps them. Review what the rebase brought in:
   if `dev` already implements (part of) the ticket, say so instead of
   re-implementing.
4. Claim the ticket on GitHub (token of whoever runs the command = assignee):

   ```
   gh issue edit N --add-assignee @me --add-label in-progress --remove-label blocked
   scripts/agent/board.sh N in-progress
   ```

   Windows: `powershell -File scripts/agent/board.ps1 N in-progress`.
   Create `in-progress` once with `gh label create in-progress` if missing.
5. Load the matching code-style skill(s) for the paths you will touch
   (see `.cursor/skills/` and project-atlas).
6. Implement the plan steps. Stay inside the ticket's scope — do not delete
   or rename files outside it (AGENTS.md).
7. Observe all Forbidden rules in AGENTS.md. If a plan step requires a
   forbidden action (editing an existing migration, live-DB change,
   secrets), stop and ask.
8. Commit locally per git-cadence (`.cursor/rules/git-cadence.mdc`) — stage
   only the ticket's files, explicitly. **Every commit body must reference
   the ticket** (`Refs #N`): `/ship` refuses to push commits that don't, so
   a parallel agent's work can never ride along. Do **NOT** push: the push
   happens in `/ship`, after verification.
9. Tick completed checklist items in the issue body as you go
   (`gh issue edit N --body-file <file>`).
10. End the report with the next step: `/verify N`. Same chat is fine for
    this ticket; suggest a fresh chat only if the user is about to switch
    to a different issue.
