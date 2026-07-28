import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/material.dart';

class KeyboardAccessoryStory extends StatefulWidget {
  const KeyboardAccessoryStory({super.key});

  @override
  State<KeyboardAccessoryStory> createState() => _KeyboardAccessoryStoryState();
}

class _KeyboardAccessoryStoryState extends State<KeyboardAccessoryStory> {
  String _lastAction = 'No action yet';

  void _record(String action) {
    setState(() => _lastAction = action);
  }

  Widget _completeFixture({
    required bool isDark,
    required double width,
    required String fixture,
  }) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: width,
        child: BLabKeyboardAccessoryBar(
          isDark: isDark,
          showNavigation: true,
          onUp: () => _record('$fixture · Previous field'),
          onDown: () => _record('$fixture · Next field'),
          onCopy: () => _record('$fixture · Copy'),
          onClearAll: () => _record('$fixture · Clear all'),
          onUndo: () => _record('$fixture · Undo'),
          onRedo: () => _record('$fixture · Redo'),
          onDone: () => _record('$fixture · Done'),
          canCopy: true,
          canClearAll: true,
          canUndo: true,
          canRedo: true,
          upSemanticLabel: 'Previous field',
          downSemanticLabel: 'Next field',
          copySemanticLabel: 'Copy selection',
          clearAllSemanticLabel: 'Clear all text',
          undoSemanticLabel: 'Undo edit',
          redoSemanticLabel: 'Redo edit',
          doneSemanticLabel: 'Dismiss keyboard',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.all(BLabSpacing.lg),
      children: [
        Text('Complete enabled state', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        _completeFixture(isDark: isDark, width: 560, fixture: 'Complete'),
        SizedBox(height: BLabSpacing.md),
        Text(_lastAction, style: BLabTypography.caption),
        SizedBox(height: BLabSpacing.xl),
        Text('Narrow overflow · 320px', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        _completeFixture(isDark: isDark, width: 320, fixture: '320px'),
        SizedBox(height: BLabSpacing.xl),
        Text('Narrow overflow · 360px', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        _completeFixture(isDark: isDark, width: 360, fixture: '360px'),
        SizedBox(height: BLabSpacing.xl),
        Text('Per-action disabled state', style: BLabTypography.subtitle),
        SizedBox(height: BLabSpacing.sm),
        SizedBox(
          width: 560,
          child: BLabKeyboardAccessoryBar(
            isDark: isDark,
            showNavigation: true,
            onUp: () {},
            onDown: () {},
            onCopy: () {},
            onClearAll: () {},
            onUndo: () {},
            onRedo: () {},
            onDone: () => _record('Done remains enabled'),
            upSemanticLabel: 'Previous field unavailable',
            downSemanticLabel: 'Next field unavailable',
            copySemanticLabel: 'Copy unavailable',
            clearAllSemanticLabel: 'Clear all unavailable',
            undoSemanticLabel: 'Undo unavailable',
            redoSemanticLabel: 'Redo unavailable',
            doneSemanticLabel: 'Dismiss keyboard',
          ),
        ),
      ],
    );
  }
}
