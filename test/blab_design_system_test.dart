import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blab_design_system/blab_design_system.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('package can be imported', () {
    expect(true, isTrue);
  });

  test('action foreground tokens meet WCAG AA contrast', () {
    expect(_contrastRatio(BLabColors.onPrimary, BLabColors.primary), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(BLabColors.onError, BLabColors.error), greaterThanOrEqualTo(4.5));
  });
}
