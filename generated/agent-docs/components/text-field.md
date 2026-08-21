<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabTextField

Single-line and multiline text input with helper, error, read-only, and clear-action semantics.

## Usage boundary

Use for user text entry; validation and loading behavior remain conditional or unclaimed where the state contract says so.

## Source and evidence

- Source: `lib/src/widgets/liquid_glass_text_field.dart`
- Example: `example/lib/stories/text_field_story.dart`
- Test: `test/blab_text_field_test.dart`
- Documentation: `docs/BLDS_PHASE_3_TEXT_FIELD_STATUS.md`

## Token references

- `component.text-field.label`
- `component.text-field.hint`
- `component.text-field.focus-outline`
- `component.text-field.error-border`
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
- Text scaling must remain ambient

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
