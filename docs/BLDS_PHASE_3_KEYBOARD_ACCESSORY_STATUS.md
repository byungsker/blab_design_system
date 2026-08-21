# BLDS Phase 3 KeyboardAccessoryBar status

Status: implementation and repository-wide aggregate verified locally;
independent Design/Quality gates pending

As of: 2026-07-28

Task scope: `BLabKeyboardAccessoryBar` family only

Design authority:
`BLDS-PHASE3-KEYBOARD-ACCESSORY-DESIGN-DECISION-2026-07-28`

Narrow-width addendum:
`BLDS-PHASE3-KEYBOARD-ACCESSORY-NARROW-WIDTH-ADDENDUM-2026-07-28`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and compatibility

This slice owns the KeyboardAccessoryBar source, deterministic story, focused
test, exact decision/state/token contract, affected validator and generated
outputs, public API snapshot, and this evidence packet. Other component
families, protected `DESIGN.md`, dependencies, assets, product adapters, Git
state, releases, and deployments are protected.

The widget remains a const `StatefulWidget`. Existing constructor inputs and
defaults remain intact. Seven nullable localized semantic labels are additive.
No dependency, asset, permission, overlay, haptic, or persistence surface is
added.

## Design-contract-to-code traceability

| Binding contract | Token/API | Implementation |
| --- | --- | --- |
| standard gradient and opaque HC | `surface-start/end` | keyed surface decoration |
| border and divider | `border`, `divider` | surface and logical group separators |
| enabled/disabled icon state | `foreground`, `disabled-foreground` | per-action icon |
| pointer state | `hover-overlay`, `pressed-overlay` | immediate/animated interaction layer |
| keyboard-visible focus | `focus-outline`, `focus-outer-ring` | exact 2px + 3px decoration |
| standard glass, HC flat surface | `blur`, `shadow` | conditional BackdropFilter/shadow |
| source-compatible localized names | seven nullable label fields | caller label then nonblank legacy fallback |
| pointer-only history repeat | no public repeat API | 500ms delay then 100ms cadence |
| finite width below content requirement | no public API or token addition | owned horizontal viewport with logical-trailing Done pinned; valid minimum is 80px Done-only, 128px with leading/no history, and 129px with history |
| finite width below the content-dependent minimum | no conformance claim | debug diagnostic before any target or divider compression |
| focus and accessibility reveal | `BLabMotion.durPress`, `BLabMotion.ease` | full 48px target; immediate for accessibility/reduced/reset |
| native overflow semantics | existing Flutter scrolling semantics | physical direction only while real overflow exists |

## Component and state coverage

Default, pointer hover, pressed, keyboard focus, and disabled-per-action are
implemented. Repeat-active is conditional for enabled Undo and Redo only.
Scrollable-overflow is conditional on finite width below the rendered-action
formula and at or above the content-dependent valid minimum. Any non-Done
action requires one full 48px scrolling viewport. A finite host below 80px
for Done-only, below 128px with leading/no history, or below 129px with
history is an invalid host allocation, not a component state or conformance
claim. Loading, selected, and invalid remain explicitly not applicable and
are not simulated.

## Accessibility, visual, and interaction evidence

Focused coverage verifies native named button semantics, excluded icon
semantics, per-action render/enable conditions, 48×48 natural and 44×44 minimum
targets, sequential Tab traversal, exactly-once Enter/Space/pointer/semantic
activation, pointer-focus ring suppression, exact focus geometry, hover and
pressed tokens, repeat cadence/cancellation/error isolation, RTL, four modes,
high contrast, ambient scaling, reduced motion, and no haptic/overlay
ownership. Narrow-width coverage adds 320px, 360px, 372/373px, content-driven
breakpoints, pinned Done, logical traversal, full-target focus and
accessibility reveal, physical scrolling semantics, drag neutrality, repeat
cancellation, overflow lifecycle/composition/Directionality synchronization,
no edge treatment, the 79/80 Done-only, 127/128 leading, and 128/129 history
boundaries, and pointer hit, complete focus reveal, and semantic activation
through a valid 48px viewport.

The automated semantics surface will not be represented as a real
assistive-technology session. Story rendering is not an approved golden.

## Package, consumer, provenance, migration, and rollback

Public API remains unchanged by the narrow-width addendum. Existing calls can
continue unchanged; products can supply the previously approved localized
labels incrementally. Undo/Redo legacy null-label fallback uses Flutter key
labels because Flutter 3.38.5 has no localized undo/redo getter; that fallback
is a nonblank compatibility name, not locale-conformance proof.

Rollback is family-scoped: restore the legacy KeyboardAccessoryBar source and
API snapshot, remove the Keyboard decision/capability/current-digest entries
and component tokens, remove its story/test/status files, then regenerate the
eight deterministic outputs. Preserve the immutable Phase 0 digest
`1c567a5430b52d41ee40afa927179712bb8fea0fe58aa833bbdfe0f4bbc6dd29`.

Astryx remains capability evidence. Its methods-only scope is an unsigned owner
statement; copy, derivation, code, values, vocabulary, assets, appearance, and
documentation facts remain unknown. Package version and dependencies stay
unchanged.

## Verification

- `flutter test test/blab_keyboard_accessory_bar_test.dart`: 43/43 passed.
- `flutter test test/phase1a_contract_test.dart`: 20/20 passed.
- `flutter test test/phase1b_pipeline_test.dart`: 18/18 passed.
- `flutter test`: 358/358 passed.
- `dart run tool/validate_contract.dart`: passed.
- `dart run tool/generate_tokens.dart --write`: passed twice.
- `dart run tool/generate_tokens.dart --check`: passed.
- `dart run tool/public_api_snapshot.dart --write`: passed.
- `dart run tool/public_api_snapshot.dart --check`: passed.
- Root-package `flutter analyze`: no issues found.
- Example-package `flutter analyze`: no issues found.
- Focused `dart format --output=none --set-exit-if-changed`: 7 files,
  0 changed.

Evidence hashes:

| Artifact | SHA-256 |
| --- | --- |
| implementation | `02cde4f9e75e01f13cff753db1555141e9219ad5848a221b6e83e26aaa0c1ec9` |
| focused test | `d109192dda660e7b8f458d32f2f61867776eee22e7e42fa2f446d86aac5d2d6d` |
| deterministic story | `b66ef2682bb9d2d8a66b9918bed1f069d7df43da18b2c9f33ae2d22132302950` |
| public API snapshot | `741f47e674a0ec3c09f940c3fac825ead957932971bcbab8ca4447b39c9b075c` |
| generated state coverage | `a4621a125e6c3c5117fcf8dfb8eabfce807af0758b436a0928543e08b3600682` |
| generated capability manifest | `bb34956043c451a023c33bbc847572984b516b7876242fc679acde57b5a90ff3` |
| eight-output checksum-manifest aggregate | `dc6be0b1e2fd31e795e4d5f5bba48b24e8af9d60538fa2346be9722529a201e9` |

## Remaining risks and decisions

- Approved goldens, physical-device rendering, real assistive-technology
  sessions, platform-matrix confirmation, and consumer smoke remain later
  gates.
- Repository-wide and release conformance claims remain false.
- Release, publication, deployment, Git mutation, and product integration are
  outside this packet.
