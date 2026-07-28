# BLDS Phase 3 PressableWrapper and Card status

Status: implementation, parent verification, and independent Design/Quality
re-review complete

As of: 2026-07-28

Task scope: `BLabPressableWrapper` and `BLabCard` only

Design authority:
`BLDS-PHASE3-PRESSABLE-CARD-DESIGN-DECISION-2026-07-26`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and compatibility

This family retains `BLabPressableWrapper` as a `StatefulWidget`, `BLabCard` as
a `StatelessWidget`, and every existing constructor name and default.
The `BLabPressableWrapper` constructor input for `onTap` is widened from
required non-null to required nullable so Card can represent a real
long-press-only action without a fabricated tap action. The exported
`BLabPressableWrapper.onTap` field remains non-null for legacy source
compatibility and resolves to a stable no-op for null input. It is not an
actionability signal: all interaction, focus, and semantics use only the
private nullable effective callback derived from the constructor input.
Existing non-null calls and field reads remain source-compatible.

PressableWrapper adds nullable `semanticLabel`, `semanticHint`, and
`borderRadius`, plus default-deny `hapticConfiguration`. Card adds nullable
`semanticLabel`/`semanticHint` and default-deny `hapticConfiguration`.
Actionable conformance requires a caller-owned localized nonblank label;
unlabeled legacy usage remains source-compatible but unclaimed. No arbitrary
role input is added.

Static Card has no PressableWrapper, focus node, gesture, semantic action, or
fabricated role. Existing default/custom radius and padding remain intact.

## Design-contract-to-code traceability

| Binding contract | Implementation | Focused evidence |
| --- | --- | --- |
| 44×44 actionable target | `BLabInteractiveTarget` wraps actionable PressableWrapper/Card only | minimum-target test; static Card stays unexpanded |
| tap-only action | tap/Enter/Space dispatch `onTap` immediately and exactly once | pointer, keyboard-cycle, and semantic-tap tests |
| long-press-only action | touch/semantic long press and keyboard fallback dispatch only `onLongPress` | no fabricated tap/button plus exact callback tests |
| tap and long press | tap/keyboard choose `onTap`; confirmed long press chooses `onLongPress` | no-double-dispatch matrix |
| hover, pressed, focus | pointer hover, pressed-over-hover, keyboard-visible 2px outline + 3px ring | four-mode token and focus tests |
| cancellation | focus loss, lifecycle, pointer/gesture cancellation, disposal clear pending state | interrupted Space-cycle test and source lifecycle paths |
| immediate callback | no delayed future or animation completion controls product callbacks | synchronous tap assertion and source inspection |
| reduced motion/scaling | zero-duration nonessential feedback; ambient linear/nonlinear scaler untouched | duration and nonlinear scaler test |
| high contrast | opaque `component.card.surface`; no BackdropFilter/blur/highlight/shadow dependency | high-contrast surface and tree test |
| custom Card geometry | resolved custom radius passes to surface, clip, overlay, outline, and ring; custom padding unchanged | custom 22px radius/31px padding test |
| haptic default deny | legacy `enableHaptic` is only a component gate; `BLabHapticPolicy` and disabled configuration remain authoritative | default suppression, touch opt-in, keyboard suppression |

## State coverage

PressableWrapper implements `default`, `hover-pointer`, `pressed`, `focus`, and
`long-press-when-supplied`. Card implements `static-default`,
`interactive-hover-when-actionable`, `interactive-pressed-when-actionable`,
`interactive-focus-when-actionable`, `long-press`, and
`role-determined-by-action`. Generated state coverage carries only those
family-local claims. Busy/loading, selected, invalid, and disabled states stay
absent according to their Design-owned applicability classifications.

## API, token, and generated impact

The public API snapshot records the nullable widening and additive fields, plus
six generated ThemeExtension colors:

- `cardSurface` and `cardBorder`;
- `pressableHoverOverlay` and `pressablePressedOverlay`;
- `pressableFocusOutline` and `pressableFocusOuterRing`.

All six resolve through primitive → semantic → component references in four
Blab modes. The generator produces the Dart token table, ThemeExtension, CSS,
Korean token reference, Figma mapping, traceability matrix, component-state
coverage, and capability manifest deterministically.

Package version, dependencies, assets, fonts, permissions, and platform
configuration are unchanged. No persisted-data or consumer migration is
required. The Card story now demonstrates static, tap-only, long-press-only,
tap-plus-long-press, and custom-geometry states with conformant labels on
actions.

## Verification evidence

| Gate | Exact result |
| --- | --- |
| focused specification | Phase 5 split-contract rerun PASS; 21/21 cases |
| package aggregate | Phase 5 Design-repair aggregate rerun PASS; 383/383 cases |
| contract/schema/custom validator | PASS, including exact decision, four-mode tokens, reference digests, raw inventory, capability ordering, and evidence paths |
| deterministic generator | write/write/check PASS; 8 outputs |
| public API snapshot | write/check PASS |
| targeted format | PASS; 6 files checked, 0 changed |
| root analyzer | PASS; `No issues found` |
| example analyzer | PASS; `No issues found` |
| workflow syntax and authority | PASS |
| doctor JSON schema/content | PASS |
| example release bundle | PASS; release bundle produced after offline example dependency configuration |

The host's IPv4 ephemeral loopback range was exhausted by `TIME_WAIT`
connections during the first focused attempts. A temporary, repository-external
Flutter tools copy passed the SDK's existing `--ipv6` test-runner option into
`DebuggingOptions`; no installed SDK or repository source was modified by that
workaround. Focused and aggregate suites then completed over IPv6. The
repository checks and example bundle were also rerun independently of that
temporary runner.

Current evidence hashes:

- PressableWrapper:
  `4af7dded05b182081c73a93d8a8d30aae5547a22bc623c36354b426ad840ca79`
  after the documented Phase 5 split-contract repair; the immutable historical
  digest remains in the canonical contract;
- Card:
  `90b4ffdbdd3f8e3d644137ee62bcbd852c679b22a2b4a8205e21ea7b7bee6dfa`;
- public API snapshot:
  `8b500683630a396b67db03e54eb85f711d9183d87db225c27982099be9bb46f6`
  after the Phase 5 split-contract documentation and current analyzer snapshot;
- component-state coverage:
  `414c8386b5b7805483e2f1203d727302fd52d82fc72e79cab87ae02f1cef65a1`;
- capability manifest:
  `d40b8f03f31860ccdc09bf6e6db2f92cd7f90280771c330350a3950f854cf4c7`.
- focused specification:
  `415f86c74f5e5b0f650adf977199679a86de41ddfd2dfa2a42aeb4cd2158c0d5`.

## Accessibility, visual, consumer, and provenance boundaries

The focused specification is keyboard- and screen-reader-oriented automated
evidence, not a real assistive-technology or physical-device session. Approved
goldens and platform-matrix confirmation remain Phase 4. The story is a
candidate visual surface, not an approved baseline.

No representative product consumer was mutated in this owner slice. Source
compatibility follows from preserving existing constructor calls and the
nullable widening; isolated representative-consumer rehearsal remains part of
the Phase 4/5 evidence packet and is not claimed here.

Astryx remains capability/method evidence only. The methods-only scope is an
unsigned owner statement; copy, derivation, source, dependency, asset, token
value, vocabulary, appearance, and documentation facts remain unknown.
The changes are presently designated by the repository for MIT, subject to
unresolved copyright-holder, notice, transfer, and contributor authority; no
new dependency or notice was identified by this implementation.

## Claim boundary and rollback

This remains family-partial evidence. Repository-wide component-state,
accessibility, visual, locale, and release claims stay false.

Rollback only the two family widgets, focused test, story, decision/status
documents, `component.card`/`component.pressable` tokens, family state
evidence, family capability entry, and migrated current reference blocks. Keep
the immutable historical digests
`50d56b2d7b2753ff0f9fcc51b344d5d1c02d43eba9072b11c7a630eccc67e8c7`
and
`422e4e1e8441b7abd13691094c20326e5a17475c28a573fe85977d952368baea`.
Then regenerate all eight derived outputs and reconcile the API snapshot.
Never roll back shared Phase 2 foundations or earlier Phase 3 families.
