<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabButton

Primary, secondary, and destructive action control.

## Usage boundary

Use for an explicit user action; do not use as a selected or loading control until those states are claimed.

## Source and evidence

- Source: `lib/src/widgets/liquid_glass_button.dart`
- Example: `example/lib/stories/button_story.dart`
- Test: `test/blab_button_test.dart`
- Documentation: `docs/BLDS_PHASE_3_BUTTON_STATUS.md`

## Token references

- `component.button.primary.background`
- `component.button.primary.foreground`
- `component.button.focus-outer-ring`
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

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
