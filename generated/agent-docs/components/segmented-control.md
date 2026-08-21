<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabSegmentedControl

Controlled selection among a small set of mutually exclusive options.

## Usage boundary

Use for controlled selection; use owned horizontal overflow only under the documented conditional contract.

## Source and evidence

- Source: `lib/src/widgets/blab_segmented_control.dart`
- Example: `example/lib/stories/segmented_story.dart`
- Test: `test/blab_segmented_control_test.dart`
- Documentation: `docs/BLDS_PHASE_3_SEGMENTED_CONTROL_STATUS.md`

## Token references

- `component.segmented.container-surface`
- `component.segmented.selected-surface`
- `component.segmented.selected-foreground`
- `component.segmented.focus-outline`
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
- Controlled selection and roving keyboard focus

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
