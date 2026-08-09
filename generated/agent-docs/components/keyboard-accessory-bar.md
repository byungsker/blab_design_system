<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabKeyboardAccessoryBar

Keyboard accessory actions for navigation, editing, and completion.

## Usage boundary

Use alongside an active text-input flow; action availability and overflow remain explicit per item.

## Source and evidence

- Source: `lib/src/widgets/keyboard_accessory_bar.dart`
- Example: `example/lib/stories/keyboard_accessory_story.dart`
- Test: `test/blab_keyboard_accessory_bar_test.dart`
- Documentation: `docs/BLDS_PHASE_3_KEYBOARD_ACCESSORY_STATUS.md`

## Token references

- `component.keyboard-accessory.surface-start`
- `component.keyboard-accessory.border`
- `component.keyboard-accessory.foreground`
- `component.keyboard-accessory.focus-outline`
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
- Horizontal overflow is owned and scrollable when conditional

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
