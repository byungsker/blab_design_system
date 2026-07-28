# BLDS Phase 3 Snackbar Design decision

Status: APPROVED implementation authority, independent gates pending

As of: 2026-07-28

Canonical packet:
`BLDS-PHASE3-SNACKBAR-DESIGN-DECISION-2026-07-28`

Scope: `BLabSnackbar` family only

Design authority: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

This record is the binding Snackbar family boundary. It does not authorize
changes to another component, global Blab conformance, release, publication,
deployment, or Figma mutation. Astryx contributes capability method evidence.
The methods-only scope is an unsigned owner statement; copy, derivation,
source, values, vocabulary, assets, appearance, and documentation facts remain
unknown.

## Compatibility and additive API

The exact legacy `BLabSnackbar.show` signature, parameter order, defaults, void
return, and `BLabSnackbarType` order—`success`, `error`, `info`, `warning`—stay
source-compatible.

The additive API is:

- `BLabSnackbarAction(label, onPressed, dismissOnPressed: true)`;
- `BLabSnackbarAnnouncementPriority.polite/assertive`;
- `BLabSnackbarQueuePolicy.enqueue/replaceCurrent/dropDuplicate`;
- `BLabSnackbarClosedReason.timeout/action/dismiss/programmatic/replaced/routeDisposed`;
- `BLabSnackbarController.closed` and idempotent `dismiss()`;
- `BLabSnackbar.showManaged`, retaining the legacy inputs and adding `action`,
  `showDismissAction`, `dismissSemanticLabel`, `announcementPriority`,
  `queuePolicy`, and `persist`.

Caller-owned action and dismiss labels must be nonblank. The default
announcement priority is polite; assertive is available only through explicit
caller opt-in.

## Queue, closure, and timeout

Each `OverlayState` owns one manager and can expose at most one Snackbar. The
enqueue policy is FIFO. Replace-current completes the current exit before the
replacement is inserted. Drop-duplicate compares type, message, and action
label across the visible and queued records and returns the existing
controller.

The controller completes exactly once with the observed close reason.
Programmatic dismissal is idempotent, and completion clears its retained
dismiss callback. A caller route's `popped` future closes both current and
pending records owned by that route with `routeDisposed`. Interactive Snackbar
timeouts are at least four seconds. `persist` disables timeout. Accessible
navigation combined with controls disables timeout. Otherwise elapsed time is
measured by a continuously advancing monotonic stopwatch, pauses during
pointer hover, owned focus, and inactive application lifecycle, then resumes
with the remaining duration.

## Semantics, focus, and input

The message is the only announcement content and becomes available only after
entry motion reaches visible. When the platform reports explicit announcement
support, exactly one priority-bearing event is sent and the message semantics
is not also a live region. Otherwise no explicit event is sent and the message
uses the implicit live-region fallback. Controls remain separate button
semantics. Explicit delivery is best-effort: an exception or unresolved
platform response never blocks timeout startup or the rest of the Snackbar
lifecycle. The Snackbar is nonmodal, never steals initial focus, and never
traps traversal.

Action and dismiss controls support one Enter or Space activation per key
cycle through their existing Button/IconButton contracts. Escape dismisses
only while focus is inside the Snackbar. Prior focus is captured when a queued
record becomes current. Restoration is conditional: after exit it re-checks
that the Snackbar still owns focus, then restores only when the prior node is
still mounted and requestable.

## Visual and geometry contract

The surface is opaque `semantic.surface.overlay`, foreground is
`semantic.text.primary`, and the border is `semantic.border.default` in
standard modes and `semantic.border.strong` in high contrast. There is no
blur, gradient, inner highlight, or glass treatment. Standard modes use the
existing standard `BLabShadow.two` shadow; high contrast has no shadow.

The radius is `BLabRadius.lg`. Horizontal outer/content padding is 20,
vertical padding is 16, and content/control gaps are 12 logical pixels. The
badge is 32 with a 20 icon. Status badges use semantic status colors, a black
glyph, distinct glyphs by type, and a strong high-contrast outline. The action
reuses the secondary Button contract. Dismiss is at least 44×44.

Placement resolves from live `MediaQuery`: keyboard mode uses
`viewInsets.bottom + 8`; otherwise it uses the greater of `bottomOffset` and
`viewPadding.bottom + 8`. Horizontal insets are safe and directional. Ambient
linear and nonlinear text scaling is not clamped. Controls wrap and stack when
width or scaling requires it, and RTL remains native.

## State and motion

Required states are entering, visible, exiting, success, error, warning, info,
and live-announcement. Action and dismiss rest/hover/pressed/keyboard-focus,
timer-paused, and programmatic-close are conditional. Disabled, loading,
selected, invalid, current, and expanded are not applicable and are not
simulated.

Normal entry and exit use `BLabMotion.durSurface` and `BLabMotion.ease`.
Reduced motion removes translation and limits essential opacity to
`BLabMotion.durPress`. No Snackbar interaction triggers haptics.

## Evidence boundary

Automated contract, generation, API, widget, semantics, keyboard, timing,
scaling, placement, analyzer, and bundle evidence may support this family.
Phase 4 retains goldens, physical-device rendering, real assistive-technology
sessions, and platform-matrix confirmation. Those deferred checks must not be
represented as completed.
