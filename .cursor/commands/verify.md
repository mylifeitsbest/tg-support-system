# /verify TICKET

`TICKET` is a GitHub issue number `N`. Verify does not touch GitHub; it needs
the number to write the ticket's own verify record and to carry it through to
the next-step line.

Run before shipping, and automatically before merge-gating checks.

1. `git pull --rebase --autostash origin dev` on the ticket branch
   (`feature/N-...`). Resolve conflicts. If a conflict is semantic (not just
   formatting/whitespace), stop and ask — don't guess intent.
2. Determine what changed since the integration branch:
   `git diff --name-only origin/dev...HEAD` plus `git status --porcelain`
   (cadence commits may already exist; the working tree may hold more).
3. Read and follow the code-verify skill matching what changed (in
   `.cursor/skills/<name>/SKILL.md`):
   - **code-verify-python** for Python / backend paths listed in that skill
     (fill paths after integrating the pack).
   - **code-verify-web** for frontend paths listed in that skill.
   - If both changed, follow both. Add more verify skills for other stacks.
4. Guards:
   - When any migration path changed (see
     `scripts/agent/check-migrations-append-only.sh` globs):
     `scripts/agent/check-migrations-append-only.sh origin/dev..HEAD`.
   - Always: `scripts/agent/check-secrets.sh origin/dev..HEAD` (add
     `--staged` too if anything is staged).
5. Write the result to the ticket's own record `.agent/verify-status-N.json`
   (one file per ticket, so parallel agents never overwrite each other;
   `.agent/verify-status.example.json` shows the shape):

   ```json
   {
     "branch": "<branch name>",
     "sha": "<current HEAD SHA>",
     "result": "pass" | "fail",
     "timestamp": "<ISO 8601>"
   }
   ```

6. Report pass/fail only, not full output, unless something failed.
7. End the report with the next step. On pass: `/ship N`, and mention it is
   a mechanical step — a small/cheap model is enough. On fail: name what to
   fix, then `/verify N` again.
