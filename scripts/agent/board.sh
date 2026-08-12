#!/usr/bin/env bash
# Move a GitHub Issue card on the team board.
#
# Usage: scripts/agent/board.sh <issue> <status>
#   <issue>   GitHub issue number
#   <status>  backlog | ready | in-progress | in-review | done
#             (optional: important — if your board has that column)
#
# Adds the issue to the project when it is missing, then sets Status.
# Done cards are moved to the TOP of the Done column (project rule).
# Fill CHANGE_ME values after creating your GitHub Project.
#
# Windows: prefer Git Bash or powershell -File scripts/agent/board.ps1 …
set -euo pipefail

usage() {
  echo "usage: scripts/agent/board.sh <issue> <status>" >&2
  echo "  status: backlog | ready | in-progress | in-review | done" >&2
  exit 1
}
[ $# -eq 2 ] || usage

issue=$1
status_raw=$2

case "$issue" in
  ''|*[!0-9]*) echo "error: issue must be a number, got '$issue'" >&2; exit 1 ;;
esac

# --- CHANGE_ME: set after `gh project list` / `gh project field-list` ---
OWNER=CHANGE_ME
PROJECT_NUMBER=1
PROJECT_ID=CHANGE_ME
STATUS_FIELD_ID=CHANGE_ME
REPO=CHANGE_ME/CHANGE_ME

if [[ "$OWNER" == "CHANGE_ME" || "$PROJECT_ID" == "CHANGE_ME" || "$STATUS_FIELD_ID" == "CHANGE_ME" || "$REPO" == "CHANGE_ME/CHANGE_ME" ]]; then
  echo "error: scripts/agent/board.sh still has CHANGE_ME placeholders — fill OWNER/PROJECT_*/REPO" >&2
  exit 1
fi

status=$(printf '%s' "$status_raw" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
case "$status" in
  # CHANGE_ME: replace option_id values with your project's Status options
  backlog)              option_id=CHANGE_ME_BACKLOG; label=Backlog ;;
  # important)         option_id=CHANGE_ME_IMPORTANT; label="Important tasks" ;;
  ready)                option_id=CHANGE_ME_READY; label=Ready ;;
  in-progress|progress) option_id=CHANGE_ME_IN_PROGRESS; label="In progress" ;;
  in-review|review)     option_id=CHANGE_ME_IN_REVIEW; label="In review" ;;
  done)                 option_id=CHANGE_ME_DONE; label=Done ;;
  *)
    echo "error: unknown status '$status_raw'" >&2
    echo "  want: backlog | ready | in-progress | in-review | done" >&2
    exit 1
    ;;
esac

if [[ "$option_id" == CHANGE_ME_* ]]; then
  echo "error: status option_id for '$status' is still a CHANGE_ME placeholder" >&2
  exit 1
fi

lookup_item() {
  gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json -L 500 \
    --jq "[.items[] | select(.content.number == $issue) | .id] | first // empty"
}

item_id=$(lookup_item)

if [ -z "$item_id" ]; then
  url="https://github.com/$REPO/issues/$issue"
  echo "board: adding #$issue to project $PROJECT_NUMBER"
  gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" >/dev/null
  item_id=$(lookup_item)
fi

[ -n "$item_id" ] || {
  echo "error: could not resolve project item for #$issue" >&2
  exit 1
}

gh project item-edit \
  --project-id "$PROJECT_ID" \
  --id "$item_id" \
  --field-id "$STATUS_FIELD_ID" \
  --single-select-option-id "$option_id" \
  >/dev/null

echo "board: #$issue -> $label"

# Project rule: Done → top of column (newest finished first).
if [ "$status" = "done" ]; then
  if gh api graphql -f query='
    mutation($projectId:ID!, $itemId:ID!) {
      updateProjectV2ItemPosition(input: { projectId: $projectId, itemId: $itemId }) {
        clientMutationId
      }
    }' -f projectId="$PROJECT_ID" -f itemId="$item_id" >/dev/null; then
    echo "board: Done -> moved to top"
  else
    echo "board: warning: failed to move #$issue to top of Done" >&2
  fi
fi
