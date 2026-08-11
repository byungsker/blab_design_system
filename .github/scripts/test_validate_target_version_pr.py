#!/usr/bin/env python3
"""Deterministic regression tests for the trusted target-version validator."""

from __future__ import annotations

import base64
import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "target_version_validator", ROOT / ".github/scripts/validate_target_version_pr.py"
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("unable to load target-version validator")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def encoded(value: Any) -> str:
    return base64.b64encode(json.dumps(value).encode("utf-8")).decode("ascii")


class ValidatorSecurityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.policy_path = ROOT / ".byungskerlab/branch-policy.json"
        self.registry_path = ROOT / ".byungskerlab/release-lines.json"
        self.policy = json.loads(self.policy_path.read_text(encoding="utf-8"))
        self.registry = json.loads(self.registry_path.read_text(encoding="utf-8"))
        self.original_env = os.environ.copy()

    def tearDown(self) -> None:
        os.environ.clear()
        os.environ.update(self.original_env)

    def configure(
        self,
        *,
        head: str,
        body: str,
        paths: list[str],
        policy: dict[str, Any] | None = None,
        trusted_policy_path: str | None = None,
    ) -> None:
        os.environ.update(
            {
                "BRANCH_POLICY_CONFIG": str(self.policy_path),
                "PR_HEAD_REF": head,
                "PR_BASE_REF": "main",
                "PR_BODY": body,
                "PR_CHANGED_FILES_B64": encoded(paths),
                "PR_POLICY_JSON_B64": encoded(policy or self.policy),
                "PR_REGISTRY_JSON_B64": encoded(self.registry),
            }
        )
        if trusted_policy_path is None:
            os.environ.pop("TRUSTED_BRANCH_POLICY_CONFIG", None)
        else:
            os.environ["TRUSTED_BRANCH_POLICY_CONFIG"] = trusted_policy_path

    def test_self_widening_proposed_policy_cannot_authorize_paths(self) -> None:
        widened = json.loads(json.dumps(self.policy))
        widened["delivery_units"]["blab-design-system"]["allowed_paths"] = ["**"]
        self.configure(
            head="codex/feature/blab-design-system/0.2.0/astryx-capability-adoption",
            body=(
                "Target-Delivery-Unit: blab-design-system\n"
                "Target-Version: 0.2.0\n"
                "Delivery-Profile: package-or-local"
            ),
            paths=[".github/workflows/target-version.yml", "lib/not-authorized.dart"],
            policy=widened,
        )
        with self.assertRaises(MODULE.PolicyError):
            MODULE.validate()

    def test_bootstrap_accepts_complete_governance_scope_without_trusted_policy(self) -> None:
        body = (
            "Target-Delivery-Unit: governance\n"
            "Target-Version: 1.0.0\n"
            "Delivery-Profile: package-or-local"
        )
        with tempfile.TemporaryDirectory() as directory:
            self.configure(
                head="chore/governance/1.0.0/open-blab-design-system-0.2.0",
                body=body,
                paths=sorted(MODULE.BOOTSTRAP_GOVERNANCE_PATHS),
                trusted_policy_path=str(Path(directory) / "missing-branch-policy.json"),
            )
            self.assertIn("target-version policy passed", MODULE.validate())

    def test_bootstrap_rejects_non_governance_path_without_trusted_policy(self) -> None:
        body = (
            "Target-Delivery-Unit: governance\n"
            "Target-Version: 1.0.0\n"
            "Delivery-Profile: package-or-local"
        )
        with tempfile.TemporaryDirectory() as directory:
            missing_policy = str(Path(directory) / "missing-branch-policy.json")
            self.configure(
                head="chore/governance/1.0.0/open-blab-design-system-0.2.0",
                body=body,
                paths=[".byungskerlab/branch-policy.json", "lib/not-authorized.dart"],
                trusted_policy_path=missing_policy,
            )
            with self.assertRaises(MODULE.PolicyError):
                MODULE.validate()

    def test_missing_proposed_policy_fails_closed_for_dotfile_path(self) -> None:
        body = (
            "Target-Delivery-Unit: governance\n"
            "Target-Version: 1.0.0\n"
            "Delivery-Profile: package-or-local"
        )
        self.configure(
            head="chore/governance/1.0.0/open-blab-design-system-0.2.0",
            body=body,
            paths=[".byungskerlab/branch-policy.json"],
        )
        os.environ["BRANCH_POLICY_CONFIG"] = ".byungskerlab/branch-policy.json"
        os.environ.pop("PR_POLICY_JSON_B64")
        with self.assertRaises(MODULE.PolicyError):
            MODULE.validate()

    def test_missing_proposed_registry_fails_closed_for_dotfile_path(self) -> None:
        body = (
            "Target-Delivery-Unit: governance\n"
            "Target-Version: 1.0.0\n"
            "Delivery-Profile: package-or-local"
        )
        self.configure(
            head="chore/governance/1.0.0/open-blab-design-system-0.2.0",
            body=body,
            paths=[".byungskerlab/release-lines.json"],
        )
        os.environ["BRANCH_POLICY_CONFIG"] = ".byungskerlab/branch-policy.json"
        os.environ.pop("PR_REGISTRY_JSON_B64")
        with self.assertRaises(MODULE.PolicyError):
            MODULE.validate()


if __name__ == "__main__":
    unittest.main(verbosity=2)
