---
name: code-style-python
description: Python conventions for backend services in this repo. Load before writing or editing Python code. Fill CHANGE_ME paths after integrating the pack.
---

# code-style-python

Load before writing or editing Python under paths listed in **project-atlas**
(CHANGE_ME: e.g. `api/`, `bot/`, `scripts/`).

## Baseline

- Prefer the project venv / pinned Python version from atlas — not a random
  system interpreter.
- No forced global reformat: **match the style of the surrounding file**.
- Stack (CHANGE_ME): e.g. FastAPI + SQLAlchemy + Alembic, or Nest is N/A —
  delete this skill if the repo is not Python.

## Conventions

- Type hints on new functions; don't backfill old code as a side quest.
- Logging via the `logging` module, never `print`, in service code.
- Async first where the surrounding module is async; don't call blocking I/O
  inside async handlers.
- New dependencies go into the **service's own** requirements/lockfile with
  a reason.
- Config from env (`.env` per service). Never hardcode tokens, keys, or
  credentialed URLs.

## Database & migrations

- Schema changes go through the project's migration tool. **Never edit an
  applied migration** — new behaviour = new migration on top (AGENTS.md).
- Do not run migrations against live DBs during verify/dev without explicit
  human confirmation.
