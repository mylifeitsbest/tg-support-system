#!/usr/bin/env bash
# Scan a git diff for committed secrets and env/db/key files.
#
# Usage:
#   scripts/agent/check-secrets.sh <range>     # e.g. origin/main..HEAD
#   scripts/agent/check-secrets.sh --staged    # scan staged changes
#
# Exits non-zero if anything suspicious is found. Used by ship.sh and CI.
# Excluded: .env.example files, docs/ (may contain sample tokens),
# package-lock files, and this script itself.
set -euo pipefail

if [ "${1:-}" = "--staged" ]; then
  DIFF_ARGS=(--cached)
  NAME_ARGS=(--cached --name-only --diff-filter=A)
else
  RANGE="${1:?usage: check-secrets.sh <range>|--staged}"
  DIFF_ARGS=("$RANGE")
  NAME_ARGS=("$RANGE" --name-only --diff-filter=A)
fi

EXCLUDES=(
  ":(exclude)**/.env.example"
  ":(exclude)scripts/agent/check-secrets.sh"
  ":(exclude)docs/**"
  ":(exclude)**/package-lock.json"
)

fail() {
  echo "x Secret guardrail: $1" >&2
  echo "  If this is a false positive, sanitize the value; real secrets live in .env files only." >&2
  exit 1
}

# 1) Block newly added env/db/key files (but allow .env.example).
added_files="$(git diff "${NAME_ARGS[@]}" -- . "${EXCLUDES[@]}" || true)"
bad_added="$(printf '%s\n' "$added_files" \
  | grep -E '((^|/)\.env(\.[^/]*)?$)|\.(db|sqlite3?|pem|key)$' || true)"
if [ -n "$bad_added" ]; then
  fail "attempt to commit an env/db/key file:
$bad_added"
fi

# 2) Scan added lines for secret-shaped strings.
added_lines="$(git diff "${DIFF_ARGS[@]}" -- . "${EXCLUDES[@]}" \
  | grep -E '^\+' | grep -Ev '^\+\+\+' || true)"

patterns=(
  '[0-9]{8,10}:AA[0-9A-Za-z_-]{33}'            # Telegram bot tokens
  'eyJ[A-Za-z0-9_=-]{10,}\.[A-Za-z0-9_=-]{10,}\.[A-Za-z0-9_=-]{10,}'  # JWT
  'AKIA[0-9A-Z]{16}'                           # AWS access key id
  'sk-[A-Za-z0-9]{20,}'                        # OpenAI-style keys
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'         # private key blocks
  'xprv[0-9A-Za-z]{80,}'                       # BIP32 extended private keys
)

for p in "${patterns[@]}"; do
  hits="$(printf '%s\n' "$added_lines" | grep -E -e "$p" || true)"
  if [ -n "$hits" ]; then
    fail "possible secret matching /$p/:
$hits"
  fi
done

echo "ok: no secrets or env files detected in the scanned diff."
