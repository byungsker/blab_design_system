import 'dart:ui' show Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabPressableWrapper compatibility and activation', () {
    testWidgets(
      'legacy public onTap field stays non-null while null input is inert',
      (tester) async {
        final widget = BLabPressableWrapper(
          onTap: null,
          child: const Text('Static pressable content'),
        );
        final VoidCallback legacyRead = widget.onTap;
        expect(legacyRead, returnsNormally);

        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_harness(widget));
        final node = tester.getSemantics(
          find.byKey(const ValueKey<String>('BLabPressable.semantics')),
        );
        expect(node.flagsCollection.isButton, isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        expect(node.flagsCollection.isFocused, isNot(Tristate.isTrue));
        await tester.tap(find.byType(BLabPressableWrapper));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

    testWidgets('legacy public onTap field dispatches the actual callback', (
      tester,
    ) async {
      var calls = 0;
      final widget = BLabPressableWrapper(
        onTap: () => calls += 1,
        child: const Text('Action'),
      );
      final VoidCallback legacyRead = widget.onTap;
      legacyRead();
      expect(calls, 1);

      await tester.pumpWidget(_harness(widget));
      await tester.tap(find.byType(BLabPressableWrapper));
      expect(calls, 2);
    });

    testWidgets('preserves legacy defaults and enforces a 44x44 target', (
      tester,
    ) async {
      final widget = BLabPressableWrapper(
        onTap: () {},
        child: const SizedBox(width: 8, height: 8),
      );
      expect(widget, isA<StatefulWidget>());
      expect(widget.scaleEnd, 0.96);
      expect(widget.brightnessEnd, 0.1);
      expect(widget.animationDuration, BLabMotion.durPress);
      expect(widget.enableHaptic, isTrue);
      expect(widget.semanticLabel, isNull);
      expect(widget.semanticHint, isNull);
      expect(widget.hapticConfiguration, BLabHapticConfiguration.disabled);

      await tester.pumpWidget(_harness(widget));
      final size = tester.getSize(find.byType(BLabPressableWrapper));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('tap, Enter, and Space each commit immediately and once', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          BLabPressableWrapper(
            semanticLabel: 'Open',
            onTap: () => calls += 1,
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.byType(BLabPressableWrapper));
      expect(calls, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      expect(calls, 2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(calls, 2);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      expect(calls, 2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, 3);
    });

    testWidgets('long press commits once without also tapping', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpWidget(
        _harness(
          BLabPressableWrapper(
            semanticLabel: 'Options',
            onTap: () => taps += 1,
            onLongPress: () => longPresses += 1,
            child: const Text('Options'),
          ),
        ),
      );

      await tester.longPress(find.byType(BLabPressableWrapper));
      expect(taps, 0);
      expect(longPresses, 1);
    });

    testWidgets('focus and lifecycle changes cancel pending key cycles', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          BLabPressableWrapper(
            semanticLabel: 'Open',
            onTap: () => calls += 1,
            child: const Text('Open'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, 0);
    });

    testWidgets('does not synthesize selected or invalid semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          BLabPressableWrapper(
            semanticLabel: 'Open',
            onTap: () {},
            child: const Text('Open'),
          ),
        ),
      );

      final node = tester.getSemantics(
        find.byKey(const ValueKey<String>('BLabPressable.semantics')),
      );
      expect(node.flagsCollection.isSelected, Tristate.none);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });
  });

  group('BLabCard action and semantics matrix', () {
    testWidgets('static Card is noninteractive and retains custom geometry', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      const radius = BorderRadius.all(Radius.circular(22));
      const padding = EdgeInsets.all(31);
      await tester.pumpWidget(
        _harness(
          const BLabCard(
            borderRadius: radius,
            padding: padding,
            child: Text('Static'),
          ),
        ),
      );

      expect(find.byType(BLabPressableWrapper), findsNothing);
      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey<String>('BLabCard.surface')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(decoration.borderRadius, radius);
      final paddingWidget = tester.widget<Padding>(
        find.byKey(const ValueKey<String>('BLabCard.padding')),
      );
      expect(paddingWidget.padding, padding);
      final node = tester.getSemantics(find.text('Static'));
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      semantics.dispose();
    });

    testWidgets('static Card rejects blank caller semantics', (tester) async {
      await tester.pumpWidget(
        _harness(
          const BLabCard(semanticLabel: '   ', child: Text('Static label')),
        ),
      );
      expect(tester.takeException(), isArgumentError);

      await tester.pumpWidget(
        _harness(
          const BLabCard(semanticHint: '   ', child: Text('Static hint')),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('tap-only Card has one button action', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Open details',
            semanticHint: 'Shows the record',
            onTap: () => taps += 1,
            child: const Text('Record'),
          ),
        ),
      );

      final action = find.byKey(
        const ValueKey<String>('BLabPressable.semantics'),
      );
      final node = tester.getSemantics(action);
      expect(node.label, 'Open details');
      expect(node.hint, 'Shows the record');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, Tristate.none);
      tester.semantics.tap(find.semantics.byLabel('Open details'));
      await tester.pump();
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('long-only Card exposes no fabricated tap or button role', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var longPresses = 0;
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Show options',
            onLongPress: () => longPresses += 1,
            child: const Text('Record'),
          ),
        ),
      );

      final finder = find.byKey(
        const ValueKey<String>('BLabPressable.semantics'),
      );
      final node = tester.getSemantics(finder);
      expect(node.flagsCollection.isButton, isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.longPress),
        isTrue,
      );

      await tester.tap(find.byType(BLabCard));
      await tester.pumpAndSettle();
      expect(longPresses, 0);
      expect(_interactionColor(tester), Colors.transparent);
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey<String>('BLabPressable.scale')),
            )
            .scale,
        1,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(longPresses, 1);
      tester.semantics.longPress(find.semantics.byLabel('Show options'));
      await tester.pump();
      expect(longPresses, 2);
      semantics.dispose();
    });

    testWidgets('both actions never double-dispatch', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Record',
            onTap: () => taps += 1,
            onLongPress: () => longPresses += 1,
            child: const Text('Record'),
          ),
        ),
      );

      await tester.tap(find.byType(BLabCard));
      expect((taps, longPresses), (1, 0));
      await tester.longPress(find.byType(BLabCard));
      expect((taps, longPresses), (1, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect((taps, longPresses), (2, 1));
    });

    testWidgets('blank caller semantics are rejected', (tester) async {
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: '   ',
            onTap: () {},
            child: const Text('Record'),
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });
  });

  group('Pressable and Card visual modes', () {
    for (final mode in _modes) {
      testWidgets('${mode.label} resolves component tokens', (tester) async {
        await tester.pumpWidget(
          _harness(
            BLabCard(
              semanticLabel: 'Open',
              onTap: () {},
              child: const Text('Open'),
            ),
            brightness: mode.brightness,
            highContrast: mode.highContrast,
          ),
        );

        final cardDecoration =
            tester
                    .widget<DecoratedBox>(
                      find.byKey(const ValueKey<String>('BLabCard.surface')),
                    )
                    .decoration
                as BoxDecoration;
        expect(cardDecoration.color, mode.tokens.cardSurface);
        expect(
          (cardDecoration.border as Border).top.color,
          mode.tokens.cardBorder,
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(
          location: tester.getCenter(find.byType(BLabCard)),
        );
        await tester.pump();
        expect(_interactionColor(tester), mode.tokens.pressableHoverOverlay);

        await mouse.down(tester.getCenter(find.byType(BLabCard)));
        await tester.pump();
        expect(_interactionColor(tester), mode.tokens.pressablePressedOverlay);
        await mouse.up();
        await mouse.removePointer();
      });
    }

    testWidgets('keyboard focus uses outline and outer-ring tokens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Open',
            onTap: () {},
            child: const Text('Open'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final outline =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>('BLabPressable.focusOutline'),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final ring =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>('BLabPressable.focusRing'),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(
        (outline.border as Border).top.color,
        BLabTokenTheme.light.pressableFocusOutline,
      );
      expect(
        (ring.border as Border).top.color,
        BLabTokenTheme.light.pressableFocusOuterRing,
      );
    });

    testWidgets('high contrast is opaque and has no backdrop filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const BLabCard(child: Text('Static')), highContrast: true),
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey<String>('BLabCard.surface')),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color!.a, 1);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('reduced motion is immediate and ambient scaling is retained', (
      tester,
    ) async {
      const scaler = _NonlinearScaler();
      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Open',
            onTap: () {},
            child: Builder(
              builder: (context) =>
                  Text('${MediaQuery.textScalerOf(context).scale(20)}'),
            ),
          ),
          disableAnimations: true,
          textScaler: scaler,
        ),
      );

      final overlay = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('BLabPressable.interaction')),
      );
      final scale = tester.widget<AnimatedScale>(
        find.byKey(const ValueKey<String>('BLabPressable.scale')),
      );
      expect(overlay.duration, Duration.zero);
      expect(scale.duration, Duration.zero);
      expect(find.text('${scaler.scale(20)}'), findsOneWidget);
    });
  });

  testWidgets(
    'haptics are default-deny and touch-only when explicitly allowed',
    (tester) async {
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
        _harness(
          BLabCard(
            semanticLabel: 'Open',
            onTap: () {},
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.byType(BLabCard));
      expect(calls, isEmpty);

      await tester.pumpWidget(
        _harness(
          BLabCard(
            semanticLabel: 'Open',
            hapticConfiguration: _enabledHaptics,
            onTap: () {},
            child: const Text('Open'),
          ),
        ),
      );
      final touch = await tester.startGesture(
        tester.getCenter(find.byType(BLabCard)),
        kind: PointerDeviceKind.touch,
      );
      await touch.up();
      await tester.pump();
      expect(calls, hasLength(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, hasLength(1));
    },
  );
}

Color? _interactionColor(WidgetTester tester) {
  final overlay = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey<String>('BLabPressable.interaction')),
  );
  return (overlay.decoration as BoxDecoration).color;
}

Widget _harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
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
        body: Center(child: BLabFocusVisibilityScope(child: child)),
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

const _modes = <_Mode>[
  _Mode('light', Brightness.light, false, BLabTokenTheme.light),
  _Mode('dark', Brightness.dark, false, BLabTokenTheme.dark),
  _Mode(
    'high-contrast light',
    Brightness.light,
    true,
    BLabTokenTheme.highContrastLight,
  ),
  _Mode(
    'high-contrast dark',
    Brightness.dark,
    true,
    BLabTokenTheme.highContrastDark,
  ),
];

class _Mode {
  const _Mode(this.label, this.brightness, this.highContrast, this.tokens);

  final String label;
  final Brightness brightness;
  final bool highContrast;
  final BLabTokenTheme tokens;
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}
