# BLDS release checklist

This is a blocked preparation checklist for package `0.2.0`. It does not grant
release, publication, Git, credential, registry, or consumer authority.

## Local preparation

- [x] Immutable `HEAD`-derived API and legacy-token baseline with provenance.
- [x] Deterministic compatibility classifier: 469 additive and 2 approved
  breaking token value corrections under
  `BLDS-BUTTON-CONTRAST-2026-07-28`; deprecated detection is unsupported and
  its result is typed unknown.
- [x] Machine-readable 0.x deprecation/removal policy.
- [x] Migration registry binds both breaking corrections to their approved
  decision; codemod remains not applicable because neither is a rename or
  source rewrite.
- [x] Disposable no-source-rewrite migration and repository-artifact rollback
  rehearsal.
- [x] Changelog, compatibility matrix, rollback runbook, notices, origin map,
  SPDX, CycloneDX, and unsigned attestation templates.
- [x] Package is aligned to the accepted repository-only `0.2.0` target and
  remains local-unreleased.
- [x] Nonpublishing dry-run inventory reduced from 7 MB to 123 KB compressed
  after candidate process-only exclusions; 82 files remain and the `doc`
  convention warning is resolved. The compatibility baseline, capture
  artifacts, test/tool evidence, and internal authority packets are excluded.
  Two consecutive captures have matching name/content digests. The composition
  is still candidate and human-unapproved. The clean candidate dry-run exits 0
  without publication.

## Required before delivery or publication

- [ ] Human-confirmed copyright holder and authority for the MIT notice.
- [ ] `baro-app` transfer or relicense authority and contributor
  aliases/restrictions.
- [x] Canonical repository identity verified as
  `byungsker/blab_design_system`; the legacy `lbo728` address is recorded as a
  redirect alias. This does not establish rights or delivery authority.
- [x] Exact `blab-design-system@0.2.0` target version/source, base, head, PR
  metadata, repository-only promotion path, rollback target, and creation-only
  delivery authority recorded in the active TDC.
- [ ] Publication markets, channels, jurisdictions, and exact package
  composition.
- [ ] Production font strategy and provider/notice review.
- [ ] Signed, scope-bound non-derivation, asset, and Figma origin attestations.
- [ ] Independent Design and Quality re-review of the Pressable compatibility
  shim and full Phase 5 packet.
- [ ] Remote Ubuntu/macOS/Windows CI evidence.
- [ ] Two clean pinned direct Flutter consumer analyze/test/build and rollback
  rehearsals. OpenCS does not count.
- [ ] Final explicit byungsker release/publication authority.

Until every item in the second section is evidenced, the only valid decision is
`REQUEST_CHANGES` for delivery/publication.
