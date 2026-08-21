# BLDS Button foreground contrast amendment

Decision ref: `BLDS-BUTTON-CONTRAST-2026-07-28`

Status: Approved by byungsker on 2026-07-28; local implementation and evidence
refresh authorized

Design owner: `byungskerlab-design-team`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

## Decision

The standard light and dark mappings for
`semantic.action.primary-foreground` and
`semantic.action.destructive-foreground` resolve to
`primitive.color.black`.

This decision narrowly supersedes the standard-mode compatibility lock for
those two semantic foreground mappings. The compatibility lock continues to
apply to every other standard token value.

The existing primary `#5B7FFF` and destructive `#FF3B30` surfaces, hover
overlays, pressed overlay, focus treatment, geometry, motion, and
high-contrast mappings remain unchanged.

Unstyled custom Button content inherits the resolved foreground through
`DefaultTextStyle` and `IconTheme`. A custom child that explicitly supplies a
text or icon color remains consumer-owned and is not a Button conformance
claim.

## Accessibility and state boundary

The active default, hover, pressed, and keyboard-visible focus states must
retain at least `4.5:1` composed foreground-to-surface contrast in light, dark,
high-contrast light, and high-contrast dark modes. Overlay composition applies
to both the content and its surface because the interaction overlay is painted
above both.

Disabled Button content remains rendered through the existing whole-control
`0.5` opacity. It is an inactive-control contrast exception and remains
explicitly unverified against the active `4.5:1` target. No disabled behavior
or token is changed.

`loading-busy` remains conditional, has no public API or runtime condition, and
remains `not-claimed`.

## Visual evidence boundary

The eight standard-mode Phase 4 image identities affected by the primary
foreground change were recaptured and approved by Design on 2026-07-28 for
bounded local reproducibility and fixture review. The durable approval binds
their exact new hashes.

The high-contrast light and high-contrast dark mappings were already black.
Their two approved image identities remain byte-identical.

Golden equality remains reproducibility evidence, not accessibility or visual
conformance.

## Rejected alternatives

- Darkening primary or destructive surfaces.
- Adding a one-off foreground or darker-surface primitive.
- Retaining white and relying on high-contrast mode, focus rings, larger type,
  shadows, or state overlays.

## Authority boundary

This decision authorizes the local contract, runtime, test, deterministic
generation, candidate recapture, and directly affected evidence updates only.
It does not authorize Git mutation, release, publication, deployment, consumer
mutation, or any Button or repository-wide conformance claim.
