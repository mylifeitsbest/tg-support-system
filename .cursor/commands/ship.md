# /ship TICKET

`TICKET` is a GitHub issue number `N` on **this repository**.
Ship the ticket branch into `dev`. **Gated on verification. Mechanical — no
design decisions.**

1. Read `.agent/verify-status-N.json`. If it records a **passing** result for
   the **current HEAD SHA**, skip straight to step 3.
2. Otherwise run `/verify N` first. Only proceed if it passes. If it fails,
   stop and report the failure — **do not ship**.
3. Ship (verification has passed):
   - **Write the commit message yourself** to `.agent/commit-msg.txt` —
     **with a shell command (heredoc), not a file-write tool.** The file is
     gitignored; file-write tools that require reading first will error:

     ```
     cat > .agent/commit-msg.txt <<'EOF'
     <subject>

     <body>

     Closes #<N>
     EOF
     ```

     The heredoc is quoted, so write the **literal** issue number
     (`Closes #42`), not a variable.

     Message rules:
     - Format: `<type>(<optional scope>): <description>` (Conventional
       Commits). Subject ≤50 chars. Explain WHY, not what. Wrap body at 72.
     - Issue reference on its own line at the end — **required**.
       Use **`Closes #N`** when the ticket is complete after ship.
       Use **`Refs #N`** only if a manual follow-up remains (e.g. human must
       apply a live migration).
   - Run the ship script:

     ```
     scripts/agent/ship.sh <N> .agent/commit-msg.txt <ticket files>
     ```

     Pass the ticket's files to stage; omit them when everything is already
     committed by cadence commits. The script takes a ship lock, re-checks
     the verify record against HEAD, rebases on `origin/dev`, refuses
     commits that don't reference `#N`, runs the secrets guard, then pushes
     the ticket branch and fast-forwards `dev`.
   - If it exits with "run /verify first" or "dev moved", do what it says.
     If a rebase conflict is semantic, stop and ask.
   - **The ship is done only when the script prints `shipped:`.**
4. Update the issue **after** the script prints `shipped:`:

   ```
   gh issue edit N --remove-label in-progress
   scripts/agent/board.sh N done
   gh issue comment N --body "зашиплено в dev: <short sha>"
   ```

   Tick completed checklist items in the body.
5. Final report: Mode B (AGENT_OPERATING_RULES.md). Next command only if
   another ticket is queued; otherwise stop.
