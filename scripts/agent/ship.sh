#!/usr/bin/env bash
# Mechanical part of /ship: verify-gated ticket branch -> dev.
# One command from message to push, so a model run cannot stop halfway.
#
# Usage: scripts/agent/ship.sh <ticket> <message-file> [file...]
#   <ticket>        GitHub issue number this branch belongs to
#   <message-file>  file with the full commit message
#   [file...]       ticket files to stage; omit when everything is already
#                   committed (cadence commits) — then the script just
#                   gates and pushes.
#
# Ships ticket branch into integration (dev). Does not touch main.
set -euo pipefail

usage() {
  echo "usage: scripts/agent/ship.sh <ticket> <message-file> [file...]" >&2
  exit 1
}
[ $# -ge 2 ] || usage

ticket=$1
msg_file=$2
shift 2

case "$ticket" in
  ''|*[!0-9]*) echo "error: ticket must be an issue number, got '$ticket'" >&2; exit 1 ;;
esac

[ -s "$msg_file" ] || {
  echo "error: message file '$msg_file' is empty or missing" >&2
  exit 1
}

cd "$(git rev-parse --show-toplevel)"

branch=$(git rev-parse --abbrev-ref HEAD)
case "$branch" in
  main|dev)
    echo "error: on '$branch' — ship works from a ticket branch (feature/$ticket-...)" >&2
    exit 1
    ;;
  "feature/$ticket"|"feature/$ticket-"*) ;;
  *)
    echo "error: branch '$branch' does not belong to ticket #$ticket" >&2
    echo "  expected feature/$ticket-<slug> — one ticket per branch." >&2
    exit 1
    ;;
esac

mkdir -p .agent

# Ship mutex: two agents must not rebase/push at the same time.
lock=.agent/ship.lock
if ! mkdir "$lock" 2>/dev/null; then
  echo "error: another ship is in progress ($lock exists)" >&2
  echo "  wait for it to finish, or remove the directory if it is stale." >&2
  exit 1
fi
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

# Verify gate: the ticket's own record must be a pass for the current HEAD.
status_file=".agent/verify-status-$ticket.json"
head_sha=$(git rev-parse HEAD)
grep -q '"result": "pass"' "$status_file" 2>/dev/null || {
  echo "error: no passing verify record for #$ticket — run /verify $ticket first" >&2
  exit 1
}
grep -q "\"sha\": \"$head_sha\"" "$status_file" || {
  echo "error: verify record for #$ticket is for another commit — run /verify $ticket first" >&2
  exit 1
}

git pull --rebase --autostash origin dev
new_head=$(git rev-parse HEAD)
[ "$new_head" = "$head_sha" ] || {
  echo "error: dev moved ($head_sha -> $new_head) — verify record is stale." >&2
  echo "Re-run /verify $ticket, then run this script again." >&2
  exit 1
}

if [ $# -ge 1 ]; then
  git add -- "$@"
fi

if ! git diff --cached --quiet; then
  scripts/agent/check-secrets.sh --staged
  git commit -F "$msg_file"
elif [ $# -ge 1 ]; then
  echo "error: nothing staged from the given files — nothing to commit" >&2
  exit 1
fi

if [ "$(git rev-list origin/dev..HEAD --count)" -eq 0 ]; then
  echo "error: nothing to ship — no commits ahead of origin/dev" >&2
  exit 1
fi

# Foreign-commit guard: every commit being shipped must name this ticket, so a
# parallel agent's work can never ride along in the same push.
foreign=""
for sha in $(git rev-list origin/dev..HEAD); do
  if ! git log -1 --format='%B' "$sha" | grep -q "#$ticket\b"; then
    foreign="$foreign
  $(git log -1 --format='%h %s' "$sha")"
  fi
done
if [ -n "$foreign" ]; then
  echo "error: commits ahead of dev do not reference #$ticket:$foreign" >&2
  echo "  every ticket commit body needs 'Refs #$ticket' or 'Closes #$ticket'." >&2
  exit 1
fi

# Secrets guard over everything not yet on dev.
scripts/agent/check-secrets.sh origin/dev..HEAD

git push origin "HEAD:refs/heads/$branch"
# Fast-forward only: a rejection here means dev moved and the ticket needs a
# fresh /verify before it can ship.
git push origin "HEAD:refs/heads/dev"
echo "shipped: $(git rev-parse --short HEAD) ($branch) -> dev"
