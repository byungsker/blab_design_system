# BLDS Phase 3 BLabTabBar Design decision

Decision ID:
`BLDS-PHASE3-NAVIGATION-TABBAR-DESIGN-DECISION-2026-07-26`

Status: APPROVED

As of: 2026-07-26

Design owner: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and authority

This decision authorizes only `BLabTabBar`. Blab is the visual and semantic
authority. Astryx is capability and method evidence only; its source, values,
appearance, vocabulary, assets, and copy are excluded. The decision does not
authorize `BLabBottomBar`, global Blab conformance, release, publication,
Figma mutation, or real assistive-technology claims.

## Public compatibility

`BLabTabBar` remains a `StatelessWidget` implementing
`PreferredSizeWidget`. Its constructor, caller-owned `TabController`, string
labels, color and style overrides, `indicatorWeight`, `isScrollable`,
`onTap`, and `dividerColor` remain unchanged. Defaults remain
`indicatorWeight = 3`, `isScrollable = false`, transparent divider, and a
minimum preferred height of 56. No additive public API is allowed. A private
stateful delegate is allowed.

Disabled is a conditional-unmet state because there is no public condition or
committed consumer need. Engineering must not add disabled inputs, disabled
indexes, public scroll/focus controllers, a new item type, haptic options, or
simulated disabled behavior.

## State precedence and pointer ownership

Precedence is:

1. keyboard-visible focus composing with selected-current;
2. pressed replacing hover;
3. pointer hover;
4. selected-current;
5. unselected;
6. default.

Pointer-down changes modality and pending pressed feedback only. A confirmed
tap updates the roving focus, requests pointer focus without keyboard-visible
decoration, performs one activation, and invokes `onTap` exactly once.
Horizontal touch drag preserves outside focus, selection, the roving Tab
entry, and callback count.

## Canonical token graph

| Component token | Light | Dark | High-contrast light | High-contrast dark |
| --- | --- | --- | --- | --- |
| `component.tab.container-surface` | `0x00000000` | `0x00000000` | `0x00000000` | `0x00000000` |
| `component.tab.selected-indicator` | `semantic.text.primary` → `0xFF000000` | `0xFFFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `component.tab.selected-foreground` | `semantic.text.primary` → `0xFF000000` | `0xFFFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `component.tab.unselected-foreground` | `semantic.text.secondary` → `0xDD000000` | `0xDDFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `component.tab.hover-overlay` | `0x14000000` | `0x14FFFFFF` | `0x1F000000` | `0x1FFFFFFF` |
| `component.tab.pressed-overlay` | `0x1F000000` | `0x1FFFFFFF` | `0x33000000` | `0x33FFFFFF` |
| `component.tab.focus-outline` | `0xFF000000` | `0xFFFFFFFF` | `0xFF000000` | `0xFFFFFFFF` |
| `component.tab.focus-outer-ring` | `semantic.focus.canvas` → `0xFF5B7FFF` | `0xFF5B7FFF` | `0xFF000000` | `0xFFFFFFFF` |
| `component.tab.divider` | `0x00000000` | `0x00000000` | `0x00000000` | `0x00000000` |

The container is transparent over a caller-owned Blab surface. Existing
selected indicator/foreground, 3px indicator weight, 56px minimum height, and
transparent divider are compatibility-retained. The former light
`grey[400]` and dark `grey[600]` unselected colors are corrected to
`semantic.text.secondary`. Hover, pressed, and modality-aware focus are
capability additions using approved Blab values. High contrast never relies
on opacity as the only state distinction.

## Geometry, typography, indicator, and divider

Every semantic and hit target is at least 44×44. The bar is at least 56 high
and may grow for ambient linear 1.0–2.0 or nonlinear `TextScaler` values; it
must not clamp or clip text. The selected style is `BLabTypography.label`
with weight 600 and the unselected style uses the same scale with weight 400.

The indicator is a label-width, bottom-aligned underline. Its default
thickness is 3px, with top radii equal to its thickness and square bottom
corners. The default divider is absent. A caller `dividerColor` produces a
full-width bottom 1px line, with the indicator painted above it. Keyboard
focus composes with the indicator through a 2px monochrome outline and 3px
outer ring drawn inside the tab target so the scroll viewport does not clip
them.

For `isScrollable = false`, tabs retain equal width. The Design-approved
conformance condition is `availableWidth >= tabs.length × 44`; narrower
non-scrollable caller configurations must use `isScrollable = true` and are
outside conformance claims.

## Controller, selection, callbacks, and semantics

Tabs must be non-empty and `controller.length` must equal `tabs.length`.
`TabController.index` is the only selected-current authority. Native tab
semantics expose the selected tab with `selected = true`; no separate
`current` copy is synthesized. Only caller labels and platform-localized
position/set-size semantics are used.

Confirmed pointer/touch tap, semantic tap, Enter, and Space request
`controller.animateTo` once for a different tab and invoke `onTap(index)`
exactly once. Reactivating the selected tab does not restart selection
animation and invokes `onTap` once. External controller changes,
Arrow/Home/End, swipe/drag, and rebuild never invoke `onTap`. `onTap` remains
a post-activation notification, not a veto API. If a caller changes the
controller after the callback, the latest controller state wins without an
additional callback. BLDS emits no haptic.

## Keyboard, focus, and RTL

There is exactly one roving Tab stop, initially at `controller.index`. Tab
enters the current tab and the next Tab exits. Navigation wraps:

- LTR Right is next and Left is previous;
- RTL Right is previous and Left is next;
- Home is first and End is last.

Up and Down are not consumed, preserving ancestor vertical navigation and
scroll. Arrow/Home/End move focus and controller selection together without
calling `onTap`. Enter and Space activate the focused tab exactly once.

External controller changes synchronize the roving entry. If focus is
outside, the control reveals the new selection without stealing focus. If
focus is inside, focus moves once to the new current tab. Pointer-down does not
move focus; only a confirmed tap does. Pointer/touch focus has no
keyboard-visible focus decoration.

## Scrollable overflow

Overflow applies only when `isScrollable = true`. Tab width reflects label
content and padding with a 44px minimum. The component privately owns a
non-primary horizontal scroll controller with clamping physics. It adds no
scrollbar, gradient, synthesized instruction, or affordance and preserves
native horizontal scroll semantics.

The initial current tab is revealed immediately. Arrow/Home/End, confirmed
activation, and external controller changes reveal the current or focused tab.
Outside-focus external changes reveal without focus theft. Manual horizontal
drag changes no selection, focus, callback, or roving entry; vertical drag
remains with ancestors. RTL logical start and physical direction follow
Flutter `Directionality`. Reveal centers the target when possible and clamps
at both ends. Focus decoration is inside the target, so no external ring
allowance is required.

## Motion and reduced motion

Component-originated indicator position and label color/weight transitions use
`BLabMotion.durSurface` (300ms) and `BLabMotion.ease`. Hover/pressed overlays
and programmatic scroll reveal use `BLabMotion.durPress` (150ms) with the same
curve. Initial reveal and all component-owned transitions are immediate under
reduced motion. Caller-originated `TabController.animateTo` duration and curve
remain caller-owned and outside BLDS motion claims.

## Override precedence and contrast boundary

Color precedence is:

1. dedicated color argument (`labelColor`, `unselectedLabelColor`,
   `indicatorColor`, `dividerColor`);
2. corresponding `TextStyle.color`;
3. the component token.

Non-color properties from `labelStyle` and `unselectedLabelStyle` merge over
their respective defaults. Custom colors, styles, or indicator weight remain
source-compatible, but contrast, scaling, clipping, and visual conformance for
those combinations are caller responsibilities.

Default accessibility evidence applies only on Blab `semantic.surface.base`,
`semantic.surface.raised`, and `semantic.surface.overlay`. Normal text must
remain at least 4.5:1 after hover/pressed compositing; indicator and both focus
adjacencies must remain at least 3:1. No automatic conformance claim is made
over transparent arbitrary product backgrounds or custom overrides.

## Unsupported states and deferred evidence

The following states are unsupported and must not be simulated: disabled,
loading, busy, invalid, error, expanded, disclosure, drag-selection, haptic,
and BottomBar behavior.

This decision is family-partial evidence only. Phase 4 approved goldens,
real-screen-reader verification, and platform-specific focus/scroll
observation remain deferred. Automated checks do not establish global visual,
accessibility, locale, release, or package conformance.

## Rollback

Rollback restores only TabBar source, component tokens/theme mappings,
canonical decision/applicability/capability evidence, focused tests, story,
status, and the reviewed API checksum header, then regenerates shared outputs.
Generated outputs are regenerated rather than deleted because they contain
completed Button, TextField, and SegmentedControl evidence. SegmentedControl,
BottomBar, caller controller ownership, consumer localization strings,
`DESIGN.md`, and product repositories remain invariants.
