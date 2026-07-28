import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/haptic_policy.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/blab_token_theme.dart';
import 'pressable_wrapper.dart';

class BLabCard extends StatelessWidget {
  static const double _borderWidth = 0.5;

  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;
  final BLabHapticConfiguration hapticConfiguration;

  const BLabCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    this.hapticConfiguration = BLabHapticConfiguration.disabled,
  });

  void _validateSemantics() {
    if (semanticLabel != null && semanticLabel!.trim().isEmpty) {
      throw ArgumentError.value(
        semanticLabel,
        'semanticLabel',
        'A semantic label must be nonblank.',
      );
    }
    if (semanticHint != null && semanticHint!.trim().isEmpty) {
      throw ArgumentError.value(
        semanticHint,
        'semanticHint',
        'A semantic hint must be nonblank.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _validateSemantics();
    final radius = borderRadius ?? BLabRadius.lgRect;
    final visualMode = BLabVisualModeResolver.of(context);
    final tokens = visualMode.tokens;
    final highContrast =
        visualMode.mode == BLabVisualMode.highContrastLight ||
        visualMode.mode == BLabVisualMode.highContrastDark;

    final surface = DecoratedBox(
      key: const ValueKey<String>('BLabCard.surface'),
      decoration: BoxDecoration(
        color: tokens.cardSurface,
        borderRadius: radius,
        border: Border.all(color: tokens.cardBorder, width: _borderWidth),
      ),
      child: Padding(
        key: const ValueKey<String>('BLabCard.padding'),
        padding: padding ?? EdgeInsets.all(BLabSpacing.lg),
        child: child,
      ),
    );
    final cardContent = ClipRRect(
      borderRadius: radius,
      child: highContrast
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: tokens.glassBlur,
                sigmaY: tokens.glassBlur,
              ),
              child: surface,
            ),
    );

    if (onTap == null && onLongPress == null) {
      return cardContent;
    }
    return BLabPressableWrapper(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      borderRadius: radius,
      hapticConfiguration: hapticConfiguration,
      child: cardContent,
    );
  }
}
