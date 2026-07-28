import 'package:flutter/widgets.dart';

/// Measured evidence for one unmodified Flutter [TextScaler].
@immutable
class BLabTextScalingEvidence {
  const BLabTextScalingEvidence({
    required this.textScaler,
    required this.unscaledFontSize,
    required this.scaledFontSize,
    required this.equivalentScale,
    required this.withinVerifiedRange,
  });

  final TextScaler textScaler;
  final double unscaledFontSize;
  final double scaledFontSize;
  final double equivalentScale;
  final bool withinVerifiedRange;
}

/// Evaluation helpers for the approved 1.0 through 2.0 verification range.
///
/// The supplied scaler is never clamped, replaced, or converted through the
/// deprecated `textScaleFactor` compatibility estimate.
abstract final class BLabTextScalingPolicy {
  static const double verifiedMinimumEquivalent = 1;
  static const double verifiedMaximumEquivalent = 2;

  static TextScaler of(BuildContext context) =>
      MediaQuery.textScalerOf(context);

  static BLabTextScalingEvidence evaluate(
    TextScaler textScaler, {
    double unscaledFontSize = 16,
  }) {
    assert(unscaledFontSize > 0 && unscaledFontSize.isFinite);
    final scaled = textScaler.scale(unscaledFontSize);
    final equivalent = scaled / unscaledFontSize;
    return BLabTextScalingEvidence(
      textScaler: textScaler,
      unscaledFontSize: unscaledFontSize,
      scaledFontSize: scaled,
      equivalentScale: equivalent,
      withinVerifiedRange:
          equivalent >= verifiedMinimumEquivalent &&
          equivalent <= verifiedMaximumEquivalent,
    );
  }
}
