#!/usr/bin/env bash
# Enforce that migration files are append-only: once a file under a versions
# dir exists on the base branch, it must never be renamed, deleted, or have
# its content changed. Only brand-new migration files may be added.
#
# Usage:
#   scripts/agent/check-migrations-append-only.sh <range>  # e.g. origin/main..HEAD
set -euo pipefail

RANGE="${1:?usage: check-migrations-append-only.sh <range>}"

# CHANGE_ME: globs for your migration trees (alembic, prisma, typeorm, …)
GLOBS=(
  '**/alembic/versions/*.py'
  # '**/migrations/*.ts'
)

# --diff-filter excludes Added (A): a file absent at BASE and present at
# HEAD is a net add, even if edited across intermediate commits — editing a
# NEW migration before it lands is fine. Forbidden is touching one that
# already existed:
#   M = modified   D = deleted   R = renamed   C = copied   T = type changed
offenders="$(git diff --name-status --find-renames \
  --diff-filter=MDRCT "$RANGE" -- "${GLOBS[@]}" || true)"

if [ -n "$offenders" ]; then
  echo "x Migration guardrail: existing migrations are append-only." >&2
  echo "  These already-committed migrations were modified/renamed/deleted:" >&2
  printf '%s\n' "$offenders" | sed 's/^/    /' >&2
  echo >&2
  echo "  Changing an applied migration desyncs the repo from deployed" >&2
  echo "  history. Add a NEW migration on top instead." >&2
  exit 1
fi

echo "ok: migrations are append-only in the scanned range."
