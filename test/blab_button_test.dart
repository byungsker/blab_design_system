import 'dart:ui' show Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabButton required states and compatibility', () {
    testWidgets('keeps a minimum 44x44 interactive target', (tester) async {
      await tester.pumpWidget(
        _buttonHarness(BLabButton(text: 'Action', onPressed: () {})),
      );

      final size = tester.getSize(find.byType(BLabButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('preserves text, icon, child, and full-width behavior', (
      tester,
    ) async {
      const customChildKey = ValueKey<String>('custom-child');
      await tester.pumpWidget(
        _buttonHarness(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BLabButton(
                text: 'Icon action',
                icon: Icons.add,
                onPressed: () {},
              ),
              BLabButton(
                text: 'Semantic fallback',
                icon: Icons.close,
                onPressed: () {},
                child: const Text('Custom', key: customChildKey),
              ),
              BLabButton(
                text: 'Full width',
                isFullWidth: true,
                onPressed: () {},
              ),
            ],
          ),
          width: 280,
        ),
      );

      expect(find.text('Icon action'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byKey(customChildKey), findsOneWidget);
      expect(find.text('Semantic fallback'), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(
        tester.getSize(find.widgetWithText(BLabButton, 'Full width')).width,
        280,
      );
    });

    testWidgets('maps standard light and dark visuals without drift', (
      tester,
    ) async {
      Future<BoxDecoration> decorationFor({
        required Brightness brightness,
        required BLabButtonVariant variant,
      }) async {
        await tester.pumpWidget(
          _buttonHarness(
            BLabButton(text: 'Visual', variant: variant, onPressed: () {}),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        return tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey<String>('BLabButton.surface')),
                )
                .decoration
            as BoxDecoration;
      }

      expect(
        (await decorationFor(
          brightness: Brightness.light,
          variant: BLabButtonVariant.primary,
        )).color,
        BLabColors.primary,
      );
      expect(
        (await decorationFor(
          brightness: Brightness.dark,
          variant: BLabButtonVariant.primary,
        )).color,
        BLabColors.primary,
      );
      expect(
        (await decorationFor(
          brightness: Brightness.light,
          variant: BLabButtonVariant.secondary,
        )).color,
        BLabTokenTheme.light.glassSurface,
      );
      expect(
        (await decorationFor(
          brightness: Brightness.dark,
          variant: BLabButtonVariant.secondary,
        )).color,
        BLabTokenTheme.dark.glassSurface,
      );
    });

    testWidgets('renders the destructive variant from Blab status tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(
            text: 'Remove',
            variant: BLabButtonVariant.destructive,
            onPressed: () {},
          ),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey<String>('BLabButton.surface')),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, BLabColors.error);
      expect(
        tester.widget<Text>(find.text('Remove')).style!.color,
        Colors.black,
      );
    });
  });

  group('BLabButton activation and semantics', () {
    testWidgets('Enter and Space activate exactly once per physical cycle', (
      tester,
    ) async {
      var activations = 0;
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(text: 'Activate', onPressed: () => activations += 1),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(activations, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      expect(activations, 1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(activations, 2);
    });

    testWidgets('pointer and touch each activate exactly once', (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(text: 'Activate', onPressed: () => activations += 1),
        ),
      );
      final center = tester.getCenter(find.byType(BLabButton));

      final touch = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await touch.up();
      await tester.pumpAndSettle();
      expect(activations, 1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      await mouse.down(center);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(activations, 2);
      await mouse.removePointer();
    });

    testWidgets('exposes button name, role, action, and enabled state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buttonHarness(BLabButton(text: 'Continue', onPressed: () {})),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Continue'));
      final flags = node.flagsCollection;
      expect(node.label, 'Continue');
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('disabled state suppresses action, focus, and haptics', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buttonHarness(
          const BLabButton(
            text: 'Unavailable',
            hapticConfiguration: _enabledHaptics,
          ),
        ),
      );
      await tester.tap(find.byType(BLabButton));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      final node = tester.getSemantics(find.bySemanticsLabel('Unavailable'));
      final flags = node.flagsCollection;
      expect(node.label, 'Unavailable');
      expect(flags.isButton, isTrue);
      expect(flags.isEnabled, Tristate.isFalse);
      expect(flags.isFocused, isNot(Tristate.isTrue));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        find.byKey(const ValueKey<String>('BLabButton.focusOutline')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('does not synthesize non-applicable semantic states', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buttonHarness(BLabButton(text: 'Plain', onPressed: () {})),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Plain'));
      final flags = node.flagsCollection;
      expect(flags.isSelected, Tristate.none);
      expect(flags.isExpanded, Tristate.none);
      expect(flags.isTextField, isFalse);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });
  });

  group('BLabButton interaction visuals', () {
    for (final mode in _buttonVisualModes) {
      for (final variant in BLabButtonVariant.values) {
        testWidgets(
          '${mode.label} ${variant.name} uses its canonical hover token',
          (tester) async {
            await tester.pumpWidget(
              _buttonHarness(
                BLabButton(text: 'Hover', variant: variant, onPressed: () {}),
                brightness: mode.brightness,
                highContrast: mode.highContrast,
              ),
            );
            final center = tester.getCenter(find.byType(BLabButton));
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(center);
            await tester.pumpAndSettle();

            expect(
              _interactionOverlay(tester).color,
              _expectedHover(mode.tokens, variant),
            );

            await mouse.down(center);
            await tester.pump();
            expect(_interactionOverlay(tester).color, const Color(0x1AFFFFFF));
            await mouse.up();
            await tester.pumpAndSettle();
            expect(
              _interactionOverlay(tester).color,
              _expectedHover(mode.tokens, variant),
            );

            await mouse.moveTo(Offset.zero);
            await tester.pumpAndSettle();
            expect(_interactionOverlay(tester).color, Colors.transparent);
            await mouse.removePointer();
          },
        );
      }
    }

    testWidgets(
      'hover is enabled-pointer-only and clears on disable/lifecycle',
      (tester) async {
        late StateSetter setHarnessState;
        var enabled = true;
        await tester.pumpWidget(
          _buttonHarness(
            StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return BLabButton(
                  text: 'Hover',
                  onPressed: enabled ? () {} : null,
                );
              },
            ),
          ),
        );
        final center = tester.getCenter(find.byType(BLabButton));

        final touch = await tester.startGesture(
          center,
          kind: PointerDeviceKind.touch,
        );
        await tester.pump();
        await touch.cancel();
        await tester.pumpAndSettle();
        expect(_interactionOverlay(tester).color, Colors.transparent);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(center);
        await tester.pumpAndSettle();
        expect(_interactionOverlay(tester).color, isNot(Colors.transparent));

        setHarnessState(() => enabled = false);
        await tester.pump();
        expect(_interactionOverlay(tester).color, Colors.transparent);

        setHarnessState(() => enabled = true);
        await tester.pump();
        await mouse.moveTo(Offset.zero);
        await mouse.moveTo(center);
        await tester.pumpAndSettle();
        expect(_interactionOverlay(tester).color, isNot(Colors.transparent));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(_interactionOverlay(tester).color, Colors.transparent);
        await mouse.removePointer();
      },
    );

    testWidgets('pressed feedback is bounded and releases after activation', (
      tester,
    ) async {
      var activations = 0;
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(text: 'Press', onPressed: () => activations += 1),
        ),
      );
      final center = tester.getCenter(find.byType(BLabButton));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey<String>('BLabButton.pressScale')),
            )
            .scale,
        0.96,
      );

      await gesture.up();
      expect(activations, 1);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey<String>('BLabButton.pressScale')),
            )
            .scale,
        1,
      );
    });

    for (final mode in _buttonVisualModes) {
      for (final variant in BLabButtonVariant.values) {
        testWidgets(
          '${mode.label} ${variant.name} focus splits outline and outer ring',
          (tester) async {
            await tester.pumpWidget(
              _buttonHarness(
                BLabButton(text: 'Focus', variant: variant, onPressed: () {}),
                brightness: mode.brightness,
                highContrast: mode.highContrast,
              ),
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();

            final surface = _surface(tester);
            final outline = _focusDecoration(tester, 'focusOutline');
            final ring = _focusDecoration(tester, 'focusRing');
            final outlineColor = outline.border!.top.color;
            final ringColor = ring.border!.top.color;
            final canvas = mode.tokens.surfaceBase;
            final actualSurface = Color.alphaBlend(surface.color!, canvas);

            expect(outline.border!.top.width, 2);
            expect(ring.border!.top.width, 3);
            expect(outlineColor, _expectedFocusOutline(mode.tokens, variant));
            expect(ringColor, mode.tokens.buttonFocusOuterRing);
            expect(
              _contrastRatio(outlineColor, actualSurface),
              greaterThanOrEqualTo(3),
            );
            expect(_contrastRatio(ringColor, canvas), greaterThanOrEqualTo(3));
            expect(outline.borderRadius, BLabRadius.mdRect);
            expect(ring.borderRadius, BorderRadius.circular(BLabRadius.md + 3));
          },
        );
      }
    }

    testWidgets('surface, overlay, outline and motion use Button corrections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buttonHarness(BLabButton(text: 'Shape', onPressed: () {})),
      );
      final center = tester.getCenter(find.byType(BLabButton));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(center);
      await tester.pump();

      expect(_surface(tester).borderRadius, BLabRadius.mdRect);
      expect(_interactionOverlay(tester).borderRadius, BLabRadius.mdRect);
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>('BLabButton.interactionAnimation'),
              ),
            )
            .curve,
        BLabMotion.ease,
      );
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey<String>('BLabButton.pressScale')),
            )
            .curve,
        BLabMotion.ease,
      );
      await mouse.removePointer();
    });

    testWidgets('high contrast maps surface, foreground, border, and focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(
            text: 'Contrast',
            variant: BLabButtonVariant.secondary,
            onPressed: () {},
          ),
          brightness: Brightness.dark,
          highContrast: true,
        ),
      );

      final surface =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey<String>('BLabButton.surface')),
                  )
                  .decoration
              as BoxDecoration;
      expect(surface.color, BLabTokenTheme.highContrastDark.glassSurface);
      expect(
        surface.border!.top.color,
        BLabTokenTheme.highContrastDark.borderDefault,
      );
      expect(
        tester.widget<Text>(find.text('Contrast')).style!.color,
        BLabTokenTheme.highContrastDark.textPrimary,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focus =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>('BLabButton.focusOutline'),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(
        focus.border!.top.color,
        BLabTokenTheme.highContrastDark.buttonSecondaryFocusOutline,
      );
    });
  });

  group('BLabButton accessibility preferences', () {
    for (final mode in _buttonVisualModes) {
      for (final variant in <BLabButtonVariant>[
        BLabButtonVariant.primary,
        BLabButtonVariant.destructive,
      ]) {
        testWidgets(
          '${mode.label} ${variant.name} content meets 4.5:1 in enabled states',
          (tester) async {
            await tester.pumpWidget(
              _buttonHarness(
                BLabButton(
                  text: 'Contrast',
                  icon: Icons.star,
                  variant: variant,
                  onPressed: () {},
                ),
                brightness: mode.brightness,
                highContrast: mode.highContrast,
              ),
            );

            void expectContrast(String state) {
              final background = Color.alphaBlend(
                _surface(tester).color!,
                mode.tokens.surfaceBase,
              );
              final overlay = _interactionOverlay(tester).color!;
              final actualBackground = Color.alphaBlend(overlay, background);
              final foreground = tester
                  .widget<Text>(find.text('Contrast'))
                  .style!
                  .color!;
              final actualForeground = Color.alphaBlend(overlay, foreground);

              expect(
                tester.widget<Icon>(find.byIcon(Icons.star)).color,
                foreground,
              );
              expect(
                _contrastRatio(actualForeground, actualBackground),
                greaterThanOrEqualTo(4.5),
                reason:
                    '${mode.label} ${variant.name} $state foreground '
                    '${_hexColor(actualForeground)} on '
                    '${_hexColor(actualBackground)}',
              );
            }

            expectContrast('default');

            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey<String>('BLabButton.focusOutline')),
              findsOneWidget,
            );
            expectContrast('focus');

            final center = tester.getCenter(find.byType(BLabButton));
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(center);
            await tester.pumpAndSettle();
            expectContrast('hover');

            await mouse.down(center);
            await tester.pumpAndSettle();
            expectContrast('pressed');
            await mouse.up();
            await mouse.removePointer();
          },
        );

        testWidgets(
          '${mode.label} ${variant.name} custom content inherits foreground',
          (tester) async {
            await tester.pumpWidget(
              _buttonHarness(
                BLabButton(
                  text: 'Custom action',
                  variant: variant,
                  onPressed: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, key: ValueKey<String>('custom-icon')),
                      Text('Custom label'),
                    ],
                  ),
                ),
                brightness: mode.brightness,
                highContrast: mode.highContrast,
              ),
            );

            final expectedForeground = switch (variant) {
              BLabButtonVariant.primary => mode.tokens.actionPrimaryForeground,
              BLabButtonVariant.destructive =>
                mode.tokens.actionDestructiveForeground,
              BLabButtonVariant.secondary => throw StateError(
                'Secondary is not part of this contrast regression.',
              ),
            };
            final textContext = tester.element(find.text('Custom label'));
            final iconContext = tester.element(
              find.byKey(const ValueKey<String>('custom-icon')),
            );

            expect(
              DefaultTextStyle.of(textContext).style.color,
              expectedForeground,
            );
            expect(IconTheme.of(iconContext).color, expectedForeground);
          },
        );
      }
    }

    testWidgets('explicit custom content colors remain consumer-owned', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(
            text: 'Custom action',
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.green),
                Text('Custom label', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      );

      expect(tester.widget<Icon>(find.byIcon(Icons.star)).color, Colors.green);
      expect(
        tester.widget<Text>(find.text('Custom label')).style!.color,
        Colors.red,
      );
    });

    for (final scale in <double>[1, 1.3, 2]) {
      testWidgets('honors ambient linear text scaling at $scale', (
        tester,
      ) async {
        final scaler = TextScaler.linear(scale);
        await tester.pumpWidget(
          _buttonHarness(
            BLabButton(text: 'Scaled action', onPressed: () {}),
            textScaler: scaler,
            width: 220,
          ),
        );

        expect(tester.takeException(), isNull);
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(BLabButton),
            matching: find.byType(RichText),
          ),
        );
        expect(identical(richText.textScaler, scaler), isTrue);
        expect(
          tester.getSize(find.byType(BLabButton)).height,
          greaterThanOrEqualTo(44),
        );
      });
    }

    testWidgets('honors ambient nonlinear text scaling without a clamp', (
      tester,
    ) async {
      const scaler = _ButtonNonlinearTextScaler();
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(text: 'Nonlinear action', onPressed: () {}),
          textScaler: scaler,
          width: 220,
        ),
      );

      expect(tester.takeException(), isNull);
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(BLabButton),
          matching: find.byType(RichText),
        ),
      );
      expect(identical(richText.textScaler, scaler), isTrue);
    });

    testWidgets('reduced motion makes press and overlay feedback immediate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(text: 'Reduced motion', onPressed: () {}),
          disableAnimations: true,
        ),
      );

      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey<String>('BLabButton.pressScale')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>('BLabButton.interactionAnimation'),
              ),
            )
            .duration,
        Duration.zero,
      );
    });
  });

  group('BLabButton haptic policy', () {
    testWidgets('defaults to no haptic and never haptics for keyboard', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _buttonHarness(BLabButton(text: 'Action', onPressed: () {})),
      );
      await tester.tap(find.byType(BLabButton));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('explicit policy allows one touch pulse, never pointer pulse', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _buttonHarness(
          BLabButton(
            text: 'Action',
            hapticConfiguration: _enabledHaptics,
            onPressed: () {},
          ),
        ),
      );
      final center = tester.getCenter(find.byType(BLabButton));
      final touch = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await touch.up();
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.arguments, 'HapticFeedbackType.selectionClick');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      await mouse.down(center);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      await mouse.removePointer();
    });
  });
}

Widget _buttonHarness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
  double width = 360,
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
            child: BLabFocusVisibilityScope(child: child),
          ),
        ),
      ),
    ),
  );
}

const _enabledHaptics = BLabHapticConfiguration(
  platformSupportsHaptics: true,
  systemHapticsEnabled: true,
  accessibilityHapticsEnabled: true,
  componentHapticsEnabled: true,
);

class _ButtonNonlinearTextScaler extends TextScaler {
  const _ButtonNonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}

const _buttonVisualModes = <_ButtonVisualMode>[
  _ButtonVisualMode(
    label: 'light',
    brightness: Brightness.light,
    highContrast: false,
    tokens: BLabTokenTheme.light,
  ),
  _ButtonVisualMode(
    label: 'dark',
    brightness: Brightness.dark,
    highContrast: false,
    tokens: BLabTokenTheme.dark,
  ),
  _ButtonVisualMode(
    label: 'high-contrast light',
    brightness: Brightness.light,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastLight,
  ),
  _ButtonVisualMode(
    label: 'high-contrast dark',
    brightness: Brightness.dark,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastDark,
  ),
];

class _ButtonVisualMode {
  const _ButtonVisualMode({
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

BoxDecoration _interactionOverlay(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>('BLabButton.interactionAnimation'),
              ),
            )
            .decoration
        as BoxDecoration;

BoxDecoration _surface(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(const ValueKey<String>('BLabButton.surface')),
            )
            .decoration
        as BoxDecoration;

BoxDecoration _focusDecoration(WidgetTester tester, String suffix) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(ValueKey<String>('BLabButton.$suffix')),
            )
            .decoration
        as BoxDecoration;

Color _expectedHover(BLabTokenTheme tokens, BLabButtonVariant variant) =>
    switch (variant) {
      BLabButtonVariant.primary => tokens.buttonPrimaryHoverOverlay,
      BLabButtonVariant.secondary => tokens.buttonSecondaryHoverOverlay,
      BLabButtonVariant.destructive => tokens.buttonDestructiveHoverOverlay,
    };

Color _expectedFocusOutline(BLabTokenTheme tokens, BLabButtonVariant variant) =>
    switch (variant) {
      BLabButtonVariant.primary => tokens.buttonPrimaryFocusOutline,
      BLabButtonVariant.secondary => tokens.buttonSecondaryFocusOutline,
      BLabButtonVariant.destructive => tokens.buttonDestructiveFocusOutline,
    };

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

String _hexColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
