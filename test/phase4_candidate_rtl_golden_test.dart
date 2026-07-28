import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/phase4_candidate_harness.dart';

void main() {
  setUpAll(() => loadPhase4FixtureFont('NotoSansArabic[wdth,wght].ttf'));

  registerPhase4GoldenTests(const <Phase4GoldenScenario>[
    Phase4GoldenScenario(
      id: 'ar-rtl',
      brightness: Brightness.light,
      locale: Locale('ar'),
      copyKind: Phase4CopyKind.arabic,
      textDirection: TextDirection.rtl,
      size: Size(800, 1200),
    ),
  ]);
}
