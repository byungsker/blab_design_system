# BLDS Phase 5 local compatibility, migration, and release-readiness status

Date: 2026-07-28
Owner: Engineering Design System Frontend
State: local preparation implemented; Phase 5 exit, delivery, and publication
blocked

Canonical machine state:
`local-preparation-implemented-exit-blocked`

## Outcome

The repository now has executable 0.x compatibility policy, immutable
`HEAD`-derived API and legacy CSS baselines, deterministic API/token
classification, a machine-readable approved-correction migration registry,
disposable no-source-rewrite rehearsal and rollback checks, rights/provenance
inventories, and blocked release documentation.

Package `0.2.0` is the accepted repository-only target and remains local and
unreleased. The active TDC authorizes branch, isolated worktree, exact protected
`DESIGN.md` restoration, commit, push, and draft-PR creation only. Promotion,
remote CI, and the two-consumer exit remain blocked. OpenCS is a web-adapter
experiment and is not a direct Flutter consumer.

## Design-contract-to-code traceability

| Contract | Implementation | Evidence |
| --- | --- | --- |
| additive/breaking and stable/experimental 0.x rules | `tool/src/phase5_compatibility.dart` | current report: 469 additive and 2 approved breaking token value corrections; deprecated detection unsupported and typed unknown |
| immutable baseline and checksum-only exclusion | `contracts/compatibility/baseline-provenance.yaml` plus two baseline files | origin commit-object validation, CSS `git show` byte equality, and analyzer API reproduction |
| breaking/removal fail-closed | classifier plus migration authority gate | negative API removal/signature and token value/semantic tests |
| migration/codemod policy | `contracts/migrations/registry.yaml` | both breaking corrections bound to `BLDS-BUTTON-CONTRAST-2026-07-28`; zero renames or source rewrites; codemod not applicable |
| disposable rehearsal and rollback | `tool/rehearse_phase5_migration.dart` | reads only normalized, real, canonically contained repository artifacts; copies only inside verified system temp; no consumer access or repository write |
| rights and provenance | `contracts/legal/rights-provenance.yaml` | four Phase 4 assets, remote CSS facts, Astryx packet, origin map, notices |
| dependency inventory | SPDX 2.3 and CycloneDX 1.6 JSON | 38 local-resolution packages/components each; dependency licenses `NOASSERTION` |
| release boundary | `contracts/release/phase5-readiness.yaml` | exit/delivery/publication false, 9 exact blockers and 2 resolved gates |

## Compatibility result

The committed `HEAD` API baseline contains 288 lines. The current analyzer
snapshot classifies 325 API changes as additive: 317 new declarations/members
and eight default-safe optional additions or input widenings. Of the 146 typed
primitive, semantic, and component token IDs, 144 remain additive relative to
the unchanged committed legacy CSS baseline. The standard-mode values of
`semantic.action.primary-foreground` and
`semantic.action.destructive-foreground` are explicitly classified as two
breaking value corrections, approved under
`BLDS-BUTTON-CONTRAST-2026-07-28`; high-contrast values are unchanged. There
are no removals, type changes, or semantic changes. The aggregate report is
469 additive and 2 breaking. Deprecated detection is not implemented in Phase
5, so no absence claim is made and the result remains typed unknown.

`BLabPressableWrapper` required one compatibility repair discovered by the
classifier. Its constructor still accepts a nullable callback for static
behavior, but the legacy public `onTap` field is again non-null and resolves to
a stable no-op when the nullable constructor input is absent. That exported
field is source-compatibility surface only and must not be used to infer
actionability. Private state, semantics, focusability, gesture handling,
long-press behavior, and static Card behavior use only the private nullable
effective callback derived from the constructor input. Focused evidence covers
legacy field read/invocation, inert null input, and actual activation. No new
public primitive was added; the existing Rule-of-Two exception remains
unchanged. Design and Quality re-review remain required.

## Rights, provenance, and package impact

- The root MIT text is observed, but copyright-holder identity and notice
  authority require a human decision.
- Astryx 0.1.3 remains capability-method evidence only. Its exact tag commit
  and three registry integrities are recorded. The implementation owner's
  methods-only scope statement is unsigned; copy, derivation, source, values,
  vocabulary, assets, and identity adoption remain unknown until attested.
- Noto Sans KR/Arabic, Material Icons, and Cupertino Icons remain repository
  test fixtures with exact hashes and license copies; they are not runtime
  assets.
- The Flutter package bundles and fetches no font files. Its Pretendard and
  JetBrains Mono family strings are preferences only; absent consumer-provided
  fonts, Flutter runtime fallback applies. The remote Pretendard/jsDelivr and
  JetBrains Mono/Google Fonts declarations are optional browser-CSS references,
  not Flutter or Figma font delivery. Production self-host, fallback, or remote
  strategy, provider terms, activation, and notices remain unresolved.
- A repository-wide CSS scan finds remote `@import` declarations in exactly
  `docs/design/tokens.css` and the immutable
  `contracts/compatibility/baselines/head-ee78fbe.tokens.css`. The former is
  excluded by the existing docs rule and the latter by the candidate
  compatibility-baseline rule. Neither issues a request unless a consumer
  explicitly loads it; exclusion is not approval of exact release composition.
- The file-origin map covers Git-tracked files plus explicitly allowed,
  nonignored candidate paths. Selection occurs through Git before content
  access; ignored secrets, local editor configuration, symlinks, and arbitrary
  untracked root files are not read or hashed. Repository-origin
  classification is not a human rights attestation.
- The SBOMs describe the local resolved development graph, not an authoritative
  release composition or dependency-license conclusion.
- The first `flutter pub publish --dry-run` performed no publication and
  exposed a 7 MB archive containing repository-only font/golden evidence plus
  the `docs` layout warning. A scoped `.pubignore` and conventional
  `doc/README.md` index and candidate process-only exclusions reduced the
  latest captured inventory to 82 files and an observed 123 KB compressed on
  the capture host while preserving
  runtime, candidate contracts/schemas, example, and root
  notices. The test fixtures, goldens, root generated evidence, API snapshot,
  build/recovery state, and `.codex` are absent. The only remaining dry-run
  warning has been eliminated in the clean committed candidate; the command
  exits 0 without publishing. Exact package composition remains
  TDC/DevOps/human-authority bound. Package-capture files
  are themselves excluded, eliminating self-reference; two consecutive runs
  match deterministic archive-name and content-manifest digests. Compressed
  size remains informational because archive compression varies by host.

## Negative gates

Twenty-two Phase 5 tests cover bounded canonical state, current classification,
typed unsupported deprecated detection, Git-object and API baseline
reproduction, baseline/checksum co-mutation rejection, checksum-only drift
exclusion, breaking API removal, breaking signature change, token
value/semantic change, unsigned-provenance claim acceptance and its fail-closed
categorical-claim cases, categorical MIT ownership wording while
project-license authority is unknown, remote-CSS completeness and its
fail-closed missing-entry case, package composition, stale migration identity,
traversal/absolute/drive/UNC/symlink migration rejection with outside-sentinel
and cleanup proof, fresh-clone-equivalent ignored-secret exclusion, missing
rights evidence, approval reuse, and rollback identity mismatch. The
existing Pressable/Card focused suite includes the legacy-field split-contract
evidence and passes 21/21.

## Resolved gate

The canonical repository identity is factually resolved as
`https://github.com/byungsker/blab_design_system`. GitHub redirects the legacy
`lbo728/blab_design_system` address to that repository. The package homepage,
README, canonical contract, rights record, and readiness record now use or
identify the canonical address. The local Git origin remains the redirect
alias and was not mutated. This resolution proves repository identity only; it
does not prove copyright ownership, provenance, delivery authority, release
authority, or publication readiness.

The exact full-repository TDC is also resolved for creation authority:
`blab-design-system@0.2.0`, `package-or-local`, canonical `main`, and
`codex/feature/blab-design-system/0.2.0/astryx-capability-adoption`.
Byungsker's approval authorizes branch, isolated worktree, commit, push, and
draft-PR creation only. Promotion remains blocked.

## Exact blockers

1. legal copyright holder and MIT notice authority;
2. `baro-app` transfer or relicense authority;
3. contributor aliases and restrictions;
4. publication markets, channels, jurisdictions, and package composition;
5. production font strategy;
6. non-derivation, asset, and Figma origin attestations;
7. final release authority;
8. remote CI;
9. two clean pinned direct Flutter consumers.

Local-preparation decision: `APPROVE_NEXT` for independent Design/Quality
review and continued evidence gathering only. Delivery and publication remain
`REQUEST_CHANGES`; no Git mutation, release, publication, deployment, or
consumer mutation is authorized.
