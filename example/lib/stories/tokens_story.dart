import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class TokensStory extends StatelessWidget {
  const TokensStory({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.md),
      children: [
        _Section(
          title: 'Color — Brand',
          child: Wrap(
            spacing: BLabSpacing.sm,
            runSpacing: BLabSpacing.sm,
            children: const [
              _Swatch(name: 'primary', color: BLabColors.primary),
              _Swatch(name: 'primaryLight', color: BLabColors.primaryLight),
              _Swatch(name: 'destructive', color: BLabColors.destructive),
            ],
          ),
        ),
        _Section(
          title: 'Color — Status',
          child: Wrap(
            spacing: BLabSpacing.sm,
            runSpacing: BLabSpacing.sm,
            children: const [
              _Swatch(name: 'success', color: BLabColors.success),
              _Swatch(name: 'warning', color: BLabColors.warning),
              _Swatch(name: 'error', color: BLabColors.error),
              _Swatch(name: 'info', color: BLabColors.info),
            ],
          ),
        ),
        _Section(
          title: 'Typography',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeRow(label: 'display / 44', style: BLabTypography.display),
              _TypeRow(label: 'h1 / 32', style: BLabTypography.h1),
              _TypeRow(label: 'h2 / 24', style: BLabTypography.h2),
              _TypeRow(label: 'title / 20', style: BLabTypography.title),
              _TypeRow(label: 'subtitle / 17', style: BLabTypography.subtitle),
              _TypeRow(label: 'body / 16', style: BLabTypography.body),
              _TypeRow(label: 'label / 14', style: BLabTypography.label),
              _TypeRow(label: 'caption / 13', style: BLabTypography.caption),
              _TypeRow(label: 'tab / 10', style: BLabTypography.tab),
            ],
          ),
        ),
        _Section(
          title: 'Spacing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SpacingRow(label: 'xs / 2', value: BLabSpacing.xs),
              _SpacingRow(label: 'sm / 8', value: BLabSpacing.sm),
              _SpacingRow(label: 'md / 16', value: BLabSpacing.md),
              _SpacingRow(label: 'lg / 20', value: BLabSpacing.lg),
              _SpacingRow(label: 'xl / 24', value: BLabSpacing.xl),
              _SpacingRow(label: 'xxl / 32', value: BLabSpacing.xxl),
            ],
          ),
        ),
        _Section(
          title: 'Radius',
          child: Wrap(
            spacing: BLabSpacing.md,
            runSpacing: BLabSpacing.md,
            children: const [
              _RadiusBox(name: 'sm / 10', radius: BLabRadius.sm),
              _RadiusBox(name: 'md / 12', radius: BLabRadius.md),
              _RadiusBox(name: 'lg / 16', radius: BLabRadius.lg),
              _RadiusBox(name: 'xl / 20', radius: BLabRadius.xl),
              _RadiusBox(name: 'pill / 100', radius: BLabRadius.pill),
            ],
          ),
        ),
        _Section(
          title: 'Shadow',
          child: Builder(
            builder: (context) => Wrap(
              spacing: BLabSpacing.lg,
              runSpacing: BLabSpacing.lg,
              children: [
                _ShadowBox(name: 'one', shadows: BLabShadow.one(context)),
                _ShadowBox(name: 'two', shadows: BLabShadow.two(context)),
                _ShadowBox(name: 'three', shadows: BLabShadow.three(context)),
                _ShadowBox(name: 'float', shadows: BLabShadow.float(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BLabSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BLabTypography.subtitle.copyWith(
              color: BLabColors.textPrimary(context),
            ),
          ),
          SizedBox(height: BLabSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final String name;
  final Color color;

  const _Swatch({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BLabRadius.mdRect,
            border: Border.all(
              color: BLabColors.borderSubtle(context),
              width: 0.5,
            ),
          ),
        ),
        SizedBox(height: BLabSpacing.xs),
        SizedBox(
          width: 64,
          child: Text(
            name,
            style: BLabTypography.caption.copyWith(
              color: BLabColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  final String label;
  final TextStyle style;

  const _TypeRow({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BLabSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BLabTypography.caption.copyWith(
              color: BLabColors.textTertiary(context),
            ),
          ),
          Text('The quick brown fox', style: style),
        ],
      ),
    );
  }
}

class _SpacingRow extends StatelessWidget {
  final String label;
  final double value;

  const _SpacingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: BLabSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: BLabTypography.caption.copyWith(
                color: BLabColors.textSecondary(context),
              ),
            ),
          ),
          Container(
            height: 12,
            width: value == 0 ? 1 : value,
            color: BLabColors.primary,
          ),
        ],
      ),
    );
  }
}

class _RadiusBox extends StatelessWidget {
  final String name;
  final double radius;

  const _RadiusBox({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BLabGlass.fill(context),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: BLabGlass.border(context), width: 0.5),
          ),
        ),
        SizedBox(height: BLabSpacing.xs),
        Text(
          name,
          style: BLabTypography.caption.copyWith(
            color: BLabColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _ShadowBox extends StatelessWidget {
  final String name;
  final List<BoxShadow> shadows;

  const _ShadowBox({required this.name, required this.shadows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: BLabColors.surface(context),
            borderRadius: BLabRadius.mdRect,
            boxShadow: shadows,
          ),
        ),
        SizedBox(height: BLabSpacing.xs),
        Text(
          name,
          style: BLabTypography.caption.copyWith(
            color: BLabColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
