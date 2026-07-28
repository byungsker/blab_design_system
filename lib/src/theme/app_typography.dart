/// BLab Design System — Typography Tokens
///
/// Mirrors `--blab-*-size/lh/ls/weight` in `docs/design/tokens.css`.
/// The package only names Pretendard and JetBrains Mono as font-family
/// preferences. It bundles and fetches no font files. Flutter therefore uses
/// its runtime font resolution and fallback behavior unless the consuming
/// product provides those families.
///
/// Remote declarations in `docs/design/tokens.css` are an optional CSS
/// reference for browser consumers; they do not load fonts for this Flutter
/// package. The production self-hosted, fallback, or remote-font strategy
/// remains unresolved.
///
/// CSS `em` letter-spacing is converted to Flutter logical pixels:
/// `letterSpacing (px) = em × fontSize`.
library;

import 'package:flutter/material.dart';

class BLabTypography {
  BLabTypography._();

  // ── Font families ─────────────────────────────────────────
  /// Pretendard (Korean + Latin, Apple-SD-Gothic-adjacent).
  /// This is a family-name reference, not a bundled or fetched font asset.
  static const String fontHeading = 'Pretendard';
  static const String fontBody = 'Pretendard';
  static const String fontMono = 'JetBrainsMono';

  // ── Type scale ────────────────────────────────────────────
  /// 44 / 1.1 / -0.022em / 700 — hero display
  static const TextStyle display = TextStyle(
    fontFamily: fontHeading,
    fontSize: 44,
    height: 1.1,
    letterSpacing: -0.968, // -0.022em × 44
    fontWeight: FontWeight.w700,
  );

  /// 32 / 1.2 / -0.02em / 700 — page title (h1)
  static const TextStyle h1 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 32,
    height: 1.2,
    letterSpacing: -0.64, // -0.02em × 32
    fontWeight: FontWeight.w700,
  );

  /// 24 / 1.3 / -0.015em / 700 — section title (h2)
  static const TextStyle h2 = TextStyle(
    fontFamily: fontHeading,
    fontSize: 24,
    height: 1.3,
    letterSpacing: -0.36, // -0.015em × 24
    fontWeight: FontWeight.w700,
  );

  /// 20 / 1.35 / -0.01em / 600 — component title
  static const TextStyle title = TextStyle(
    fontFamily: fontBody,
    fontSize: 20,
    height: 1.35,
    letterSpacing: -0.2, // -0.01em × 20
    fontWeight: FontWeight.w600,
  );

  /// 17 / 1.4 / -0.005em / 600 — subtitle (iOS-native feel)
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontBody,
    fontSize: 17,
    height: 1.4,
    letterSpacing: -0.085, // -0.005em × 17
    fontWeight: FontWeight.w600,
  );

  /// 16 / 1.5 / 0 / 400 — body copy
  static const TextStyle body = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// 16 / 1.5 / 0 / 600 — emphasized body
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  /// 13 / 1.45 / 0 / 500 — supplemental text
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  /// 14 / 1.4 / 0 / 500 — field label, chip label
  static const TextStyle label = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// 16 / 1.2 / -0.005em / 600 — button label
  static const TextStyle button = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    height: 1.2,
    letterSpacing: -0.08, // -0.005em × 16
    fontWeight: FontWeight.w600,
  );

  /// 10 / 1.2 / 0 / 600 — bottom bar tab label
  static const TextStyle tab = TextStyle(
    fontFamily: fontBody,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// 14 / 1.5 — inline code, numeric displays
  static const TextStyle code = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    height: 1.5,
  );
}
