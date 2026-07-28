import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum BLabInteractiveTargetKind {
  interactive,
  nonInteractive,
  documentedException,
}

/// Layout-only minimum-target policy. It does not prescribe visual dimensions.
@immutable
class BLabInteractiveTargetPolicy {
  const BLabInteractiveTargetPolicy.interactive()
    : kind = BLabInteractiveTargetKind.interactive,
      exceptionReason = null,
      designDecisionReference = null;

  const BLabInteractiveTargetPolicy.nonInteractive()
    : kind = BLabInteractiveTargetKind.nonInteractive,
      exceptionReason = null,
      designDecisionReference = null;

  factory BLabInteractiveTargetPolicy.documentedException(
    String exceptionReason, {
    required String designDecisionReference,
  }) {
    if (exceptionReason.trim().isEmpty) {
      throw ArgumentError.value(
        exceptionReason,
        'exceptionReason',
        'A documented exception requires a nonblank reason.',
      );
    }
    if (designDecisionReference.trim().isEmpty) {
      throw ArgumentError.value(
        designDecisionReference,
        'designDecisionReference',
        'A documented exception requires a nonblank Design decision or '
            'review reference.',
      );
    }
    return BLabInteractiveTargetPolicy._documentedException(
      exceptionReason: exceptionReason,
      designDecisionReference: designDecisionReference,
    );
  }

  const BLabInteractiveTargetPolicy._documentedException({
    required this.exceptionReason,
    required this.designDecisionReference,
  }) : kind = BLabInteractiveTargetKind.documentedException;

  static const double minimumWidth = 44;
  static const double minimumHeight = 44;

  final BLabInteractiveTargetKind kind;
  final String? exceptionReason;
  final String? designDecisionReference;

  bool get enforcesMinimum => kind == BLabInteractiveTargetKind.interactive;

  Size evaluate(Size naturalSize) {
    if (!enforcesMinimum) return naturalSize;
    return Size(
      math.max(minimumWidth, naturalSize.width),
      math.max(minimumHeight, naturalSize.height),
    );
  }
}

/// Enforces the Blab 44x44 logical-pixel interactive layout target.
class BLabInteractiveTarget extends StatelessWidget {
  const BLabInteractiveTarget({
    super.key,
    this.policy = const BLabInteractiveTargetPolicy.interactive(),
    this.alignment = Alignment.center,
    required this.child,
  });

  final BLabInteractiveTargetPolicy policy;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!policy.enforcesMinimum) return child;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: BLabInteractiveTargetPolicy.minimumWidth,
        minHeight: BLabInteractiveTargetPolicy.minimumHeight,
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        alignment: alignment,
        child: child,
      ),
    );
  }
}
