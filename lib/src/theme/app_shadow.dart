/// BLab Design System — Shadow Tokens
///
/// 4-level elevation system. Mirrors `--blab-shadow-*` in
/// `docs/design/tokens.css`. Values differ between Light/Dark modes.
library;

import 'package:flutter/material.dart';

class BLabShadow {
  BLabShadow._();

  // ── Light mode ────────────────────────────────────────────
  static const List<BoxShadow> _lightOne = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 4,
      color: Color(0x14000000), // rgba(0,0,0,0.08)
    ),
  ];

  static const List<BoxShadow> _lightTwo = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 12,
      color: Color(0x1A000000), // rgba(0,0,0,0.10)
    ),
  ];

  static const List<BoxShadow> _lightThree = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x1F000000), // rgba(0,0,0,0.12)
    ),
  ];

  static const List<BoxShadow> _lightFloat = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 32,
      color: Color(0x26000000), // rgba(0,0,0,0.15)
    ),
  ];

  // ── Dark mode ─────────────────────────────────────────────
  static const List<BoxShadow> _darkOne = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 4,
      color: Color(0x59000000), // rgba(0,0,0,0.35)
    ),
  ];

  static const List<BoxShadow> _darkTwo = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 12,
      color: Color(0x66000000), // rgba(0,0,0,0.40)
    ),
  ];

  static const List<BoxShadow> _darkThree = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x80000000), // rgba(0,0,0,0.50)
    ),
  ];

  static const List<BoxShadow> _darkFloat = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 32,
      color: Color(0x8C000000), // rgba(0,0,0,0.55)
    ),
  ];

  // ── Context-aware accessors ───────────────────────────────
  /// Smallest elevation — segmented control selection, chip
  static List<BoxShadow> one(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkOne
        : _lightOne;
  }

  /// Medium elevation — card hover, dropdown
  static List<BoxShadow> two(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkTwo
        : _lightTwo;
  }

  /// High elevation — modal, sheet
  static List<BoxShadow> three(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkThree
        : _lightThree;
  }

  /// Floating — bottom bar, floating action bar, keyboard accessory
  static List<BoxShadow> float(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkFloat
        : _lightFloat;
  }
}
