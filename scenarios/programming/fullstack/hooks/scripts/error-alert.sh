#!/usr/bin/env bash
# =====================================================================
# error-alert.sh — 错误分级告警
# 
# 输入：stdin  JSON {level, message, agent_id, session_id}
# 分级：
#   INFO/WARN → 仅记录日志
#   ERROR     → 日志 + stderr
#   CRITICAL  → 日志 + stderr + Slack（如果 SLACK_WEBHOOK_URL 已设置）
#
# 超时：15 秒
# =====================================================================

set -uo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LOG_DIR="${PROJECT_ROOT}/logs"
mkdir -p "${LOG_DIR}"

LOG_FILE="${LOG_DIR}/errors.log"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# ── 解析 JSON（使用 python3 + json，跨平台稳定） ────────────────────
PAYLOAD="$(cat || true)"
if [[ -z "${PAYLOAD}" ]]; then
    PAYLOAD='{"level":"ERROR","message":"Agent error (no details)","agent_id":"'"${AGENT_ID:-unknown}"'","session_id":"'"${SESSION_ID:-unknown}"'"}'
fi

# 用 python3 解析 JSON（Windows / macOS / Linux 都可用）
parse_json() {
    python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for key in ['level', 'message', 'agent_id', 'session_id']:
    print(data.get(key, ''))
" <<< "$1"
}

LEVEL=$(parse_json "$PAYLOAD" | sed -n '1p')
MESSAGE=$(parse_json "$PAYLOAD" | sed -n '2p')
AGENT_ID=$(parse_json "$PAYLOAD" | sed -n '3p')
SESSION_ID=$(parse_json "$PAYLOAD" | sed -n '4p')

LEVEL="${LEVEL:-ERROR}"
MESSAGE="${MESSAGE:-An error occurred}"
AGENT_ID="${AGENT_ID:-unknown}"
SESSION_ID="${SESSION_ID:-unknown}"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u)"

echo "[${TS}] [${LEVEL}] agent=${AGENT_ID} session=${SESSION_ID} :: ${MESSAGE}" >> "${LOG_FILE}"

# ── 连续错误计数 ──
ERROR_COUNTER_FILE="/tmp/devkit-error-counter"
CONSECUTIVE_ERRORS="$(cat "${ERROR_COUNTER_FILE}" 2>/dev/null || echo 0)"
CONSECUTIVE_ERRORS=$((CONSECUTIVE_ERRORS + 1))
echo "${CONSECUTIVE_ERRORS}" > "${ERROR_COUNTER_FILE}"

# ── 分级路由 ──
case "${LEVEL^^}" in
    INFO|WARN)
        ;;  # 仅日志
    ERROR)
        echo "[ERROR] ${MESSAGE} (agent=${AGENT_ID})" >&2
        ;;
    CRITICAL)
        echo "[CRITICAL] ${MESSAGE} (agent=${AGENT_ID}, consecutive=${CONSECUTIVE_ERRORS})" >&2
        if [[ -n "${SLACK_WEBHOOK_URL}" ]]; then
            SLACK_TEXT="*CRITICAL Agent Error*\nAgent: ${AGENT_ID}\nSession: ${SESSION_ID}\nErrors: ${CONSECUTIVE_ERRORS}\nMsg: ${MESSAGE}"
            curl -s -m 5 -X POST \
                -H "Content-Type: application/json" \
                -d "{\"text\":\"${SLACK_TEXT}\"}" \
                "${SLACK_WEBHOOK_URL}" >/dev/null 2>&1 \
                || echo "[WARN] Slack 通知失败" >&2
        fi
        ;;
esac

exit 0
