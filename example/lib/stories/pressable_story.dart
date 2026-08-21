import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class PressableStory extends StatefulWidget {
  const PressableStory({super.key});

  @override
  State<PressableStory> createState() => _PressableStoryState();
}

class _PressableStoryState extends State<PressableStory> {
  String _lastAction = 'No action yet';

  @override
  Widget build(BuildContext context) {
    return BLabFocusVisibilityScope(
      child: ListView(
        padding: EdgeInsets.all(BLabSpacing.lg),
        children: [
          Text(
            'Tab reveals focus, pointer entry reveals hover, and pointer-down '
            'reveals pressed state.',
            style: BLabTypography.caption.copyWith(
              color: BLabColors.textSecondary(context),
            ),
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabPressableWrapper(
            semanticLabel: 'Open direct pressable fixture',
            onTap: () => setState(() => _lastAction = 'Tap activated'),
            child: _surface(context, 'Default actionable wrapper'),
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabPressableWrapper(
            semanticLabel: 'Show direct pressable options',
            onTap: null,
            onLongPress: () =>
                setState(() => _lastAction = 'Long press activated'),
            child: _surface(context, 'Long-press-only wrapper'),
          ),
          SizedBox(height: BLabSpacing.lg),
          BLabPressableWrapper(
            semanticLabel: 'Open or show direct pressable options',
            semanticHint: 'Tap to open; long press for options',
            onTap: () => setState(() => _lastAction = 'Dual tap activated'),
            onLongPress: () =>
                setState(() => _lastAction = 'Dual long press activated'),
            child: _surface(context, 'Tap and long-press wrapper'),
          ),
          SizedBox(height: BLabSpacing.lg),
          Text(_lastAction, style: BLabTypography.caption),
        ],
      ),
    );
  }

  Widget _surface(BuildContext context, String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BLabColors.surface(context),
        borderRadius: BLabRadius.mdRect,
        border: Border.all(color: BLabColors.borderSubtle(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(BLabSpacing.lg),
        child: Text(label, style: BLabTypography.body),
      ),
    );
  }
}
