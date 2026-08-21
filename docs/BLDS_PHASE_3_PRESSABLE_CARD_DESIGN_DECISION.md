# BLDS Phase 3 PressableWrapper and Card Design decision

Status: APPROVED implementation authority, independent gates pending

As of: 2026-07-26

Canonical packet:
`BLDS-PHASE3-PRESSABLE-CARD-DESIGN-DECISION-2026-07-26`

Scope: `BLabPressableWrapper` and `BLabCard` only

Design authority: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

This binding record authorizes the sequential Phase 3 family 4 implementation.
It does not authorize another component, a global Blab conformance claim,
release, publication, deployment, or Figma mutation.

## Compatibility and public API

`BLabPressableWrapper` remains a `StatefulWidget`. Its `child`, `onTap`,
`onLongPress`, `scaleEnd`, `brightnessEnd`, `animationDuration`, and
`enableHaptic` names and defaults remain source-compatible. `onTap` is widened
from required non-null to required nullable so `BLabCard` can express a real
long-press-only action without manufacturing a no-op tap action. The wrapper
adds optional `semanticLabel`, `semanticHint`, `borderRadius`, and
`hapticConfiguration`; their defaults preserve legacy call-site compilation.

`BLabCard` remains a `StatelessWidget`. Its child, nullable padding, nullable
border radius, nullable tap, and nullable long-press inputs remain unchanged.
It adds only optional `semanticLabel`, `semanticHint`, and default-deny
`hapticConfiguration`.

A supplied semantic label or hint must be nonblank. A legacy actionable caller
without a caller-owned localized label remains source-compatible but cannot
claim family conformance. No arbitrary semantic-role input is exposed: role is
derived from the actual callback contract.

## Action and semantics matrix

| Configuration | Pointer/touch | Keyboard | Semantics | Role |
| --- | --- | --- | --- | --- |
| static Card | none | none | child semantics only | none fabricated |
| tap only | tap calls `onTap` once | Enter/Space call `onTap` once | tap action | button |
| long press only | confirmed long press calls `onLongPress` once; tap does nothing | Enter/Space call the sole action once | long-press action | no fabricated button |
| tap and long press | tap calls `onTap`; confirmed long press calls `onLongPress`; never both for one gesture | Enter/Space choose primary `onTap` once | tap and long-press actions | button |

Enter commits on its first key-down; Space commits on key-up. Repeats are
consumed. Focus loss, app lifecycle change, pointer cancellation, gesture
cancellation, and disposal clear pending interaction state. Product callbacks
run immediately when Flutter confirms the action and never wait for a release
animation.

## State, geometry, and motion

Actionable PressableWrapper and Card enforce a 44×44 logical-pixel minimum
target. Hover is pointer-only. Pressed replaces hover. Keyboard-visible focus
adds a 2px surface outline and a distinct 3px canvas ring; pointer/touch focus
does not draw the focus treatment. The public `borderRadius` coordinates the
interaction overlay and focus geometry, and Card passes its resolved custom
radius through unchanged.

`scaleEnd = 0.96`, `brightnessEnd = 0.1`, and the public animation-duration
override remain compatibility inputs. Default visual colors come from
component tokens; non-default legacy brightness values adjust only the
resolved pressed-overlay opacity. The approved curve is `BLabMotion.ease`.
Reduced motion makes scale and overlay changes immediate. Text scaling remains
ambient for linear and nonlinear scalers and is never clamped.

Card retains `padding ?? EdgeInsets.all(BLabSpacing.lg)` and
`borderRadius ?? BLabRadius.lgRect`. Static Card does not gain target expansion,
focus, hover, pressed, gesture, or semantic action behavior.

## Token reference graph

| Token | Light | Dark | HC light | HC dark |
| --- | --- | --- | --- | --- |
| `component.card.surface` | `semantic.surface.glass` | `semantic.surface.glass` | opaque white | opaque `#121212` |
| `component.card.border` | `semantic.border.default` | `semantic.border.default` | black | white |
| `component.pressable.hover-overlay` | `#14000000` | `#14FFFFFF` | `#1F000000` | `#1FFFFFFF` |
| `component.pressable.pressed-overlay` | `#1F000000` | `#1FFFFFFF` | `#33000000` | `#33FFFFFF` |
| `component.pressable.focus-outline` | black | white | black | white |
| `component.pressable.focus-outer-ring` | `semantic.focus.canvas` | `semantic.focus.canvas` | black | white |

Standard Card keeps the existing Blab translucent glass surface and border.
High contrast uses an opaque surface and has no BackdropFilter, blur, highlight,
gradient, or shadow dependency. The migration is classified
`compatibility-correction-not-legacy-retained`.

## Haptics

`enableHaptic = true` remains only as a legacy component gate. It cannot grant
permission. The ambient component configuration defaults to
`BLabHapticConfiguration.disabled`, and `BLabHapticPolicy` must approve a
confirmed touch action before one selection pulse may occur. Keyboard, mouse,
focus, hover, semantic/programmatic activation, no-op tap paths, repeated
callback paths, and disposed cycles never pulse. There is at most one pulse per
committed action.

## Evidence and claim boundary

Focused source, contract, token, semantics, keyboard, pointer, motion, scaling,
high-contrast, API, analyzer, and bundle evidence may support this family
packet. Approved goldens, physical-device rendering, real assistive-technology
sessions, and platform-matrix confirmation remain Phase 4. Repository-wide
component-state, accessibility, visual, locale, and release claims remain
false. Astryx remains capability and method evidence only. Its methods-only
scope is an unsigned owner statement; copy, derivation, source, values,
vocabulary, appearance, assets, and documentation facts remain unknown.
