import 'package:flutter/material.dart';

import '../theme/blab_token_theme.dart';

@immutable
class BLabResolvedVisualMode {
  const BLabResolvedVisualMode({required this.mode, required this.tokens});

  final BLabVisualMode mode;
  final BLabTokenTheme tokens;
}

/// Additively resolves standard or high-contrast Blab token themes.
abstract final class BLabVisualModeResolver {
  static BLabResolvedVisualMode resolve({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final mode = switch ((brightness, highContrast)) {
      (Brightness.light, false) => BLabVisualMode.light,
      (Brightness.dark, false) => BLabVisualMode.dark,
      (Brightness.light, true) => BLabVisualMode.highContrastLight,
      (Brightness.dark, true) => BLabVisualMode.highContrastDark,
    };
    return BLabResolvedVisualMode(
      mode: mode,
      tokens: BLabTokenTheme.forMode(mode),
    );
  }

  static BLabResolvedVisualMode of(BuildContext context) {
    return resolve(
      brightness: Theme.of(context).brightness,
      highContrast: MediaQuery.highContrastOf(context),
    );
  }
}
