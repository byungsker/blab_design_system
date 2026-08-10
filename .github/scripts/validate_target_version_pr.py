#!/usr/bin/env python3
"""Fail-closed target-version validation for trusted pull_request_target CI."""

from __future__ import annotations

import base64
import fnmatch
import json
import os
import re
import sys
import urllib.request
from pathlib import Path
from typing import Any


SEMVER = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
WORK_RE = re.compile(
    rf"^(?:codex/)?(?P<type>feature|fix|chore|refactor|docs|ci|migration|sync)/"
    rf"(?P<unit>[a-z0-9][a-z0-9-]*)/(?P<version>{SEMVER})/"
    r"(?P<scope>[A-Za-z0-9][A-Za-z0-9._-]*)$"
)
PROMOTION_RE = re.compile(
    rf"^(?:codex/)?(?P<type>release|hotfix)/"
    rf"(?P<unit>[a-z0-9][a-z0-9-]*)/(?P<version>{SEMVER})$"
)
METADATA_KEYS = (
    "Target-Delivery-Unit",
    "Target-Version",
    "Delivery-Profile",
)
BOOTSTRAP_GOVERNANCE_PATHS = frozenset(
    {
        ".byungskerlab/branch-policy.json",
        ".byungskerlab/release-lines.json",
        ".github/scripts/validate_target_version_pr.py",
        ".github/scripts/test_validate_target_version_pr.py",
        ".github/workflows/target-version.yml",
        "AGENTS.md",
    }
)


class PolicyError(ValueError):
    """Raised for a fail-closed delivery-policy violation."""


def repository_path(path: Path) -> str:
    value = path.as_posix()
    return value[2:] if value.startswith("./") else value


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        raise PolicyError(f"invalid governance JSON: {path}") from exc
    if not isinstance(value, dict):
        raise PolicyError(f"governance JSON must be an object: {path}")
    return value


def load_json_b64(encoded: str, label: str) -> dict[str, Any]:
    try:
        value = json.loads(base64.b64decode(encoded, validate=True))
    except (ValueError, json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise PolicyError(f"invalid proposed governance JSON: {label}") from exc
    if not isinstance(value, dict):
        raise PolicyError(f"proposed governance JSON must be an object: {label}")
    return value


def metadata_value(body: str, key: str) -> str:
    matches = re.findall(
        rf"(?mi)^[ \t]*{re.escape(key)}[ \t]*:[ \t]*([^\r\n]*)$", body
    )
    if len(matches) != 1 or not matches[0].strip():
        raise PolicyError(f"{key} must appear exactly once")
    return matches[0].strip()


def changed_files(encoded: str) -> list[str]:
    try:
        value = json.loads(base64.b64decode(encoded, validate=True))
    except (ValueError, json.JSONDecodeError) as exc:
        raise PolicyError("changed-file evidence is malformed") from exc
    if not isinstance(value, list) or not value or not all(
        isinstance(item, str) for item in value
    ):
        raise PolicyError("changed-file evidence must be a non-empty string array")
    return value


def check_paths(unit: str, policy: dict[str, Any], paths: list[str]) -> None:
    allowlist = policy.get("allowed_paths")
    if not isinstance(allowlist, list) or not allowlist:
        raise PolicyError(f"delivery unit {unit} has no allowed paths")
    for path in paths:
        if path.startswith("/") or ".." in Path(path).parts:
            raise PolicyError(f"invalid changed path: {path!r}")
        if not any(fnmatch.fnmatchcase(path, pattern) for pattern in allowlist):
            raise PolicyError(f"changed path outside {unit}: {path}")


def check_ancestry(source_sha: str) -> bool:
    repository = os.environ.get("GITHUB_REPOSITORY", "")
    head_sha = os.environ.get("PR_HEAD_SHA", "")
    token = os.environ.get("GH_TOKEN", "")
    if (
        not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository)
        or not re.fullmatch(r"[0-9a-f]{40}", head_sha)
        or not re.fullmatch(r"[0-9a-f]{40}", source_sha)
        or not token
    ):
        return False
    request = urllib.request.Request(
        f"https://api.github.com/repos/{repository}/compare/{source_sha}...{head_sha}",
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            value = json.load(response)
    except (OSError, ValueError):
        return False
    return value.get("status") in {"ahead", "identical"} and value.get(
        "merge_base_commit", {}
    ).get("sha") == source_sha


def validate() -> str:
    config_path = Path(
        os.environ.get("BRANCH_POLICY_CONFIG", ".byungskerlab/branch-policy.json")
    )
    trusted_config_path = Path(
        os.environ.get("TRUSTED_BRANCH_POLICY_CONFIG", str(config_path))
    )
    paths = changed_files(os.environ.get("PR_CHANGED_FILES_B64", ""))
    head = os.environ.get("PR_HEAD_REF", "")
    base = os.environ.get("PR_BASE_REF", "")
    body = os.environ.get("PR_BODY", "")
    match = WORK_RE.fullmatch(head) or PROMOTION_RE.fullmatch(head)
    if not match:
        raise PolicyError("head branch does not match the delivery contract")
    branch_type = match.group("type")
    unit = match.group("unit")
    version = match.group("version")
    policy_path = repository_path(config_path)
    proposed_policy = os.environ.get("PR_POLICY_JSON_B64", "")
    if policy_path in paths and not proposed_policy:
        raise PolicyError("proposed policy JSON is missing")
    config = (
        load_json_b64(proposed_policy, policy_path)
        if proposed_policy
        else load_json(config_path)
    )
    if config.get("schema_version") != 1:
        raise PolicyError("policy schema_version must be 1")
    units = config.get("delivery_units")
    if not isinstance(units, dict) or not units:
        raise PolicyError("policy delivery_units must be non-empty")

    sources: list[str] = []
    for unit_name, unit_record in units.items():
        if not isinstance(unit_record, dict):
            raise PolicyError(f"invalid delivery unit record: {unit_name}")
        source_value = unit_record.get("target_version_source")
        if not isinstance(source_value, str) or not source_value:
            raise PolicyError(f"target version source is missing for {unit_name}")
        if not isinstance(unit_record.get("production_branch"), str) or not unit_record.get(
            "production_branch"
        ):
            raise PolicyError(f"production branch is missing for {unit_name}")
        sources.append(source_value)
    if len(set(sources)) != 1:
        raise PolicyError("delivery units use divergent target version sources")
    source = sources[0]
    source_path = Path(source)
    if source_path.is_absolute():
        registry_path = source_path
    elif source_path.parts and source_path.parts[0] == config_path.parent.name:
        registry_path = config_path.parent.parent / source_path
    else:
        registry_path = config_path.parent / source_path
    registry_repo_path = repository_path(registry_path)
    proposed_registry = os.environ.get("PR_REGISTRY_JSON_B64", "")
    if registry_repo_path in paths and not proposed_registry:
        raise PolicyError("proposed release registry JSON is missing")
    registry = (
        load_json_b64(proposed_registry, registry_repo_path)
        if proposed_registry
        else load_json(registry_path)
    )
    if registry.get("schema_version") != 1:
        raise PolicyError("release registry schema_version must be 1")
    registry_units = registry.get("delivery_units")
    if not isinstance(registry_units, dict) or set(registry_units) != set(units):
        raise PolicyError("policy/registry delivery units differ")
    for unit_name, unit_policy in units.items():
        registry_unit = registry_units.get(unit_name)
        if not isinstance(unit_policy, dict) or not isinstance(registry_unit, dict):
            raise PolicyError(f"invalid delivery unit record: {unit_name}")
        active_versions = unit_policy.get("active_versions")
        registry_versions = registry_unit.get("active_versions")
        if (
            not isinstance(active_versions, list)
            or not isinstance(registry_versions, list)
            or not all(isinstance(version_value, str) for version_value in active_versions)
            or not all(isinstance(version_value, str) for version_value in registry_versions)
            or set(registry_versions) != set(active_versions)
        ):
            raise PolicyError(
                f"policy/registry active versions differ for {unit_name}"
            )

    unit_policy = units.get(unit)
    registry_unit = registry_units.get(unit)
    if not isinstance(unit_policy, dict) or not isinstance(registry_unit, dict):
        raise PolicyError(f"unknown delivery unit: {unit}")

    active = unit_policy.get("active_versions")
    if not isinstance(active, list) or version not in active:
        raise PolicyError(f"target version {version} is not active for {unit}")
    profile = unit_policy.get("profile")
    if not isinstance(profile, str) or not profile:
        raise PolicyError(f"delivery unit {unit} has no profile")
    if trusted_config_path.exists():
        trusted_config = load_json(trusted_config_path)
        trusted_units = trusted_config.get("delivery_units")
        if not isinstance(trusted_units, dict):
            raise PolicyError("trusted policy delivery_units is invalid")
        trusted_unit_policy = trusted_units.get(unit)
        if not isinstance(trusted_unit_policy, dict):
            raise PolicyError(f"trusted policy has no delivery unit: {unit}")
        check_paths(unit, trusted_unit_policy, paths)
    elif unit == "governance":
        unauthorized = [path for path in paths if path not in BOOTSTRAP_GOVERNANCE_PATHS]
        if unauthorized:
            raise PolicyError(
                f"bootstrap governance path outside immutable allowlist: {unauthorized[0]}"
            )
    else:
        raise PolicyError("trusted branch policy is missing")

    expected = {
        "Target-Delivery-Unit": unit,
        "Target-Version": version,
        "Delivery-Profile": profile,
    }
    for key, value in expected.items():
        if metadata_value(body, key) != value:
            raise PolicyError(f"{key} does not match the committed policy")

    production_branch = unit_policy.get("production_branch")
    if not isinstance(production_branch, str) or not production_branch:
        raise PolicyError(f"production branch is missing for {unit}")
    if base != production_branch:
        raise PolicyError(f"base must be {production_branch}")

    promotion_metadata = re.findall(
        r"(?mi)^[ \t]*Promotion-Source-SHA[ \t]*:", body
    )
    if branch_type not in {"release", "hotfix"}:
        if promotion_metadata:
            raise PolicyError("Promotion-Source-SHA is forbidden on normal work PRs")
    else:
        sources = registry_unit.get("promotion_sources")
        if not isinstance(sources, dict):
            raise PolicyError("promotion source is not recorded")
        source_by_version = sources.get(branch_type)
        if not isinstance(source_by_version, dict):
            raise PolicyError("promotion source is not recorded")
        source_record = source_by_version.get(version)
        if not isinstance(source_record, dict) or not isinstance(
            source_record.get("sha"), str
        ):
            raise PolicyError("promotion source is not recorded")
        if metadata_value(body, "Promotion-Source-SHA") != source_record["sha"]:
            raise PolicyError("promotion source SHA does not match the registry")
        if not check_ancestry(source_record["sha"]):
            raise PolicyError("promotion head ancestry is not verified")

    return (
        f"target-version policy passed: unit={unit} profile={profile} "
        f"version={version} head={head} base={base}"
    )


if __name__ == "__main__":
    try:
        print(validate())
    except PolicyError as exc:
        print(f"target-version policy failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
