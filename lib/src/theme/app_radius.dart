/// BLab Design System — Radius Tokens
///
/// Mirrors `--blab-radius-*` in `docs/design/tokens.css`.
library;

import 'package:flutter/widgets.dart';

class BLabRadius {
  BLabRadius._();

  /// 6px — smallest (future use)
  static const double xs = 6;

  /// 10px — segmented controls (outer), small chips
  static const double sm = 10;

  /// 12px — buttons, text inputs, small cards
  static const double md = 12;

  /// 16px — cards, snackbars, medium surfaces
  static const double lg = 16;

  /// 20px — large cards (future use)
  static const double xl = 20;

  /// 100px — bottom bars, tab bar, floating action bar, keyboard accessory
  static const double pill = 100;

  // ── BorderRadius helpers ──────────────────────────────────
  static const BorderRadius xsRect = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRect = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRect = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRect = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRect = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillRect = BorderRadius.all(Radius.circular(pill));
}
