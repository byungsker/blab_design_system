import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class ButtonStory extends StatelessWidget {
  const ButtonStory({super.key});

  @override
  Widget build(BuildContext context) {
    return BLabFocusVisibilityScope(
      child: ListView(
        padding: EdgeInsets.all(BLabSpacing.lg),
        children: [
          Text(
            'Use Tab for visible focus, Enter or Space for keyboard '
            'activation, and a pointer or touch gesture for press feedback. '
            'Primary and destructive content use the approved black '
            'foreground in every visual mode.',
            style: BLabTypography.caption.copyWith(
              color: BLabColors.textSecondary(context),
            ),
          ),
          SizedBox(height: BLabSpacing.xxl),
          _label('Primary — default, hover, pressed, focus', context),
          BLabButton(text: 'Primary button', onPressed: () {}),
          SizedBox(height: BLabSpacing.lg),
          BLabButton(
            text: 'Primary with icon',
            icon: Icons.favorite,
            onPressed: () {},
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabButton(
            text: 'Custom child',
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text('Custom child'),
              ],
            ),
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabButton(text: 'Full width', isFullWidth: true, onPressed: () {}),
          SizedBox(height: BLabSpacing.xxl),

          _label('Secondary', context),
          BLabButton(
            text: 'Secondary',
            variant: BLabButtonVariant.secondary,
            onPressed: () {},
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabButton(
            text: 'Secondary with icon',
            icon: Icons.settings,
            variant: BLabButtonVariant.secondary,
            onPressed: () {},
          ),
          SizedBox(height: BLabSpacing.xxl),

          _label('Destructive variant', context),
          BLabButton(
            text: 'Destructive',
            variant: BLabButtonVariant.destructive,
            onPressed: () {},
          ),
          SizedBox(height: BLabSpacing.xxl),

          _label('Disabled', context),
          const BLabButton(text: 'Disabled primary'),
          SizedBox(height: BLabSpacing.lg),
          const BLabButton(
            text: 'Disabled secondary',
            variant: BLabButtonVariant.secondary,
          ),
          SizedBox(height: BLabSpacing.xxl),
          Text(
            'Unstyled custom text and icons inherit the Button foreground; '
            'explicit child colors remain consumer-owned. Disabled contrast '
            'is inactive-control exempt and unverified. Haptics are '
            'default-deny and touch-only when a product supplies an explicit '
            'eligible configuration. Loading/busy is not part of the current '
            'Button API.',
            style: BLabTypography.caption.copyWith(
              color: BLabColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BLabSpacing.md),
      child: Text(
        text,
        style: BLabTypography.subtitle.copyWith(
          color: BLabColors.textPrimary(context),
        ),
      ),
    );
  }
}
