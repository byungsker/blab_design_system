<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabPressableWrapper

Interaction primitive for press, hover, focus, and action-derived semantics.

## Usage boundary

Use only when the wrapped content has a real action; static content must not receive interactive semantics.

## Source and evidence

- Source: `lib/src/widgets/pressable_wrapper.dart`
- Example: `example/lib/stories/pressable_story.dart`
- Test: `test/blab_pressable_card_test.dart`
- Documentation: `docs/BLDS_PHASE_3_PRESSABLE_CARD_STATUS.md`

## Token references

- `component.pressable.hover-overlay`
- `component.pressable.pressed-overlay`
- `component.pressable.focus-outline`
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
- Haptic policy is default-deny

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
