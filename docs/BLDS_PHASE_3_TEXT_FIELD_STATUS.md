# BLDS Phase 3 family 2: BLabTextField

Status: Implementation complete locally; current parent aggregate verified;
independent gates pending

As of: 2026-07-26

Contract version: `0.2.0`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Authority and claim boundary

This packet covers only Phase 3 family 2, `BLabTextField`. Blab remains the
visual and semantic authority. The implementation does not authorize release,
publication, Figma mutation, a visual or accessibility conformance claim, or
implementation claims for any other public component.

The Design dependency
`BLDS-PHASE3-TEXTFIELD-DESIGN-DEPENDENCY-2026-07-26` is the authority for the
TextField precedence, token values, semantic mappings, and contrast thresholds
implemented here. Every repaired visual value is classified
`compatibility-correction-not-legacy-retained`.

The Design-owned applicability contract classifies `empty`, `populated`,
`hover-pointer`, `focus`, `read-only`, `obscured`, and `multiline` as required.
It classifies `disabled`, `required`, `invalid`, `error-help`, and
`clear-action` as conditional. All twelve applicable states have bounded local
implementation and focused automated evidence. `selected`, `loading`, and
`current` remain not applicable and are not simulated.

Flutter 3.38.5 exposes a native `Semantics.isRequired` channel, so the additive
`isRequired` condition does not need invented marker copy or a new Blab visual
semantic. `errorText` supplies the invalid condition and linked message;
`helperText` supplies the non-error support condition; and `enabled: false`
supplies the disabled condition. Existing nonempty, editable fields retain the
automatic clear condition. No autofill, prefix, loading, busy, selected, or
current API is introduced.

## Design contract to code traceability

| Approved contract | TextField implementation | Focused evidence |
| --- | --- | --- |
| empty and populated value states | existing required controller remains the value owner; listener ownership now follows controller replacement | empty/populated rendering, controller replacement, and clear tests |
| label, hint, value, and support/error relationships | one semantic field container augments the native editable node; visual label/support duplicates are excluded from separate announcements | label/hint/value, helper, invalid/error, and required semantics tests |
| enabled pointer hover | component hover-border token; touch does not hover; disable, exit, and lifecycle transitions clear hover | four-mode hover and pointer-modality tests |
| visible focus | every enabled focus, including invalid, uses the monochrome 2px outline; keyboard-visible focus adds the existing 3px outer ring | focused-invalid precedence, pointer-versus-keyboard focus, external focus ownership, and four-mode token/contrast tests |
| disabled | additive `enabled = true`; false has first precedence and suppresses hover, focus/ring, editing, and automatic clear while retaining validation copy/semantics without an error border | disabled-invalid precedence plus disabled widget and semantics tests |
| read-only | existing `readOnly` remains separate from disabled and suppresses automatic clear | read-only behavior and semantics-oriented state test |
| obscured | existing `obscureText` forces one line without adding password copy or a visibility control | obscured/max-lines test |
| multiline | existing `maxLines` remains ambient-height content, except obscured inputs stay single-line | multiline test |
| required | additive `isRequired = false` maps only to Flutter's native required semantic flag | required relationship test |
| invalid and error/help | additive nullable `errorText` and `helperText`; error supersedes helper visually and semantically; unfocused invalid uses the red border and error copy uses `semantic.text.primary` | helper/error rendering, focused/disabled invalid precedence, validation result, semantic linkage, and four-mode contrast tests |
| clear action | existing automatic clear condition uses Design-corrected background/foreground tokens, a localized Material tooltip, and a 44x44 target | clear visibility, activation, target, semantics, and four-mode composited contrast tests |
| ambient text scaling | no component scaler override or clamp | linear 1.0, 1.3, 2.0 and nonlinear ambient scaler tests |
| reduced motion | border feedback duration resolves through `BLabReducedMotionPolicy` | zero-duration feedback test |
| light/dark/high contrast | `BLabVisualModeResolver` maps glass, text, border, focus, status, and clear tokens; high contrast resolves zero blur; all six required adjacent contrast pairs pass in every mode | standard-mode, high-contrast, exact-token, and composited-ratio tests |

## Component and state coverage

| State | Classification | Local evidence | Claim |
| --- | --- | --- | --- |
| empty | required | `test/blab_text_field_test.dart`, this packet | implemented locally |
| populated | required | same | implemented locally |
| hover-pointer | required | same | implemented locally |
| focus | required | same | implemented locally |
| read-only | required | same | implemented locally |
| obscured | required | same | implemented locally |
| multiline | required | same | implemented locally |
| disabled | conditional on `enabled: false` | same | implemented locally |
| required | conditional on `isRequired: true` | same | implemented locally |
| invalid | conditional on non-null `errorText` | same | implemented locally |
| error-help | conditional on non-null `helperText` or `errorText` | same | implemented locally |
| clear-action | conditional on enabled, editable, nonempty value with no caller suffix | same | implemented locally |
| selected | not applicable | observable semantic-flag absence | not simulated |
| loading | not applicable | typed API/code inspection only | not simulated |
| current | not applicable | typed API/code inspection only; Flutter has no TextField current channel here | not simulated |

`contracts/components/state-applicability.yaml` remains the canonical
Design-owned applicability source and carries Engineering-owned per-state
implementation evidence. Deterministic generation copies only the Button and
TextField family claims into `generated/component-state-coverage.yaml`; every
later component family remains `not-claimed`. The TextField capability is
family-partial, and all repository-wide conformance and component-state claims
remain false.

## API and compatibility

Public API classification: additive and default-safe.

`BLabTextField` adds:

```dart
String? helperText
String? errorText
bool enabled = true
bool isRequired = false
```

Existing constructor calls continue to compile. The required controller,
external label, hint, read-only, obscured, autofocus, tap callback, caller
suffix, caller focus node, max-lines behavior, automatic clear condition,
standard glass surface, standard primary/label colors, padding, radius, and
default border values remain compatible. Hint, focus outline, error copy, clear
background, and clear foreground are intentional Design-approved compatibility
corrections rather than legacy-retained values.

The implementation corrects lifecycle gaps by moving listeners when the
controller or focus node changes and by never disposing a caller-owned focus
node. The automatic clear affordance retains its existing visibility condition
while its visual contrast, hit target, and semantic label are corrected.

No persisted data, input value, controller, focus node, or caller callback is
migrated. No prefix, autofill, keyboard-type, capitalization, max-length,
loading, visibility-toggle, or product copy API is added.

## Historical and current source evidence

The immutable Phase 0 TextField baseline remains
`6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f`.
It is historical evidence and is never compared with the migrated source.
Phase 3 current-source validation uses a separate current digest linked to this
packet and `test/blab_text_field_test.dart`. This split prevents a migrated
component from erasing Phase 0 history while still failing closed on current
implementation drift. The final implementation digest is
`2780bc171dc30de47f7f13c38ea565b4fa2a6343c047e7a74921daa2a55e7ac8`.

## Accessibility and visual evidence

The focused widget suite supplies automated behavior, semantics,
keyboard/focus, pointer, target-size, text-scaling, reduced-motion, theme, and
high-contrast evidence. It is screen-reader-oriented and keyboard-oriented
evidence, not a real assistive-technology session or public audit.

Error copy is consumer-owned, uses `semantic.text.primary`, and is rendered as
text as well as an invalid semantic result; color is not the only error
indicator. The platform-localized clear tooltip comes from Flutter Material
localizations rather than embedded product copy. The component does not clamp
ambient linear or nonlinear text scaling.

The repository has no approved TextField golden ownership flow. No golden image
is added, because doing so here would imply a Design-approved baseline that
Phase 4 explicitly owns. The TextField story is a reproducible candidate visual
surface for later Design capture and approval; property-level tests verify
contract mapping without claiming appearance approval.

The focused composited-contrast test records these ratios against the exact
Design-approved values. Standard-mode translucent colors are alpha-composited
over the field before measurement.

| Mode | Focus/field | Ring/canvas | Hint/field | Error/canvas | Clear bg/field | Clear icon/bg |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| light | 16.89 | 3.40 | 5.36 | 20.12 | 5.36 | 6.67 |
| dark | 13.42 | 5.29 | 5.89 | 18.73 | 5.89 | 9.22 |
| high-contrast light | 21.00 | 21.00 | 21.00 | 21.00 | 21.00 | 21.00 |
| high-contrast dark | 18.73 | 18.73 | 18.73 | 18.73 | 18.73 | 21.00 |

Every pair exceeds its required threshold: `3:1` for focus/field, ring/canvas,
clear-background/field, and clear-icon/background; `4.5:1` for hint/field and
error/canvas.

## Local verification

Implementation-owner repair verification has these exact bounded results:

- The test-first repair run failed `6` newly added assertions as intended:
  focused-invalid and disabled-invalid precedence, four-mode token/contrast
  mapping, and high-contrast error-copy mapping (`+26 -6`).
- `flutter test test/blab_text_field_test.dart` passed `32/32`.
- `flutter test test/phase1a_contract_test.dart` passed `17/17` after its exact
  approved graph expectations were updated.
- The selected Phase 1A, Phase 1B, Phase 2, Button, and TextField regression run
  passed `169/169`.
- The complete package run passed `176/176`.
- `dart run tool/validate_contract.dart` passed, including schema, exact-scope,
  current-digest, immutable historical-digest, raw-value, phase-routing, and
  negative-drift coverage.
- Two consecutive final-source deterministic writes each wrote eight outputs
  with identical combined SHA-256
  `54b7a6e6a3e1ba03275e41a5230b2db34509eabc5812d9fd52793fd0e74c9f00`;
  the subsequent no-write check passed.
- Before the intentional snapshot refresh, the checked-in input hash was
  `bacc01ece8c2e94a3176ffa5b1b6bb2da206ae9ecc2966744de2740e137ce7cb`;
  the generated input hash is
  `26587aa73df11cc994173102da9ee5da3247e15b0192e20af52167833e2ed923`.
  Both bodies have 562 lines and only lines 469, 484, and 499 differ. The
  bodies are identical after normalizing `Color(0x........)` values, proving
  that symbols, field names, types, and shape are unchanged while approved
  generated color defaults changed. The interpretation of “no API drift” is
  therefore no public API shape drift; the value-only snapshot refresh remains
  truthful compatibility evidence. The value snapshot write passed four
  consecutive no-write checks. Closing the authority reference later changed
  only exported generated-source checksum headers; the analyzer body remained
  byte-identical at 562 lines and its input-checksum-only refresh passed two
  further no-write checks. The final snapshot SHA-256 is
  `e89fcea51821f93a111d00dc2cdb735a466b20af476ec1ba951c51b2c1b44484`.
- Targeted implementation files passed `dart format
  --output=none --set-exit-if-changed` with zero changes.
- Root and example `flutter analyze` each reported `No issues found`.
- `flutter build bundle` in `example/` exited `0`. The example has no web
  platform configuration, so `flutter build web` was not substituted for the
  platform-neutral bundle gate.
- Doctor human and JSON outputs agree and exit `0`: `pass=5`, `warning=3`,
  `failure=0`, `information=1`. The warnings remain the approved
  release-authority, remote-font/assets, and repository-custody deferrals.
- Protected Phase 0/other-family sources retained their starting hashes:
  `DESIGN.md`
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`,
  Button
  `fca58bb9c9f4ce8056f980f9c843321d04cf3b054062597120abe1f36914b1cb`,
  and the seven other protected component sources remained byte-identical to
  their recorded manifest digests.
- The final 16-file machine-verifiable repair source/artifact scope, excluding
  this self-referential status packet, has combined SHA-256
  `3a71bffbab9e5ad299bc14bc8a11846c4fd0ecabbe2bc2491e85865f25ea84fa`.

The implementation owner did not run the parent aggregate tool or launch an
independent reviewer in the original TextField-only run. The subsequent
current aggregate passes 413/413 package tests; independent review remains
with the parent task.

## Package, consumer, and provenance impact

- Package version, dependencies, assets, fonts, permissions, and platform
  configuration are unchanged.
- Public API symbols, field names, types, constructor shape, and line count are
  unchanged by this repair. The analyzer snapshot delta is limited to approved
  generated `Color` defaults and the corresponding exported-source input
  checksum; the deterministic snapshot was refreshed without changing the
  snapshot tool.
- The example story remains local and uses no external service.
- Astryx remains capability evidence only. Its methods-only scope is an
  unsigned owner statement; inspection, copy, derivation, translation,
  bundling, source, dependency, asset, value, vocabulary, appearance, and
  product-copy facts remain unknown.
- The changes are presently designated by the repository for MIT, subject to
  unresolved copyright-holder, notice, transfer, and contributor authority;
  no new third-party code or notice was identified by this repair.
- This repair does not rerun the archive-only Baroguni canary. Its earlier
  bounded evidence used committed app HEAD
  `efa512c7d3539ba176cb5cb3c085d9906f6c4c84` with a temporary local BLDS path
  override and empty ignored `.env` asset. All 19 committed `BLabTextField`
  call sites analyzed with zero errors. The non-fatal lint run exited `0` with
  44 pre-existing consumer findings (3 warnings and 41 infos), and consumer
  utility tests passed `43/43`.
- The aggregate consumer test run passed those 43 tests, then the committed
  widget test failed because its harness does not initialize `flutter_dotenv`.
  This is recorded as a pre-existing consumer-test limitation and not a BLab
  compatibility failure. The consumer worktree was never mutated.

## Migration and rollback

Existing callers require no migration. Consumers may opt into disabled,
required, helper, or invalid behavior through the additive parameters.

Rollback is family-scoped and must preserve the completed Button family and
unrelated work:

1. Restore only the pre-Phase-3 TextField implementation. Leave the shared
   Phase 2 foundations, Button, and every later component family intact.
2. Restore canonical sources: remove `component_decisions.text-field`; remove
   only the eight TextField component tokens; change the TextField capability
   back to `not-started`; and remove only TextField implementation/absence
   evidence while preserving Design-owned applicability.
3. Restore the TextField reference-manifest entry to its historical-only Phase
   0 form and remove the current migrated digest/evidence block while
   preserving immutable digest
   `6f7775e19887d9e227d21a01278d2fae3feea662cc8cbb94c2a822b8dcc6948f`.
4. Regenerate all eight deterministic outputs.
5. Refresh the public API snapshot only after source and generated theme
   outputs are coherent.
6. Remove the TextField-only focused test, story expansion, status packet, and
   README additions.

No other component source, dependency, asset, consumer data, or product
repository is part of this rollback.

## Deferred evidence and decisions

- Parent aggregate verification remained outside the original
  implementation-owner run; the subsequent current aggregate passes 413/413
  package tests. Independent Design/Quality gates remain open.
- Real screen-reader, platform keyboard, touch-device, and platform autofill
  sessions remain later evidence.
- Approved TextField goldens and platform-matrix evidence remain Phase 4.
- Prefix, autofill, visibility-toggle, keyboard configuration, max-length, and
  product validation copy remain unsupported rather than simulated.
- Remaining Phase 3 component families are not started by this packet.
- Consumer migration tooling, release readiness, publication, and conformance
  authority remain Phase 5 or later authority-bound work.
