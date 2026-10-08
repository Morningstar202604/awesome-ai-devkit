#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# hooks/scripts/post-task.sh
#
# 任务完成后脚手架后置钩子。
# 运行 post_task validations，生成 summary，清理 session。
#
# 协议: scaffolds/scaffold-protocol.md (v1.0)
#
# 调用方式:
#   hooks/scripts/post-task.sh                   # 自动从 env 找到 session
#   hooks/scripts/post-task.sh <session-dir>     # 指定 session 目录
#
# 退出码:
#   0 — 任务完成且全部 validation 通过
#   1 — 存在 FAIL，需回退或修复
# ──────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cecho() { echo -e "\033[1;36m[post-task]\033[0m $*"; }
warn() { echo -e "\033[1;33m[post-task ⚠]\033[0m $*"; }
err()  { echo -e "\33[1;31m[post-task ✗]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[post-task ✓]\033[0m $*"; }

# ── 定位 session ──────────────────────────────────────────────────
SESSION_DIR="${1:-${DEVKIT_SESSION_DIR:-}}"
SCAFFOLD_FILE="${DEVKIT_SCAFFOLD:-scaffold.yaml}"

if [[ -z "${SESSION_DIR}" || ! -d "${SESSION_DIR}" ]]; then
    err "未找到 session 目录"
    echo "使用方式:"
    echo "  DEVKIT_SESSION_DIR=/path/to/session hooks/scripts/post-task.sh"
    echo "  或: hooks/scripts/post-task.sh /path/to/session"
    exit 1
fi

if [[ ! -f "${SESSION_DIR}/meta.json" ]]; then
    warn "${SESSION_DIR} 中没有 meta.json — 可能是旧格式 session"
fi

cd "${REPO_ROOT}"

cecho "Scaffold Protocol v1.0 — Post-task Completion Check"
cecho "Session: ${SESSION_DIR}"

# ── Step 1: 检查所有 Step 日志 ─────────────────────────────────────
TOTAL_STEPS=0
COMPLETED_STEPS=0
FAILED_STEPS=0

for step_log in "${SESSION_DIR}"/step-*.json; do
    [[ ! -f "${step_log}" ]] && continue
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    STATUS="$(python3 -c "import json; d=json.load(open('${step_log}')); print(d.get('status','?'))" 2>/dev/null || echo "?")"
    if [[ "${STATUS}" == "completed" ]]; then
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    else
        FAILED_STEPS=$((FAILED_STEPS + 1))
        warn "Step $(basename ${step_log}): ${STATUS}"
    fi
done

echo ""
cecho "Step 统计: ${COMPLETED_STEPS}/${TOTAL_STEPS} 完成, ${FAILED_STEPS} 失败"

if [[ "${FAILED_STEPS}" != "0" && "${FAILED_STEPS}" != "" ]]; then
    err "${FAILED_STEPS} 个 Step 未完成"
    # 不立即退出，先运行 validations 收集更多信息
fi

# ── Step 2: 运行 scaffold 中的 post_task validations ────────────────
if [[ -f "${SCAFFOLD_FILE}" ]]; then
    cecho "运行 scaffold post_task validations..."

    # 使用独立 validation 脚本运行 scaffold validations
    if python3 "${REPO_ROOT}/hooks/scripts/scaffold-validate.py" "${SCAFFOLD_FILE}"; then
        ok "所有 post_task validations 通过"
    else
        err "post_task validation 存在 FAIL"
    fi
fi

# ── Step 3: 生成 session summary ─────────────────────────────────
TASK_NAME="$(SESSION_DIR="${SESSION_DIR}" python3 << 'PYEOF'
import json, os
session_dir = os.environ['SESSION_DIR']
meta_file = os.path.join(session_dir, 'meta.json')
if os.path.exists(meta_file):
    print(json.load(open(meta_file)).get('task', 'unknown'))
PYEOF
)" 2>/dev/null || echo "unknown"

SUMMARY_FILE="${SESSION_DIR}/summary.json"

SESSION_DIR="${SESSION_DIR}" SUMMARY_FILE="${SUMMARY_FILE}" TASK_NAME="${TASK_NAME}" python3 << 'PYEOF'
import json, os, glob, datetime

session_dir = os.environ['SESSION_DIR']
summary_file = os.environ['SUMMARY_FILE']
task_name = os.environ['TASK_NAME']

steps = []
for f in sorted(glob.glob(os.path.join(session_dir, 'step-*.json'))):
    with open(f) as fp:
        step = json.load(fp)
        steps.append({
            'id': step.get('step_id', os.path.basename(f)),
            'status': step.get('status', 'unknown'),
            'outputs': step.get('outputs', []),
            'committed_as': step.get('committed_as', None),
        })

summary = {
    'task': task_name,
    'session_id': os.path.basename(session_dir),
    'status': 'completed',
    'completed_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'total_steps': len(steps),
    'completed_steps': len([s for s in steps if s['status'] == 'completed']),
    'failed_steps': len([s for s in steps if s['status'] != 'completed']),
    'steps': steps,
}

with open(summary_file, 'w') as fp:
    json.dump(summary, fp, indent=2, ensure_ascii=False)
print(f'summary → {summary_file}')
PYEOF

ok "Summary 已生成"

# ── Step 4: 输出收尾信息 ────────────────────────────────────────────
echo ""
cecho "══════════════════════════════════════════════════"
cecho "🏁 Scaffold 任务收尾"
cecho "   Task: ${TASK_NAME}"
cecho "   Session: ${SESSION_DIR}"
   cecho "   Summary: ${SESSION_DIR}/summary.json"
cecho ""
cecho "   尝试执行完整收尾脚本 save-session-log.sh..."
echo ""

# 级联调用 save-session-log.sh
if [[ -f "${SCRIPT_DIR}/save-session-log.sh" ]]; then
    if bash "${SCRIPT_DIR}/save-session-log.sh" "${SESSION_DIR}" 2>/dev/null; then
        ok "save-session-log.sh 已执行"
    else
        warn "save-session-log.sh 执行失败（非阻断）"
    fi
fi

cecho "══════════════════════════════════════════════════"

# 最终退出码: 有任何 FAIL 则退出 1
if [[ "${FAILED_STEPS}" != "0" && "${FAILED_STEPS}" != "" ]]; then
    exit 1
fi

exit 0
