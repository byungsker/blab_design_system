# BLDS project engineering harness

## Scope and routing

This repository uses the global Engineering Team harness. Shared frontend
system work routes through:

`engineering-team > engineering-frontend > engineering-design-system-frontend`

Blab remains the semantic and visual authority. Product identity, vocabulary,
localization, token meaning, and design approval remain with the byungskerlab
Design Team.

## Protected sources and local configuration

- `DESIGN.md` is a protected legacy source. Its required SHA-256 is
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`.
  Do not edit it or update the expected hash to accommodate drift.
- `.codex/` is local, user-owned configuration and is excluded from delivery.
  Never edit, delete, publish, or use it as repository evidence.
- Local configuration, credentials, identity, repository state, or a matching
  account never grants task authority.

## Authority boundaries

No task implicitly authorizes Git branch/worktree changes, commits, pushes,
pull requests, merges, releases, publication, deployment, consumer mutation,
credential changes, or external-account actions.

Before any Git or delivery action, load the company Target Delivery Contract
rules and verify an authoritative delivery unit, exact target version and
source, base, head, pull-request metadata, and promotion path. Missing values
are a fail-closed `REQUEST_CHANGES`, not permission to infer them.

Consumer checks are read-only by default. Any authorized execution must use a
validated disposable archive and must never write to a source consumer
checkout.

## Verification and completion

- Preserve unrelated and pre-existing user changes.
- Keep Phase 4 claims bounded by
  `contracts/delivery/phase4-custody.yaml`.
- Golden equality is reproducibility evidence, not accessibility or visual
  conformance.
- Run `dart run tool/verify.dart` and inspect the final scope before reporting
  engineering completion.
- A local pass does not authorize delivery, approval, release, publication, or
  a conformance claim.
