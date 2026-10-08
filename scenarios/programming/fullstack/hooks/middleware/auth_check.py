#!/usr/bin/env python3
"""
Authorization Check Middleware

Every tool call carries an `auth_scope` claim. This middleware verifies
the calling agent holds sufficient privilege for the requested scope.

Scopes form a hierarchy:  admin > write > read > none

Mapping lives in `context/project.yaml -> agents.*.allowed_scopes` for static
permissions, with an optional webhook for dynamic RBAC lookups.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Dict, List, Optional


# ── Authority levels (ordinal comparison) ──────────────────────────
LEVELS = {"none": 0, "read": 1, "write": 2, "admin": 3}

# ── Default tool-to-scope mapping ──────────────────────────────────
# Override by adding a `tool_scopes` block in config.yaml.
DEFAULT_TOOL_SCOPES: Dict[str, str] = {
    # Read-only tools
    "web_search": "read",
    "read_file": "read",
    "git_log": "read",
    "database_query": "read",
    # Write tools
    "write_file": "write",
    "shell_exec": "write",
    "database_write": "write",
    "git_push": "write",
    "api_call": "write",
    # Admin tools
    "deploy": "admin",
    "delete_resource": "admin",
    "modify_permissions": "admin",
    "database_admin": "admin",
}


@dataclass
class MiddlewareResult:
    passed: bool
    reason: Optional[str] = None
    metadata: dict = field(default_factory=dict)


class AuthCheck:
    """
    Verifies the agent's privilege level against the tool's required scope.

    Parameters
    ----------
    agent_scopes : dict[str, list[str]]
        `{agent_id: ["read", "write"]}` — what the agent is allowed to do.
    tool_overrides : dict[str, str] | None
        Optional map that overrides DEFAULT_TOOL_SCOPES for this instance.
    strict : bool
        If True, agents with no `allowed_scopes` entry are denied.
        If False, they fall back to "read".
    """

    def __init__(
        self,
        agent_scopes: Dict[str, List[str]] | None = None,
        tool_overrides: Dict[str, str] | None = None,
        strict: bool = False,
    ) -> None:
        self._agent_scopes: Dict[str, List[str]] = agent_scopes or {}
        self._tool_scopes = {**DEFAULT_TOOL_SCOPES, **(tool_overrides or {})}
        self._strict = strict

    # ── public API ────────────────────────────────────────────────
    def check(self, tool_call: dict) -> MiddlewareResult:
        agent_id: str = tool_call.get("agent_id", "anonymous")
        tool_name: str = tool_call.get("tool", "unknown")
        requested_scope = self._tool_scopes.get(tool_name, "write")

        # 1. Determine agent's effective level
        allowed = self._agent_scopes.get(agent_id)
        if not allowed:
            if self._strict:
                return MiddlewareResult(
                    passed=False,
                    reason=(
                        "Agent '%s' has no defined allowed_scopes. "
                        "Strict mode: deny by default." % agent_id
                    ),
                    metadata={"agent_id": agent_id, "tool": tool_name},
                )
            allowed = ["read"]

        agent_level = max(LEVELS.get(s, 0) for s in allowed)
        required_level = LEVELS.get(requested_scope, 0)

        # 2. Compare
        if agent_level >= required_level:
            return MiddlewareResult(
                passed=True,
                metadata={
                    "agent_id": agent_id,
                    "tool": tool_name,
                    "agent_level": agent_level,
                    "required_level": required_level,
                },
            )

        # ── Denied ────────────────────────────────────────────────
        return MiddlewareResult(
            passed=False,
            reason=(
                "Agent '%s' lacks scope for tool '%s'. "
                "Agent level: %d (%s). "
                "Required: %d (%s)."
                % (agent_id, tool_name, agent_level, allowed, required_level, requested_scope)
            ),
            metadata={
                "agent_id": agent_id,
                "tool": tool_name,
                "agent_level": agent_level,
                "required_level": required_level,
            },
        )

    def grant(self, agent_id: str, scopes: List[str]) -> None:
        """Dynamically grant scopes (called by admin hooks)."""
        self._agent_scopes[agent_id] = scopes

    def revoke(self, agent_id: str) -> bool:
        """Remove all scopes for an agent. Returns True if existed."""
        return self._agent_scopes.pop(agent_id, None) is not None


# ── Framework entry point ──────────────────────────────────────────
def load_default_auth() -> AuthCheck:
    """Load per-agent scopes from project context (best-effort)."""
    from pathlib import Path

    scopes: Dict[str, List[str]] = {}
    project_path = Path(os.environ.get("PROJECT_ROOT", ".")) / "context" / "project.yaml"

    if project_path.exists():
        current_agent = None
        in_allowed = False
        with project_path.open() as fh:
            for raw in fh:
                line = raw.rstrip()
                if not line or line.lstrip().startswith("#"):
                    continue
                stripped = line.strip()
                if stripped.startswith("- id:"):
                    current_agent = stripped.split(":", 1)[1].strip()
                    scopes[current_agent] = []
                elif "allowed_scopes:" in stripped:
                    in_allowed = True
                elif in_allowed and stripped.startswith("- "):
                    if current_agent:
                        scopes[current_agent].append(stripped[2:].strip())
                elif not line.startswith(" "):
                    in_allowed = False

    return AuthCheck(agent_scopes=scopes)


middleware = load_default_auth()


# ── CLI smoke test ────────────────────────────────────────────────
if __name__ == "__main__":
    demo = AuthCheck(
        agent_scopes={
            "frontend-dev": ["read", "write"],
            "data-analyst": ["read"],
            "devops": ["read", "write", "admin"],
        }
    )

    test_calls = [
        {"agent_id": "frontend-dev", "tool": "database_write"},
        {"agent_id": "data-analyst", "tool": "shell_exec"},
        {"agent_id": "devops", "tool": "deploy"},
        {"agent_id": "unknown-agent", "tool": "read_file"},
    ]
    for call in test_calls:
        r = demo.check(call)
        flag = "PASS" if r.passed else "DENY"
        print("  %s  [%-18s] -> %-20s %s" % (flag, call["agent_id"], call["tool"], r.reason or ""))
