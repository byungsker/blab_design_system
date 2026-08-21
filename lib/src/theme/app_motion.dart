/// BLab Design System — Motion Tokens
///
/// Mirrors `--blab-ease`, `--blab-dur-*` in `docs/design/tokens.css`.
library;

import 'package:flutter/animation.dart';

class BLabMotion {
  BLabMotion._();

  /// `cubic-bezier(0.4, 0, 0.2, 1)` — standard ease for most transitions.
  /// Flutter equivalent of CSS ease-in-out (Material standard).
  static const Cubic ease = Cubic(0.4, 0, 0.2, 1);

  /// Alias — same as [ease]. Reserved for future differentiation.
  static const Cubic easeInOut = Cubic(0.4, 0, 0.2, 1);

  /// 150ms — press feedback (tap scale, brightness overlay)
  static const Duration durPress = Duration(milliseconds: 150);

  /// 180ms — segmented control selection slide
  static const Duration durSegment = Duration(milliseconds: 180);

  /// 300ms — surface transitions, bottom bar droplet slide
  static const Duration durSurface = Duration(milliseconds: 300);
}
