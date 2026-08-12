#!/usr/bin/env bash
# Set issue Priority on GitHub issue **Fields → Priority** (org issue field).
# Optionally mirrors onto a Project Priority field when the issue is on the board.
# Never use Labels `priority:*`.
#
# Usage: scripts/agent/priority.sh <issue> <priority>
#   priority: urgent | high | medium | low
#
# Windows: powershell -File scripts/agent/priority.ps1 N urgent
#
# Requires GraphQL feature header `issue_fields`. Discover IDs:
#   gh api graphql -H "GraphQL-Features: issue_fields" -f query='
#     query { organization(login:"OWNER") { issueFields(first:20) {
#       nodes { ... on IssueFieldSingleSelect { id name options { id name } } } } } }'
set -euo pipefail

usage() {
  echo "usage: scripts/agent/priority.sh <issue> <priority>" >&2
  echo "  priority: urgent | high | medium | low" >&2
  exit 1
}
[ $# -eq 2 ] || usage

issue=$1
raw=$2
case "$issue" in
  ''|*[!0-9]*) echo "error: issue must be a number, got '$issue'" >&2; exit 1 ;;
esac

key=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
case "$key" in
  p0|crit|critical|urgent) key=urgent; human=Urgent ;;
  p1|high) key=high; human=High ;;
  p2|med|medium) key=medium; human=Medium ;;
  p3|low) key=low; human=Low ;;
  *)
    echo "error: unknown priority '$raw'" >&2
    usage
    ;;
esac

# --- CHANGE_ME: org Issue Field Priority (sidebar Fields → Priority) ---
REPO=CHANGE_ME/CHANGE_ME
ISSUE_PRIORITY_FIELD_ID=CHANGE_ME          # e.g. IFSS_…
ISSUE_PRIORITY_URGENT=CHANGE_ME            # e.g. IFSSO_…
ISSUE_PRIORITY_HIGH=CHANGE_ME
ISSUE_PRIORITY_MEDIUM=CHANGE_ME
ISSUE_PRIORITY_LOW=CHANGE_ME

# Optional Project mirror (same option names). Leave CHANGE_ME to skip.
OWNER=CHANGE_ME
PROJECT_NUMBER=1
PROJECT_ID=CHANGE_ME
PROJECT_PRIORITY_FIELD_ID=CHANGE_ME
PROJECT_PRIORITY_URGENT=CHANGE_ME
PROJECT_PRIORITY_HIGH=CHANGE_ME
PROJECT_PRIORITY_MEDIUM=CHANGE_ME
PROJECT_PRIORITY_LOW=CHANGE_ME

if [[ "$REPO" == "CHANGE_ME/CHANGE_ME" || "$ISSUE_PRIORITY_FIELD_ID" == "CHANGE_ME" ]]; then
  echo "error: scripts/agent/priority.sh still has CHANGE_ME placeholders — fill REPO + ISSUE_PRIORITY_*" >&2
  exit 1
fi

case "$key" in
  urgent) option_id=$ISSUE_PRIORITY_URGENT ;;
  high) option_id=$ISSUE_PRIORITY_HIGH ;;
  medium) option_id=$ISSUE_PRIORITY_MEDIUM ;;
  low) option_id=$ISSUE_PRIORITY_LOW ;;
esac
if [[ "$option_id" == CHANGE_ME* ]]; then
  echo "error: ISSUE_PRIORITY_$key is still CHANGE_ME" >&2
  exit 1
fi

# Strip legacy priority:* labels
existing="$(gh issue view "$issue" --repo "$REPO" --json labels --jq '.labels[].name' 2>/dev/null || true)"
while IFS= read -r name; do
  [ -n "$name" ] || continue
  case "$name" in
    priority:*)
      gh issue edit "$issue" --repo "$REPO" --remove-label "$name" >/dev/null || true
      echo "priority: removed legacy label $name"
      ;;
  esac
done <<<"$existing"

issue_node_id="$(gh issue view "$issue" --repo "$REPO" --json id --jq .id)"
[ -n "$issue_node_id" ] || {
  echo "error: could not resolve issue node id for #$issue" >&2
  exit 1
}

tmp="$(mktemp)"
cat >"$tmp" <<EOF
{"query":"mutation(\$issueId:ID!, \$fieldId:ID!, \$optionId:ID!) { setIssueFieldValue(input: { issueId: \$issueId, issueFields: [{ fieldId: \$fieldId, singleSelectOptionId: \$optionId }] }) { issue { id } } }","variables":{"issueId":"$issue_node_id","fieldId":"$ISSUE_PRIORITY_FIELD_ID","optionId":"$option_id"}}
EOF

if ! out="$(gh api graphql -H "GraphQL-Features: issue_fields" --input "$tmp" 2>&1)"; then
  rm -f "$tmp"
  echo "error: failed to set issue Fields Priority for #$issue: $out" >&2
  exit 1
fi
rm -f "$tmp"
echo "$out" | grep -q '"errors"' && {
  echo "error: failed to set issue Fields Priority for #$issue: $out" >&2
  exit 1
}
echo "priority: #$issue Fields → Priority -> $human"

# Optional Project mirror
if [[ "$OWNER" == "CHANGE_ME" || "$PROJECT_ID" == "CHANGE_ME" || "$PROJECT_PRIORITY_FIELD_ID" == "CHANGE_ME" ]]; then
  exit 0
fi
case "$key" in
  urgent) p_opt=$PROJECT_PRIORITY_URGENT ;;
  high) p_opt=$PROJECT_PRIORITY_HIGH ;;
  medium) p_opt=$PROJECT_PRIORITY_MEDIUM ;;
  low) p_opt=$PROJECT_PRIORITY_LOW ;;
esac
[[ "$p_opt" == CHANGE_ME* ]] && exit 0

item_id="$(
  gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json --limit 200 2>/dev/null \
    | jq -r --argjson n "$issue" \
      '[.items[] | select(.content.number == $n) | .id] | first // empty'
)" || true
[ -n "$item_id" ] && [ "$item_id" != "null" ] || {
  echo "priority: Project mirror skipped (#$issue not on project yet)"
  exit 0
}

if out="$(gh project item-edit \
  --id "$item_id" \
  --project-id "$PROJECT_ID" \
  --field-id "$PROJECT_PRIORITY_FIELD_ID" \
  --single-select-option-id "$p_opt" 2>&1)"; then
  echo "priority: #$issue Project Priority mirrored -> $human"
else
  case "$out" in
    *'no changes to make'*) echo "priority: #$issue Project Priority mirrored -> $human" ;;
    *) echo "priority: warning: Project Priority mirror failed for #$issue" >&2 ;;
  esac
fi
