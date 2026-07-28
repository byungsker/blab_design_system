import 'dart:ui' show ImageFilter, Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabTextField required states and compatibility', () {
    testWidgets('preserves empty, populated, label, hint, and clear behavior', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Name',
            hintText: 'Enter a name',
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Enter a name'), findsOneWidget);
      expect(_clearAction, findsNothing);

      controller.text = 'Ada';
      await tester.pump();
      expect(find.text('Ada'), findsOneWidget);
      expect(_clearAction, findsOneWidget);

      await tester.tap(_clearAction);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(_clearAction, findsNothing);
    });

    testWidgets('moves its listener when the controller changes', (
      tester,
    ) async {
      final first = TextEditingController(text: 'First');
      final second = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      late StateSetter setHarnessState;
      var controller = first;

      await tester.pumpWidget(
        _textFieldHarness(
          StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return BLabTextField(controller: controller);
            },
          ),
        ),
      );
      expect(_clearAction, findsOneWidget);

      setHarnessState(() => controller = second);
      await tester.pump();
      expect(_clearAction, findsNothing);

      first.clear();
      second.text = 'Second';
      await tester.pump();
      expect(_clearAction, findsOneWidget);
    });

    testWidgets('keeps the field and clear action at least 44x44', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Clear me');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(BLabTextField(controller: controller), width: 220),
      );

      expect(
        tester.getSize(find.byType(BLabTextField)).height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.getSize(_clearAction).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(_clearAction).height, greaterThanOrEqualTo(44));
    });

    testWidgets('preserves standard light and dark glass values', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      for (final mode in _textFieldVisualModes.take(2)) {
        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(controller: controller),
            brightness: mode.brightness,
          ),
        );
        await tester.pumpAndSettle();
        final surface = _surface(tester);
        expect(surface.color, mode.tokens.glassSurface, reason: mode.label);
        expect(
          surface.border!.top.color,
          mode.tokens.borderDefault,
          reason: mode.label,
        );
        expect(surface.borderRadius, BLabRadius.mdRect, reason: mode.label);
      }
    });

    testWidgets('uses caller suffix instead of the automatic clear action', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Value');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            suffixIcon: const Icon(Icons.visibility),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(_clearAction, findsNothing);
    });

    testWidgets('supports read-only, obscured, and multiline contracts', (
      tester,
    ) async {
      final readOnly = TextEditingController(text: 'Fixed');
      final obscured = TextEditingController(text: 'secret');
      final multiline = TextEditingController(text: 'Line one');
      addTearDown(readOnly.dispose);
      addTearDown(obscured.dispose);
      addTearDown(multiline.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BLabTextField(controller: readOnly, readOnly: true),
              BLabTextField(
                controller: obscured,
                obscureText: true,
                maxLines: 4,
              ),
              BLabTextField(controller: multiline, maxLines: 4),
            ],
          ),
        ),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].readOnly, isTrue);
      expect(fields[1].obscureText, isTrue);
      expect(fields[1].maxLines, 1);
      expect(fields[2].maxLines, 4);
      expect(
        find.descendant(
          of: find.byWidget(fields[0]),
          matching: find.byKey(
            const ValueKey<String>('BLabTextField.clearAction'),
          ),
        ),
        findsNothing,
      );
    });
  });

  group('BLabTextField semantics and conditional states', () {
    testWidgets('links label, hint, value, and text-field role', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Ada');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Name',
            hintText: 'Enter a name',
          ),
        ),
      );
      final relationship = find.byKey(
        const ValueKey<String>('BLabTextField.fieldSemantics'),
      );
      final containerNode = tester.getSemantics(relationship);
      final fieldNode = tester.getSemantics(
        find.descendant(of: relationship, matching: find.byType(EditableText)),
      );
      expect(containerNode.label, contains('Name'));
      expect(containerNode.hint, contains('Enter a name'));
      expect(fieldNode.flagsCollection.isTextField, isTrue);
      expect(fieldNode.value, 'Ada');
      expect(
        find.descendant(of: relationship, matching: find.byType(EditableText)),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('exposes helper text in the linked semantic hint', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Name',
            helperText: 'Use your full name',
          ),
        ),
      );

      expect(find.text('Use your full name'), findsOneWidget);
      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
      );
      expect(node.hint, contains('Use your full name'));
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });

    testWidgets('error text supersedes helper and marks the field invalid', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'bad');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Email',
            helperText: 'Use a work address',
            errorText: 'Invalid email',
          ),
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.text('Use a work address'), findsNothing);
      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
      );
      expect(node.hint, contains('Invalid email'));
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
      expect(
        _surface(tester).border!.top.color,
        BLabTokenTheme.light.statusError,
      );
      semantics.dispose();
    });

    testWidgets('required state uses the native semantic relationship', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Email',
            isRequired: true,
          ),
        ),
      );

      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
      );
      expect(node.flagsCollection.isRequired, Tristate.isTrue);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });

    testWidgets('disabled state suppresses editing, focus, and clear action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Unavailable');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Disabled field',
            enabled: false,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      expect(_clearAction, findsNothing);
      expect(
        find.byKey(const ValueKey<String>('BLabTextField.focusRing')),
        findsNothing,
      );
      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
      );
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isFocused, isNot(Tristate.isTrue));
      semantics.dispose();
    });

    testWidgets(
      'focused invalid field uses focus precedence and primary error copy',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = TextEditingController(text: 'bad');
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(
              controller: controller,
              focusNode: focusNode,
              errorText: 'Invalid value',
            ),
          ),
        );
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        expect(
          _surface(tester).border!.top.color,
          BLabTokenTheme.light.textFieldFocusOutline,
        );
        expect(
          _surface(tester).border!.top.width,
          BLabTokenTheme.light.focusOutlineWidth,
        );
        expect(
          tester.widget<Text>(find.text('Invalid value')).style!.color,
          BLabTokenTheme.light.textPrimary,
        );
        expect(
          tester
              .getSemantics(
                find.byKey(
                  const ValueKey<String>('BLabTextField.fieldSemantics'),
                ),
              )
              .getSemanticsData()
              .validationResult,
          SemanticsValidationResult.invalid,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'disabled invalid field suppresses error border but retains semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = TextEditingController(text: 'bad');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(
              controller: controller,
              enabled: false,
              errorText: 'Invalid value',
            ),
          ),
        );

        expect(
          _surface(tester).border!.top.color,
          BLabTokenTheme.light.borderDefault,
        );
        expect(_surface(tester).border!.top.width, 0.5);
        expect(
          find.byKey(const ValueKey<String>('BLabTextField.focusRing')),
          findsNothing,
        );
        expect(_clearAction, findsNothing);
        expect(
          tester.widget<Text>(find.text('Invalid value')).style!.color,
          BLabTokenTheme.light.textPrimary,
        );
        final node = tester.getSemantics(
          find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
        );
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(
          node.getSemanticsData().validationResult,
          SemanticsValidationResult.invalid,
        );
        semantics.dispose();
      },
    );

    testWidgets('does not synthesize selected, loading, or current states', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(BLabTextField(controller: controller)),
      );
      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabTextField.fieldSemantics')),
      );
      expect(node.flagsCollection.isSelected, Tristate.none);
      expect(node.flagsCollection.isExpanded, Tristate.none);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });

    testWidgets('automatic clear action uses platform-localized semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Value');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _textFieldHarness(BLabTextField(controller: controller)),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Clear text'));
      expect(node.label, 'Clear text');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });

  group('BLabTextField interaction visuals', () {
    for (final mode in _textFieldVisualModes) {
      testWidgets('${mode.label} hover and focus use canonical tokens', (
        tester,
      ) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        final focusVisibility = BLabFocusVisibilityController();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        addTearDown(focusVisibility.dispose);
        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(controller: controller, focusNode: focusNode),
            brightness: mode.brightness,
            highContrast: mode.highContrast,
            focusVisibility: focusVisibility,
          ),
        );

        final center = tester.getCenter(find.byType(BLabTextField));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(center);
        await tester.pumpAndSettle();
        expect(
          _surface(tester).border!.top.color,
          mode.tokens.textFieldHoverBorder,
        );

        focusVisibility.registerKeyboardIntent(LogicalKeyboardKey.tab);
        focusNode.requestFocus();
        await tester.pumpAndSettle();
        expect(
          _surface(tester).border!.top.color,
          mode.tokens.textFieldFocusOutline,
        );

        final ring = _focusRing(tester);
        expect(ring.border!.top.color, mode.tokens.textFieldFocusOuterRing);
        expect(ring.border!.top.width, mode.tokens.focusRingWidth);
        await mouse.removePointer();
      });

      testWidgets('${mode.label} composited contrast meets Design packet', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'Value');
        final focusNode = FocusNode();
        final focusVisibility = BLabFocusVisibilityController();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        addTearDown(focusVisibility.dispose);

        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: 'Hint',
              errorText: 'Invalid value',
            ),
            brightness: mode.brightness,
            highContrast: mode.highContrast,
            focusVisibility: focusVisibility,
          ),
        );
        focusVisibility.registerKeyboardIntent(LogicalKeyboardKey.tab);
        focusNode.requestFocus();
        await tester.pumpAndSettle();

        final canvas = mode.tokens.surfaceBase;
        final field = Color.alphaBlend(mode.tokens.glassSurface, canvas);
        final hint = Color.alphaBlend(mode.tokens.textFieldHint, field);
        final clearBackground = Color.alphaBlend(
          mode.tokens.textFieldClearBackground,
          field,
        );
        final clearForeground = Color.alphaBlend(
          mode.tokens.textFieldClearForeground,
          clearBackground,
        );
        final surface = _surface(tester);
        final ring = _focusRing(tester);
        final textField = tester.widget<TextField>(find.byType(TextField));
        final errorCopy = tester.widget<Text>(find.text('Invalid value'));
        final clearDecoration = _clearDecoration(tester);
        final clearIcon = tester.widget<Icon>(
          find.descendant(of: _clearAction, matching: find.byIcon(Icons.clear)),
        );

        expect(
          field.toARGB32(),
          _expectedFieldComposite(mode).toARGB32(),
          reason: mode.label,
        );
        expect(
          surface.border!.top.color,
          _expectedFocusOutline(mode),
          reason: mode.label,
        );
        expect(
          ring.border!.top.color,
          _expectedFocusOuterRing(mode),
          reason: mode.label,
        );
        expect(
          textField.decoration!.hintStyle!.color,
          _expectedHint(mode),
          reason: mode.label,
        );
        expect(
          errorCopy.style!.color,
          mode.tokens.textPrimary,
          reason: mode.label,
        );
        expect(
          clearDecoration.color,
          _expectedClearBackground(mode),
          reason: mode.label,
        );
        expect(
          clearIcon.color,
          _expectedClearForeground(mode),
          reason: mode.label,
        );

        expect(
          _contrastRatio(surface.border!.top.color, field),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} focus outline/field',
        );
        expect(
          _contrastRatio(ring.border!.top.color, canvas),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} outer ring/canvas',
        );
        expect(
          _contrastRatio(hint, field),
          greaterThanOrEqualTo(4.5),
          reason: '${mode.label} hint/field',
        );
        expect(
          _contrastRatio(errorCopy.style!.color!, canvas),
          greaterThanOrEqualTo(4.5),
          reason: '${mode.label} error/canvas',
        );
        expect(
          _contrastRatio(clearBackground, field),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} clear background/field',
        );
        expect(
          _contrastRatio(clearForeground, clearBackground),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} clear icon/background',
        );
      });
    }

    testWidgets('hover is pointer-only and clears when disabled', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      late StateSetter setHarnessState;
      var enabled = true;
      await tester.pumpWidget(
        _textFieldHarness(
          StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return BLabTextField(controller: controller, enabled: enabled);
            },
          ),
        ),
      );
      final center = tester.getCenter(find.byType(BLabTextField));

      final touch = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await touch.cancel();
      await tester.pumpAndSettle();
      expect(
        _surface(tester).border!.top.color,
        BLabTokenTheme.light.borderDefault,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(center);
      await tester.pumpAndSettle();
      expect(
        _surface(tester).border!.top.color,
        BLabTokenTheme.light.textFieldHoverBorder,
      );

      setHarnessState(() => enabled = false);
      await tester.pumpAndSettle();
      expect(
        _surface(tester).border!.top.color,
        BLabTokenTheme.light.borderDefault,
      );
      await mouse.removePointer();
    });

    testWidgets(
      'keyboard focus draws an outer ring and pointer focus does not',
      (tester) async {
        final controller = TextEditingController();
        final focusVisibility = BLabFocusVisibilityController();
        addTearDown(controller.dispose);
        addTearDown(focusVisibility.dispose);
        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(controller: controller),
            focusVisibility: focusVisibility,
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('BLabTextField.focusRing')),
          findsNothing,
        );

        focusVisibility.registerKeyboardIntent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('BLabTextField.focusRing')),
          findsOneWidget,
        );
      },
    );

    testWidgets('preserves caller focus-node ownership', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(controller: controller, focusNode: focusNode),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => focusNode.requestFocus(), returnsNormally);
    });
  });

  group('BLabTextField accessibility preferences', () {
    for (final scale in <double>[1, 1.3, 2]) {
      testWidgets('honors ambient linear text scaling at $scale', (
        tester,
      ) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final scaler = TextScaler.linear(scale);
        await tester.pumpWidget(
          _textFieldHarness(
            BLabTextField(
              controller: controller,
              label: 'A deliberately long field label',
              helperText: 'A deliberately long helper message that wraps',
            ),
            textScaler: scaler,
            width: 220,
          ),
        );

        expect(tester.takeException(), isNull);
        for (final richText in tester.widgetList<RichText>(
          find.descendant(
            of: find.byType(BLabTextField),
            matching: find.byType(RichText),
          ),
        )) {
          expect(identical(richText.textScaler, scaler), isTrue);
        }
        expect(
          tester.getSize(find.byType(BLabTextField)).height,
          greaterThanOrEqualTo(44),
        );
      });
    }

    testWidgets('honors ambient nonlinear scaling without a component clamp', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      const scaler = _TextFieldNonlinearTextScaler();
      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(
            controller: controller,
            label: 'Field label',
            helperText: 'Helper message',
          ),
          textScaler: scaler,
          width: 220,
        ),
      );

      expect(tester.takeException(), isNull);
      for (final richText in tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(BLabTextField),
          matching: find.byType(RichText),
        ),
      )) {
        expect(identical(richText.textScaler, scaler), isTrue);
      }
    });

    testWidgets('reduced motion makes border feedback immediate', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(controller: controller),
          disableAnimations: true,
        ),
      );

      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey<String>('BLabTextField.surface')),
            )
            .duration,
        Duration.zero,
      );
    });

    testWidgets('high contrast removes blur and resolves semantic colors', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _textFieldHarness(
          BLabTextField(controller: controller, label: 'Contrast'),
          brightness: Brightness.dark,
          highContrast: true,
        ),
      );

      final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(filter.filter, ImageFilter.blur(sigmaX: 0, sigmaY: 0));
      expect(
        _surface(tester).color,
        BLabTokenTheme.highContrastDark.glassSurface,
      );
      expect(
        tester.widget<Text>(find.text('Contrast')).style!.color,
        BLabTokenTheme.highContrastDark.textTertiary,
      );
    });
  });
}

Finder get _clearAction =>
    find.byKey(const ValueKey<String>('BLabTextField.clearAction'));

BoxDecoration _surface(WidgetTester tester) {
  return tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey<String>('BLabTextField.surface')),
          )
          .decoration
      as BoxDecoration;
}

BoxDecoration _focusRing(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find.byKey(const ValueKey<String>('BLabTextField.focusRing')),
          )
          .decoration
      as BoxDecoration;
}

BoxDecoration _clearDecoration(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find.descendant(
              of: _clearAction,
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration
      as BoxDecoration;
}

Color _expectedFieldComposite(_TextFieldVisualMode mode) =>
    switch (mode.label) {
      'light' => const Color(0xFFE6E6E6),
      'dark' => const Color(0xFF2F2F2F),
      'high-contrast-light' => const Color(0xFFFFFFFF),
      'high-contrast-dark' => const Color(0xFF121212),
      _ => throw StateError('Unhandled mode ${mode.label}'),
    };

Color _expectedFocusOutline(_TextFieldVisualMode mode) =>
    mode.brightness == Brightness.light
    ? const Color(0xFF000000)
    : const Color(0xFFFFFFFF);

Color _expectedFocusOuterRing(_TextFieldVisualMode mode) =>
    switch (mode.label) {
      'light' || 'dark' => const Color(0xFF5B7FFF),
      'high-contrast-light' => const Color(0xFF000000),
      'high-contrast-dark' => const Color(0xFFFFFFFF),
      _ => throw StateError('Unhandled mode ${mode.label}'),
    };

Color _expectedHint(_TextFieldVisualMode mode) => switch (mode.label) {
  'light' => const Color(0x99000000),
  'dark' => const Color(0x99FFFFFF),
  'high-contrast-light' => const Color(0xFF000000),
  'high-contrast-dark' => const Color(0xFFFFFFFF),
  _ => throw StateError('Unhandled mode ${mode.label}'),
};

Color _expectedClearBackground(_TextFieldVisualMode mode) =>
    _expectedHint(mode);

Color _expectedClearForeground(_TextFieldVisualMode mode) =>
    mode.brightness == Brightness.light
    ? const Color(0xFFFFFFFF)
    : const Color(0xFF000000);

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

Widget _textFieldHarness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
  double width = 360,
  BLabFocusVisibilityController? focusVisibility,
}) {
  return MaterialApp(
    theme: BLabTheme.light,
    darkTheme: BLabTheme.dark,
    themeMode: brightness == Brightness.light
        ? ThemeMode.light
        : ThemeMode.dark,
    home: MediaQuery(
      data: MediaQueryData(
        highContrast: highContrast,
        disableAnimations: disableAnimations,
        textScaler: textScaler,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: BLabFocusVisibilityScope(
              controller: focusVisibility,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TextFieldNonlinearTextScaler extends TextScaler {
  const _TextFieldNonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}

const _textFieldVisualModes = <_TextFieldVisualMode>[
  _TextFieldVisualMode(
    label: 'light',
    brightness: Brightness.light,
    highContrast: false,
    tokens: BLabTokenTheme.light,
  ),
  _TextFieldVisualMode(
    label: 'dark',
    brightness: Brightness.dark,
    highContrast: false,
    tokens: BLabTokenTheme.dark,
  ),
  _TextFieldVisualMode(
    label: 'high-contrast-light',
    brightness: Brightness.light,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastLight,
  ),
  _TextFieldVisualMode(
    label: 'high-contrast-dark',
    brightness: Brightness.dark,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastDark,
  ),
];

class _TextFieldVisualMode {
  const _TextFieldVisualMode({
    required this.label,
    required this.brightness,
    required this.highContrast,
    required this.tokens,
  });

  final String label;
  final Brightness brightness;
  final bool highContrast;
  final BLabTokenTheme tokens;
}
