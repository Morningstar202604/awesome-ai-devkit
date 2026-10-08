#!/usr/bin/env python3
"""
scaffold-validate.py — 运行 scaffold.yaml 中 post_task 定义的 validations

返回值:
    0 — 全部 PASS
    1 — 存在 FAIL

用法:
    python3 hooks/scripts/scaffold-validate.py [scaffold.yaml]
"""
import os
import subprocess
import sys
from pathlib import Path

import yaml


def main() -> int:
    scaffold_file = sys.argv[1] if len(sys.argv) > 1 else os.environ.get(
        "DEVKIT_SCAFFOLD", "scaffold.yaml"
    )
    if not os.path.exists(scaffold_file):
        print("[scaffold-validate] scaffold 文件不存在，跳过")
        return 0

    data = yaml.safe_load(Path(scaffold_file).read_text())
    post_task = data.get("post_task", {})
    validations = post_task.get("validations", [])

    if not validations:
        print("[scaffold-validate] post_task.validations 为空，跳过")
        return 0

    passed = 0
    failed = 0
    for v in validations:
        name = v.get("name", "unnamed")
        cmd = v.get("run", "")
        pass_when = v.get("pass_when", "exit 0")
        if not cmd:
            continue

        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=60
            )
            rc = result.returncode
            if "exit 0" in pass_when and rc == 0:
                status = "PASS"
            elif "exit 0" in pass_when:
                status = "FAIL"
            else:
                try:
                    threshold = int("".join(c for c in pass_when if c.isdigit()))
                    actual = int(result.stdout.strip()) if result.stdout.strip().isdigit() else 0
                    status = "PASS" if actual >= threshold else "FAIL"
                except Exception:
                    status = "PASS" if rc == 0 else "FAIL"

            print(f"  [{status}] {name}: {cmd}")
            if status == "FAIL":
                failed += 1
                if result.stderr:
                    print(f"         stderr: {result.stderr.strip()[:200]}")
            else:
                passed += 1
        except Exception as e:
            print(f"  [ERROR] {name}: {e}")
            failed += 1

    print(f"\nTOTAL: {passed} PASS / {failed} FAIL")
    return 1 if failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
