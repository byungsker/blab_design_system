# Astryx Capability Adoption Plan

Status: Phases 0–2 complete. Phase 3 Button, TextField, SegmentedControl,
TabBar, and BottomBar are implemented, verified, and independently approved.
PressableWrapper and Card are implemented with 19 repair-focused and 286
aggregate tests passing and both independent re-review gates approved.
Snackbar is implemented and its independent Design/Quality gates are approved.
KeyboardAccessoryBar is implemented locally with 43 focused tests passing,
including the Design-approved conditional narrow-width overflow addendum; its
valid minimum host allocation is 80px for Done-only, 128px with leading
actions but no history, and 129px with Undo or Redo. This guarantees one full
48px scrolling viewport, and smaller finite allocations are not conformance
evidence. Its
repaired parent aggregate passes; independent Design/Quality re-gates remain
open. Phase 4 local evidence infrastructure remains exit-blocked. Phase 5
compatibility, migration, rollback, rights/provenance, and release-readiness
preparation is implemented locally, but its exit, delivery, and publication
remain blocked.

As of: 2026-07-28

Owners: byungskerlab Design Team (contract) and Engineering Design System
Frontend (implementation)

## Decision

Use Astryx as an evidence source for design-system capabilities and operating
methods. Independently implement the selected capabilities for BLDS while
keeping Blab as the only semantic and visual authority.

The intended relationship is:

```text
byungskerlab Design Team
  owns Blab identity, semantics, accessibility policy, and platform intent
                         ↓
repository-owned machine-readable Blab contract
                         ↓
BLDS generators, Flutter adapters, components, tests, docs, and diagnostics
                         ↓
verified product consumers
```

Astryx React and StyleX code does not become BLDS Flutter code. Its neutral
theme, vocabulary, templates, and page composition do not become Blab.

## Why this work is needed

BLDS has a recognizable visual language, Flutter tokens, nine widgets, design
documentation, and an example application. Phase 0 added one repository-owned
machine-readable contract, contract-reference drift checks, and an
analyzer-backed public API drift check. Phase 1 implements deterministic token
generation, contract-only component state coverage, local diagnostics, and
pipeline verification. Phase 2 implements the bounded shared interaction and
accessibility foundation. Both phases have passed aggregate verification;
Phase 2's independent Design/Quality gates remain open. Phase 3 families 1 and
2 remediate
`BLabButton` and `BLabTextField`; the approved navigation boundaries remediate
`BLabSegmentedControl`, `BLabTabBar`, and `BLabBottomBar`. The preceding Phase
3 boundaries have independent approval and per-state automated evidence;
TabBar has approved Design authority and local implementation evidence. Its
native-semantics, label-interpolation, equal-width/RTL geometry, contrast, and
indicator-constraint repair passed the parent aggregate at 239/239. Direct
inspection then found and removed a redundant generic button flag from the
native tab semantics; the current aggregate passes 239/239 and the component
passed independent Design. Quality subsequently required post-layout reveal
reconciliation for viewport/content width changes, `Directionality`, and
scrollable re-entry. That narrow repair passes the current parent aggregate at
242/242. A subsequent Quality re-gate found selection-induced content-width
changes were excluded; that exclusion is removed and the current parent
aggregate first passed 243/243. The next Quality re-gate identified equal-total
width swaps; `selectedIndex` is now part of layout reconciliation, and the
correction passed its independent Quality re-gate.
SegmentedControl
additionally verifies narrow 44px targets,
fixed per-item indicator opacity/color motion, conditional owned overflow and
logical reveal, actual composited contrast pairs, public StatelessWidget
compatibility, and asynchronous controlled-focus retention. BottomBar has
approved Design authority and local family-partial source, contract,
semantics, keyboard, drag, four-mode, scaling, motion, and compatibility
evidence. BottomBar focused tests pass 23/23, the repository aggregate passes
267/267, and independent Design and Quality gates approved it. There
is no whole-Phase 3 claim. BLDS does not yet have the remaining
sequential component remediation, approved golden/platform surfaces, complete
consumer compatibility gates, or migration and release tooling.

Before Phase 0, the authority descriptions conflicted:

- the root README calls `docs/design/tokens.css` authoritative;
- the same README calls an external `blab-design` skill bundle the SSOT;
- `docs/design/README.md` calls the repository documents sources of truth;
- Dart files are manually described as CSS mirrors.

The approved `contracts/blab.design.yaml` contract now wins over those legacy
claims. Astryx 0.1.3 demonstrates useful implementations of typed themes, runtime and
static theme artifacts, structured component documentation, machine-readable
CLI output, diagnostics, upgrade registries, and detailed interaction and
accessibility contracts. Those are capability references, not Blab design
decisions.

## Evidence baseline

### BLDS

- Package version: `0.0.1`.
- Primary implementation: Flutter/Dart.
- Design artifacts: prose documents, CSS custom properties, manually mirrored
  Dart tokens, optional Figma mirror, and an external skill bundle.
- Components: Button, Card, TextField, BottomBar, TabBar, SegmentedControl,
  Snackbar, KeyboardAccessoryBar, and PressableWrapper.
- Tests: one package test file with a real root-library import, contract
  validation, and analyzer snapshot drift coverage; no declared golden or
  consumer matrix.
- Example: component stories used as a living showcase, not an automated
  state-completeness contract.
- License: standard MIT text selected by byungsker; publication remains
  separately authority-bound.
- Worktree baseline: `DESIGN.md` was already modified before this plan and is
  outside this change.

### OpenCS Map and installed Astryx

- Installed packages: `@astryxdesign/core`, `@astryxdesign/cli`, and
  `@astryxdesign/theme-neutral` 0.1.3.
- Package metadata identifies the Meta Astryx repository and MIT licensing.
- The lockfile records package tarball integrity.
- CLI and neutral theme ship MIT license files; the installed Core package
  declares MIT in package metadata but does not ship a root license file.
- `astryx doctor --json`: 4 pass, 2 warn, 0 fail, and 2 info.
- Warnings: the CLI does not detect the theme wiring and agent documentation
  has no managed Astryx markers. These do not establish a product defect,
  accessibility result, or Blab conformance.
- The executable CLI manifest exposes 15 top-level commands and 17
  JSON-capable entries. Installed documentation mentions `gap-report`, but the
  0.1.3 executable manifest does not expose it.
- OpenCS currently uses the Astryx Theme and LinkProvider, neutral theme,
  Button, CSS imports, and local token bridges. It is an incomplete,
  product-local integration and is not Blab-conformant evidence.

## Capability disposition

| Disposition | Capabilities |
| --- | --- |
| Adopt as methods and contracts | primitive → semantic → component traceability; typed theme contracts; runtime/static adapter separation; structured documentation metadata; machine-readable manifests; typed CLI result/error envelopes; side-effect-free diagnostics; accessibility state matrices; versioned migration registry |
| Independently implement in BLDS | canonical Blab schema; Dart/CSS/docs generation; Flutter ThemeExtensions; focus, keyboard, semantics, text scaling and reduced-motion behavior; widget/semantics/golden tests; BLDS doctor and manifest; API snapshots; migration tooling |
| Keep product-local in OpenCS | Astryx React/StyleX runtime; Theme; LinkProvider; generated Astryx web theme; Astryx CLI; Blab-to-Astryx adapter; course search, progress, completion dialog, notes, Korean copy, and product information architecture |
| Defer until Rule of Two | shared Blab web package; company-wide Astryx configuration; cross-framework component layer; shared progress, dialog, search, or course-navigation primitives |
| Reject | Astryx neutral theme as Blab; React/StyleX-to-Flutter translation; source swizzling into BLDS; bulk templates; public Astryx identity; forced framework migration; package health as a conformance claim |

## Target contract architecture

The approved repository-owned, platform-neutral contract is
`contracts/blab.design.yaml` version `0.2.0`. Phase 0 reference-locked existing
values by digest so it could establish authority without inventing a new token
taxonomy or changing Dart/CSS outputs. Phase 1 implemented the typed value and
additive generation model below while preserving existing standard-mode
sources.

```yaml
schema: blab.design/v1
metadata:
  owner: byungskerlab-design-team
  visual_authority: Blab
  contract_version: 0.x
  provenance: []
  approvals: []

tokens:
  primitive: {}
  semantic: {}
  component: {}

modes:
  light: {}
  dark: {}
  high_contrast: {}

platform_overrides:
  flutter: {}
  web: {}

accessibility:
  minimum_target: 44px
  focus: {}
  text_scaling: {}
  contrast: {}
  reduced_motion: {}

localization:
  source_locale: {}
  supported_locales: []
  audience_and_tone: {}
  glossary_ref: {}
  do_not_translate: []
  locale_formatting: {}
  layout_expansion: {}
  cultural_risk_review: {}
  product_overrides: {}

deprecations: []
outputs:
  - flutter_tokens
  - flutter_theme_extensions
  - css_custom_properties
  - component_state_manifest
  - documentation_tables
  - figma_mapping
  - traceability_matrix
```

The generated artifacts must carry generated-file headers and checksums. CSS,
Dart constants, documentation tables, Figma mappings, web themes, and agent
skill bundles become generated outputs or versioned distribution mirrors.
They must not compete for authority.

### Artifact disposition

| Artifact | Disposition | Phase 1 drift gate |
| --- | --- | --- |
| canonical Blab contract | implemented, hand-authored, Design-approved authority | schema, reference digest, approval, and provenance validation passes |
| Dart tokens and Flutter ThemeExtensions | existing standard-mode Dart preserved; additive generated data and ThemeExtension implemented | byte-for-byte `--check` |
| CSS custom properties | existing CSS preserved; additive generated CSS implemented | byte-for-byte `--check` |
| documentation token tables | generated canonical `ko-KR` token table implemented | byte-for-byte `--check` |
| component state manifest | generated Design applicability coverage implemented; six Button, twelve TextField, nine SegmentedControl, and eight TabBar states carry Phase 3 family evidence, qualified absence evidence stays family-scoped, unsupported states remain unclaimed, and every later component state remains unclaimed | schema, per-state evidence, family-scope, and coverage checks |
| traceability matrix | generated token and compatibility traceability implemented | reference resolution and byte-for-byte `--check` |
| Figma mapping manifest | local mapping generated; remote Figma not mutated | local mapping drift check only |
| web theme | deferred output until the OpenCS spike has an approved mapping and a second product proves a shared interface | excluded from Phase 1 acceptance |
| agent skill bundle | downstream versioned distribution mirror | excluded from Phase 1 acceptance; separately synchronized after repository checks |

Phase 1 does not mutate Figma, generate a shared web package, or update an
external skill bundle. Those surfaces consume a verified repository contract
through separately authorized workflows.

## Work plan

### Phase 0 — Authority, provenance, and baseline

Owner: Design Team with Engineering and Legal support.

Current packet:
[`BLDS_PHASE_0_BASELINE.md`](./BLDS_PHASE_0_BASELINE.md). It records the
observed API and consumer baseline, Astryx 0.1.3 provenance, accepted Design
contract, local verification, and remaining migration/publication limits.

Tasks:

- choose and document the repository-owned SSOT — completed;
- preserve primitive, semantic, and component values without inventing a new
  taxonomy — completed through a reference-locked digest manifest; typed
  normalization was subsequently implemented in Phase 1;
- define supported light, dark, high-contrast, text-scaling, reduced-motion,
  focus, haptic, and platform-override policies;
- approve a versioned localization contract with source and supported locales,
  audience, tone, glossary, do-not-translate identifiers, locale formatting,
  layout-expansion expectations, cultural-risk review metadata, product-local
  overrides, approval provenance, and an MQM-informed review method;
- explicitly distinguish BLDS documentation locales, product-owned customer
  target locales, and expansion/RTL test fixtures that are not supported
  locales;
- keep `Blab` and `Astryx` untranslated when they are identifiers; customer
  copy and terminology still require the applicable product glossary;
- inventory every public BLDS token, widget, variant, state, and consumer;
- identify real Flutter consumers instead of treating README examples as
  dependency evidence;
- record Astryx package, version, integrity, upstream revision, license,
  NOTICE status, included license files, derivation status, and reviewer;
- choose the BLDS license — completed with MIT — and document font and
  remote-asset distribution policy — ledger remains unresolved and blocks
  bundling.

Exit gate:

- versioned Design decision exists;
- the localization contract has a Design owner, version, intended source and
  documentation locales, actual artifact-language status, a reconciliation
  gate, product-owned target-locale boundary, versioned glossary and
  do-not-translate references, and explicitly classified expansion/RTL test
  fixtures;
- BLDS license is no longer a placeholder;
- an analyzer-backed public API baseline and the current consumer baseline are
  reproducible;
- provenance unknowns are either closed or explicitly block derivative work.

Exit result: the locally authorized contract, MIT, and analyzer snapshot gates
are complete. Canonical repository identity was subsequently resolved as
`byungsker/blab_design_system`, with `lbo728/blab_design_system` retained only
as a legacy redirect alias. Rights, delivery authority, and the asset/font
ledger remain separate blockers to migration/release and
bundling/derivative work. Phase 1 generation was subsequently implemented
locally and remains subject to final independent verification.

### Phase 1 — Contract pipeline

Owner: Engineering Design System Frontend.

Current state: implemented locally; the parent engineering gate must complete
final independent verification before Phase 1 is closed.

Tasks:

- implement schema validation and reference/cycle checks;
- generate Dart tokens, Flutter ThemeExtensions, CSS custom properties,
  documentation tables, Figma mappings, and a traceability matrix;
- add generated headers, deterministic ordering, and checksums;
- add a no-write `--check` mode and CI drift gate;
- expose a versioned capability manifest with structured JSON;
- implement a read-only BLDS doctor that distinguishes pass, warning, failure,
  and information and never claims visual or accessibility conformance;
- keep raw values legal only in the canonical primitive layer or documented
  platform overrides.

Exit gate:

- two consecutive clean generations produce byte-identical artifacts;
- the no-write check passes from a clean checkout;
- manual edits to generated outputs fail CI;
- every current Dart and CSS token is traced to the canonical contract or
  classified as legacy/deprecated.

### Phase 2 — Shared interaction and accessibility foundation

Owner: Engineering Design System Frontend; Design approves semantics.

Current state: implemented locally as additive Flutter foundations. The scoped
evidence and exact deferred boundary are recorded in
[`BLDS_PHASE_2_STATUS.md`](./BLDS_PHASE_2_STATUS.md). Parent aggregate
verification passed; independent Design/Quality gates remain open. No
individual component state implementation is inferred from the shared
foundation alone.

Tasks:

- define shared focus-visible and keyboard activation behavior;
- create reusable semantic-state mapping for disabled, loading, busy,
  selected, current, invalid, expanded, and destructive states;
- enforce 44×44 minimum interactive targets where applicable;
- respect supported text scaling and reduced motion;
- define focus order, overlay containment, dismissal, and focus restoration;
- make haptics explicit, configurable, and disabled where inappropriate;
- define light, dark, and supported high-contrast behavior.

Exit gate:

- widget and semantics tests cover the shared interaction foundations;
- keyboard-only and screen-reader-oriented checks have explicit evidence;
- text scaling and reduced motion do not rely on visual inspection alone.

### Phase 3 — Sequential remediation of existing public components

Current state: families 1 `BLabButton` and 2 `BLabTextField` and all three
boundaries of navigation family 3 are implemented locally. TabBar's
four-blocker repair passed a 239/239 parent
aggregate, and its subsequent native-tab generic-button cleanup also passed
independent Design and Quality. BottomBar now passes 23/23 focused and 267/267
aggregate verification plus both independent gates. Family 4 PressableWrapper
and Card is implemented and has passed 19/19 post-repair focused and 286/286
post-repair aggregate verification plus both independent gates. Family 5
Snackbar is implemented and has passed its focused and aggregate verification
plus both independent Design/Quality gates. Family 6 KeyboardAccessoryBar is
implemented locally with 43/43 focused tests, including the Design-approved
conditional narrow-width overflow addendum, deterministic contract/API
generation, and focused analyzer evidence; repaired parent aggregate and
contract gates pass, while its independent Design/Quality re-gates remain open.
The scoped packets include
[`BLDS_PHASE_3_BUTTON_STATUS.md`](./BLDS_PHASE_3_BUTTON_STATUS.md) and
[`BLDS_PHASE_3_TEXT_FIELD_STATUS.md`](./BLDS_PHASE_3_TEXT_FIELD_STATUS.md),
[`BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md`](./BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md),
[`BLDS_PHASE_3_TAB_BAR_STATUS.md`](./BLDS_PHASE_3_TAB_BAR_STATUS.md), and
[`BLDS_PHASE_3_BOTTOM_BAR_STATUS.md`](./BLDS_PHASE_3_BOTTOM_BAR_STATUS.md), plus
[`BLDS_PHASE_3_PRESSABLE_CARD_STATUS.md`](./BLDS_PHASE_3_PRESSABLE_CARD_STATUS.md)
and [`BLDS_PHASE_3_SNACKBAR_STATUS.md`](./BLDS_PHASE_3_SNACKBAR_STATUS.md).
KeyboardAccessoryBar adds
[`BLDS_PHASE_3_KEYBOARD_ACCESSORY_DESIGN_DECISION.md`](./BLDS_PHASE_3_KEYBOARD_ACCESSORY_DESIGN_DECISION.md)
and
[`BLDS_PHASE_3_KEYBOARD_ACCESSORY_STATUS.md`](./BLDS_PHASE_3_KEYBOARD_ACCESSORY_STATUS.md).

Remediate the nine existing public components sequentially, one component
family at a time. Do not redesign all components in a single migration.

Order:

1. `BLabButton`
2. `BLabTextField`
3. `BLabSegmentedControl`, `BLabTabBar`, and `BLabBottomBar`
4. `BLabPressableWrapper` and `BLabCard`
5. `BLabSnackbar`
6. `BLabKeyboardAccessoryBar`

For each component:

- document its public API, tokens, variants, applicable states, keyboard
  behavior, semantics, text scaling, reduced motion, and platform differences;
- test default, hover where supported, pressed, focus, disabled, loading,
  selected, validation, empty, overlay, and error states where applicable;
- preserve existing public interfaces or ship additive aliases and explicit
  deprecations;
- add one complete example story and approved visual baselines;
- record intentional differences from comparable Astryx behavior.

The repaired Button family uses explicit component hover tokens, separate
surface-outline and canvas-ring focus tokens, immediate exactly-once committed
activation, `BLabMotion.ease`, and `BLabRadius.md`. These are intentional
compatibility corrections, not legacy-retained values. Its capability id and
status are Button-family partial; they do not complete the generic
component-state capability or claim loading/busy.

The repaired TextField family preserves its standard surface, label, spacing,
radius, public API, and automatic-clear condition. Its hint, focus outline,
error copy, clear background, and clear foreground use Design-approved
compatibility corrections rather than legacy-retained values. State precedence
is disabled, enabled focus, unfocused invalid, unfocused pointer hover, then
default. It adds default-safe disabled, required, helper, and error conditions;
platform-native semantic relationships; pointer hover; keyboard-visible outer
focus; a localized 44x44 clear action; composited contrast evidence; ambient
linear/nonlinear scaling; reduced motion; and high-contrast resolution. Its
capability id and status are TextField-family partial; they do not complete the
generic component-state capability or claim loading, selected, or current
behavior.

Per-family exit gate:

- focused behavior, semantics, keyboard/focus, text-scale, reduced-motion, and
  applicable golden checks pass;
- the generated state manifest and documentation contain every applicable
  variant and state;
- public API and token snapshots are unchanged or the additive/deprecation
  change is approved and documented;
- `flutter analyze`, package tests, and example smoke pass;
- at least one confirmed representative consumer passes an analyze/build smoke
  against that family before work starts on the next family;
- the family can be rolled back without reverting completed independent
  families or consumer product data.

Progress, dialog, and search remain OpenCS-local until two real products need a
stable shared contract or byungsker approves an exception.

### Phase 4 — Evidence, playground, goldens, and platform matrix

Owner: Engineering Design System Frontend with independent Quality review.

Current state: safe local evidence infrastructure is implemented. The
machine-readable story manifest covers all nine public component contract ids
and every state currently marked `implemented-local`, while loading and
no-results remain explicitly unsupported instead of simulated. Ten
deterministic light/dark/high-contrast/text-scale/ko-KR/40-percent-expansion/
Arabic-RTL/reduced-motion/narrow candidate PNGs are checked in with paths,
dimensions, hashes, and `design-approved-local` status for reproducibility and
fixture review only. Every capture
geometrically frames all nine public families; Snackbar is held visible through
its public persistent API, including alongside KeyboardAccessoryBar in the
text-scale-2 and 360px narrow captures. Pinned OFL-1.1 Noto Sans KR and Noto
Sans Arabic fixture fonts from a single official `google/fonts` commit replace
the former Ahem-only text evidence in isolated test processes. They are
test-only fixtures registered under a process-local alias required by the
current widget styles, are not runtime Pretendard, and do not change production
font policy. Golden equality remains reproducibility evidence only. Design
reviewed all ten local baseline identities on 2026-07-28 under the
`byungskerlab-design-team` role, with evidence reference
`design-final-gate-handoff:button_contrast_standard_goldens:2026-07-28`; this
bounded approval is not visual or accessibility conformance. The
scenario environment is installed at `MaterialApp.builder` above the
Navigator/Overlay, and the persistent Snackbar surface asserts the same
brightness, high-contrast, text-scale, locale, direction, and reduced-motion
context as the other eight families. The synthetic expansion fixture is a
rune-count-only stress and makes no 40-percent rendered-width claim. The
previously compatibility-locked Button foreground residual is resolved by
decision `BLDS-BUTTON-CONTRAST-2026-07-28`; all ten exact golden identities
have bounded local Design approval, disabled contrast remains inactive-control
exempt/unverified, and no accessibility or visual conformance is claimed. Dart
`^3.10.4`, Flutter `>=3.38.5`, macOS-local package execution, a BLabButton-only
61/61 Chrome widget result with explicit non-support limitations, and a
syntax-validated Ubuntu/macOS/Windows CI configuration are recorded in
`contracts/platform-support.yaml`; no remote CI run is claimed. The
representative-consumer manifest confirms only baroguni as a direct package
consumer and preserves the missing second consumer boundary. Its read-only
preflight currently skips because the local checkout is dirty, while custody
and execution authority also remain unverified; no consumer command or
mutation occurred. Full status and rollback boundaries are in
[`BLDS_PHASE_4_STATUS.md`](./BLDS_PHASE_4_STATUS.md). Independent Quality
approval, remote matrix execution, physical-platform evidence, and
representative-consumer smoke remain open, so the Phase 4 exit gate is not
complete and no visual, accessibility, platform, consumer, or release
conformance is claimed. Any Phase 4 no-package-runtime or no-public-API
statement is scoped only to the exact delivery unit in
`contracts/delivery/phase4-custody.yaml`; it does not characterize unrelated
or pre-existing worktree changes. The exact ten path/hash identities are bound
by the non-generated Design approval artifact, while the separate Target
Delivery Contract remains typed `REQUEST_CHANGES` because its target version,
base/head, PR authority, and promotion path require a human decision. Local
evidence verification remains permitted and does not imply delivery readiness.

Tasks:

- expand the example app into a complete component and state playground;
- add widget, semantics, keyboard/focus, text-scale, reduced-motion, golden,
  public-export, and token-drift tests;
- declare the supported Flutter/Dart/platform matrix;
- add API snapshots and generated documentation consistency checks;
- add representative consumer analyze, test, and build jobs;
- record screenshots and golden approval ownership without treating golden
  equality as accessibility evidence.

Exit gate:

- every public component, variant, and applicable state appears in the
  playground and state manifest;
- `flutter analyze`, package tests, example build, and representative consumer
  checks pass on the declared matrix;
- Design approves visual baselines and Quality approves the evidence packet.

### Phase 5 — Compatibility, migration, and release readiness

Owner: Engineering; release remains byungsker-authorized.

Current state: local preparation is implemented. The immutable committed-HEAD
baseline plus approved Button correction provenance classifies 469 current
changes as additive and 2 token value changes as breaking compatibility
corrections under `BLDS-BUTTON-CONTRAST-2026-07-28`. Deprecated detection is
unsupported in Phase 5, so its result is typed unknown and no absence claim is
made. A no-source-rewrite migration and repository-artifact rollback rehearsal
passes in a disposable copy; there are zero repeated deterministic renames, so
a codemod is not applicable.
Rights/provenance and SBOM inventories preserve human unknowns. Package `0.0.1`
is local-unreleased with no release target.
The exact TDC, remote CI, two clean pinned Flutter consumers, Legal/Design
origin and font decisions, independent review, and final human authority
remain open. See `docs/BLDS_PHASE_5_STATUS.md`.

Tasks:

- classify token and API changes as additive, deprecated, or breaking;
- define a 0.x deprecation window and removal rules;
- generate migration maps and introduce codemods only for repeated,
  deterministic changes;
- maintain changelog, compatibility matrix, release checklist, and rollback
  instructions;
- verify at least two confirmed Flutter consumers before treating a component
  contract as stable shared evidence;
- keep OpenCS as a semantic web-adapter consumer, not as a second Flutter
  consumer and not automatic Rule-of-Two evidence for a shared web package.

Exit gate:

- migration rehearsal and rollback succeed on representative consumers;
- provenance and license review is complete;
- no unresolved Design, Quality, Legal, or consumer-compatibility blocker
  remains;
- publication is separately approved by byungsker.

## Separately authorized OpenCS adapter spike

Owner: `engineering-frontend` in the OpenCS repository.

Authority: separate product-source change authority is required; this BLDS
plan does not authorize the spike.

Entry dependency: Phase 0 produced the Design-approved semantic mapping and
provenance boundary. The spike remains separately authorized and may use a
product-local adapter, but it must not invent missing Blab semantics or treat
the locally implemented Phase 1 pipeline as shared-web-package authority.

OpenCS remains the bounded web experiment:

- pin the evaluated Astryx version exactly during the spike;
- centralize Blab mapping in one adapter/theme source, one provider boundary,
  and one generated CSS entry;
- remove customer-facing Astryx identity;
- preserve native or local fallbacks and avoid component swizzling;
- verify the home hero/CTA, catalog search/card, and lesson
  progress/completion surfaces only;
- preserve routes, course data, LocalStorage keys and schema,
  lesson-completion semantics, and learner notes as rollback invariants;
- measure bundle impact, custom CSS removed/added, keyboard/focus behavior,
  responsive behavior, Korean copy/layout, and adapter removal cost.

Spike exit gate:

- only the approved home hero/CTA, catalog search/card, and lesson
  progress/completion surfaces changed;
- Design reviews semantic and visual mapping without treating Astryx health as
  Blab conformance;
- normal text contrast, 44×44 targets, keyboard focus, completion-dialog focus
  containment/restoration, reduced motion, Korean typography/copy, 320px and
  375px layouts, and 200% zoom have evidence;
- project tests, lint, type/build, bundle comparison, and raw-value inventory
  pass within the approved thresholds;
- removing the adapter restores the captured baseline without changing routes,
  course data, LocalStorage, completion semantics, or notes.

The OpenCS result does not block BLDS Phases 1–5. It informs future web adapter
decisions and may expose missing semantic contracts that Design must route
back into BLDS separately.

OpenCS uses `ko-KR` as its product source locale. Its roadmap, catalog, lesson
workspace, study-guide, timestamp, transcript, and course terms remain
in a product-local glossary unless Design separately approves a term as shared
Blab language.

The adapter becomes a shared Blab Web candidate only after a second real web
product needs the same stable interface.

## Acceptance contract

No phase may claim Blab conformance from generation, doctor, build, tests, or
goldens alone. Completion evidence must include:

- a Design-approved canonical contract and traceability matrix;
- deterministic generation and a clean no-write drift check;
- no unexplained raw visual or motion values outside approved layers;
- complete applicable state matrices;
- tested names, roles, values, current/selected/invalid/busy semantics;
- keyboard activation, focus order, overlay containment, and restoration;
- verified targets, contrast, text scaling, themes, and reduced motion;
- complete playground and approved visual baselines;
- declared package/platform compatibility and representative consumer builds;
- classified public API/token differences with migration instructions;
- provenance, license, NOTICE, derivation, and reviewer records;
- localization evidence covering supported locales, terminology, formatting,
  truncation/expansion, product overrides, and recorded cultural-risk review;
- a rehearsed rollback path.

## Migration and rollback

BLDS changes are additive first:

1. capture current contract, API, screenshots, and consumers;
2. introduce generated aliases for existing public tokens and exports;
3. migrate one component family at a time;
4. announce deprecations before removals;
5. keep the previous canonical contract and generated artifact set available
   for rollback during the migration window.

Rollback restores the previous contract and regenerates all outputs. Generated
files must never be manually repaired. A failed consumer migration rolls back
only that phase and does not require reverting unrelated Design documentation
or product data.

Migrated component source evidence preserves both layers: the immutable Phase 0
digest remains historical evidence, while a separate current digest is the
only value compared with the current source. A migration must never overwrite
the Phase 0 source digest.

## Risks and open decisions

| Risk or decision | Owner | Required disposition |
| --- | --- | --- |
| Conflicting SSOT claims | closed for repository authority | `contracts/blab.design.yaml` is authoritative; mirrors are downstream |
| BLDS license | MIT implemented locally | release/publication still requires separate authority |
| Astryx exact upstream revision and root NOTICE status | resolved for method study | source-derived redistribution review remains required before copying any substantial source or documentation |
| Core package lacks a root installed license file | Legal/Engineering | verify upstream artifact and distribution obligations |
| Canonical repository identity | resolved for repository identity only | use `byungsker/blab_design_system`; treat `lbo728/blab_design_system` as a legacy redirect alias; rights and delivery authority remain separate |
| High-contrast and text-scaling contract | resolved for Phases 1–2 | additive light/dark high-contrast tokens and ambient linear 1.0–2.0 plus nonlinear scaling have focused local evidence; no component or conformance claim |
| Shared localization boundary | approved with reconciliation required | current English artifacts do not yet satisfy intended `ko-KR`; product target locales remain product-owned |
| Web sharing lacks Rule-of-Two evidence | byungsker/Design | keep OpenCS adapter local unless a second product proves need |
| Astryx docs and executable manifest differ | Engineering | treat the installed executable manifest as version-specific truth |
| protected `DESIGN.md` differs from canonical `main` | resolved for this exact delivery only | restore only the owner-approved protected bytes with SHA-256 `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`; no reinterpretation or expected-hash change |

## Authority boundaries

Design Team owns Blab semantics, visual identity, accessibility policy,
terminology, localization, new shared primitives, and conformance review.
Engineering owns implementation, generation, tests, compatibility, migration,
diagnostics, and rollback evidence.

Only byungsker may approve a Rule-of-Two exception, BLDS license choice,
shared-package activation, publication, release, or public conformance claim.
This plan authorizes none of those actions.
