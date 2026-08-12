---
name: project-atlas
description: Repository map — services, ports, entry points, logs, databases, env files, test suites, and ownership boundaries. Load before any task spanning more than one service, or when unsure which service a file belongs to.
---

# Project atlas

> **CHANGE_ME:** fill this skill for the target repository after copying the pack.
> Agents treat it as the source of truth for "where does X live?".

## Services

| Path | Role | How to run | Port | Log |
| --- | --- | --- | --- | --- |
| `CHANGE_ME/` (e.g. `api/`) | CHANGE_ME | CHANGE_ME | CHANGE_ME | CHANGE_ME |
| `CHANGE_ME/` (e.g. `web/`) | CHANGE_ME | CHANGE_ME | CHANGE_ME | CHANGE_ME |

## Runtime / tooling

- Language / package manager: CHANGE_ME
- Shared venv or node version: CHANGE_ME
- Requirements / lockfiles: CHANGE_ME

## Databases

| Database | Notes |
| --- | --- |
| CHANGE_ME | Live vs local / test URLs — never invent secrets |

## Migrations

Paths (must stay append-only once shipped): CHANGE_ME  
Guard script globs: `scripts/agent/check-migrations-append-only.sh`

## Tests (per service)

| Area | Command |
| --- | --- |
| CHANGE_ME | CHANGE_ME |

## Env / secrets layout

- Per-service `.env` locations: CHANGE_ME
- Never commit or print secret values

## Ownership boundaries

- Which folder owns which domain: CHANGE_ME
- Do not edit unrelated services in the same ticket unless the plan says so
