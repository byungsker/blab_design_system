# BLDS Phase 0 Authority and Baseline

Status: Historical Phase 0 baseline, implemented and locally verified. Phase 1
is implemented locally and tracked separately while awaiting final independent
verification; release remains unauthorized.

As of: 2026-07-25

Design owner: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

Legal role: provenance and license issue spotting only

## Outcome

Phase 0 establishes a verified starting point for improving BLDS with
capabilities studied from Astryx while keeping Blab as the only visual and
semantic identity.

Byungsker accepted the repository-owned SSOT direction and canonical location,
selected MIT, and approved an analyzer-backed full public API snapshot. The
resulting `contracts/blab.design.yaml` version `0.1.0` is authoritative,
reference-locks current values without generating outputs, and records the
approved Phase 0 accessibility and localization policy.

This packet does not authorize source copying, Phase 1 generation, a package
release, a consumer migration, a Figma mutation, or a claim of accessibility
or Blab conformance. The existing `DESIGN.md` worktree change predates this
packet, remains untouched, and is not used as an accepted decision.

## Evidence labels

- `verified`: directly observed in a repository, installed package, registry,
  or upstream source on 2026-07-25;
- `inferred`: a conclusion from verified evidence that still needs validation;
- `proposed`: a decision requiring the named owner;
- `authority-bound`: requires byungsker approval and cannot be selected by an
  agent.

## Authority decision

### Resolved pre-Phase 0 conflict

Before this closeout, BLDS described more than one authority:

- `README.md` calls `docs/design/tokens.css` the authoritative token source;
- the same README and `DESIGN.md` call an external `blab-design` skill bundle
  the SSOT;
- `docs/design/README.md` calls repository design documents sources of truth;
- Dart token files describe themselves as manual mirrors of the CSS file;
- `docs/design/tokens.css` describes itself as a mirror of Dart and widget
  patterns.

The approved contract now resolves the authority order. Legacy prose is a
downstream explanation or mirror and cannot override the contract.

### Accepted Design decision

Adopt this authority order:

```text
Design-approved, repository-owned, platform-neutral Blab contract
                              ↓
generated Flutter tokens, CSS tokens, documentation tables, and mappings
                              ↓
Flutter components, examples, tests, diagnostics, and product adapters
                              ↓
Figma files and agent skill bundles as versioned distribution mirrors
```

Blab owns:

- brand character and visual identity;
- primitive, semantic, and component token meaning;
- component anatomy, variants, and state meaning;
- accessibility policy and evidence requirements;
- motion, haptics, localization, and platform intent;
- approval of intentional Flutter and web deviations.

Astryx may inform:

- schema structure and token traceability;
- typed theme and component contracts;
- state and accessibility matrices;
- deterministic generation and drift checks;
- documentation metadata, manifests, diagnostics, and migrations.

Astryx does not own Blab values, vocabulary, component appearance, page
composition, product copy, or cross-platform policy.

### Implemented canonical location

`contracts/blab.design.yaml` is the approved canonical contract.
`contracts/schema/blab.design.schema.yaml` defines the minimal validation
rules. The validator parses YAML, verifies required policy and authority
fields, rejects invalid output states, confines references to the repository,
and checks the SHA-256 digest of every Phase 0 value source.

For migrated sources, the Phase 0 digest remains immutable historical evidence.
It is never overwritten to make current-source validation pass. The Button
historical digest is
`27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f`;
Phase 3 records and validates its current implementation digest separately in
the canonical contract and Button status packet.

The contract deliberately reference-locks the current CSS, Flutter token, theme,
and widget sources. Primitive, semantic, and component taxonomies are preserved
but not yet normalized. No Dart, CSS, documentation table, Figma mapping, or
agent-skill output is generated in Phase 0.

## Current BLDS package inventory

### Package and public surface

| Item | Verified baseline |
| --- | --- |
| package | `blab_design_system` |
| package version | `0.0.1` |
| implementation | Flutter/Dart |
| root library | `lib/blab_design_system.dart` |
| exported files | 17 |
| public top-level declarations | 21 |
| automated tests | real package import plus contract and analyzer snapshot drift tests |
| visual regression | not observed |
| consumer compatibility matrix | not observed |
| package license | standard MIT text; publication remains separately authorized |

The 21 public declarations are:

- foundations: `BLabColors`, `BLabTypography`, `BLabSpacing`, `BLabRadius`,
  `BLabShadow`, `BLabMotion`, `BLabGlass`, and `BLabTheme`;
- supporting types: `BLabButtonVariant`, `BLabSnackbarType`,
  `BLabBottomBarItem`, and `BLabSegmentedItem<T>`;
- components and utilities: `BLabButton`, `BLabCard`, `BLabTextField`,
  `BLabBottomBar`, `BLabTabBar`, `BLabSegmentedControl<T>`,
  `BLabSnackbar`, `BLabKeyboardAccessoryBar`, and
  `BLabPressableWrapper`.

The checked-in `api/blab_design_system.api.txt` is now the reproducible Phase 0
public API baseline. Its pinned analyzer extractor resolves the root export
namespace and records public types, enum values in declaration order,
constructors, required/optional named and positional parameters, defaults,
declared public fields, getters, setters, methods, static members, and constant
token initializers. It excludes inherited framework members so Flutter SDK
implementation detail does not become BLDS-owned API.

### Component contract gaps

| Component family | Current public states or variants | Contract gaps to close before remediation |
| --- | --- | --- |
| Button | primary, secondary, destructive; callback-null disabled behavior | loading, busy semantics, keyboard/focus evidence, text scale, reduced motion |
| TextField | empty/non-empty, focus, read-only, obscured, autofocus, multiline | error/help text, required/invalid semantics, disabled contract, focus ownership |
| Navigation | selected index/value, tab callbacks, optional bottom-bar action | keyboard model, current/selected semantics, focus order, overflow and text expansion |
| Card/Pressable | tap, long press, press animation, optional haptic | role semantics, keyboard activation, reduced motion/haptic policy |
| Snackbar | success, error, info, warning; duration and placement controls | live-region semantics, action/dismiss contract, announcement timing |
| Keyboard accessory | enabled capability flags, navigation and edit callbacks | platform boundary, labels, focus order, repeated-action semantics |

The table records missing explicit contracts. It does not claim each current
implementation is defective.

## Consumer baseline

### Verified consumers

| Repository | Evidence | Classification |
| --- | --- | --- |
| `baro-app/app` | Git dependency on BLDS `main`; 40 source/test files import the root BLDS library | only verified direct Flutter package consumer |
| `book-golas/app` | no BLDS dependency or package import; product-local `BLab*` theme and widget declarations exist | divergent local implementation, not a BLDS package consumer |
| BLDS `example/` | local package example | canary only, not independent product evidence |
| OpenCS Map | Astryx React integration and a proposed Blab adapter | web experiment, not a Flutter BLDS consumer |

The Company Control Plane identifies baroguni and bookgolas as products whose
design system is Blab. That product identity does not prove both products
consume this Flutter package.

### Compatibility consequence

`baro-app` is the initial compatibility canary. Its current dependency points
to `https://github.com/lbo728/blab_design_system.git` on `main`, while this
repository documents `https://github.com/byungsker/blab_design_system.git`.
Engineering must resolve whether the former remote is a compatibility alias,
stale origin, or separate custody path before any migration or release plan.
Its current lockfile resolves BLDS commit
`671b7b24778574ce19b0acd8b1300156593f2b11`.

`book-golas` currently declares Dart `^3.5.3`; directly adopting BLDS would
raise its effective floor to BLDS's Dart `^3.10.4` unless one side changes.
Its local BottomBar, Card, and TextField contracts also contain
product-specific differences that require an additive adapter rehearsal.

Observed `baro-app` source/test references include:

| API | Occurrences |
| --- | ---: |
| `BLabColors` | 301 |
| `BLabTheme` | 2 |
| `BLabButton` | 134 |
| `BLabCard` | 18 |
| `BLabTextField` | 21 |
| `BLabBottomBar` | 5 |
| `BLabTabBar` | 2 |
| `BLabSegmentedControl` | 1 |
| `BLabSnackbar` | 161 |
| `BLabKeyboardAccessoryBar` | 2 |
| `BLabPressableWrapper` | 1 |

These are textual occurrence counts, not runtime coverage. Before changing a
public API, Phase 1 must add an API snapshot and compile a pinned consumer
fixture.

## Accessibility contract baseline

### Verified policy fragments

Current repository prose mentions:

- WCAG-style 4.5:1 normal-text contrast;
- 44×44 minimum interactive targets;
- visible focus indication;
- light and dark modes;
- reduced-motion behavior;
- 150–300ms motion using the Blab easing curve.

The package does not currently provide automated evidence that every public
component satisfies these statements.

### Approved Design-owned Phase 0 policy

The canonical contract versions:

- supported visual modes: light, dark, and the decision on high contrast;
- text contrast thresholds for normal text, large text, and preferred key
  reading surfaces;
- 44×44 minimum pointer target and documented exceptions;
- keyboard activation, traversal, containment, dismissal, and focus return;
- semantic roles, names, values, relationships, and live announcements;
- text scaling range and reflow/overflow expectations;
- reduced-motion behavior for every non-essential transition;
- haptic purpose, disablement, and platform override rules;
- automated and manual evidence required before a conformance claim.

Flutter semantics, widget behavior, and test implementation remain
Engineering-owned. Design owns the intended user-facing meaning.
High-contrast support and the exact supported text-scaling range remain
explicitly undecided. Current implementation evidence is not established, and
the contract forbids a conformance claim from these Phase 0 checks.

## Localization contract baseline

### Verified

Before Phase 0, BLDS did not have a versioned localization contract. Public
widget APIs include consumer-provided strings, while some internal comments
and behavior names mix Korean and English. No repository glossary,
source-locale decision, expansion budget, or product-override contract was
observed in that baseline.

### Approved boundary with locale reconciliation required

- intended contract and repository documentation source locale: `ko-KR`;
- actual current artifact source language: predominantly English;
- intended supported BLDS documentation locales: `ko-KR` only during Phase 0,
  with no currently verified documentation locale until reconciliation;
- BLDS product target locales: none, because the package currently owns no
  localized customer copy;
- every product adapter must declare its own source locale, supported customer
  target locales, glossary, and review evidence;
- system identifiers that remain untranslated: `Blab`, `BLDS`, `Astryx`,
  package names, code symbols, URLs, and slugs;
- component-owned customer strings must use a versioned glossary and
  localization keys rather than embedded literals;
- product-specific nouns and tone remain product-owned overrides;
- component geometry must be verified with Korean, a synthetic 40% expansion
  pseudo-locale, and an RTL stress sample before acceptance; the two stress
  inputs are test fixtures, not supported customer locales;
- truncation, line wrapping, reading order, semantics labels, number/date
  formatting, and bidirectional behavior must be recorded where applicable;
- localization review evidence must distinguish terminology, accuracy, tone,
  layout, and accessibility findings.

The versioned `contracts/glossary/blab.terms.yaml` file defines `Blab` and
`Blab Design System` as display forms, `BLDS` as the acronym, and `BLab` as the
existing Dart-symbol prefix. Product terms remain product-adapter-owned.
This policy does not translate existing product copy or expand supported
product locales, and it is not a localization-conformance claim.

## Astryx provenance ledger

Verified on 2026-07-25 from the npm registry, installed OpenCS lockfile, and
the upstream `facebook/astryx` repository:

| Package | Version | Registry integrity | License metadata |
| --- | --- | --- | --- |
| `@astryxdesign/core` | 0.1.3 | `sha512-NTiKu0+keZckb5RB6enErCXDGYLF6j4cUYjK/V0uWrqbflX+47sUQgaCZVFZB4b2kAe4k4czBCZS3mtaJcbZlw==` | MIT |
| `@astryxdesign/cli` | 0.1.3 | `sha512-vhn9BP8MOfVnJjr9YkSlZi8785cj8mevmW4LDLxhKQ8m8KLrIkOrr5HtTcHJL1GtyXn6J5Z6WTnRXln/RTgXfg==` | MIT |
| `@astryxdesign/theme-neutral` | 0.1.3 | `sha512-diwEEukajD0OHSeQ3XnyaNYHssaWgbjbwAGG5t/NANjE4X0sjFXUKb5drwWHhje5AU+hTFU7yOUltvjSW4LHvg==` | MIT |

Upstream tag `v0.1.3` resolves to commit
`6d57c8d9126b768ee6fdb90e74e060a8e3494e8e`, dated 2026-07-04. The tag's
three package manifests identify the same package names and versions, the
Meta Astryx repository, and MIT licensing. The upstream root license names
Meta Platforms, Inc.; no root `NOTICE` file was observed at the tag.

Installed package detail:

- CLI and neutral theme include an MIT license file;
- Core declares MIT in package metadata but its installed package lacks a
  root license file;
- the implementation owner states, without a signature, a methods-only intent
  for the current work; inspection, copy, derivation, source, value, and asset
  facts remain unknown pending a signed, scope-bound attestation;
- a repository scan observed no Astryx dependency or implementation identifier
  in BLDS, but that owner statement plus scan does not independently prove
  non-derivation.

Before any future source-derived implementation, record the exact source
file, revision, license file, transformation, destination, retained notice,
and reviewer. Prefer independent implementation from a Blab contract.

## License and asset boundary

Byungsker selected MIT. `LICENSE` now contains the standard MIT text with
`Copyright (c) 2026 byungsker and byungskerlab`, and the contract records SPDX
identifier `MIT`. This implements the local license choice only; it does not
authorize publication, release, or incorporation of third-party source. Any
copied MIT material must retain the applicable copyright and permission notice.
This is preparation and issue spotting, not qualified legal advice.

Pretendard, JetBrains Mono, icons, Figma assets, remote images, and any future
bundled asset require their own source, license, redistribution, subsetting,
and notice record. Referencing a font in design prose is not distribution
permission.

`docs/design/tokens.css` currently activates remote imports when a web consumer
loads it: Pretendard Variable `v1.3.9` through jsDelivr and JetBrains Mono
weights 400/500/600 through Google Fonts. Upstream repositories identify both
font families as `OFL-1.1`, but provider terms, notices, activation decisions,
and the standard request metadata disclosed by an end-user browser remain
unresolved. Phase 0 does not authorize publication or activation of those
remote requests. The copyright-holder legal-name choice and the rights chain
for implementation historically transferred from `baro-app` also remain
publication blockers.

## Reproduction commands

Run from the BLDS repository root:

```bash
flutter pub get
dart run tool/validate_contract.dart
dart run tool/public_api_snapshot.dart --check
flutter analyze
flutter test
rg -l 'package:blab_design_system/blab_design_system.dart' \
  ../baro-app/app/lib ../baro-app/app/test
rg -n -A4 '^  blab_design_system:' ../baro-app/app/pubspec.yaml
rg -n 'blab_design_system|package:blab_design_system' \
  ../book-golas/app/pubspec.yaml ../book-golas/app/lib ../book-golas/app/test
```

Consumer repositories were dirty during inspection. The counts describe the
observed working trees, not a clean released product baseline.

## Phase 0 exit status

| Gate | Status | Owner / next evidence |
| --- | --- | --- |
| repository-owned SSOT direction | accepted and implemented | contract `0.1.0` plus validator |
| token naming layers | historical reference-preserved baseline | Phase 1 subsequently normalized typed layers without inventing values |
| accessibility policy | approved; implementation evidence absent | high contrast and exact text-scale range remain undecided |
| localization contract | approved boundary; reconciliation required | current English artifacts do not yet satisfy intended `ko-KR`; product target locales remain product-owned |
| export and top-level declaration inventory | superseded by stronger evidence | analyzer-backed snapshot |
| complete public API baseline | verified | deterministic checked-in snapshot plus `--check` |
| consumer baseline | verified with custody unknown | Engineering resolves `lbo728` versus `byungsker` remote |
| Astryx 0.1.3 provenance | verified for method study, including upstream tag and root NOTICE check | source-derived work remains separately blocked |
| BLDS license | MIT selected and implemented locally | publication remains separately authorized |
| font and asset distribution | ledger created; disposition open | Design and Legal complete and resolve the ledger before bundling |

The authorized local Phase 0 closeout remains complete. Phase 1 local
contract-pipeline implementation is now recorded in
`docs/BLDS_PHASE_1_STATUS.md`; this historical baseline is not the current
Phase 1 status, and Phase 1 remains subject to final independent verification
until the parent engineering gate closes it. Phase 2 is the shared interaction
and accessibility foundation; Phase 3 remediates the nine existing public
components sequentially; Phase 4 adds the evidence playground, goldens, and
platform matrix; and Phase 5 covers compatibility, migration, and release
readiness. There is still no accessibility, visual, or locale conformance
evidence. Consumer migration/release planning remains blocked on remote
custody, and font/asset bundling or derivative-source adoption remains blocked
on its provenance ledger and separate review.
