<div align="center">

# BLab Design System

**Calm, polished, trustworthy — a Liquid Glass design language for modern products.**

A Flutter UI component library that ships Blab's design tokens and Liquid Glass
widgets. Blab is the shared design language for byungskerlab products; direct
consumption of this Flutter package is verified separately per product.

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.38.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart SDK](https://img.shields.io/badge/Dart-%5E3.10.4-0175C2?logo=dart)](https://dart.dev)
[![Style](https://img.shields.io/badge/style-Liquid%20Glass-5B7FFF)](./docs/design/BRAND.md)

</div>

---

## Table of contents

- [Why BLab](#why-blab)
- [Install](#install)
- [Quick start](#quick-start)
- [Design tokens](#design-tokens)
- [Components](#components)
- [Architecture & SSOT](#architecture--ssot)
- [Phase 1 through Phase 3 component status](#phase-1-through-phase-3-component-status)
- [Design docs](#design-docs)
- [Versioning & compatibility](#versioning--compatibility)
- [License](#license)
- [Contributing](#contributing)

## Why BLab

BLab is the visual identity behind Byungsker's products. It is built around a single idea:

> Interfaces should feel **deliberate, smooth, and lightweight** — never noisy, never decorative, never dense-without-hierarchy.

The defining motif is **Liquid Glass** — translucent pill-shaped surfaces that float over content, with heavy backdrop blur, a hairline border, and an inner top-edge highlight that reads as refracted light.

| Principle | What it means in practice |
|---|---|
| Prefer semantic tokens over raw values | No arbitrary colors, spacing, radius, or elevation values in components |
| Consistency before novelty | Reuse patterns before inventing new ones |
| Motion improves clarity, not decoration | 150–300ms, easing `cubic(0.4, 0, 0.2, 1)`, respect reduced motion |
| Accessibility is required | 4.5:1 contrast, 44×44 touch targets, visible focus rings |

`DESIGN.md` is an unreconciled legacy draft with protected pre-existing
changes. It is useful background, but it cannot supply implementation decisions
until Design reviews it against the authoritative contract.

## Install

```yaml
# pubspec.yaml
dependencies:
  blab_design_system:
    git:
      url: https://github.com/byungsker/blab_design_system.git
      ref: main   # pin to a tag for production: ref: v1.0.0
```

Then:

```bash
flutter pub get
```

The canonical repository is
`https://github.com/byungsker/blab_design_system`. GitHub currently redirects
the legacy `lbo728/blab_design_system` address to that repository. Existing
consumer pins should migrate to the canonical URL during an independently
authorized consumer change; this README is not release evidence.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:blab_design_system/blab_design_system.dart';

void main() => runApp(const BLabApp());

class BLabApp extends StatelessWidget {
  const BLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello BLab',
      theme: BLabTheme.light,
      darkTheme: BLabTheme.dark,
      home: const Scaffold(body: _Demo()),
    );
  }
}

class _Demo extends StatelessWidget {
  const _Demo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(BLabSpacing.lg),
      child: BLabCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome', style: BLabTypography.h2),
            SizedBox(height: BLabSpacing.sm),
            Text(
              'Calm, polished, trustworthy.',
              style: BLabTypography.body.copyWith(
                color: BLabColors.textSecondary(context),
              ),
            ),
            SizedBox(height: BLabSpacing.lg),
            BLabButton(text: 'Get started', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
```

## Design tokens

The authoritative source is the versioned
[`contracts/blab.design.yaml`](./contracts/blab.design.yaml) contract, owned
semantically by byungskerlab Design and implemented by Engineering. Phase 1A
normalizes the approved contract into typed primitive, semantic, and component
layers while retaining the complete Phase 0 reference manifest as compatibility
evidence. Existing standard-mode token/widget sources remain hand-maintained;
the generator writes additive owned outputs only.

| Category | Import | Representative API |
|---|---|---|
| **Color** | `BLabColors` | `primary`, `textPrimary(context)`, `surface(context)`, `borderSubtle(context)` |
| **Typography** | `BLabTypography` | `display`, `h1`, `h2`, `title`, `subtitle`, `body`, `caption`, `label`, `button`, `tab`, `code` |
| **Spacing** | `BLabSpacing` | `xs` (2), `sm` (8), `md` (16), `lg` (20), `xl` (24), `xxl` (32) |
| **Radius** | `BLabRadius` | `xs` (6), `sm` (10), `md` (12), `lg` (16), `xl` (20), `pill` (100) |
| **Shadow** | `BLabShadow` | `one(context)`, `two(context)`, `three(context)`, `float(context)` |
| **Motion** | `BLabMotion` | `ease` (cubic 0.4/0/0.2/1), `durPress` 150ms, `durSegment` 180ms, `durSurface` 300ms |
| **Glass** | `BLabGlass` | `blur` 25, `fill(context)`, `border(context)`, `highlight(context)` |

Both **light** and **dark** modes are first-class; context-aware accessors (`BLabColors.surface(context)`) flip automatically.

## Components

9 Liquid Glass widgets live under `lib/src/widgets/`. They consume many of the
tokens above, but the verified Phase 0 baseline still contains component-local
raw values and intentional deviations. The reference-locked contract preserves
that state; it does not claim completed token traceability or Blab conformance.

| Widget | Purpose |
|---|---|
| `BLabButton` | Primary / Secondary / Destructive CTA with explicit touch-only haptic policy |
| `BLabCard` | Glass-fill container with 16px radius, 20px padding |
| `BLabTextField` | Text input with label, helper/error relationships, required/disabled semantics, and localized clear action |
| `BLabBottomBar` | Controlled bottom navigation with native tab semantics, roving keyboard focus, touch drag, and conditional action/disclosure |
| `BLabTabBar` | Controlled in-screen tab switcher with equal-width or owned scrollable navigation |
| `BLabSegmentedControl` | Controlled segmented picker with disabled items, roving keyboard focus, and selected semantics |
| `BLabSnackbar` | Floating toast with `success / error / warning / info` types |
| `BLabKeyboardAccessoryBar` | iOS-style keyboard toolbar (navigation, copy, undo/redo, done) |
| `BLabPressableWrapper` | Press-scale + brightness overlay + haptics primitive |

Each widget supports light and dark mode out of the box.

## Architecture & SSOT

Blab's Single Source of Truth is the repository-owned, machine-readable
[`contracts/blab.design.yaml`](./contracts/blab.design.yaml) contract.

```
                    contracts/blab.design.yaml  ◄── authoritative
                                  │
                 ┌────────────────┼────────────────┐
                 ▼                ▼                ▼
       Flutter/Dart outputs    CSS/docs       mappings/manifests
                 │                │                │
                 └────────────────┼────────────────┘
                                  ▼
                  components, examples, and tests
                                  │
                                  ▼
                  Figma and agent-skill mirrors
```

- **Design owns semantics:** identity, token meaning, accessibility and
  localization policy, component intent, and approved platform differences.
- **Engineering owns implementation:** validation, generation, Flutter
  adapters, tests, compatibility, migration, and rollback evidence.
- **Astryx is capability evidence only:** the implementation owner states,
  without a signed attestation, that the intended scope was methods and
  contract patterns only. Copy, derivation, value, and identity adoption facts
  remain unknown pending a signed, scope-bound attestation.
- **Figma and skill bundles are downstream mirrors:** Phase 0 did not mutate
  either surface.

Run `dart run tool/generate_tokens.dart --write` to regenerate the additive
Dart data, exported ThemeExtension, CSS custom properties, traceability matrix,
canonical `ko-KR` token table, repository-local Figma token mapping,
component-state coverage, and versioned capability manifest. Use `--check` in
CI or review workflows. Every generated artifact records its source and content
checksums; JSON artifacts carry the same provenance in a structured
`_generated` envelope. Generation never calls or mutates Figma.

## Phase 1 through Phase 3 component status

The locally authorized Phase 1 contract pipeline is implemented. Phase 1A
established the typed token foundation, and Phase 1B completes the local
generated-document, manifest, diagnostic, and verification surfaces:

- approved contract `0.2.0` with typed primitive, semantic, and component
  structures, including 146 typed tokens;
- exact standard light/dark compatibility inventory for 134 CSS names and 139
  Dart symbols, plus source-extracted classification of 300 component-local
  numeric and color literal occurrences;
- additive `BLabTokenTheme` support for light, dark, high-contrast light, and
  high-contrast dark;
- deterministic Dart, CSS, and Markdown generation with write/check modes;
- canonical `ko-KR` token documentation for 146 typed tokens;
- a local-only Figma mapping for the same 146 token IDs, with no remote call;
- Design applicability coverage for 9 components, 70 applicable state
  contracts, and 28 qualified absence-evidence entries; it began contract-only
  and now carries only six proven Button, twelve proven TextField, and nine
  proven SegmentedControl plus eight proven TabBar implementation claims, with
  qualified family-scoped absence evidence;
- a versioned 16-entry capability manifest derived from canonical capability
  data;
- a read-only offline `BLDS doctor` with human and typed JSON output, stable
  severity classification, deterministic ordering, and failure-only nonzero
  status;
- an aggregate local verification command and a secret-free GitHub Actions
  verification workflow with no release job;
- graph/reference/cycle/duplicate/path/output-status validation and drift
  tests;
- analyzer-backed checked-in public API snapshot including the additive API.

Phase 2 is also implemented locally as a bounded, additive shared interaction
and accessibility foundation. The current parent aggregate passes 413/413
package tests; independent Design/Quality gates remain open. Focus visibility and surface-aware focus
tokens, Enter/Space activation, typed semantic state, 44x44 target policy,
ambient text scaling through 2.0 plus nonlinear scaling, reduced motion,
light/dark/high-contrast resolution, default-deny haptic eligibility, and
focus-owned overlays have focused evidence.

Phase 3 family 1, `BLabButton`, now adopts those foundations locally. Its six
required states—default, pointer hover, pressed, focus, disabled, and
destructive variant—have focused automated evidence. Loading/busy has no API
or runtime condition and remains unclaimed; invalid absence is observable
through Flutter validation semantics, while current and loading/busy absence
are only typed/code-inspection evidence. Selected/current/invalid/expanded are
not simulated. Hover uses variant/mode component tokens, and focus paints
separate surface outline and canvas outer-ring treatments with verified
adjacent contrast. Immediate committed activation, `BLabMotion.ease`, and the
12px Button radius are intentional compatibility corrections rather than
legacy-retained behavior. The only additive component API is a default-deny
`hapticConfiguration`; existing calls still compile, while eligible touch
haptics now require explicit platform, system, accessibility, and component
gates. See
[`docs/BLDS_PHASE_3_BUTTON_STATUS.md`](./docs/BLDS_PHASE_3_BUTTON_STATUS.md).

Phase 3 family 2, `BLabTextField`, now has bounded local evidence for all
twelve Design-applicable required and conditional states: empty, populated,
pointer hover, focus, read-only, obscured, multiline, disabled, required,
invalid, error/help, and clear action. Four additive parameters remain
default-safe: `helperText`, `errorText`, `enabled`, and `isRequired`. Label,
hint, value, support/error, required, and invalid relationships augment the
native editable semantics; the automatic clear affordance keeps its existing
condition while adopting Design-approved hint, focus, error-copy, and clear
contrast corrections, a localized label, and a 44x44 target. Disabled takes
precedence over focus and invalid borders; enabled focus takes precedence over
invalid and hover borders. These are compatibility corrections, not
legacy-retained visual values.
No prefix, autofill, loading, selected, current, visibility-toggle, keyboard
configuration, or product validation copy is invented. See
[`docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md`](./docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md).

The first approved navigation boundary, `BLabSegmentedControl`, now implements
the Design decision
`BLDS-PHASE3-NAVIGATION-SEGMENTED-DESIGN-DECISION-2026-07-26`. Its controlled
selection model remains source compatible, with only default-safe `enabled`
parameters added to items and the control; the public control remains a
`StatelessWidget` backed by private interaction state. It has family-scoped evidence for
unselected, selected, pointer hover, pressed, keyboard-visible focus,
controlled selection, conditional disabled and scrollable-overflow behavior,
and enabled-only roving keyboard focus. Exact four-mode
`component.segmented` tokens, 44×44 targets, conditional owned horizontal
overflow without narrow target shrinkage, stable per-item 180ms opacity/color
indicators, caller-owned mutually-exclusive semantics, RTL traversal and
physical scroll actions, ambient text scaling, and reduced motion are covered
locally. See
[`docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md`](./docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md).

The second approved navigation boundary, `BLabTabBar`, implements
`BLDS-PHASE3-NAVIGATION-TABBAR-DESIGN-DECISION-2026-07-26` without changing
its constructor, caller-owned `TabController`, defaults, localized labels, or
public `StatelessWidget` inheritance. Eight required/conditional states have
family-scoped evidence: unselected, selected-current, hover, pressed,
keyboard-visible focus, controller-controlled selection, roving keyboard
focus, and `isScrollable` overflow. It uses exact four-mode `component.tab`
tokens, 44×44 targets in a 56px minimum bar, confirmed-tap focus ownership,
exactly-once activation callbacks, LTR/RTL Arrow/Home/End traversal,
Enter/Space activation, private non-primary reveal, native horizontal scroll
semantics, unclamped ambient scaling, and immediate reduced-motion behavior.
No disabled or unsupported state is simulated. See
[`docs/BLDS_PHASE_3_TAB_BAR_STATUS.md`](./docs/BLDS_PHASE_3_TAB_BAR_STATUS.md).

The third approved navigation boundary, `BLabBottomBar`, now has local
family-partial implementation evidence for controlled selection/reactivation,
native tab semantics, roving keyboard focus, RTL-correct touch drag, four-mode
component tokens, reduced motion, scaling, safe area, and the conditional
action/disclosure contracts. Parent Flutter verification and independent
Design/Quality gates are complete at 23/23 focused and 267/267 aggregate
tests; no device or global conformance is claimed. See
[`docs/BLDS_PHASE_3_BOTTOM_BAR_STATUS.md`](./docs/BLDS_PHASE_3_BOTTOM_BAR_STATUS.md).

Decision `BLDS-BUTTON-CONTRAST-2026-07-28` changes the standard primary and
destructive foreground pairings to black while preserving their surfaces,
overlays, focus, geometry, motion, and already-black high-contrast mappings.
Composed default, hover, pressed, and focus checks now pass the 4.5:1 active
normal-text target. Disabled contrast remains inactive-control
exempt/unverified, loading/busy remains not claimed, and this repair does not
authorize a Button or repository-wide accessibility or visual conformance
claim.

This is not a consumer migration, package publication, accessibility
conformance result, visual conformance result, locale conformance result, or
release approval. Standard-mode tokens outside the two approved Button
foreground exceptions and all later component sources remain unchanged;
Button standard surfaces remain compatibility-locked. Consumers may add
`BLabTokenTheme.light` or another approved mode to `ThemeData.extensions`
without replacing current APIs. Phase 2 rollback removes that extension and
its additive foundation exports. Button, TextField, and SegmentedControl
rollback are separately family-scoped in their status packets; none involves
persisted data migration.

Run the offline diagnostics directly:

```bash
dart run tool/blab_doctor.dart
dart run tool/blab_doctor.dart --json > /tmp/blab-doctor.json
dart run tool/validate_doctor_json.dart /tmp/blab-doctor.json
```

Warnings about remote font/assets and release authority are expected until
their separate evidence or human-authority gates are resolved. Repository
identity is recorded as resolved by local evidence. The doctor performs no
telemetry or external service call.

## Design docs

The prose side of the system lives under [`docs/design/`](./docs/design/). Read in this order:

1. [`BRAND.md`](./docs/design/BRAND.md) — personality, tone, surface philosophy
2. [`TOKENS.md`](./docs/design/TOKENS.md) — naming conventions for color, type, spacing, radius, elevation, glass
3. [`COMPONENTS.md`](./docs/design/COMPONENTS.md) — shared component rules (buttons, cards, inputs, …)
4. [`PATTERNS.md`](./docs/design/PATTERNS.md) — multi-component patterns (forms, lists, empty/loading/error states)
5. [`MOTION.md`](./docs/design/MOTION.md) — timing, easing, reduced-motion rules
6. [`A11Y.md`](./docs/design/A11Y.md) — contrast, focus, touch targets, forms, modals
7. [`DO_DONT.md`](./docs/design/DO_DONT.md) — contributor do's and don'ts
8. [`ASTRYX_CAPABILITY_ADOPTION_PLAN.md`](./docs/ASTRYX_CAPABILITY_ADOPTION_PLAN.md) — phased capability adoption, authority, evidence, migration, and rollback gates
9. [`BLDS_PHASE_0_BASELINE.md`](./docs/BLDS_PHASE_0_BASELINE.md) — accepted authority decisions, verified API/consumer baseline, provenance, and remaining limits
10. [`BLDS_PHASE_1_STATUS.md`](./docs/BLDS_PHASE_1_STATUS.md) — implemented local pipeline, evidence counts, limitations, and rollback
11. [`BLDS_PHASE_2_STATUS.md`](./docs/BLDS_PHASE_2_STATUS.md) — shared interaction and accessibility foundations, evidence, and deferred component adoption
12. [`BLDS_PHASE_3_BUTTON_STATUS.md`](./docs/BLDS_PHASE_3_BUTTON_STATUS.md) — Button-only state, API, accessibility, compatibility, and rollback evidence
13. [`BLDS_PHASE_3_TEXT_FIELD_STATUS.md`](./docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md) — TextField-only state, semantics, API, compatibility, and rollback evidence
14. [`BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md`](./docs/BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md) — exact approved SegmentedControl visual, state, input, semantics, and compatibility contract
15. [`BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md`](./docs/BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md) — approved fixed indicator and conditional owned-overflow correction
16. [`BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md`](./docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md) — SegmentedControl-only implementation, evidence, compatibility, limitations, and rollback
17. [`BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md`](./docs/BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md) — exact approved TabBar visual, state, controller, keyboard, semantics, overflow, and compatibility contract
18. [`BLDS_PHASE_3_TAB_BAR_STATUS.md`](./docs/BLDS_PHASE_3_TAB_BAR_STATUS.md) — TabBar-only implementation, evidence, compatibility, limitations, and rollback
19. [`BLDS_PHASE_3_BOTTOM_BAR_DESIGN_DECISION.md`](./docs/BLDS_PHASE_3_BOTTOM_BAR_DESIGN_DECISION.md) — approved BottomBar state, token, interaction, semantics, and compatibility contract
20. [`BLDS_PHASE_3_BOTTOM_BAR_STATUS.md`](./docs/BLDS_PHASE_3_BOTTOM_BAR_STATUS.md) — BottomBar-only implementation, evidence, compatibility, limitations, and rollback
21. [`BLDS_PHASE_4_STATUS.md`](./docs/BLDS_PHASE_4_STATUS.md) — local story, candidate-baseline, platform, consumer-preflight, and custody evidence
22. [`BLDS_PHASE_5_STATUS.md`](./docs/BLDS_PHASE_5_STATUS.md) — local compatibility, migration, rights/provenance, release-readiness preparation, and exact blockers
23. [`BLDS_COMPATIBILITY_MATRIX.md`](./docs/BLDS_COMPATIBILITY_MATRIX.md) — declared floors, local evidence, consumers, and unverified platforms
24. [`BLDS_RELEASE_CHECKLIST.md`](./docs/BLDS_RELEASE_CHECKLIST.md) — completed local preparation and authority-bound release gates
25. [`BLDS_PHASE_5_ROLLBACK.md`](./docs/BLDS_PHASE_5_ROLLBACK.md) — disposable rehearsal and repository-artifact rollback procedure
26. [`BLDS_TARGET_DELIVERY_PROPOSAL.md`](./docs/BLDS_TARGET_DELIVERY_PROPOSAL.md) — exact full-repository, repository-only Target Delivery Contract proposal

## Versioning & compatibility

- Dart SDK: `^3.10.4` · Flutter: `>=3.38.5` (the verified Phase 0 floor)
- The checked-in [`api/blab_design_system.api.txt`](./api/blab_design_system.api.txt)
  file is the analyzer compatibility baseline. Any change requires review and
  deliberate snapshot regeneration.
- Analyzer, YAML, and digest tooling dependencies are exactly pinned. The root
  lockfile remains intentionally ignored because this repository is a library;
  `flutter pub get` resolves the compatible tool graph.
- Phase 5 compares the current API and token contract with immutable
  committed-`HEAD` baselines. The current result is 469 additive and 2
  breaking token value corrections approved under
  `BLDS-BUTTON-CONTRAST-2026-07-28`; deprecated detection is explicitly
  unsupported with a typed unknown result. Package `0.2.0` is the accepted
  repository-only target and remains local and unreleased; this result is not
  release or publication evidence.

## License

The source is presently designated by the repository for MIT in
[`LICENSE`](./LICENSE), using SPDX identifier `MIT` and the observed copyright
notice `Copyright (c) 2026 byungsker and byungskerlab`, subject to unresolved
copyright-holder, notice, transfer, and contributor authority. This local
designation does not authorize a release or publication and does not establish
the legal-name choice or contribution rights chain. Third-party fonts, icons,
assets, and any future copied material retain separate provenance and notice
requirements.

## Contributing

- **Do** prefer semantic tokens over raw values. **Don't** introduce arbitrary colors, spacing, or radii.
- **Do** reuse existing component patterns. **Don't** duplicate a widget with a new name just to tweak one style.
- If a new visual rule is needed, propose an update to the relevant file in [`docs/design/`](./docs/design/) first.
- Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages (`feat:`, `fix:`, `refactor:`, …).

### Local development

```bash
flutter pub get
dart run tool/validate_contract.dart
dart run tool/generate_tokens.dart --check
dart run tool/public_api_snapshot.dart --check
dart run tool/classify_compatibility.dart --json
dart run tool/generate_phase5_inventories.dart --check
dart run tool/rehearse_phase5_migration.dart
dart run tool/validate_phase5_readiness.dart
dart run tool/blab_doctor.dart
dart run tool/verify.dart
dart run tool/validate_diff_hygiene.dart
```

---

<sub>Made with care for the Byungsker product family.</sub>
