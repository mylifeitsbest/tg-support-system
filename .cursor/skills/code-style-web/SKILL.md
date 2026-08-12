---
name: code-style-web
description: React/TypeScript conventions for the frontend package. Load before writing or editing frontend code. Fill CHANGE_ME paths after integrating the pack.
---

# code-style-web

Load before writing or editing code in the frontend package
(CHANGE_ME: e.g. `web/`, `frontend/`).

## Baseline

- TypeScript + React (versions per `package.json`). Prefer the lockfile
  package manager already in use — do not switch npm/pnpm/yarn mid-ticket.
- Dev / build scripts: CHANGE_ME (`npm run dev`, `npm run build`, …).

## Lint & format

- Follow the project's configured linter (`npm run lint` or equivalent).
- No drive-by reformat of unrelated files — match surrounding style.

## React

- Functional components; match existing `src/` layout.
- Typed props; avoid new `any` unless surrounding code forces it.

## Env & API

- Env via the framework's pattern (e.g. `import.meta.env`); never hardcode
  backend URLs or keys. New vars: names only in `.env.example`.
- Reuse the existing HTTP client / API helpers.
