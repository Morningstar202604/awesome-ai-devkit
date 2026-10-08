#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# hooks/scripts/load-project-context.sh
#
# Called by the framework's on_agent_start hook.
# Loads project context into env variables + prints JSON summary.
# Timeout budget: 5 seconds. Non-fatal.
# ──────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CONTEXT_DIR="${PROJECT_ROOT}/context"
SESSION_ID="${SESSION_ID:-$(date +%s%N)}"

# ── Resolve context file ──────────────────────────────────────────────
CONTEXT_FILE=""
if [[ -f "${CONTEXT_DIR}/project.yaml" ]]; then
    CONTEXT_FILE="${CONTEXT_DIR}/project.yaml"
elif [[ -f "${CONTEXT_DIR}/project.template.yaml" ]]; then
    CONTEXT_FILE="${CONTEXT_DIR}/project.template.yaml"
    echo "[WARN] project.yaml not found — loading template as fallback" >&2
fi

# ── Extract key fields (best-effort, awk to avoid yq dependency) ───────
PROJECT_NAME=""
FRAMEWORK_VERSION=""
STACK_FRONTEND=""
STACK_BACKEND=""
STACK_DATABASE=""
ADR_COUNT=0

if [[ -n "${CONTEXT_FILE}" ]]; then
    PROJECT_NAME="$(awk '/^name:/{sub(/name: */,""); print; exit}' "${CONTEXT_FILE}")"
    FRAMEWORK_VERSION="$(awk '/^framework_version:/{sub(/framework_version: */,""); print; exit}' "${CONTEXT_FILE}")"
    STACK_FRONTEND="$(awk '/^\s\sfrontend:/{sub(/.*frontend: */,""); print; exit}' "${CONTEXT_FILE}")"
    STACK_BACKEND="$(awk '/^\s\sbackend:/{sub(/.*backend: */,""); print; exit}' "${CONTEXT_FILE}")"
    STACK_DATABASE="$(awk '/^\s\sdatabase:/{sub(/.*database: */,""); print; exit}' "${CONTEXT_FILE}")"
    ADR_COUNT="$(grep -cE '^\s*-\s+id:\s+adr-' "${CONTEXT_DIR}/architecture.md" 2>/dev/null || echo 0)"
fi

# ── Git context ───────────────────────────────────────────────────
CURRENT_BRANCH="$(git --git-dir="${PROJECT_ROOT}/.git" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
LAST_COMMIT="$(git --git-dir="${PROJECT_ROOT}/.git" log -1 --format="%h %s" 2>/dev/null || echo "no-git")"

# ── Output JSON summary ────────────────────────────────────────────
cat <<EOF
{
  "session_id": "${SESSION_ID}",
  "project_root": "${PROJECT_ROOT}",
  "project_name": "${PROJECT_NAME:-unnamed}",
  "framework_version": "${FRAMEWORK_VERSION:-unknown}",
  "stack": {
    "frontend": "${STACK_FRONTEND:-(not set)}",
    "backend": "${STACK_BACKEND:-(not set)}",
    "database": "${STACK_DATABASE:-(not set)}"
  },
  "git": {
    "branch": "${CURRENT_BRANCH}",
    "last_commit": "${LAST_COMMIT}"
  },
  "adr_count": ${ADR_COUNT},
  "context_file": "${CONTEXT_FILE:-none}",
  "loaded_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "[INFO] context loaded for project '${PROJECT_NAME:-unnamed}' on branch '${CURRENT_BRANCH}'" >&2
exit 0
