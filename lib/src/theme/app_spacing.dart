/// BLab Design System — Spacing Tokens
///
/// 4px base scale. Mirrors `--blab-space-*` in `docs/design/tokens.css`.
library;

class BLabSpacing {
  BLabSpacing._();

  /// 0px — no spacing
  static const double s0 = 0;

  /// 2px — tightest unit
  static const double s1 = 2;

  /// 4px — base unit
  static const double s2 = 4;

  /// 8px
  static const double s3 = 8;

  /// 12px
  static const double s4 = 12;

  /// 16px — default padding
  static const double s5 = 16;

  /// 20px
  static const double s6 = 20;

  /// 24px
  static const double s7 = 24;

  /// 32px
  static const double s8 = 32;

  /// 40px
  static const double s9 = 40;

  /// 48px
  static const double s10 = 48;

  /// 64px
  static const double s11 = 64;

  // ── Semantic aliases ──────────────────────────────────────
  static const double xs = s1; // 2
  static const double sm = s3; // 8
  static const double md = s5; // 16
  static const double lg = s6; // 20
  static const double xl = s7; // 24
  static const double xxl = s8; // 32
}
