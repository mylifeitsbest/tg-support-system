---
name: do-all
description: Runs the full ticket cycle /pplan → /work → /verify → /ship in one go for small urgent fixes. Use when the user asks /do-all, «сделай всё», or wants a tiny urgent fix shipped end-to-end without stopping between steps.
---

# do-all

One-shot cycle for **small urgent fixes** only.

```text
/pplan → /work → /verify → /ship
```

## When to use

- Tiny bugfix or one-knob change
- Scope clear; few files; no product ambiguity
- User wants it done ASAP (`/do-all N` or «сделай от плана до ship»)

## When NOT to use

- Large features, unclear product rules
- Open blockers or unanswered product questions
- Live DB migrations / secrets work that needs human OK first

If unsuitable → refuse `/do-all`, run normal `/pplan` only, end with `/work N`.

## Size gate (hard)

| OK for do-all | Too big — split cycle |
| --- | --- |
| ≤ ~3 files, ≤ ~1–2 hours of focused work | New UI flows, schema design, audits |
| Acceptance fits in ≤ ~8 checklist lines | Needs several product A/B answers |

If too big after `/pplan` body is clear: stop after plan, report `/work N`.

## Procedure

Follow each command’s full file under `.cursor/commands/` — do not skip gates.

1. **`/pplan N`** — ask blocking questions in chat first; write plan; Priority;
   board → `ready`. If questions remain → **stop**.
2. **`/work N`** — branches, implement, local commits with `#N`.
3. **`/verify N`** — write `.agent/verify-status-N.json`. Fail → fix → re-verify.
4. **`/ship N`** — mechanical; board → Done.

## Reporting

- One short Mode B report at the end
- Do not ask for the next command unless blocked mid-cycle

## Model

Prefer cheaper models for verify/ship when policy allows; usual model for
plan + implementation.
