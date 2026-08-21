import 'package:flutter/material.dart';

import '../theme/blab_token_theme.dart';

/// Surface relationship used to resolve a contrastive Blab focus color.
enum BLabFocusSurface { canvas, surface, accent }

/// Canonical focus geometry and color, without applying component visuals.
@immutable
class BLabFocusVisualStyle {
  const BLabFocusVisualStyle({
    required this.outlineWidth,
    required this.ringWidth,
    required this.color,
  });

  final double outlineWidth;
  final double ringWidth;
  final Color color;
}

/// Resolves generated focus tokens for an adjacent surface.
abstract final class BLabFocusVisualResolver {
  static BLabFocusVisualStyle resolve({
    required BLabTokenTheme tokens,
    required BLabFocusSurface surface,
  }) {
    final color = switch (surface) {
      BLabFocusSurface.canvas => tokens.focusCanvas,
      BLabFocusSurface.surface => tokens.focusSurface,
      BLabFocusSurface.accent => tokens.focusAccent,
    };
    return BLabFocusVisualStyle(
      outlineWidth: tokens.focusOutlineWidth,
      ringWidth: tokens.focusRingWidth,
      color: color,
    );
  }
}
