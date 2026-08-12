#!/usr/bin/env bash
# Shared helpers for agent workflow scripts.
set -euo pipefail

_agent_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$_agent_lib_dir/../.." && pwd)"
AGENT_DIR="$ROOT/.agent"
mkdir -p "$AGENT_DIR"

agent_config_file() {
  if [ -f "$ROOT/agent-config.json" ]; then
    echo "$ROOT/agent-config.json"
  elif [ -f "$AGENT_DIR/agent-config.json" ]; then
    echo "$AGENT_DIR/agent-config.json"
  elif [ -f "$ROOT/agent-config.example.json" ]; then
    echo "$ROOT/agent-config.example.json"
  else
    echo "error: no agent-config.json — copy agent-config.example.json" >&2
    exit 1
  fi
}

CONFIG="$(agent_config_file)"

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "error: jq is required" >&2
    exit 1
  }
}

require_jq

integration_branch() {
  jq -r '.integration_branch // "dev"' "$CONFIG"
}

production_branch() {
  jq -r '.production_branch // "main"' "$CONFIG"
}

current_github_login() {
  gh api user -q .login 2>/dev/null || true
}

github_repo_slug() {
  gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true
}
