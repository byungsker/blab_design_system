<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabBottomBar

Bottom navigation with selected, focus, drag, optional action, and localized label behavior.

## Usage boundary

Use for top-level product navigation; accessibility-large reflow and action semantics remain bounded by the consumer and state contract.

## Source and evidence

- Source: `lib/src/widgets/liquid_glass_bottom_bar.dart`
- Example: `example/lib/stories/bottom_bar_story.dart`
- Test: `test/blab_bottom_bar_test.dart`
- Documentation: `docs/BLDS_PHASE_3_BOTTOM_BAR_STATUS.md`

## Token references

- `component.bottom-bar.container-surface`
- `component.bottom-bar.selected-surface`
- `component.bottom-bar.selected-foreground`
- `component.bottom-bar.action-surface`
- `component.bottom-bar.focus-outline`
- `semantic.focus.ring`

## State contract

### Required

- None recorded.

### Conditional

- None recorded.

### Not applicable

- None recorded.

## Platform constraints

- Flutter package API
- 44x44 minimum interactive target
- Accessibility-large reflow must not shrink text to hide overflow

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
