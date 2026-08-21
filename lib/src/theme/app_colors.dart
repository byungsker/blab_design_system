/// BLab Design System — Color Tokens
///
/// Authoritative source: `contracts/blab.design.yaml` and its typed token
/// contract. Equality with the hand-maintained CSS is compatibility evidence,
/// not a separate source of design authority.
///
/// Structure:
///   1. Primitives — Brand / Status / Chart / Grey
///   2. Surfaces — Light / Dark
///   3. Text (Foreground) — Light / Dark
///   4. Borders — Light / Dark
///   5. Semantic aliases — Action / Surface / Text
///   6. Context-aware accessors (use these in widgets)
library;

import 'package:flutter/material.dart';

class BLabColors {
  BLabColors._();

  // ════════════════════════════════════════════════════════════
  // PRIMITIVES — Brand
  // ════════════════════════════════════════════════════════════

  /// `--blab-primary` #5B7FFF — brand primary, use sparingly for CTAs
  static const Color primary = Color(0xFF5B7FFF);

  /// `--blab-primary-light` #6B8AFF — hover/active variant
  static const Color primaryLight = Color(0xFF6B8AFF);

  // ════════════════════════════════════════════════════════════
  // PRIMITIVES — Status
  // ════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF10B981); // --blab-success
  static const Color successAlt = Color(0xFF34C759); // --blab-success-alt
  static const Color successBg = Color(0xFFD1FAE5); // --blab-success-bg

  static const Color error = Color(0xFFFF3B30); // --blab-error
  static const Color errorAlt = Color(0xFFEF4444); // --blab-error-alt
  static const Color errorBg = Color(0xFFFEE2E2); // --blab-error-bg
  static const Color errorLight = Color(0xFFFCA5A5); // (legacy)

  static const Color warning = Color(0xFFFF9500); // --blab-warning
  static const Color warningAlt = Color(0xFFFFBE0B); // --blab-warning-alt

  static const Color info = Color(0xFF4ECDC4); // --blab-info
  static const Color infoAlt = Color(0xFF3498DB); // --blab-info-alt

  static const Color destructive = Color(0xFFFF6B6B); // --blab-destructive

  static const Color purple = Color(0xFF9B59B6); // (chart ramp)

  // ════════════════════════════════════════════════════════════
  // PRIMITIVES — Chart Ramp
  // ════════════════════════════════════════════════════════════

  /// Full 10-color chart palette. Use sparingly — BLab prefers grayscale +
  /// single-accent visualizations by default.
  static const List<Color> chartColors = [
    Color(0xFF5B7FFF), // chart-1
    Color(0xFFFF6B6B), // chart-2
    Color(0xFF4ECDC4), // chart-3
    Color(0xFFFFBE0B), // chart-4
    Color(0xFF9B59B6), // chart-5
    Color(0xFF3498DB), // chart-6
    Color(0xFFE74C3C), // chart-7
    Color(0xFF1ABC9C), // chart-8
    Color(0xFFF39C12), // chart-9
    Color(0xFF8E44AD), // chart-10
  ];

  // Legacy colors (kept for backward compat; not in tokens.css)
  static const Color gold = Color(0xFFFFD700);
  static const Color amber = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerAlt = Color(0xFFD97706);

  // ════════════════════════════════════════════════════════════
  // PRIMITIVES — Grey (CSS-aligned, Tailwind-style)
  // ════════════════════════════════════════════════════════════

  static const Color grey50 = Color(0xFFF5F5F5); // --blab-grey-50
  static const Color grey100 = Color(0xFFF3F4F6); // --blab-grey-100
  static const Color grey200 = Color(0xFFE5E7EB); // --blab-grey-200
  static const Color grey300 = Color(0xFFD1D5DB); // --blab-grey-300
  static const Color grey400 = Color(0xFF9CA3AF); // --blab-grey-400
  static const Color grey500 = Color(0xFF6B7280); // --blab-grey-500
  static const Color grey600 = Color(0xFF4B5563); // --blab-grey-600
  static const Color grey700 = Color(0xFF374151); // --blab-grey-700
  static const Color grey800 = Color(0xFF1F2937); // --blab-grey-800
  static const Color grey900 = Color(0xFF111827); // --blab-grey-900

  // Legacy aliases
  static const Color grey50Light = grey50;
  static const Color grey100Light = grey100;
  static const Color grey200Light = grey200;

  // ════════════════════════════════════════════════════════════
  // SURFACES — Light
  // ════════════════════════════════════════════════════════════

  static const Color scaffoldLight = Color(0xFFFAFAFA); // --blab-scaffold
  static const Color surfaceLight = Colors.white; // --blab-surface
  static const Color cardLight = Colors.white; // --blab-card
  static const Color elevatedLight = Color(0xFFF8F9FA); // --blab-elevated
  static const Color subtleBlueLight = Color(0xFFF5F7FF); // --blab-subtle-blue

  // ════════════════════════════════════════════════════════════
  // SURFACES — Dark
  // ════════════════════════════════════════════════════════════

  static const Color scaffoldDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color elevatedDark = Color(0xFF2C2C2E);
  static const Color subtleDark = Color(0xFF2A2A2A);

  // ════════════════════════════════════════════════════════════
  // TEXT — Foreground (Light)
  // ════════════════════════════════════════════════════════════

  static const Color textPrimaryLight = Colors.black; // --blab-fg-primary
  static const Color textSecondaryLight = Color(0xDD000000); // 87%
  static const Color textTertiaryLight = Color(0x99000000); // 60%
  static const Color textQuaternaryLight = Color(0x62000000); // 38%
  static const Color textInverseLight = Colors.white; // --blab-fg-inverse

  // ════════════════════════════════════════════════════════════
  // TEXT — Foreground (Dark)
  // ════════════════════════════════════════════════════════════

  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xDDFFFFFF); // 87%
  static const Color textTertiaryDark = Color(0x99FFFFFF); // 60%
  static const Color textQuaternaryDark = Color(0x62FFFFFF); // 38%
  static const Color textInverseDark = Colors.black;

  // ════════════════════════════════════════════════════════════
  // BORDERS (Light / Dark)
  // ════════════════════════════════════════════════════════════

  static const Color borderSubtleLight = Color(0x0D000000); // 5%
  static const Color borderDefaultLight = Color(0x14000000); // 8%
  static const Color borderStrongLight = Color(0x26000000); // 15%

  static const Color borderSubtleDark = Color(0x14FFFFFF); // 8%
  static const Color borderDefaultDark = Color(0x26FFFFFF); // 15%
  static const Color borderStrongDark = Color(0x38FFFFFF); // 22%

  // ════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES — Action
  // ════════════════════════════════════════════════════════════

  /// `--blab-action-primary` → --blab-primary
  static const Color actionPrimary = primary;

  /// `--blab-action-destructive` → --blab-error
  static const Color actionDestructive = error;

  /// `--blab-action-secondary` Light — rgba(0,0,0,0.08)
  static const Color actionSecondaryLight = Color(0x14000000);

  /// `--blab-action-secondary` Dark — rgba(255,255,255,0.12)
  static const Color actionSecondaryDark = Color(0x1FFFFFFF);

  // ════════════════════════════════════════════════════════════
  // CONTEXT-AWARE ACCESSORS
  // ════════════════════════════════════════════════════════════

  /// `surface.base` — scaffold background
  static Color scaffold(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? scaffoldDark
        : scaffoldLight;
  }

  /// `surface.raised` — primary surface
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  /// `surface.overlay` — card surface (same as [surface] currently)
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardDark
        : cardLight;
  }

  /// `--blab-elevated` — raised chrome surface (TextField fill, etc.)
  static Color elevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? elevatedDark
        : elevatedLight;
  }

  /// `--blab-subtle-blue` / `--blab-subtle-dark` — subtle tinted surface
  static Color subtleBlue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? subtleDark
        : subtleBlueLight;
  }

  /// `text.primary`
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  /// `text.secondary` (87% alpha)
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  /// `text.tertiary` (60% alpha)
  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textTertiaryDark
        : textTertiaryLight;
  }

  /// `text.quaternary` (38% alpha) — disabled text
  static Color textQuaternary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textQuaternaryDark
        : textQuaternaryLight;
  }

  /// `text.inverse` — text on primary/destructive surfaces
  static Color textInverse(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textInverseDark
        : textInverseLight;
  }

  /// `border.subtle` (5% light / 8% dark)
  static Color borderSubtle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderSubtleDark
        : borderSubtleLight;
  }

  /// `border.default` (8% light / 15% dark)
  static Color borderDefault(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderDefaultDark
        : borderDefaultLight;
  }

  /// `border.strong` (15% light / 22% dark)
  static Color borderStrong(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderStrongDark
        : borderStrongLight;
  }

  /// `action.secondary` — neutral button background
  static Color actionSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? actionSecondaryDark
        : actionSecondaryLight;
  }

  /// Grey at the given shade (50-900). CSS-aligned Tailwind-style grey in Light;
  /// inverted Material grey in Dark (legacy behavior preserved).
  static Color grey(int shade, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (shade) {
      case 50:
        return isDark ? const Color(0xFF303030) : grey50;
      case 100:
        return isDark ? const Color(0xFF424242) : grey100;
      case 200:
        return isDark ? const Color(0xFF616161) : grey200;
      case 300:
        return isDark ? const Color(0xFF757575) : grey300;
      case 400:
        return isDark ? const Color(0xFF9E9E9E) : grey400;
      case 500:
        return isDark ? const Color(0xFFBDBDBD) : grey500;
      case 600:
        return isDark ? const Color(0xFFE0E0E0) : grey600;
      case 700:
        return isDark ? const Color(0xFFEEEEEE) : grey700;
      case 800:
        return isDark ? const Color(0xFFF5F5F5) : grey800;
      case 850:
        return isDark ? const Color(0xFFFAFAFA) : grey800;
      case 900:
        return isDark ? Colors.white : grey900;
      default:
        return isDark ? Colors.grey[shade]! : Colors.grey[shade]!;
    }
  }
}
