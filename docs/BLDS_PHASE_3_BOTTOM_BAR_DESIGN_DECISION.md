# BLDS Phase 3 BottomBar Design decision

Status: APPROVED implementation authority, independent gates pending

As of: 2026-07-26

Canonical packet:
`BLDS-PHASE3-NAVIGATION-BOTTOMBAR-DESIGN-DECISION-2026-07-26`

Scope: `BLabBottomBar` only

Design authority: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

This durable record transcribes the binding independent Design response
supplied for the sequential Phase 3 BottomBar boundary. It does not authorize
TabBar, SegmentedControl, Button, TextField, other component changes, global
Blab conformance, release, publication, deployment, or Figma mutation.

## Compatibility and API

The complete existing `BLabBottomBarItem` and `BLabBottomBar` API remains
source-compatible. `BLabBottomBar` remains a `StatefulWidget`; selection stays
controlled by `selectedIndex`; activating the selected item still calls
`onTabSelected` exactly once. `noMargin`, the 62 logical-pixel baseline, equal
tab allocation, action callback position/size, and existing defaults remain.

Exactly three optional, null-default named inputs are additive:

- `actionSemanticLabel`;
- `firstTabChevronSemanticLabel`;
- `firstTabChevronExpanded`.

Legacy optional-action and chevron configurations still compile. An action is
conformant only with `onSearchTap` and a caller-owned localized
`actionSemanticLabel`. A disclosure is conformant only when the chevron is
shown and callback, localized label, and controlled expanded state are all
present. Incomplete legacy configurations are explicitly nonconformant.

## Applicability and precedence

| State | Applicability | Contract |
| --- | --- | --- |
| unselected | required | unselected foreground, inactive icon |
| selected-current | required | persistent selected surface, foreground, active icon, native selected adapter |
| hover-pointer | required | pointer-only overlay |
| pressed | required | replaces hover |
| keyboard-visible focus | required | additive 2px outline and 3px ring; selection remains |
| touch-only long-press drag | required | supplemental, logical-index/RTL-correct |
| optional action | conditional | callback plus localized label; separate button |
| expanded disclosure | conditional | callback plus localized label plus controlled expanded state; separate button |
| disabled, loading, invalid | not applicable | never simulated |

Environment modifiers resolve first. Selection remains persistent. Interaction
precedence is `drag > pressed > hover > rest`. Keyboard-visible focus composes
with the result and never erases selection. Pointer/touch focus has no keyboard
focus decoration.

## Token reference graph

All component values are canonical `component.bottom-bar.*` tokens. Standard
mode values preserve the established Blab glass/droplet character while
correcting raw literals into the approved graph. High contrast uses opaque
surfaces and removes blur, gradient, highlight, and shadow.

| Token | Light | Dark | HC light | HC dark |
| --- | --- | --- | --- | --- |
| container-surface | `0x14000000` | `0x1FFFFFFF` | `0xFFFFFFFF` | `0xFF121212` |
| container-border | `0x14000000` | `0x26FFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| selected-surface | `0x1F000000` | `0x38FFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| selected-highlight | `0x66FFFFFF` | `0x26FFFFFF` | transparent | transparent |
| selected-foreground | `0xFF000000` | `0xFFFFFFFF` | `0xFFFFFFFF` | `0xFF000000` |
| unselected-foreground | `0xDD000000` | `0xDDFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| hover-overlay | `0x14000000` | `0x14FFFFFF` | `0x1F000000` | `0x1FFFFFFF` |
| pressed-overlay | `0x1F000000` | `0x1FFFFFFF` | `0x33000000` | `0x33FFFFFF` |
| drag-overlay | `0x26000000` | `0x26FFFFFF` | `0x33000000` | `0x33FFFFFF` |
| focus-outline | black | white | black | white |
| focus-outer-ring | `0xFF5B7FFF` | `0xFF5B7FFF` | black | white |
| action-surface | container surface | container surface | opaque white | opaque `0xFF121212` |
| action-foreground | black | white | black | white |
| selected-shadow | black 8% | black 8% | transparent | transparent |

The container/action surfaces map to `semantic.surface.glass`, borders to
`semantic.border.default`, unselected/action foregrounds to the corresponding
semantic text tokens, and the focus ring to `semantic.focus.canvas`.
Component-specific selected/highlight/interaction values preserve the approved
BottomBar anatomy. The migration classification is
`compatibility-correction-not-legacy-retained`.

## Semantics and input

The parent exposes native `SemanticsRole.tabBar`; every item exposes native
`SemanticsRole.tab`, caller product label only, mutually-exclusive selected
semantics, and tap activation. No generic-button role or synthesized position
copy is added to tab children.

There is one roving tab stop. Entry uses `selectedIndex`; Tab exits. LTR
Right/Left move next/previous, RTL reverses the horizontal mapping, and
Home/End move to logical first/last. Up/Down are not consumed. Navigation does
not select. Enter/Space activates the focused tab exactly once. Confirmed
pointer/touch taps own roving focus without keyboard decoration.

The separate conformant action and disclosure expose native button semantics,
caller labels/tooltips, and at least 44×44 targets. Disclosure exposes the
controlled expanded state.

## Motion, drag, haptic, scaling, and safe area

Controlled selection uses `BLabMotion.durSurface` and `BLabMotion.ease`;
hover/pressed use `BLabMotion.durPress`. Reduced motion makes nonessential
transitions immediate. Callbacks and semantics are never delayed.

Long-press drag is touch-only and supplemental. Its physical movement maps to
logical indices in both LTR and RTL and commits one callback, including valid
selected reactivation. Unconditional `HapticFeedback` calls are removed.
Eligibility remains governed by the existing default-deny `BLabHapticPolicy`;
no keyboard, pointer, focus, hover, or programmatic haptic is allowed.

Ambient linear and nonlinear scaling is not clamped. The bar grows beyond its
62px baseline when content requires it and must not clip. Safe-area bottom
inset remains outside the baseline and is never counted twice. `noMargin`
removes only the component-owned outer spacing.

## Evidence and claim boundary

Automated source, contract, semantics, contrast, keyboard, scaling, motion,
analyzer, and bundle evidence may support the family packet. Phase 4 retains
goldens, physical-device rendering, real assistive-technology sessions, and
platform-matrix confirmation. Global capability and repository-wide
conformance remain false. Astryx contributes capability/method evidence only.
The methods-only owner statement is unsigned; copy, derivation, values,
vocabulary, assets, appearance, and documentation facts remain unknown pending
a signed attestation.
