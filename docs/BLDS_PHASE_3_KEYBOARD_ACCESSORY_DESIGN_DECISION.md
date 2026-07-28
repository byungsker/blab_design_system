# BLDS Phase 3 KeyboardAccessoryBar Design decision

Status: APPROVED implementation authority, independent gates pending

As of: 2026-07-28

Canonical packet:
`BLDS-PHASE3-KEYBOARD-ACCESSORY-DESIGN-DECISION-2026-07-28`

Scope: `BLabKeyboardAccessoryBar` family only

Design authority: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

This record is the binding KeyboardAccessoryBar family boundary. It does not
authorize another component change, a global Blab conformance claim, release,
publication, deployment, product integration, or Figma mutation. Astryx is a
capability reference. The methods-only scope is an unsigned owner statement;
copy, derivation, source, values, vocabulary, assets, appearance, and
documentation facts remain unknown pending signed attestation.

## Compatibility and additive API

`BLabKeyboardAccessoryBar` remains a `StatefulWidget` with a const constructor.
The existing constructor fields, order, required inputs, defaults, and public
types remain source-compatible. The only public additions are nullable,
caller-owned localized labels:

- `upSemanticLabel`;
- `downSemanticLabel`;
- `copySemanticLabel`;
- `clearAllSemanticLabel`;
- `undoSemanticLabel`;
- `redoSemanticLabel`;
- `doneSemanticLabel`.

A supplied label is rejected when blank after trimming. Caller labels take
precedence. Legacy null labels resolve to nonblank platform localization
where Flutter exposes one. Flutter exposes no localized undo/redo getter, so
the legacy fallback uses the nonblank platform key labels; consumers requiring
localized undo/redo names must supply the additive fields. That compatibility
fallback is not localization-conformance evidence.

No haptic configuration or haptic API is added, and no interaction emits
haptic feedback.

## Action rendering and availability

Done is always rendered and enabled. Up and Down render only when
`showNavigation` is true and are enabled only when their callback exists and
their `can` flag is true. Copy, Clear All, Undo, and Redo render only when their
callback exists and are enabled only when their `can` flag is true.

Every rendered action is an independent native button-semantic node with one
nonblank semantic name and excluded icon semantics. Each natural button target
is 48×48 logical pixels and retains a 44×44 minimum constraint. Disabled
actions remain named button nodes without tap actions and leave sequential
focus traversal. Loading, selected, and invalid are not applicable.

## Input, focus, and repeat

Each enabled action is one logical Tab stop. Traversal follows reading order
and exits normally; the bar does not trap focus. Enter and Space activate the
focused action exactly once per physical key cycle. Semantic activation invokes
the action once and never starts repeat. Pointer activation owns focus for
continuity but registers pointer modality first, so it never displays a
keyboard focus ring.

Keyboard-visible focus uses `component.keyboard-accessory.focus-outline` at
exactly 2px plus `component.keyboard-accessory.focus-outer-ring` at exactly
3px. Pointer, touch, hover, and programmatic focus do not display this
decoration.

Undo and Redo alone support pointer long-press repeat:

1. the recognized long press invokes one initial callback;
2. it then waits 500ms;
3. it invokes the first repeat callback;
4. subsequent repeat callbacks occur every 100ms.

A recognized long press never also dispatches tap. Repeat stops on pointer up
or cancel, active callback identity change, enabled-state change, any
application lifecycle change, pointer down on another repeat-capable action,
disposal, or callback exception. Keyboard and semantic activation always
remain single-shot. Repeat cadence is unchanged by reduced motion.

## Narrow-width overflow addendum

Design addendum
`BLDS-PHASE3-KEYBOARD-ACCESSORY-NARROW-WIDTH-ADDENDUM-2026-07-28`
authorizes one conditional `scrollable-overflow` state without changing the
public API or token set.

Let `L` be the rendered Up, Down, Copy, and Clear All count and `H` the
rendered Undo and Redo count. Disabled rendered actions still count. The exact
outer width is:

```text
requiredWidth =
  32
  + 48 × (L + H + 1)
  + max(0, L - 1)
  + H
```

The seven-action matrix therefore requires 373px. A finite
`maxWidth < requiredWidth` uses component-owned overflow; exactly 373px,
sufficient width, and unbounded width retain the fixed row and `Spacer`. The
minimum valid host allocation is:

```text
minimumValidHostWidth =
  32
  + 48 for Done
  + (L + H > 0 ? 48 : 0)
  + (H > 0 ? 1 : 0)
```

Done-only therefore requires 80px, any leading action without history requires
128px, and any rendered history action requires 129px. The conditional 48px
allocation guarantees one complete scrolling target viewport; the history
pixel preserves the required fixed divider before Done. A finite host below
its applicable minimum is invalid and emits a debug diagnostic; it is not
overflow-conformance evidence.

In overflow, Done is pinned at logical trailing and every other rendered
action shares one horizontal viewport. Logical action order and within-group
dividers remain unchanged; rendered Undo or Redo adds one fixed 1px divider
before Done. Maximum scrolling content is 292px, the pinned block is 49px,
and the viewport is exactly 239px at 320px or 279px at 360px. The controller
is owned, non-primary, horizontal, clamped, and has no scrollbar. Targets and
dividers never wrap, scale, compress, overlap, or duplicate. Horizontal drag
belongs to the component while vertical drag remains available to ancestors.
Drag before long-press recognition invokes no action, and manual scrolling
cancels pointer-pressed and repeat state.

Initial overflow position is logical start. RTL keeps the first logical action
at physical right and pins Done at physical left. A Directionality change
resets immediately to logical start unless an enabled scrolling action owns
focus, in which case that complete target is revealed immediately. Exiting
overflow discards its position; re-entry starts fresh under the same rule.
Active-overflow width or composition changes preserve then clamp the offset
and reveal any internally focused action.

Focus acquisition reveals the complete 48px scrolling target. Normal reveal
uses `BLabMotion.durPress` (150ms) and `BLabMotion.ease`; initial,
Directionality-reset, accessibility-focus, and reduced-motion reveals are
immediate. A newer reveal retargets active motion, an already visible target
does not restart it, Done focus never changes the offset, and programmatic
focus does not synthesize keyboard modality or a focus ring. Accessibility
focus reveals without moving keyboard focus.

Native horizontal scroll semantics exist only during real overflow and expose
physical scroll-left/right actions according to available extent and RTL.
Action nodes remain individually named, ordered, single-shot, and available
offscreen. No duplicate scroll label, hidden-action count, synthetic action,
fade, mask, edge gradient, shadow, ellipsis, copied action, or “more”
affordance is added. The standard surface gradient remains fixed across the
whole component; high-contrast treatment and host placement ownership remain
unchanged.

## Direction, placement, and ownership

RTL mirrors leading and trailing group placement through directional layout.
Undo and Redo also exchange their logical glyph direction in RTL. The host
owns safe-area padding, `viewInsets`, keyboard attachment, and any overlay.
The component adds no `SafeArea`, inset compensation, `Overlay`, or
positioning layer.

## Tokens and visual modes

The family maps through:

- `component.keyboard-accessory.surface-start`;
- `component.keyboard-accessory.surface-end`;
- `component.keyboard-accessory.border`;
- `component.keyboard-accessory.foreground`;
- `component.keyboard-accessory.disabled-foreground`;
- `component.keyboard-accessory.divider`;
- `component.keyboard-accessory.hover-overlay`;
- `component.keyboard-accessory.pressed-overlay`;
- `component.keyboard-accessory.focus-outline`;
- `component.keyboard-accessory.focus-outer-ring`;
- `component.keyboard-accessory.shadow`;
- `component.keyboard-accessory.blur`.

Standard light and dark modes preserve the existing gradient, 20px blur,
border, foreground/disabled alpha, divider, and shadow appearance. Hover,
pressed, and focus are additive component-state corrections. High-contrast
light and dark use one opaque surface, a strong border, no gradient, zero blur,
and no shadow.

Normal hover/pressed visuals use `BLabMotion.durPress` and `BLabMotion.ease`.
Reduced motion makes those nonessential visuals immediate. Targets and icon
content do not clamp or override ambient linear or nonlinear text scaling.

## Evidence boundary

Required evidence covers default, pointer hover, pressed, keyboard focus, and
disabled-per-action. Long-press repeat-active is conditional. Automated
contract, token generation, public API, widget, semantics, input, timing,
cancellation, four-mode, scaling, reduced-motion, analyzer, and source
ownership checks may support this family. Approved goldens, physical-device
rendering, real assistive-technology sessions, platform-matrix confirmation,
and representative product-consumer builds remain later gates.
