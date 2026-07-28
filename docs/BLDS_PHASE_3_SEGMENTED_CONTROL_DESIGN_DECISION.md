# BLDS Phase 3 BLabSegmentedControl Design decision

Decision ID:
`BLDS-PHASE3-NAVIGATION-SEGMENTED-DESIGN-DECISION-2026-07-26`

Status: APPROVED

As of: 2026-07-26

Design owner: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and authority

This decision applies only to `BLabSegmentedControl`. It does not approve or
make implementation claims for `BLabTabBar` or `BLabBottomBar`. Blab remains
the visual and semantic authority. Astryx remains capability and method
evidence only. The methods-only scope is an unsigned owner statement; copy,
derivation, source, values, vocabulary, assets, appearance, documentation, and
adoption facts remain unknown.

The canonical machine-readable citation is
`component_decisions.segmented-control.decision_ref` in
`contracts/blab.design.yaml`. This document is the durable human-readable
record of the exact approved packet. Indicator motion and conditional narrow
overflow are supplemented by the approved
`BLDS-PHASE3-NAVIGATION-SEGMENTED-SCROLLABLE-OVERFLOW-ADDENDUM-2026-07-26`,
durably recorded in
[`BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md`](./BLDS_PHASE_3_SEGMENTED_CONTROL_SCROLLABLE_OVERFLOW_ADDENDUM.md).

## State contract

Precedence is:

1. disabled;
2. keyboard-visible focus, composing with selection;
3. pressed, replacing hover;
4. hover;
5. selected;
6. unselected.

Disabled suppresses hover, pressed, focus, activation, and traversal. A
disabled selected item retains its selected surface and weight; its indicator
and text use the disabled foreground. Keyboard-visible focus uses a
monochrome 2px outline and a 3px outer ring without replacing selection.
Pointer and touch focus receive no keyboard-focus decoration.

Selected items use the selected surface, weight 600, and a full-width
inset-bottom 2px indicator. Unselected items use weight 400.

## Exact component tokens

ARGB values are ordered light, dark, high-contrast light, high-contrast dark.

| `component.segmented` token | Light | Dark | HC light | HC dark |
| --- | --- | --- | --- | --- |
| `container-surface` | `0xFFF5F5F5` | `0xFF232323` | `0xFFFFFFFF` | `0xFF121212` |
| `container-border` | `0x00000000` | `0x00000000` | `0xFF000000` | `0xFFFFFFFF` |
| `selected-surface` | `0xFFFFFFFF` | `0xFF2C2C2E` | `0xFFFFFFFF` | `0xFF121212` |
| `selected-indicator` | `0xFF5B7FFF` | `0xFF5B7FFF` | `0xFF000000` | `0xFFFFFFFF` |
| `selected-foreground` | `0xFF000000` | `0xFFFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `unselected-foreground` | `0xDD000000` | `0xDDFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `disabled-foreground` | `0xFF68707D` | `0xFF9CA3AF` | `0xFF6B7280` | `0xFF9CA3AF` |
| `hover-overlay` | `0x14000000` | `0x14FFFFFF` | `0x1F000000` | `0x1FFFFFFF` |
| `pressed-overlay` | `0x1F000000` | `0x1FFFFFFF` | `0x33000000` | `0x33FFFFFF` |
| `focus-outline` | `0xFF000000` | `0xFFFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `focus-outer-ring` | `0xFF5B7FFF` | `0xFF5B7FFF` | `0xFF000000` | `0xFFFFFFFF` |
| `selected-shadow` | black 8% | black 8% | none | none |

The standard selected shadow uses blur 4 and y-offset 1. High-contrast mode
uses a 1px container border, opaque surfaces, no shadow, blur, gradient, or
highlight.

## Geometry, contrast, and motion

The indicator is 2px. Focus widths use the existing semantic 2px outline and
3px ring. The outer radius uses the caller's existing radius; the selected
radius is `max(0, radius - padding)`. The visible minimum remains 40px with
padding 3, font size 13, and weights 600/400. Interactive and semantic targets
are at least 44×44. Layout may grow and does not clamp ambient linear or
nonlinear text scaling. When a finite available width is below
`itemCount × 44px + 2 × horizontal padding`, the control exposes the
addendum-defined owned horizontal scroll viewport and preserves every item's
44px minimum width; it never silently shrinks semantic or hit targets.
Unbounded and sufficient widths do not scroll.

Normal text is tested at 4.5:1 minimum; indicators and focus visuals are
tested at 3:1 minimum. Alpha foreground and overlay colors are composited in
paint order before luminance is calculated. Exact ratios are:

| Actual foreground/background pair | Light | Dark | HC light | HC dark |
| --- | ---: | ---: | ---: | ---: |
| selected foreground / selected surface | 21.000000 | 13.936646 | 21.000000 | 18.733664 |
| composited unselected foreground / container surface | 14.828065 | 12.094355 | 21.000000 | 18.733664 |
| disabled foreground / container surface | 4.583551 | 6.190552 | 4.834490 | 7.378825 |
| disabled foreground / selected surface | 4.997129 | 5.489373 | 4.834490 | 7.378825 |
| composited unselected foreground / hover-over-container | 12.827809 | 9.751737 | 15.908084 | 13.424353 |
| composited unselected foreground / pressed-over-container | 11.776640 | 8.542605 | 13.076547 | 10.144430 |
| selected foreground / hover-over-selected | 17.615398 | 10.915317 | 15.908084 | 13.424353 |
| selected foreground / pressed-over-selected | 15.908084 | 9.471309 | 13.076547 | 10.144430 |
| selected indicator / selected surface | 3.544556 | 3.931845 | 21.000000 | 18.733664 |
| focus outline / selected surface | 21.000000 | 13.936646 | 21.000000 | 18.733664 |
| focus outline / container surface | 19.261973 | 15.716827 | 21.000000 | 18.733664 |
| outer ring / canvas surface base | 3.395932 | 5.285193 | 21.000000 | 18.733664 |
| outer ring / container surface | 3.251197 | 4.434075 | 21.000000 | 18.733664 |
| outer ring / selected surface | 3.544556 | 3.931845 | 21.000000 | 18.733664 |

The outer ring's outside edge can adjoin the canvas above/below the visible
container or the container surface along item sides; its inside edge adjoins
the selected surface when selection composes with focus. Tests cover all three
actual adjacency pairs.

Selected and indicator feedback use `BLabMotion.durSegment` (180ms) and
`BLabMotion.ease`. Hover and pressed feedback use `BLabMotion.durPress`
(150ms) and the same curve. Focus has no animation. All nonessential
transitions are immediate under reduced motion. There is no movement, scale,
or haptic API. Per the approved addendum, every item owns one stable indicator
node at a fixed inset-bottom position. Controlled selection animates only
indicator opacity and color for 180ms; reduced motion resolves the same
transition to zero duration. Indicator position and scale never animate.

## API, semantics, and controlled selection

The only approved additive API is:

- `BLabSegmentedItem<T>.enabled`, default `true`;
- `BLabSegmentedControl<T>.enabled`, default `true`.

The public `BLabSegmentedControl<T>` remains a `StatelessWidget`. It delegates
focus, hover, press, and animation state to a private stateful implementation,
preserving the established public inheritance contract.

An all-disabled control is valid. If a focused item becomes disabled, focus
moves to the next enabled item, otherwise the previous enabled item, without
callback or haptic. A disabled selection retains the current enabled focus.

Each item exposes only the caller label and native selected, enabled, focus,
tap, and mutually-exclusive-group semantics. It does not stringify `T`,
synthesize positional copy, or expose `current`.

Selection remains controlled. Reactivating the selected item calls
`onChanged` exactly once without restarting selection animation or invoking
haptics. External `selectedValue` changes do not call back or invoke haptics.
An external enabled selection synchronizes roving focus when focus is already
inside; it does not steal outside focus. Synchronization runs only when
`selectedValue` changes. An unrelated parent rebuild after a rejected or
asynchronous selection request preserves the newly roved focus.

There is one roving Tab stop. Entry is the selected enabled item, otherwise
the first enabled item; Tab exits. Traversal wraps enabled items only and
selection follows focus: Arrow, Home, and End invoke `onChanged` once while
the visual selection waits for the controlled value.

- LTR: Right next, Left previous.
- RTL: Right previous, Left next.
- Both directions: Up previous, Down next, Home first, End last.
- Enter and Space activate exactly once.

Pointer and touch interaction update focus ownership without keyboard-visible
decoration. Each handled navigation key requests the destination focus exactly
once.

## Unsupported states

The implementation must not simulate loading, busy, invalid, error, overlay,
expanded, current, disclosure, drag, or haptic states.

This is a family-partial Design decision. It does not authorize global visual
or accessibility conformance, release, publication, Figma mutation, or
Phase 4 golden/real assistive-technology claims.
