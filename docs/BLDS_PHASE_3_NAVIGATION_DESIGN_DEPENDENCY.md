# BLDS Phase 3 navigation family Design dependency

Status: SegmentedControl, TabBar, and BottomBar dependencies closed

As of: 2026-07-26

Dependency packet:
`BLDS-PHASE3-NAVIGATION-DESIGN-DEPENDENCY-2026-07-26`

Originating engineering task:
`BLDS-PHASE3-NAVIGATION-FAMILY-2026-07-26`

Implementation owner:
`engineering-team > engineering-frontend > engineering-design-system-frontend`

Design owner: byungskerlab Design Team

## Scoped resolution

Independent Design approved only the first boundary through
`BLDS-PHASE3-NAVIGATION-SEGMENTED-DESIGN-DECISION-2026-07-26`. Its exact
decision is recorded in
[`BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md`](./BLDS_PHASE_3_SEGMENTED_CONTROL_DESIGN_DECISION.md)
and cited canonically by `contracts/blab.design.yaml`.

Independent Design subsequently approved the second boundary through
`BLDS-PHASE3-NAVIGATION-TABBAR-DESIGN-DECISION-2026-07-26`. Its exact decision
is recorded in
[`BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md`](./BLDS_PHASE_3_TAB_BAR_DESIGN_DECISION.md)
and cited canonically by `contracts/blab.design.yaml`.

Independent Design approved the third boundary through
`BLDS-PHASE3-NAVIGATION-BOTTOMBAR-DESIGN-DECISION-2026-07-26`. Its exact
decision is recorded in
[`BLDS_PHASE_3_BOTTOM_BAR_DESIGN_DECISION.md`](./BLDS_PHASE_3_BOTTOM_BAR_DESIGN_DECISION.md)
and cited canonically by `contracts/blab.design.yaml`.

These decisions close the dependencies for `BLabSegmentedControl`,
`BLabTabBar`, and `BLabBottomBar`. The requests and baseline below remain the
historical family dependency packet.

## Decision requested

Approve the missing navigation-family visual, semantic, interaction, and
conditional-state contract for:

- `BLabSegmentedControl`;
- `BLabTabBar`; and
- `BLabBottomBar`.

Engineering has stopped before tests or production changes that would require
inventing Blab values or semantics. Astryx remains capability and method
evidence only and supplies no values, vocabulary, assets, appearance, source,
or implementation to this packet.

## Why implementation is blocked

The canonical applicability source names required and conditional navigation
states, and the shared Phase 2 contract supplies general accessibility
policies. The repository does not yet contain a Design-approved
navigation-family decision comparable to `component_decisions.button` or
`component_decisions.text-field`.

In particular, no canonical source defines:

- navigation-family token mappings for selected, unselected, hover, pressed,
  focus, disabled, indicator, or icon-only action states;
- state precedence when selected/current, focus, pressed, hover, and disabled
  overlap;
- the disabled-item or disabled-control public contract for segmented controls
  and tabs;
- whether disabled is applicable to `BLabBottomBar`;
- how selected and current semantics differ on platforms without a dedicated
  current channel;
- the accessible label, tooltip, and disclosure contract for the BottomBar
  action and first-tab chevron;
- the four-mode treatment of the BottomBar droplet, gradients, blur, shadows,
  icons, and labels; or
- which current component-local raw values are approved compatibility
  corrections, approved retained values, or values that must be replaced.

The current raw values are Phase 0 reference evidence marked
`component-local-raw` and `legacy-retained`. Engineering cannot promote them to
approved interaction or high-contrast semantics without Design authority.

## Verified family baseline

### Source and public API

| Component | Source | Phase 0 SHA-256 | Current public surface |
| --- | --- | --- | --- |
| Segmented control | `lib/src/widgets/blab_segmented_control.dart` | `d3fa831d6cf4764130cd4f1430f134f7db840b0dbd1816a067ca7a776cf97628` | generic item list, controlled selected value, required callback, height/radius/padding overrides |
| Tab bar | `lib/src/widgets/liquid_glass_tab_bar.dart` | `6120a861479ca1db44eb1fd14680a48ab046652e4f63bfc262c157a0176d8bc3` | caller-owned `TabController`, string labels, optional visual overrides, scrollability, tap callback |
| Bottom bar | `lib/src/widgets/liquid_glass_bottom_bar.dart` | `ed6440ff2e40014b501eeaa8548c7f40a9713dad8ef318dd79446e78c0e9f618` | controlled selected index, required selection callback, optional action, optional first-tab chevron, optional margin removal |

All three types are exported from
`package:blab_design_system/blab_design_system.dart` and are present in the
analyzer-backed API snapshot.

### Current implementation behavior

#### `BLabSegmentedControl`

- Two or more text segments are supported by current callers.
- Selection is controlled by `selectedValue`.
- Every item is currently enabled; there is no disabled-item or
  disabled-control condition.
- Activation is pointer/touch-only through `GestureDetector`.
- There is no hover, pressed, focus-visible, keyboard traversal, or explicit
  selected semantic adapter.
- The default visible height is 40 logical pixels, below the 44×44 interactive
  target unless a separate hit-target treatment is approved.
- Standard selected/unselected surfaces, shadows, typography, and foregrounds
  use component-local raw values.

#### `BLabTabBar`

- Selection and controlled updates are delegated to the caller-owned
  `TabController`.
- Flutter `TabBar` supplies baseline traversal and semantics, but BLDS does not
  explicitly contract or test its selected/current, hover, pressed, focus,
  disabled, RTL, or overflow behavior.
- The public API has no item-disabled condition.
- Several visual colors fall back to Flutter/theme defaults or
  component-local raw grey values rather than navigation-family Blab tokens.
- The example application has no dedicated TabBar story.

#### `BLabBottomBar`

- Selection is controlled by `selectedIndex`; tapping the selected item still
  invokes the callback, which current Baroguni callers use for product-local
  reselection behavior.
- Long-press drag is a supplemental selection path with unconditional legacy
  haptics and raw motion/visual values.
- Items and the optional action are pointer/touch-only; there is no explicit
  keyboard focus, activation, hover, pressed, selected/current semantic, or
  reduced-motion adapter.
- The optional action is icon-only and has no public semantic-label or tooltip
  contract.
- `showFirstTabChevron` and `onFirstTabChevronTap` exist publicly, but the
  current chevron is not a separate accessible disclosure control and the
  callback is not connected to a 44×44 action.
- The applicability source does not classify a disabled BottomBar item or
  control.
- Droplet colors, highlight gradients, shadows, blur, icon/label foregrounds,
  and haptic behavior are component-local legacy evidence.
- The example application has no dedicated BottomBar story.

## Confirmed callers

Committed Baroguni app HEAD:
`efa512c7d3539ba176cb5cb3c085d9906f6c4c84`.

| Component | Committed product call sites | Observed compatibility requirement |
| --- | ---: | --- |
| `BLabBottomBar` | 1 | Four localized items; controlled selection; reselection callbacks are meaningful |
| `BLabTabBar` | 2 | Two and four localized text tabs; caller-owned controllers; one divider override |
| `BLabSegmentedControl` | 1 | Two Korean text segments; controlled generic value |

The BLDS example has two segmented-control instances and no TabBar or BottomBar
story. These are textual/source observations, not runtime or conformance
evidence.

## Design-owned state applicability

The following matrix transcribes
`contracts/components/state-applicability.yaml`. It does not add Engineering
claims.

| Component | State | Classification | Current explicit BLDS evidence |
| --- | --- | --- | --- |
| Segmented | unselected | required | not claimed |
| Segmented | selected | required | not claimed |
| Segmented | hover-pointer | required | not claimed |
| Segmented | pressed | required | not claimed |
| Segmented | focus | required | not claimed |
| Segmented | disabled-item-or-control | conditional | no public condition |
| Segmented | keyboard-roving-focus | required when two or more enabled items | no explicit implementation |
| Segmented | loading, invalid, overlay | not applicable | must not be simulated |
| TabBar | unselected | required | not claimed |
| TabBar | selected-current | required | not claimed |
| TabBar | hover-pointer | required | not claimed |
| TabBar | pressed | required | not claimed |
| TabBar | focus | required | not claimed |
| TabBar | scrollable-overflow | conditional on `isScrollable` | delegated to Flutter; no BLDS evidence |
| TabBar | disabled | conditional on an explicit item contract | no public condition |
| TabBar | loading, invalid | not applicable | must not be simulated |
| BottomBar | unselected | required | not claimed |
| BottomBar | selected-current | required | not claimed |
| BottomBar | hover-pointer | required | not claimed |
| BottomBar | pressed | required | not claimed |
| BottomBar | focus | required | not claimed |
| BottomBar | long-press-drag | required | legacy path only; not claimed |
| BottomBar | optional-action | conditional when supplied | missing label/keyboard contract |
| BottomBar | expanded | conditional on a real disclosure control | current chevron is not a real control |
| BottomBar | loading, invalid | not applicable | must not be simulated |
| BottomBar | disabled | unclassified | Design decision required |

## Existing approved policies Engineering can apply after dependency closure

These policies already exist and do not require new values:

- 44×44 logical-pixel minimum interactive targets;
- ambient linear 1.0–2.0 and nonlinear text scaling without component clamps;
- keyboard-visible focus with a minimum 2px outline or distinct 3px ring and
  at least 3:1 adjacent contrast;
- arrow navigation for tabs and segments;
- default-deny, explicitly gated touch-only haptics;
- reduced-motion resolution through `BLabReducedMotionPolicy`;
- light, dark, high-contrast light, and high-contrast dark mode resolution;
- product-owned localized labels and platform-localized generic control
  vocabulary; and
- no accessibility, visual, locale, or package conformance claim from automated
  checks alone.

Design must still map these policies to navigation anatomy and overlapping
states.

## Required Design decisions

### 1. Family anatomy and state precedence

Approve one explicit precedence order per component for combinations of:

- disabled;
- keyboard-visible focus;
- pressed;
- pointer hover;
- selected/current; and
- default/unselected.

State whether the focus treatment replaces, surrounds, or composes with the
selected indicator and whether pressed replaces hover.

### 2. Four-mode token graph

Provide approved token references or exact ARGB values for light, dark,
high-contrast light, and high-contrast dark. Design may approve shared
navigation tokens or component-specific tokens, but must identify the mapping
for:

- control/container surface and border where applicable;
- selected/current indicator or surface;
- selected/current foreground;
- unselected foreground;
- disabled foreground and any disabled surface;
- pointer-hover treatment;
- pressed treatment;
- focus outline and optional outer ring;
- BottomBar droplet base, highlight, and shadow/blur disposition;
- BottomBar optional-action surface and foreground; and
- divider/indicator treatment where not caller-overridden.

For every translucent treatment, identify the compositing surface and required
contrast pair. State which current standard-mode raw values, if any, are
compatibility-retained or compatibility-corrected.

### 3. Disabled applicability and additive API shape

Approve:

- Segmented whole-control disabled, per-item disabled, or both;
- TabBar whole-control disabled, per-item disabled, or both; and
- whether BottomBar items, the whole bar, the optional action, or none are
  disabled states.

If per-item disabled behavior is required, approve whether existing item/string
APIs receive optional metadata, an additive item type, or a separate
default-empty disabled-index/value input. Every addition must remain
source-compatible and default-enabled.

### 4. Selection and current semantics

Define:

- whether segmented items expose only selected semantics;
- whether TabBar and BottomBar expose selected as the platform adapter for the
  Design-owned `selected-current` state when Flutter has no dedicated current
  field;
- whether re-activating an already selected item remains a meaningful callback;
  and
- what selected/current value, position, and set-size semantics must be
  exposed without inventing customer copy.

### 5. Keyboard model and RTL

Approve the navigation model for:

- Left/Right arrow traversal in LTR and RTL;
- whether Up/Down also traverse the horizontal controls;
- Home/End behavior;
- roving focus versus selection-follows-focus;
- Enter/Space activation when focus does not immediately select;
- controlled external updates while a control owns focus; and
- BottomBar keyboard behavior while preserving long-press drag as a
  supplemental touch interaction.

### 6. BottomBar icon-only action and disclosure

Approve:

- the default localized label/tooltip when the default search icon is used;
- the required caller-owned label contract for a custom `actionIcon`;
- whether tooltip and semantic label share one string;
- whether `showFirstTabChevron` represents an expanded/collapsed disclosure;
- the required additive expanded-state input;
- labels/tooltips for expand and collapse; and
- whether the chevron is a separate 44×44 control or part of the first tab.

Until this is approved, Engineering must not claim the optional action or
expanded state.

### 7. Motion, drag, and haptics

Map each animation to an existing motion token and classify it as essential or
nonessential for reduced motion:

- segmented selected-surface transition;
- TabBar indicator movement where BLDS owns it;
- BottomBar controlled-selection slide;
- BottomBar long-press drag/droplet response; and
- hover/pressed overlays.

Confirm that BottomBar haptics use the existing default-deny configuration and
state which committed touch events, if any, are eligible for one pulse.

### 8. High contrast and glass disposition

Confirm whether BottomBar high contrast:

- disables blur and decorative gradients/shadows using the existing
  high-contrast glass policy;
- uses an opaque surface and border;
- keeps or replaces the droplet treatment; and
- requires a separate selected indicator beyond icon/label foreground changes.

## Required Design response contract

Return a versioned packet with:

```text
packet_id
status: APPROVED | REQUEST_CHANGES
scope: BLabSegmentedControl | BLabTabBar | BLabBottomBar
state_precedence_by_component
token_matrix_light_dark_high_contrast_light_high_contrast_dark
token_reference_graph
translucent_compositing_surfaces_and_contrast_pairs
disabled_applicability_and_public_condition
selection_current_semantics
keyboard_rtl_model
bottom_bar_action_and_disclosure_contract
motion_reduced_motion_haptic_mapping
high_contrast_glass_disposition
compatibility_classification
unsupported_states_not_to_simulate
```

If Design approves only part of the family, identify the independently
implementable component boundary. Engineering will not infer approval for the
remaining components.

## Baseline verification

Before this packet was created:

- `dart run tool/validate_contract.dart` passed;
- `dart run tool/generate_tokens.dart --check` passed;
- `dart run tool/public_api_snapshot.dart --check` passed;
- `flutter test test/blab_design_system_test.dart -r compact` passed `7/7`;
- `flutter analyze --no-pub` reported no issues;
- all three navigation source hashes matched their immutable Phase 0 manifest;
- `DESIGN.md` matched
  `3efc7ad9cb1872e53f857b1e44422fad5040d6302fdfba9c6a94f2a96ca53bd4`;
  and
- Button, TextField, and every other protected component matched their recorded
  current or historical source hashes.

These checks establish a coherent pre-implementation baseline. They do not
close the Design dependency or claim any navigation-family state
implementation.

## Implementation boundary and rollback

No navigation source, canonical contract, token source, generator, generated
artifact, public API snapshot, example, or consumer repository is changed by
this dependency packet.

Rollback is deletion of this dependency document only. No product data,
consumer migration, or package behavior is involved.
