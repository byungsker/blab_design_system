import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class CardStory extends StatelessWidget {
  const CardStory({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        _label('Default', context),
        BLabCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Card title', style: BLabTypography.title),
              SizedBox(height: BLabSpacing.sm),
              Text(
                'A glass-fill surface with 16px radius and 20px padding.',
                style: BLabTypography.body.copyWith(
                  color: BLabColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Tappable', context),
        BLabCard(
          semanticLabel: 'Open card details',
          semanticHint: 'Shows the selected card',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Card tapped')));
          },
          child: Row(
            children: [
              Icon(Icons.star, color: BLabColors.primary),
              SizedBox(width: BLabSpacing.md),
              Expanded(
                child: Text('Tap this card', style: BLabTypography.body),
              ),
              Icon(
                Icons.chevron_right,
                color: BLabColors.textTertiary(context),
              ),
            ],
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Long press only', context),
        BLabCard(
          semanticLabel: 'Show card options',
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Card options requested')),
            );
          },
          child: Text(
            'Long press for options; keyboard activation invokes the sole '
            'action.',
            style: BLabTypography.body,
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Tap + long press', context),
        BLabCard(
          semanticLabel: 'Open card or show options',
          semanticHint: 'Tap to open; long press for options',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Card opened')));
          },
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Card options requested')),
            );
          },
          child: Text(
            'Tap opens; long press shows options.',
            style: BLabTypography.body,
          ),
        ),
        SizedBox(height: BLabSpacing.xl),

        _label('Custom radius & padding', context),
        BLabCard(
          borderRadius: BLabRadius.xlRect,
          padding: EdgeInsets.all(BLabSpacing.xxl),
          child: Center(
            child: Text(
              'radius xl, padding xxl',
              style: BLabTypography.label.copyWith(
                color: BLabColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ],
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
