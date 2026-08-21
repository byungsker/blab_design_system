# BLDS Phase 5 migration and rollback runbook

Phase 5 has no release and no consumer migration to undo. The current rehearsal
is deliberately limited to repository artifacts in a disposable temporary
directory.

## Rehearse locally

```sh
dart run tool/classify_compatibility.dart --json
dart run tool/validate_phase5_baselines.dart
dart run tool/rehearse_phase5_migration.dart
dart run tool/generate_phase5_inventories.dart --check
dart run tool/validate_phase5_readiness.dart
```

The rehearsal reads only normalized, non-symlink repository-relative source
files whose canonical paths remain inside the repository. It copies the current
API/token inputs and immutable rollback pair only to canonically contained
current/rollback lanes inside a tool-owned system temporary directory, verifies
all recorded SHA-256 identities, performs the registered approved
compatibility-correction rehearsal without a consumer source rewrite,
confirms the repository source identities did not change, and verifies cleanup.
It never reads, executes, or writes a consumer checkout.

The baseline validator independently resolves `origin.commit` as a Git commit
object, compares legacy CSS bytes with `git show`, and regenerates the analyzer
API snapshot from that commit's `lib` blobs using the existing pinned local
package configuration. It performs no network, Git mutation, or worktree
mutation. A future baseline is admitted only as a new immutable artifact
through the separate, human-bound admission template; existing baselines are
never regenerated in place.

## Repository-artifact rollback

If the Phase 5 preparation itself must be removed before delivery:

1. preserve unrelated worktree changes and the protected `DESIGN.md`;
2. remove only the Phase 5 contracts, schemas, tools, tests, docs, notices,
   origin/SBOM inventories, and doctor/verifier wiring;
3. restore the pre-shim `BLabPressableWrapper` only if Design and Quality
   explicitly reject the compatibility shim—otherwise retain the public
   non-null field compatibility repair;
4. regenerate the analyzer snapshot and run the pre-existing aggregate gate;
5. confirm no consumer source, Git state, release, registry, or external
   account changed.

The immutable rollback identities are:

- API: `69d604922ef6f4109dcf03afc23fcc5b9c5cf0342afa0fd422dcdd556fc16089`
- legacy CSS tokens:
  `e774b7e7ba7faedbd8d2dc18dc4faf9fbd179d89ebaa2a0a46dbc89949fd1e75`

Consumer and release rollback remain not applicable because neither action was
authorized or executed.
