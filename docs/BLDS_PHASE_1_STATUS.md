# BLDS Phase 1 local contract-pipeline status

Status: Implemented and locally verified; parent engineering closure recorded

As of: 2026-07-25

Contract version: `0.2.0`

Capability manifest version: `0.1.0`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Implemented scope

Phase 1 owns deterministic, repository-local contract outputs and diagnostics.
The generator preflights every destination for containment and symbolic links,
writes through sibling temporary files, and atomically replaces each output.
`--check` compares exact bytes.

| Output | Source | Count or scope |
| --- | --- | ---: |
| `lib/src/generated/blab_token_data.g.dart` | typed token contract | 76 tokens × 4 modes |
| `lib/src/theme/blab_token_theme.dart` | typed token contract | 4 additive visual modes |
| `generated/blab.tokens.css` | compatibility mappings | 134 legacy CSS names plus high-contrast mappings |
| `generated/token-traceability.md` | token and compatibility contracts | 76 tokens, 139 Dart symbols, 223 classified component-local values |
| `generated/token-reference.ko-KR.md` | tokens plus approved glossary | 76 token rows |
| `generated/figma-token-mapping.json` | typed token contract | 76 local mapping rows; no remote mutation |
| `generated/component-state-coverage.yaml` | Design-owned applicability contract | 9 components, 67 applicable states, 26 not-applicable states |
| `generated/blab-capabilities.v1.json` | capability source in the main contract | 13 capability records |

The component-state artifact records required, conditional, and required-when
Design contracts. Every applicable state is present, but each row explicitly
records `implementation_evidence: not-claimed`.

Current-state note: Phase 3 family 1 subsequently added seven Button component
tokens, six proven Button implementation claims, and qualified Button absence
evidence. See `BLDS_PHASE_3_BUTTON_STATUS.md`; this Phase 1 packet remains the
historical pipeline-completion record.

## Offline doctor

`dart run tool/blab_doctor.dart` and its `--json` form inspect:

- contract validation and generated-output drift;
- analyzer-backed public API snapshot presence and drift;
- protected `DESIGN.md` checksum status;
- state, visual-baseline, and glossary provenance;
- unresolved remote font and asset activation;
- repository custody evidence; and
- release and publication authority.

The JSON envelope uses `blab.doctor-envelope/v1` and report schema
`blab.doctor/v1`. Checks are sorted by stable IDs and classified as `pass`,
`warning`, `failure`, or `information`. Warnings do not fail the command;
failures exit `1`; invalid usage exits `64`. Diagnostics are read-only and
offline and do not collect telemetry.

The current expected warnings are unresolved repository custody, remote
font/assets, and missing release/publication authority. These warnings are not
silenced by successful local checks.

## Verification

Phase 1 received an independent repair review decision of `APPROVE_NEXT`.
The parent verification evidence was:

- `dart run tool/verify.dart` passed;
- the full Flutter test suite passed, 35/35;
- Flutter/package analysis passed;
- example analysis passed; and
- the example release web build passed.

This evidence closes the prior "awaiting final independent verification"
status for the local Phase 1 implementation. It is not release authority,
publication authority, or a Blab accessibility, visual, localization, locale,
consumer, or package conformance claim.

Run the aggregate gate from the repository root:

```bash
dart run tool/verify.dart
```

It checks format, the contract, all generated outputs, the public API snapshot,
doctor JSON content, Flutter analysis/tests, example analysis, and an example
release bundle build. `.github/workflows/verify.yml` runs the same gate without
secrets or a release job. The format gate covers Phase 1-owned Dart tools,
tests, and generated Dart outputs; reference-locked hand-maintained sources are
analyzed and tested without rewriting their preserved bytes.

The workflow uses `actions/checkout@v4` for repository checkout and
`subosito/flutter-action@v2` to provision the contract floor Flutter `3.38.5`.
The repository scan records the resulting workflow references but cannot prove
copy or derivation history. Any owner statement about source or asset origin is
unsigned and requires a scope-bound attestation. Exact action commit pinning
and repository-local license verification remain CI-hardening work before any
release-authority gate; the current workflow is verification
only.

## Explicit limits

- Phase 1 is locally verified with an independent repair review decision of
  `APPROVE_NEXT`; this does not authorize release, publication, or conformance
  claims.
- Phase 2 shared interaction and accessibility foundations are implemented
  locally; the subsequent current parent aggregate passes 413/413 package
  tests, while independent Design/Quality gates remain pending. This does not
  claim implementation of any applicable component state.
- Phase 3 is the sequential remediation of the nine existing public components
  and component families; it has not started.
- Phase 4 adds evidence surfaces, the complete playground, approved goldens,
  and the supported platform matrix; it has not started.
- Phase 5 covers compatibility, migration, and release readiness; it has not
  started.
- There is no accessibility, visual, localization, locale, consumer, package,
  publication, or release conformance claim.
- Figma was not called or changed.
- Repository custody remains unresolved because no repository-local redirect
  evidence is recorded.
- Remote fonts/assets and their activation/notice decisions remain unresolved.

## Rollback

Revert the Phase 1B generator, validator, doctor, aggregate verification,
workflow, generated artifacts, and status documentation together. Restore the
previous `contracts/blab.design.yaml` output list and schema rules in the same
change. Phase 1A additive outputs can remain independently if their original
four-output generator contract is restored. No persisted customer or product
data migration is involved.
