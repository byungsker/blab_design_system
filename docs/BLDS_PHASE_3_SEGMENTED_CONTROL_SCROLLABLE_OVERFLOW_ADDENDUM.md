# BLDS Phase 3 BLabSegmentedControl scrollable-overflow addendum

Decision ID:
`BLDS-PHASE3-NAVIGATION-SEGMENTED-SCROLLABLE-OVERFLOW-ADDENDUM-2026-07-26`

Status: APPROVED

As of: 2026-07-26

Design owner: byungskerlab Design Team

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Scope and authority

This addendum corrects only `BLabSegmentedControl` indicator motion and the
conditional `scrollable-overflow` state. It supplements
`BLDS-PHASE3-NAVIGATION-SEGMENTED-DESIGN-DECISION-2026-07-26`; it does not
authorize changes or claims for `BLabTabBar` or `BLabBottomBar`. It adds no
public API or token value.

The canonical citations are
`component_decisions.segmented-control.addendum_ref` and
`component_decisions.segmented-control.addendum_document` in
`contracts/blab.design.yaml`.

## Indicator correction

There is one stable, always-present 2px indicator node at the same
inset-bottom location in every item. Controlled selection transitions only
its opacity and color over `BLabMotion.durSegment` (180ms) with
`BLabMotion.ease`. Reduced motion resolves the transition immediately.
Disabled selected uses `component.segmented.disabled-foreground`.

Indicator position and scale never animate. The earlier one-node sliding
position statement is superseded by this addendum.

## Conditional overflow contract

`scrollable-overflow` applies only when the viewport width is finite and:

```text
itemCount × 44 + 2 × horizontalPadding > viewportWidth
```

Unbounded or sufficient width has no scroll viewport. Actual overflow uses a
component-owned, non-primary horizontal controller, clamping physics, no
scrollbar, gradient, synthesized copy, or visual affordance, and native
horizontal scroll semantics/actions in physical LTR/RTL directions. Vertical
drag ownership remains with ancestors.

The viewport begins at logical start: physical left in LTR and physical right
in RTL. After layout it immediately reveals a valid selected item, including a
disabled selected item, with 3px inline allowance for the outer focus ring.
The focus ring is not clipped.

## Reveal priorities and motion

- Arrow, Home, and End reveal the roved enabled focus target. Pending or
  rejected controlled selection never pulls the viewport away from that
  focus.
- An external enabled selection moves focus and reveals when focus is inside;
  outside it reveals without stealing focus.
- An external disabled selection leaves inside enabled focus authoritative and
  reveals that focus. With focus outside, it reveals the disabled selection.
- Programmatic reveal uses `BLabMotion.durPress` (150ms) and
  `BLabMotion.ease`. Initial reveal and reduced motion are immediate.
- A later reveal retargets the active motion. A target already fully visible
  with its 3px allowance does not restart motion.
- Manual horizontal scrolling changes no selection, focus, callback, or
  haptic state and remains in place until the next required reveal.
- Pointer/touch ownership suppresses keyboard-visible focus decoration.

This remains family-partial evidence. It does not establish global visual,
accessibility, locale, release, Phase 4 golden, or real assistive-technology
conformance.
