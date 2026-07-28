import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

enum BLabInteractionAvailability { enabled, disabled }

enum BLabInteractionActivity { idle, loading, busy }

enum BLabSelectionState { notApplicable, unselected, selected }

enum BLabCurrentState { notApplicable, notCurrent, current }

enum BLabValidationState { notApplicable, valid, invalid }

enum BLabDisclosureState { notApplicable, collapsed, expanded }

enum BLabSemanticRelationship { none, labelOnly, valueOnly, labelAndValue }

/// Typed component state which adapters can map to platform semantics.
///
/// This object contains no customer-facing fallback copy. Labels and values
/// must be supplied by the component or product that owns that content.
@immutable
class BLabSemanticInteractionState {
  const BLabSemanticInteractionState({
    this.availability = BLabInteractionAvailability.enabled,
    this.activity = BLabInteractionActivity.idle,
    this.selection = BLabSelectionState.notApplicable,
    this.current = BLabCurrentState.notApplicable,
    this.validation = BLabValidationState.notApplicable,
    this.disclosure = BLabDisclosureState.notApplicable,
    this.destructive = false,
    this.readOnly = false,
    this.label,
    this.value,
  });

  final BLabInteractionAvailability availability;
  final BLabInteractionActivity activity;
  final BLabSelectionState selection;
  final BLabCurrentState current;
  final BLabValidationState validation;
  final BLabDisclosureState disclosure;
  final bool destructive;
  final bool readOnly;
  final String? label;
  final String? value;

  bool get suppressesActivation =>
      availability == BLabInteractionAvailability.disabled ||
      activity != BLabInteractionActivity.idle;

  BLabSemanticRelationship get relationship {
    if (label != null && value != null) {
      return BLabSemanticRelationship.labelAndValue;
    }
    if (label != null) return BLabSemanticRelationship.labelOnly;
    if (value != null) return BLabSemanticRelationship.valueOnly;
    return BLabSemanticRelationship.none;
  }

  SemanticsProperties toSemanticsProperties() {
    return SemanticsProperties(
      enabled: availability == BLabInteractionAvailability.enabled,
      selected: switch (selection) {
        BLabSelectionState.notApplicable => null,
        BLabSelectionState.unselected => false,
        BLabSelectionState.selected => true,
      },
      expanded: switch (disclosure) {
        BLabDisclosureState.notApplicable => null,
        BLabDisclosureState.collapsed => false,
        BLabDisclosureState.expanded => true,
      },
      readOnly: readOnly,
      label: label,
      value: value,
      validationResult: switch (validation) {
        BLabValidationState.notApplicable => SemanticsValidationResult.none,
        BLabValidationState.valid => SemanticsValidationResult.valid,
        BLabValidationState.invalid => SemanticsValidationResult.invalid,
      },
    );
  }
}
