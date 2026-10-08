#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# hooks/scripts/save-session-log.sh
#
# Called by the framework's on_agent_end hook. Persists the session
# log so a future session can resume or so auditors can inspect it.
#
# Timeout budget: 10 seconds.
# ──────────────────────────────────────────────────────────────────────

set -uo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_DIR="${PROJECT_ROOT}/logs/sessions"
SESSION_ID="${SESSION_ID:-unknown}"

# ── Locate session data ──────────────────────────────────────────────
# Convention: /tmp/devkit-session-${SESSION_ID}.jsonl
INCOMING_SESSION_FILE="${1:-/tmp/devkit-session-${SESSION_ID}.jsonl}"
OUT_FILE="${LOG_DIR}/${SESSION_ID}.jsonl"
MANIFEST_LOG="${LOG_DIR}/_manifest.jsonl"

mkdir -p "${LOG_DIR}"

# ── Summary metrics ──────────────────────────────────────────────────
TOOL_COUNT=0
FILE_CHANGE_COUNT=0
TOKEN_IN=0
TOKEN_OUT=0
DURATION_SEC=0

if [[ -f "${INCOMING_SESSION_FILE}" ]]; then
    TOOL_COUNT="$(wc -l < "${INCOMING_SESSION_FILE}")"
    [[ "${TOOL_COUNT}" -lt 1 ]] && TOOL_COUNT=0

    TOKEN_IN="$(grep -m1 '"prompt_tokens"' "${INCOMING_SESSION_FILE}" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || echo 0)"
    TOKEN_OUT="$(grep -oE '"completion_tokens":[0-9]+' "${INCOMING_SESSION_FILE}" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || echo 0)"
    FILE_CHANGE_COUNT="$(grep -c '"file_change"' "${INCOMING_SESSION_FILE}" 2>/dev/null || echo 0)"
    DURATION_SEC="$(grep -oE '"duration_ms":[0-9]+' "${INCOMING_SESSION_FILE}" 2>/dev/null | grep -oE '[0-9]+' | tail -1 | awk '{printf "%.1f", $1/1000}')"
fi

# ── Write final session log ──────────────────────────────────────────
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ -f "${INCOMING_SESSION_FILE}" ]]; then
    grep -v '^{"__meta__"' "${INCOMING_SESSION_FILE}" > "${OUT_FILE}" || true
else
    : > "${OUT_FILE}"
fi

cat >> "${OUT_FILE}" << SUMMARY
{"__summary__": true, "session_id": "${SESSION_ID}", "status": "completed", "tool_calls": ${TOOL_COUNT}, "file_changes": ${FILE_CHANGE_COUNT}, "prompt_tokens": ${TOKEN_IN:-0}, "completion_tokens": ${TOKEN_OUT:-0}, "duration_sec": ${DURATION_SEC:-0}, "saved_at": "${TS}"}
SUMMARY

echo "{\"session_id\": \"${SESSION_ID}\", \"saved_at\": \"${TS}\", \"file\": \"${OUT_FILE}\", \"tool_calls\": ${TOOL_COUNT}}" \
  >> "${MANIFEST_LOG}"

# ── Rotation: keep last 50 sessions ──────────────────────────────────
mapfile -t ALL_SESSIONS < <(ls -t "${LOG_DIR}"/*.jsonl 2>/dev/null)
if [[ ${#ALL_SESSIONS[@]} -gt 50 ]]; then
    for ((i=50; i<${#ALL_SESSIONS[@]}; i++)); do
        rm -f "${ALL_SESSIONS[$i]}"
    done
fi

echo "[INFO] session ${SESSION_ID} saved — ${TOOL_COUNT} tool calls, ${FILE_CHANGE_COUNT} file changes" >&2
exit 0
