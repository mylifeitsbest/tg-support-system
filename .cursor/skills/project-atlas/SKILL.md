---
name: project-atlas
description: Repository map — services, ports, entry points, logs, databases, env files, test suites, and ownership boundaries. Load before any task spanning more than one service, or when unsure which service a file belongs to.
---

# Project atlas — tg-support-system

## Services

| Path | Role | How to run | Port | Log |
| --- | --- | --- | --- | --- |
| `api/` | FastAPI REST backend, SQLite DB, operator auth | `make api` / `uvicorn app.main:app --reload` | 8000 | stdout |
| `bot/` | aiogram 3 Telegram bot, user-facing | `make bot` / `python -m app.main` | — (polling) | stdout |
| `web/` | Vue 3 + Tailwind Telegram Mini App (operator UI) | `make web` / `npm run dev` | 5173 | stdout |

## Runtime / tooling

- Language / package manager: Python 3.11+ (api, bot), Node 20+ (web)
- api: `api/requirements.txt`, venv at `api/.venv/`
- bot: `bot/requirements.txt`, venv at `bot/.venv/`
- web: `web/package.json`, npm

## Databases

| Database | Notes |
| --- | --- |
| SQLite (`api/support.db`) | Local dev only. File must not be committed. |

## Migrations

Paths: `api/alembic/versions/` — append-only once shipped.
Guard: `scripts/agent/check-migrations-append-only.sh`

## Tests (per service)

| Area | Command |
| --- | --- |
| api | `cd api && pytest` |
| bot | `cd bot && pytest` (smoke only) |

## Env / secrets layout

- Root `.env.example` → copy to `.env` in repo root
- Each service reads from `../.env` (one level up) or its own `.env`
- Never commit or print secret values
- Key vars: `BOT_TOKEN`, `OPERATOR_ALLOWLIST`, `DATABASE_URL`, `VITE_API_BASE_URL`

## Ownership boundaries

- `api/` owns: DB schema, migrations, REST endpoints, auth logic
- `bot/` owns: Telegram handlers, message routing; talks to `api/` via HTTP
- `web/` owns: Mini App UI; talks to `api/` via HTTP + initData auth
- Do not edit unrelated services in the same ticket unless the plan says so
