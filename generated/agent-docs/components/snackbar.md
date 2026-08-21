<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabSnackbar

Transient feedback surface for success, error, warning, and info messages.

## Usage boundary

Use for short-lived feedback with readable timing and optional action; do not use as persistent content or modal error handling.

## Source and evidence

- Source: `lib/src/widgets/blab_snackbar.dart`
- Example: `example/lib/stories/snackbar_story.dart`
- Test: `test/blab_snackbar_test.dart`
- Documentation: `docs/BLDS_PHASE_3_SNACKBAR_STATUS.md`

## Token references

- `component.snackbar.surface`
- `component.snackbar.foreground`
- `component.snackbar.border`
- `semantic.status.success`
- `semantic.status.error`

## State contract

### Required

- None recorded.

### Conditional

- None recorded.

### Not applicable

- None recorded.

## Platform constraints

- Flutter package API
- Do not steal focus from the current task

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
