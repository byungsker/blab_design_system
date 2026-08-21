/// BLab Design System — Glass (Liquid Glass) Tokens
///
/// Mirrors `--blab-glass-*` in `docs/design/tokens.css`. BLab's signature
/// translucent frosted-surface effect.
library;

import 'package:flutter/material.dart';

class BLabGlass {
  BLabGlass._();

  /// 25px — backdrop filter blur radius.
  /// Used with `BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur))`.
  static const double blur = 25;

  /// 1.8 (180%) — backdrop filter saturation.
  /// Note: Flutter doesn't ship a built-in saturation filter; use `ColorFilter.matrix`
  /// or `ImageFilter.compose` if saturation lift is needed.
  static const double saturation = 1.8;

  // ── Light mode ────────────────────────────────────────────
  // Single-line literals are consumed by the legacy-value compatibility
  // extractor.
  // dart format off
  static const Color _lightFill = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color _lightBorder = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color _lightHighlight = Color(0x99FFFFFF); // rgba(255,255,255,0.60)

  // ── Dark mode ─────────────────────────────────────────────
  static const Color _darkFill = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color _darkBorder = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const Color _darkHighlight = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  // dart format on

  // ── Context-aware accessors ───────────────────────────────
  static Color fill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkFill
        : _lightFill;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkBorder
        : _lightBorder;
  }

  /// Top-edge refraction highlight color.
  /// Use in a `LinearGradient` from this color (at top) to transparent (~45%).
  static Color highlight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkHighlight
        : _lightHighlight;
  }
}
