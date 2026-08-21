import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/phase4_candidate_harness.dart';

void main() {
  setUpAll(() => loadPhase4FixtureFont('NotoSansKR[wght].ttf'));

  registerPhase4GoldenTests(const <Phase4GoldenScenario>[
    Phase4GoldenScenario(
      id: 'light',
      brightness: Brightness.light,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'dark',
      brightness: Brightness.dark,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'high-contrast-light',
      brightness: Brightness.light,
      highContrast: true,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'high-contrast-dark',
      brightness: Brightness.dark,
      highContrast: true,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'text-scale-2',
      brightness: Brightness.light,
      textScale: 2,
      size: Size(800, 1600),
    ),
    Phase4GoldenScenario(
      id: 'ko-kr',
      brightness: Brightness.light,
      locale: Locale('ko', 'KR'),
      copyKind: Phase4CopyKind.korean,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'expansion-40',
      brightness: Brightness.light,
      locale: Locale('en', 'XA'),
      copyKind: Phase4CopyKind.expanded,
      size: Size(800, 1400),
    ),
    Phase4GoldenScenario(
      id: 'reduced-motion',
      brightness: Brightness.light,
      reducedMotion: true,
      size: Size(800, 1200),
    ),
    Phase4GoldenScenario(
      id: 'narrow',
      brightness: Brightness.light,
      size: Size(360, 1400),
    ),
  ], includeExpansionInvariant: true);
}
