# BLDS Phase 3 family 1: BLabButton

Status: Approved foreground contrast amendment implemented locally; all ten
exact visual identities have bounded Design approval; awaiting parent gates

As of: 2026-07-28

Contract version: `0.2.0`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Authority and claim boundary

This packet covers only Phase 3 family 1, `BLabButton`. Blab remains the visual
and semantic authority. The implementation does not authorize release,
publication, Figma mutation, a visual or accessibility conformance claim, or
implementation claims for any other public component.

Byungsker approved decision `BLDS-BUTTON-CONTRAST-2026-07-28`, which narrowly
supersedes the standard-value compatibility lock for
`semantic.action.primary-foreground` and
`semantic.action.destructive-foreground`. Both resolve to black in standard
light and dark modes. Primary `#5B7FFF`, destructive `#FF3B30`, overlays,
focus, geometry, motion, and the already-black high-contrast mappings remain
unchanged. The authority and claim boundary is recorded in
`docs/BLDS_PHASE_3_BUTTON_CONTRAST_DECISION.md`.

Automated composed-color checks now meet the contract's 4.5:1 active
normal-text target for primary and destructive default, hover, pressed, and
keyboard-visible focus states across all four visual modes. This closes the
recorded active Button foreground residual only. It does not establish Button
or repository-wide accessibility or visual conformance.

The required Button states `default`, `hover-pointer`, `pressed`, `focus`,
`disabled`, and `destructive-variant` have local implementation and automated
evidence. The conditional `loading-busy` state has no public API or runtime
condition and remains `not-claimed`. `selected`, `current`, `invalid`, and
`expanded` remain not applicable and are not synthesized. Flutter exposes
`SemanticsValidationResult`, so invalid absence has an observable runtime
assertion. Selected and expanded semantic flags are also observed absent.
Flutter exposes no Button current channel here, and loading/busy has no API, so
those two absences are typed/code-inspection evidence only—not runtime semantic
claims.

## Design contract to code traceability

| Approved contract | Button implementation | Focused evidence |
| --- | --- | --- |
| default action, existing content API, and 44x44 minimum target | standard primary/secondary surfaces plus `BLabInteractiveTarget` | minimum target; standard light/dark values; text, icon, child, and full-width tests |
| 4.5:1 active normal-text contrast target | approved black primary/destructive foregrounds; interaction overlay is composed over both content and surface | parameterized unrounded checks cover default, focus, hover, and pressed across four visual modes; standard primary minimum 5.12:1 and destructive minimum 5.10:1 |
| custom-child inheritance | `DefaultTextStyle` and `IconTheme` supply the resolved Button foreground without overriding explicit child colors | four modes × primary/destructive inherited text/icon tests plus an explicit-color ownership test |
| enabled pointer hover | variant/mode component tokens provide ARGB overlays; exit, disable, and lifecycle transitions clear hover; pressed replaces hover | exact token matrix for three variants × four modes; touch absence; mouse exit, disable, lifecycle, and pressed precedence |
| pressed feedback and exact activation | pointer gesture state plus `BLabKeyboardActivationController`; committed activation invokes the callback immediately and exactly once | pointer/touch once without an 80ms delay; Enter/Space once per physical key cycle; press scale release |
| modality-aware visible focus | separate component outline and outer-ring colors; 2px outline at radius `BLabRadius.md`, then distinct 3px canvas ring at radius `md + ringWidth` | three variants × four modes assert outline-to-actual-surface and ring-to-canvas contrast of at least 3:1 |
| disabled action | null `onPressed` suppresses pointer, keyboard, semantic action, focus, and haptic behavior; existing whole-control 0.5 opacity is unchanged | disabled semantics and suppression test; inactive contrast is exempt/unverified, not a 4.5:1 claim |
| destructive variant | existing `BLabButtonVariant.destructive` mapped to Blab destructive background/foreground tokens | destructive typing and token-value test without invented product copy |
| ambient text scaling | no component scaler override or clamp | linear 1.0, 1.3, 2.0 and nonlinear ambient scaler tests |
| reduced motion | `BLabReducedMotionPolicy` resolves press and overlay durations | zero-duration nonessential feedback test |
| high contrast | `BLabVisualModeResolver` maps high-contrast surface, foreground, border, blur, and focus tokens | high-contrast dark secondary and focus test; shared Phase 2 light/dark token tests remain regression evidence |
| explicit haptic policy | additive default-deny `hapticConfiguration`, `BLabHapticActionCycle`, touch-only trigger | default/keyboard/pointer suppression and one explicitly enabled touch pulse |

## Component and state coverage

| State | Classification | Local evidence | Claim |
| --- | --- | --- | --- |
| default | required | `test/blab_button_test.dart`, this packet, Button story | implemented locally |
| hover-pointer | required | same | implemented locally |
| pressed | required | same | implemented locally |
| focus | required | same | implemented locally |
| disabled | required | same | implemented locally |
| destructive-variant | required | same | implemented locally |
| loading-busy | conditional | typed API/code inspection only; no API or runtime condition | not claimed |
| invalid | not applicable | observable `SemanticsValidationResult.none` runtime assertion | not simulated |
| selected/expanded | not applicable | observable semantic-flag absence | not simulated |
| current | not applicable | typed API/code inspection only; no Button current channel is exposed here | not simulated |

`contracts/components/state-applicability.yaml` remains the canonical
Design-owned applicability source and now carries Engineering-owned per-state
implementation evidence. Deterministic generation copies only those six Button
claims into `generated/component-state-coverage.yaml`; all other component
states remain `not-claimed`. The capability entry is explicitly named
`button-component-state-implementation`, has
`implemented-local-family-partial` status and Button-only scope, and keeps
loading/busy and global completion false. The manifest also retains
`component_state_implementation: false` as the repository-wide claim.

## API and compatibility

Public API classification: additive, with an intentional default behavior
correction.

`BLabButton` adds:

```dart
BLabHapticConfiguration hapticConfiguration =
    BLabHapticConfiguration.disabled
```

Existing constructor calls continue to compile. Text remains the semantic name
and default visible label; `child` still replaces the default visible text/icon
content; `icon` and `isFullWidth` retain their behavior. An unstyled custom
child now inherits the resolved Button text/icon foreground. Explicit custom
child colors remain consumer-owned.

The standard primary/destructive foreground value is an authority-backed
behavior correction, not a source-breaking API change. Standard surfaces,
borders, padding, typography, disabled opacity, press scale, overlays, focus,
geometry, and motion remain compatible.

The Button interaction treatment intentionally corrects legacy drift and is
classified as a compatibility correction, not `legacy-retained`: hover no
longer uses raw `0.04`; activation has no 80ms delay or reverse-animation
coupling; all Button surface/overlay/outline shapes use `BLabRadius.md` (12px);
the outer focus ring uses `md + ringWidth`; and both interaction animations use
`BLabMotion.ease`, never a raw `easeInOut`.

The previous implementation fired `HapticFeedback.selectionClick`
unconditionally from its tap callback, including activation paths that could
not prove touch modality or system/accessibility permission. The default is now
no haptic. A product that requires tactile feedback must pass a configuration
whose platform, system, accessibility, and component gates are all explicitly
true. Even then, the Button emits at most one selection pulse for a committed
touch action and never for keyboard, pointer hover/click, focus, semantics, a
disabled control, or a repeated callback path.

No loading or busy parameter is added. There is no migration for persisted data
or layout.

## Historical and current source evidence

The immutable Phase 0 Button baseline remains
`27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f`.
It is historical evidence and is never compared with the migrated source.
Phase 3 current-source validation instead uses
`fca58bb9c9f4ce8056f980f9c843321d04cf3b054062597120abe1f36914b1cb`
and links the approved contrast decision, this status packet, and the focused
Button suite. This split prevents a migrated component from erasing Phase 0
history while still failing closed on current implementation drift.

## Accessibility and visual evidence

The focused widget suite supplies automated behavior, semantics,
keyboard/focus, pointer, text-scaling, reduced-motion, theme, high-contrast,
and haptic evidence. It is screen-reader-oriented and keyboard-oriented
evidence, not a real assistive-technology session or public audit.

The focus-outline and outer-ring tests continue to cover the separate 3:1
adjacent-contrast contract. Active content tests compose the interaction
overlay over both foreground and surface and assert at least 4.5:1 without
rounding. Disabled whole-control opacity remains an inactive-control exception
and is recorded as unverified, never as an active-contrast pass.

Phase 4 recaptured and Design-approved the eight affected standard-mode
identities for bounded local reproducibility and fixture review. The two
already-black high-contrast images remain byte-identical. This bounded approval
and automated contrast evidence do not establish accessibility or visual
conformance.

## Local verification

Current local evidence:

- focused Button suite: 61/61 passed;
- focused BLabButton browser widget suite: 61/61 passed with
  `flutter test --platform chrome test/blab_button_test.dart` on Chrome
  150.0.7871.187; this is not full-package web, web-build, browser-matrix,
  device, assistive-technology, haptic, rendering-conformance, or public web
  support evidence;
- deterministic token generation write/check: all 8 outputs passed;
- Phase 4 evidence validator and focused suite: 12/12 passed;
- candidate recapture/drift suites: 10/10 Latin/Korean and 1/1 Arabic passed;
- exactly eight standard candidate hashes changed; both high-contrast hashes
  remained byte-identical;
- Button retains its immutable Phase 0 digest and its separate current Phase 3
  digest matches source; and
- protected `DESIGN.md` SHA-256 remains
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`.

The current parent aggregate verification passes 413/413 package tests. This
is bounded local evidence only; it does not establish accessibility, visual,
platform, consumer, release, publication, or conformance approval.

The example has no web scaffold, so a web build is not an applicable example
gate. The successful bundle build is the repository-native build evidence.
The bounded Chrome widget suite above does not substitute for a web build.

The consumer canary was not rerun in this repair. The prior targeted evidence
used a validated temporary archive of committed
`baro-app` `HEAD:app`. Local-path dependency resolution passed and
representative primary/secondary Button consumer files analyzed with no
issues. Whole-app analysis retained 45 pre-existing/archive findings, including
the committed `pubspec.yaml` reference to an unavailable `.env`; widget-test
and bundle commands stopped at that same missing asset before BLDS execution.
No consumer worktree file was read or changed. The temporary archive was
deleted after validation and remains reproducible from committed HEAD.

## Package, consumer, and provenance impact

- Package version, dependencies, assets, fonts, permissions, and platform
  configuration are unchanged.
- Analyzer API snapshot impact remains additive: the default-deny constructor
  field plus generated optional Button token fields; no existing declaration is
  removed.
- The example story remains local and uses no external service.
- Astryx remains capability evidence only. Its methods-only scope is an
  unsigned owner statement; copy, derivation, source, dependency, asset, value,
  vocabulary, appearance, and product-copy facts remain unknown.
- The changes are presently designated by the repository for MIT, subject to
  unresolved copyright-holder, notice, transfer, and contributor authority;
  no new third-party code or notice was identified by this implementation.
- A representative consumer canary must use a temporary committed-HEAD archive
  and is evidence only; it does not authorize consumer mutation or release.

## Migration and rollback

No source migration is needed for existing callers. To opt into eligible touch
haptics, pass an explicit `BLabHapticConfiguration`; otherwise accept the safer
default-deny behavior.

To roll back only decision `BLDS-BUTTON-CONTRAST-2026-07-28`, restore the two
standard semantic foreground mappings to white, remove only the approved
compatibility exception and custom-child inherited foreground wrappers,
regenerate the eight token outputs, restore the prior eight standard candidate
images and hashes, and restore their previous durable approval binding. Keep
the immutable Phase 0 digest and every unrelated component change intact.

Rollback is family-scoped and must preserve unrelated work. Apply it in this
order so canonical sources are coherent before derived artifacts are refreshed:

1. Restore only the pre-Phase-3 Button implementation. Leave shared Phase 2
   foundations and every other component family intact.
2. Restore the canonical contract sources: remove
   `component_decisions.button`; remove the Button-specific typed hover-overlay,
   focus-outline, and focus-outer-ring tokens; change
   `button-component-state-implementation` back to `not-started` with no Phase 3
   evidence; and remove only the Button `implementation_evidence` and
   `absence_evidence` blocks (plus their Button-only evidence-owner/as-of
   metadata when unused) so Design-owned applicability remains contract-only.
3. Restore the Button reference-manifest entry to its historical-only Phase 0
   form and remove the current migrated `current` digest/evidence block while
   preserving the immutable Phase 0 digest
   `27400bff8776551ca6803dd799bf12d83020320b33979d30649fc61fad88bf4f`.
4. Regenerate all eight derived outputs:
   `lib/src/generated/blab_token_data.g.dart`,
   `lib/src/theme/blab_token_theme.dart`, `generated/blab.tokens.css`,
   `generated/token-reference.ko-KR.md`,
   `generated/figma-token-mapping.json`,
   `generated/token-traceability.md`,
   `generated/component-state-coverage.yaml`, and
   `generated/blab-capabilities.v1.json`.
5. Refresh `api/blab_design_system.api.txt` only after the restored Button
   source and regenerated typed outputs are in place, then verify that the
   Button capability/state evidence is back to `not-started`/`not-claimed`,
   loading/busy and global completion remain false, and the historical digest is
   unchanged.
6. Remove the Phase 3 Button-only status/test/story additions after their
   canonical evidence references have been removed.

This ordering prevents generated provenance or the public API snapshot from
describing a mixture of migrated and rolled-back inputs. No other Phase 3
family, dependency, asset, consumer data, or product repository is part of this
rollback.

## Deferred evidence and decisions

- Parent aggregate verification passes 413/413 package tests; independent
  Quality review and the authority-bound gates below remain open.
- Real screen-reader, platform keyboard, touch-device, and haptic-device
  sessions remain later evidence.
- All ten exact golden identities have bounded local Design approval; remote
  platform and consumer evidence remain open.
- Disabled readability remains exempt/unverified; explicit custom child colors
  remain consumer-owned; loading/busy remains not claimed.
- Remaining Phase 3 component families are not started by this packet.
- Consumer migration tooling, release readiness, publication, and conformance
  authority remain Phase 5 or later authority-bound work.
