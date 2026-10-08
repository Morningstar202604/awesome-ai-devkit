#!/usr/bin/env python3
"""devkit-doctor 集成测试 — 自包含，无 patching，独立运行返回 0/1"""

import sys
import os
import tempfile
import subprocess
import importlib.util
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = PROJECT_ROOT / "devkit-doctor.py"
spec = importlib.util.spec_from_file_location("devkit_doctor", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

SkillIntegrityCheck = mod.SkillIntegrityCheck
ScaffoldValidityCheck = mod.ScaffoldValidityCheck
MCPConfigCheck = mod.MCPConfigCheck
HooksCheck = mod.HooksCheck
EnvDependencyCheck = mod.EnvDependencyCheck
CheckResult = mod.CheckResult
detect_project_root = mod.detect_project_root


def run_all():
    root = detect_project_root(PROJECT_ROOT)
    for cls in [SkillIntegrityCheck, ScaffoldValidityCheck,
                MCPConfigCheck, HooksCheck, EnvDependencyCheck]:
        report = cls(root).run()
        assert report.result == CheckResult.PASS, (
            f"{cls.name}: {report.result.value}: "
            f"{[f.message for f in report.findings]}")

def test_detect_project_root():
    detected = detect_project_root(PROJECT_ROOT)
    assert (detected / "scaffolds").exists()

def test_scaffold_rejects_bad_yaml():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "scaffolds").mkdir()
        (tmp / "scaffolds" / "bad.yaml").write_text("not: valid: yaml: [")
        report = ScaffoldValidityCheck(tmp).run()
        assert report.result == CheckResult.FAIL

def test_hooks_missing():
    with tempfile.TemporaryDirectory() as tmp:
        report = HooksCheck(Path(tmp)).run()
        assert report.result == CheckResult.FAIL

def test_skill_missing_file():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        skills = tmp / "scenarios" / "programming" / "fullstack" / "skills"
        skills.mkdir(parents=True)
        (skills / "fake-skill").mkdir()
        report = SkillIntegrityCheck(tmp).run()
        assert report.result == CheckResult.FAIL

def test_mcp_missing_warns():
    with tempfile.TemporaryDirectory() as tmp:
        report = MCPConfigCheck(Path(tmp)).run()
        assert report.result == CheckResult.WARN

def test_env_git_unavailable():
    original = subprocess.run
    def fake_run(*a, **k):
        class R: stdout=""; stderr=""; returncode=1
        return R()
    subprocess.run = fake_run
    try:
        with tempfile.TemporaryDirectory() as tmp:
            report = EnvDependencyCheck(Path(tmp)).run()
            git_f = next(f for f in report.findings if "git" in f.message.lower())
            assert git_f.result in (CheckResult.FAIL, CheckResult.WARN)
    finally:
        subprocess.run = original


if __name__ == "__main__":
    tests = [
        ("真实项目全部检查通过", run_all),
        ("根目录自动检测",     test_detect_project_root),
        ("损坏 scaffold 处理", test_scaffold_rejects_bad_yaml),
        ("无 hooks 时 FAIL",   test_hooks_missing),
        ("缺失 SKILL.md FAIL", test_skill_missing_file),
        ("无 mcp 时 WARN",     test_mcp_missing_warns),
        ("git 不可用 FAIL",    test_env_git_unavailable),
    ]

    failed = 0
    for name, fn in tests:
        try:
            fn()
            print(f"  pass  {name}")
        except Exception as e:
            print(f"  FAIL  {name}: {e}")
            failed += 1

    print(f"\n{'ALL TESTS PASS' if not failed else f'{failed} TESTS FAILED'}")
    sys.exit(0 if not failed else 1)
