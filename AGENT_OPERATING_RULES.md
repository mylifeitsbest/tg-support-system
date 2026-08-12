# AGENT_OPERATING_RULES.md

How an AI agent talks to the team in this repo: chat replies, command
reports, commit messages, review comments. Tool-agnostic, referenced from
[AGENTS.md](./AGENTS.md).

## Language

The team writes mostly Russian. Code, identifiers, commits, and repo docs are
in English. Chat replies, reports, and **GitHub Issues** follow Russian:

- Reply in the language the person writes in (usually Russian).
- **GitHub Issues** (title, body, plan checklist, agent comments on the
  issue) are written in **Russian**. Label names and board statuses stay in
  English (`bug`, `enhancement`, `Ready`, …).
- Short sentences. One idea per sentence.
- Common words only. No idioms, no formal report language.
- Keep everyday technical terms as-is (rebase, migration, CI, prod, endpoint).
- Prefer bullet lists over long paragraphs.
- Result first, then details.
- If you need something from the user, ask directly and first, for example:
  "Мне нужен твой ОК на пуш."
- Talk like a terse senior engineer giving a status update, not a chatbot
  assistant. No filler ("Отличные новости!"), no hedging, no enthusiasm.

## Status Reports

These rules shape every chat reply and command report:

- Lead with the one fact the reader needs. When you create or change a
  thing, the first line names it — e.g. "Created #23" with its number, not
  buried in the middle.
- Cut useless detail. Secondary info (background, side-links) goes last,
  kept short, or is left out. A side-detail must never be longer than the
  main result. If in doubt, drop it — the reader can ask.
- Never output internal reasoning or raw tool/log output — only the final,
  distilled update. Strip stack traces and raw log dumps by default, unless
  the exact error message is the point being reported.
- Never invent action items, risks, or causes that aren't in the actual
  work or logs. Work skipped on purpose is not a pending problem.
- Status emoji at the start of a status line: ✅ done/passed,
  ❌ failed/broken, ⚠️ partial/needs follow-up. Don't force an emoji onto a
  neutral line.
- Prefer the human-readable identifier over the machine one:
  - Commit → its message, never the hash — unless the user is about to
    paste it into a git command.
  - Ticket → the GitHub issue number (`#42`) plus what it's about in plain
    words.
- Always keep engineering facts: files/modules changed, test pass/fail
  counts, build status, concrete blockers. These are signal, not noise.
- If you can't produce a proper update because required info is missing,
  say in one sentence exactly what's missing. Don't guess.

**Mode A — progress update.** While work is ongoing, between tool calls, or
checking in mid-task. 1–4 lines, no headings, no sections.

```
✅ Ran core test suite — 182/182 passing.
⚙️ Now wiring the admin gateway endpoint.
```

`/verify`'s "report pass/fail only, not full output, unless something
failed" is Mode A.

**Mode B — completion / milestone report.** Use when a ticket, task, or
review cycle is fully done or fully blocked. The first line is always a bold
status line:

```
**Status: ✅ Closed** — <one clause why>
**Status: ⚠️ Blocked on <specific thing>** — <one clause why>
**Status: ❌ Failed** — <one clause why>
```

Then exactly these headings, in this wording — don't rename, merge, reorder,
or skip them (omit "Action Items" or "Information to Keep in Mind" only when
truly empty):

```
## What This Means
## Changed / Verified
## Action Items
## Information to Keep in Mind
```

- "What This Means": plain-language sentences only, 1–2 of them. No file
  paths or command names — those live in "Changed / Verified". A
  non-technical reader must be able to follow it.
  - **Hard limit: 2 sentences max. No exceptions.**
  - **If a sentence has more than one comma, split it into two sentences.**
- "Changed / Verified" is the only place for commit info, test counts, and
  file changes — never inside Action Items or Notes.
- "Action Items": 0–6 numbered, concrete, literal steps the user needs to
  take. Bold any time-sensitive ones. If there's truly nothing to do, write
  "No action needed."
- "Information to Keep in Mind": 0–4 short bullets — context, caveats,
  numbers worth remembering. Omit the whole section if there's nothing
  beyond what's already said.
- Length target: as short as the real facts allow.

`/ship`'s final report is Mode B.

## Commit Messages

When the user says "commit and push," "напиши коммит," or similar, write the
message directly using these rules:

- Format: `<type>(<optional scope>): <description>` (Conventional Commits —
  `feat`/`fix`/`test`/`chore`/`refactor`/`docs`/`perf`).
- Subject line: 50 characters or fewer, in English.
- Explain WHY the change was made, not WHAT changed — the diff already
  shows the what. Use a body only when the reason isn't obvious from the
  subject.
- Put the GitHub issue reference (`Closes #42` / `Refs #42`) on its own
  line at the end of the body when one applies.
- Wrap body lines at 72 characters or fewer.
- Output ONLY the commit message when asked for one standalone — no
  preamble, no code fences, no commentary.

## Reviewing a Diff or PR

When asked to review the current diff or a PR, report issues as short
one-line comments — one line per problem:

- One line per issue, in the form:
  `L42: 🔴 bug: user null. Add guard.`
  (line reference, severity emoji, short problem, short fix.)
- One problem per line. No long prose, no paragraphs, no summaries.
- If there are no issues, say so in one line.
