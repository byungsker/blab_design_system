# BLDS Phase 2 shared interaction and accessibility foundation

Status: Implemented locally; current parent aggregate verified; independent
Design/Quality gates pending

As of: 2026-07-25

Contract version: `0.2.0`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

Historical boundary: this packet records the Phase 2 completion state before
component adoption. Phase 3 family 1 subsequently changed `BLabButton` and six
Button manifest entries only; see `BLDS_PHASE_3_BUTTON_STATUS.md`. All other
component and claim boundaries in this packet remain unchanged.

## Authority and claim boundary

Phase 2 implements the smallest shared Flutter interaction and accessibility
foundation approved by `contracts/blab.design.yaml`. Blab remains the visual
and semantic authority. This implementation does not change standard light or
dark visual values, product vocabulary, product copy, or any existing public
component implementation.

The implementation and tests are local engineering evidence only. They do not
authorize release, publication, package activation, or a Blab accessibility,
visual, localization, locale, consumer, or package conformance claim.
`generated/component-state-coverage.yaml` remains contract-only evidence with
every applicable state marked `implementation_evidence: not-claimed`.

## Design contract to code traceability

| Approved contract | Public implementation | Focused evidence |
| --- | --- | --- |
| modality-aware visible focus and logical traversal | `BLabFocusVisibilityController`, `BLabFocusVisibilityScope`, `BLabInputModality`, `BLabTraversalIntent` | keyboard, touch, pointer decision, reset, owned-scope lifecycle |
| Enter/Space activation and repeated-action suppression | `BLabKeyboardActivationController`, `BLabKeyboardActivator`, `BLabActivationIntent` | one callback per physical key cycle; disabled and busy suppression; focus-loss and app-lifecycle reset |
| typed interaction semantics | `BLabSemanticInteractionState` and typed availability, activity, selection, current, validation, disclosure, and label/value relationship enums | enabled maps only availability; selected maps only selection; current, loading/busy, and destructive remain typed |
| 44x44 logical-pixel pointer target | `BLabInteractiveTargetPolicy`, `BLabInteractiveTargetKind`, `BLabInteractiveTarget` | layout enforcement and runtime rejection of blank exception reason or Design decision/review reference |
| ambient linear and nonlinear scaling, 1.0 through 2.0 inclusive | `BLabTextScalingPolicy`, `BLabTextScalingEvidence` | ambient 1.0, 1.3, 2.0 linear scalers and a nonlinear scaler, without clamping |
| platform reduced-motion signals and approved duration bounds | `BLabReducedMotionPolicy`, `BLabTransitionRole` | `disableAnimations`/`accessibleNavigation`, zero nonessential duration, nonzero essential-opacity bound |
| additive light/dark high contrast and focus visuals | `BLabVisualModeResolver`, `BLabResolvedVisualMode`, `BLabFocusVisualResolver`, `BLabFocusVisualStyle`, `BLabFocusSurface` | generated 2px outline/3px ring geometry; canvas/surface/accent color and 3:1 value tests, including high-contrast black on accent |
| explicit touch-only haptic policy | `BLabHapticPolicy`, required configuration gates, intent, trigger, decision, reason, and `BLabHapticActionCycle` | default deny; platform, system, accessibility, component, modality, disabled, busy, no-op; one pulse reservation per committed action; reset/dispose/multiple actions |
| focus-owned modal/overlay coordination | `BLabFocusOwnedOverlay`, `BLabInitialFocusPolicy`, `BLabOverlayDismissIntent` | immediate previous-focus capture, safe invalid-focus fallback, Tab/directional closed loops, Escape, coordinated topmost-owner platform back, complete nested-tree restoration, idempotent restoration/disposal |

## Flutter semantic mapping

Flutter `SemanticsProperties` does not expose dedicated `current`,
`busy/loading`, or `destructive` fields. Phase 2 therefore preserves these as
typed Blab state without collapsing them into unrelated Flutter fields:

- Flutter `selected` is derived only from Blab selection;
- Flutter `enabled` is derived only from Blab availability;
- loading and busy suppress activation without presenting the control as
  disabled;
- current, activity, and destructive remain typed for the later Phase 3
  adapter and announcement contract; and
- no product-facing fallback label, value, status text, or announcement copy is
  invented.

This is an implementation-shape adaptation, not a change to the approved Blab
semantic contract.

## Component and state boundary

Phase 2 provides opt-in foundations for later Phase 3 component adoption. It
does not modify or claim state implementation for `BLabButton`,
`BLabTextField`, `BLabSegmentedControl`, `BLabTabBar`, `BLabBottomBar`,
`BLabPressableWrapper`, `BLabCard`, `BLabSnackbar`, or
`BLabKeyboardAccessoryBar`.

In particular:

- no existing component is wrapped by the new target or activation helpers;
- no typography is changed or clamped;
- no component duration is changed;
- no high-contrast theme is activated globally;
- no haptic side effect is performed; and
- `BLabSnackbar` and every other Phase 3 component remain byte-preserved.

## Accessibility and visual evidence

`test/phase2_foundation_test.dart` contains focused unit and widget evidence
for the Phase 2 contracts. Automated semantics and focus tests are
screen-reader-oriented evidence, but no real assistive-technology session or
public conformance audit is claimed.

There are no new golden images or visual-baseline approvals. The visual
baseline manifest remains approved workflow metadata with no images. The only
additive visual foundation is canonical/generated focus geometry and
surface-aware color tokens; no component applies them. Phase 2 does not add or
modify assets, fonts, Figma data, or remote services.

## Local verification

The implementation-owner verification completed:

- focused Dart formatting: clean, 0 files changed on the final check;
- `flutter test test/phase2_foundation_test.dart`: 59/59 passed, including
  nested platform-back child/parent dismissal and focus restoration;
- `flutter analyze --no-pub`: no issues;
- `dart run tool/validate_contract.dart`: passed with bounded Phase 2
  implementation evidence and canonical Phase 3/4/5 capability routing
  cross-validation;
- two consecutive `dart run tool/generate_tokens.dart --write` runs produced
  byte-identical output across all eight deterministic destinations;
- `dart run tool/generate_tokens.dart --check`: passed;
- `dart run tool/public_api_snapshot.dart --check`: passed after the reviewed
  additive snapshot update;
- doctor JSON schema/content validation: passed with 5 pass, 3 expected
  warnings, 0 failures, and 1 information;
- all nine Phase 3 component source digests: matched the approved contract;
- `generated/component-state-coverage.yaml`: 67 applicable-state
  `implementation_evidence: "not-claimed"` rows, plus 1 metadata-level
  `not-claimed` marker, and 0 implementation claims;
- `DESIGN.md` SHA-256:
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`;
  and
- final tracked diff whitespace check: passed.

Per the Phase 2 authority boundary, the implementation owner did not run the
full aggregate gate, launch an independent reviewer, build a release artifact,
or inspect a product consumer. The parent task owns those later gates.

## Package, compatibility, and provenance

- Public API changes are additive exports from
  `package:blab_design_system/blab_design_system.dart`, except the unreleased
  Phase 2 `documentedException` and haptic configuration contracts are
  deliberately tightened to require runtime Design evidence and explicit
  policy gates.
- No dependency, asset, font, platform permission, package version, or release
  configuration changes are introduced.
- Existing public tokens, themes, and component declarations remain
  compatible; the analyzer-backed snapshot records only additive declarations.
- No product consumer repository was inspected or mutated. Consumer runtime
  adoption and smoke tests remain Phase 3/5 work.
- Astryx remains capability evidence only. The owner-stated methods-only scope
  is unsigned; source, asset, component, value, vocabulary, translation,
  bundling, copy, and derivation facts remain unknown pending attestation.
- License impact: none beyond the repository's existing MIT license; no new
  third-party code or dependency was added.

## Migration and rollback

There is no mandatory migration. Phase 3 components may adopt one foundation
at a time while preserving their existing public APIs and visual values.

Rollback is source-only: remove the ten `lib/src/foundation/` files, their
root-library exports, the additive public API snapshot declarations, the
focused Phase 2 test, the normalized focus tokens, regenerated outputs, and
this status document together. Restore the Phase 2 canonical capability entry
and adoption-plan line to `not started`. No persisted product or customer data,
asset, dependency, or consumer migration is involved.

## Deferred evidence and decisions

- Parent aggregate verification was not part of the original
  implementation-owner run; the subsequent current aggregate passes 413/413
  package tests. Independent Design/Quality gates remain open.
- Real keyboard-only and screen-reader sessions remain later evidence.
- Component-level state applicability and announcements remain Phase 3.
- Approved reproducible goldens and platform evidence remain Phase 4.
- Consumer compatibility, migration tooling, release readiness, publication,
  and conformance authority remain Phase 5 or later authority-bound work.
