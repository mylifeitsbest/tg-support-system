# /do-all TICKET

Run the full cycle in **one turn** for a **small urgent fix**:

`/pplan` → `/work` → `/verify` → `/ship`

Load skill **do-all** and follow it. Obey every gate inside
`.cursor/commands/pplan.md`, `work.md`, `verify.md`, `ship.md` —
this command only means “don’t stop between steps.”

## Eligibility

Use only when:

- Fix is small (roughly ≤3 files / short checklist)
- Acceptance is clear (or answers already in chat)
- No open blocker; no live migration / secrets needing human OK

Otherwise refuse: run `/pplan N` only (or ask clarifying questions), end with
`/work N`.

## Steps

1. If `TICKET` missing and the user described the fix — create the issue first
   (Russian title/body), then `[ N ] ` prefix, then continue as `N`.
2. Execute `/pplan N` fully (Priority Fields, board, type label).
3. If open questions remain — **stop**; do not work.
4. Execute `/work N` → `/verify N` → `/ship N` without waiting for the user
   between steps.
5. One final report: what shipped and shas.

## Priority

Small urgent bugs → Fields Priority **Urgent** (via `priority.ps1` /
`priority.sh`), not Labels `priority:*`.
