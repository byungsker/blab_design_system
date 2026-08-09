<!-- GENERATED CODE - DO NOT EDIT. -->
<!-- Sources: contracts/components/agent-registry.yaml, contracts/components/state-applicability.yaml, generated/component-state-coverage.yaml, contracts/tokens/blab.tokens.yaml, contracts/components/figma-agent-mapping.yaml -->
# BLabCard

Glass surface container that may become actionable when an explicit action is supplied.

## Usage boundary

Use as a visual grouping surface; derive interactive semantics only from an actual action callback.

## Source and evidence

- Source: `lib/src/widgets/liquid_glass_card.dart`
- Example: `example/lib/stories/card_story.dart`
- Test: `test/blab_pressable_card_test.dart`
- Documentation: `docs/BLDS_PHASE_3_PRESSABLE_CARD_STATUS.md`

## Token references

- `component.card.surface`
- `component.card.border`
- `component.pressable.focus-outline`
- `semantic.surface.glass`

## State contract

### Required

- None recorded.

### Conditional

- None recorded.

### Not applicable

- None recorded.

## Platform constraints

- Flutter package API
- Static cards must remain non-interactive

Generated from the BLDS registry and state contract. Not-claimed behavior must not be presented as implemented.
