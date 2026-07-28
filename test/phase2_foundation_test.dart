import 'dart:math' as math;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('focus visibility and modality', () {
    test(
      'tracks deterministic keyboard, pointer, touch, and traversal intent',
      () {
        final controller = BLabFocusVisibilityController();
        addTearDown(controller.dispose);

        expect(controller.modality, BLabInputModality.unknown);
        expect(controller.shouldShowVisibleFocus(hasFocus: true), isFalse);

        controller.registerKeyboardIntent(
          LogicalKeyboardKey.tab,
          shiftPressed: true,
        );
        expect(controller.modality, BLabInputModality.keyboard);
        expect(controller.traversalIntent, BLabTraversalIntent.previous);
        expect(controller.shouldShowVisibleFocus(hasFocus: true), isTrue);

        controller.registerPointer(PointerDeviceKind.mouse);
        expect(controller.modality, BLabInputModality.pointer);
        expect(controller.traversalIntent, BLabTraversalIntent.none);
        expect(controller.shouldShowVisibleFocus(hasFocus: true), isFalse);

        controller.registerPointer(PointerDeviceKind.touch);
        expect(controller.modality, BLabInputModality.touch);

        controller.reset();
        expect(controller.modality, BLabInputModality.unknown);
        expect(controller.traversalIntent, BLabTraversalIntent.none);
      },
    );

    testWidgets('scope owns and releases its controller without global state', (
      tester,
    ) async {
      late BLabFocusVisibilityController first;
      late BLabFocusVisibilityController second;

      Widget build(ValueChanged<BLabFocusVisibilityController> capture) {
        return MaterialApp(
          home: BLabFocusVisibilityScope(
            child: Builder(
              builder: (context) {
                capture(BLabFocusVisibilityScope.of(context));
                return const Focus(autofocus: true, child: Text('focus'));
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(build((value) => first = value));
      first.registerKeyboardIntent(LogicalKeyboardKey.tab);
      expect(first.modality, BLabInputModality.keyboard);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(build((value) => second = value));
      expect(identical(first, second), isFalse);
      expect(second.modality, BLabInputModality.unknown);
    });

    testWidgets('scope observes real keyboard and touch events', (
      tester,
    ) async {
      final controller = BLabFocusVisibilityController();
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusVisibilityScope(
            controller: controller,
            child: Focus(
              autofocus: true,
              focusNode: node,
              child: const ColoredBox(
                key: ValueKey('modality-target'),
                color: Colors.transparent,
                child: SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(controller.modality, BLabInputModality.keyboard);
      expect(controller.traversalIntent, BLabTraversalIntent.next);

      await tester.tap(find.byKey(const ValueKey('modality-target')));
      expect(controller.modality, BLabInputModality.touch);
      expect(controller.traversalIntent, BLabTraversalIntent.none);
    });
  });

  group('keyboard activation', () {
    testWidgets('Enter and Space activate once per physical key cycle', (
      tester,
    ) async {
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BLabKeyboardActivator(
            autofocus: true,
            onActivate: () => activations += 1,
            child: const Text('activate'),
          ),
        ),
      );
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

    testWidgets('disabled and busy controls suppress activation', (
      tester,
    ) async {
      var activations = 0;

      Future<void> pump({required bool enabled, required bool busy}) {
        return tester.pumpWidget(
          MaterialApp(
            home: BLabKeyboardActivator(
              autofocus: true,
              enabled: enabled,
              busy: busy,
              onActivate: () => activations += 1,
              child: const Text('activate'),
            ),
          ),
        );
      }

      await pump(enabled: false, busy: false);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      await pump(enabled: true, busy: true);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(activations, 0);
    });

    for (final key in <LogicalKeyboardKey>[
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      testWidgets(
        '$key resets after focus loss before key-up and accepts next cycle',
        (tester) async {
          final activatorNode = FocusNode();
          final elsewhereNode = FocusNode();
          addTearDown(activatorNode.dispose);
          addTearDown(elsewhereNode.dispose);
          var activations = 0;

          await tester.pumpWidget(
            MaterialApp(
              home: Column(
                children: [
                  BLabKeyboardActivator(
                    focusNode: activatorNode,
                    onActivate: () => activations += 1,
                    child: const Text('activate'),
                  ),
                  Focus(
                    focusNode: elsewhereNode,
                    child: const Text('elsewhere'),
                  ),
                ],
              ),
            ),
          );

          activatorNode.requestFocus();
          await tester.pump();
          await tester.sendKeyDownEvent(key);
          elsewhereNode.requestFocus();
          await tester.pump();
          await tester.sendKeyUpEvent(key);
          activatorNode.requestFocus();
          await tester.pump();
          await tester.sendKeyDownEvent(key);
          await tester.sendKeyUpEvent(key);

          expect(activations, key == LogicalKeyboardKey.enter ? 2 : 1);
        },
      );
    }

    testWidgets('lifecycle transitions reset an incomplete key cycle', (
      tester,
    ) async {
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BLabKeyboardActivator(
            autofocus: true,
            onActivate: () => activations += 1,
            child: const Text('activate'),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);

      expect(activations, 1);
    });
  });

  test(
    'semantic interaction state maps typed relationships and suppression',
    () {
      const state = BLabSemanticInteractionState(
        availability: BLabInteractionAvailability.enabled,
        activity: BLabInteractionActivity.loading,
        selection: BLabSelectionState.selected,
        current: BLabCurrentState.current,
        validation: BLabValidationState.invalid,
        disclosure: BLabDisclosureState.expanded,
        destructive: true,
        readOnly: true,
        label: 'Label',
        value: 'Value',
      );

      final properties = state.toSemanticsProperties();
      expect(state.relationship, BLabSemanticRelationship.labelAndValue);
      expect(state.suppressesActivation, isTrue);
      expect(properties.enabled, isTrue);
      expect(properties.selected, isTrue);
      expect(properties.expanded, isTrue);
      expect(properties.readOnly, isTrue);
      expect(properties.label, 'Label');
      expect(properties.value, 'Value');
      expect(properties.validationResult, SemanticsValidationResult.invalid);
    },
  );

  test('semantic state covers idle, busy, disabled, valid, and collapsed', () {
    const idleValid = BLabSemanticInteractionState(
      activity: BLabInteractionActivity.idle,
      selection: BLabSelectionState.unselected,
      current: BLabCurrentState.notCurrent,
      validation: BLabValidationState.valid,
      disclosure: BLabDisclosureState.collapsed,
    );
    const disabledBusy = BLabSemanticInteractionState(
      availability: BLabInteractionAvailability.disabled,
      activity: BLabInteractionActivity.busy,
    );

    final idleProperties = idleValid.toSemanticsProperties();
    expect(idleValid.suppressesActivation, isFalse);
    expect(idleProperties.enabled, isTrue);
    expect(idleProperties.selected, isFalse);
    expect(idleProperties.expanded, isFalse);
    expect(idleProperties.validationResult, SemanticsValidationResult.valid);
    expect(disabledBusy.suppressesActivation, isTrue);
    expect(disabledBusy.toSemanticsProperties().enabled, isFalse);
  });

  test('current and activity never collapse into selected or disabled', () {
    const currentLoading = BLabSemanticInteractionState(
      availability: BLabInteractionAvailability.enabled,
      activity: BLabInteractionActivity.loading,
      selection: BLabSelectionState.notApplicable,
      current: BLabCurrentState.current,
      destructive: true,
    );

    final properties = currentLoading.toSemanticsProperties();
    expect(currentLoading.suppressesActivation, isTrue);
    expect(properties.enabled, isTrue);
    expect(properties.selected, isNull);
    expect(currentLoading.current, BLabCurrentState.current);
    expect(currentLoading.activity, BLabInteractionActivity.loading);
    expect(currentLoading.destructive, isTrue);
  });

  group('interactive targets', () {
    test('interactive policy expands layout evidence to 44x44', () {
      const policy = BLabInteractiveTargetPolicy.interactive();
      expect(policy.evaluate(const Size(12, 20)), const Size(44, 44));
      expect(policy.evaluate(const Size(50, 52)), const Size(50, 52));
    });

    test(
      'typed noninteractive and documented exceptions do not force size',
      () {
        const noninteractive = BLabInteractiveTargetPolicy.nonInteractive();
        final exception = BLabInteractiveTargetPolicy.documentedException(
          'Design review reference BLDS-EXAMPLE',
          designDecisionReference: 'BLDS-ALL-PHASES-2026-07-25',
        );

        expect(noninteractive.evaluate(const Size(12, 20)), const Size(12, 20));
        expect(exception.evaluate(const Size(12, 20)), const Size(12, 20));
        expect(exception.exceptionReason, isNotEmpty);
        expect(exception.designDecisionReference, isNotEmpty);
      },
    );

    test('documented exceptions reject blank runtime evidence', () {
      expect(
        () => BLabInteractiveTargetPolicy.documentedException(
          ' ',
          designDecisionReference: 'BLDS-ALL-PHASES-2026-07-25',
        ),
        throwsArgumentError,
      );
      expect(
        () => BLabInteractiveTargetPolicy.documentedException(
          'Reason',
          designDecisionReference: '\n\t',
        ),
        throwsArgumentError,
      );
      dynamic missing;
      expect(
        () => BLabInteractiveTargetPolicy.documentedException(
          missing,
          designDecisionReference: 'BLDS-ALL-PHASES-2026-07-25',
        ),
        throwsA(anything),
      );
      expect(
        () => BLabInteractiveTargetPolicy.documentedException(
          'Reason',
          designDecisionReference: missing,
        ),
        throwsA(anything),
      );
    });

    testWidgets('interactive target enforces layout without changing visuals', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BLabInteractiveTarget(child: SizedBox(width: 8, height: 8)),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(BLabInteractiveTarget)),
        const Size(44, 44),
      );
      expect(tester.getSize(find.byType(SizedBox)), const Size(8, 8));
    });
  });

  group('text scaling policy', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'evaluates ambient linear TextScaler $scale without clamping',
        (tester) async {
          final scaler = TextScaler.linear(scale);
          late BLabTextScalingEvidence evidence;
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: scaler),
              child: Builder(
                builder: (context) {
                  evidence = BLabTextScalingPolicy.evaluate(
                    BLabTextScalingPolicy.of(context),
                    unscaledFontSize: 20,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          expect(evidence.scaledFontSize, closeTo(20 * scale, 0.0001));
          expect(evidence.withinVerifiedRange, isTrue);
          expect(identical(evidence.textScaler, scaler), isTrue);
        },
      );
    }

    test('honors nonlinear TextScaler through scale()', () {
      const scaler = _NonlinearTextScaler();
      final evidence = BLabTextScalingPolicy.evaluate(
        scaler,
        unscaledFontSize: 20,
      );

      expect(evidence.scaledFontSize, 27);
      expect(evidence.equivalentScale, 1.35);
      expect(identical(evidence.textScaler, scaler), isTrue);
    });

    testWidgets('reads the ambient TextScaler without taking ownership', (
      tester,
    ) async {
      const scaler = _NonlinearTextScaler();
      late TextScaler ambient;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: scaler),
          child: Builder(
            builder: (context) {
              ambient = BLabTextScalingPolicy.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(ambient, scaler), isTrue);
    });
  });

  group('reduced motion', () {
    test('preserves approved durations when platform reduction is off', () {
      const policy = BLabReducedMotionPolicy(reduceMotion: false);

      expect(
        policy.resolve(
          duration: BLabMotion.durSurface,
          role: BLabTransitionRole.nonEssential,
        ),
        BLabMotion.durSurface,
      );
    });

    test('zeroes nonessential motion and bounds essential opacity', () {
      const policy = BLabReducedMotionPolicy(reduceMotion: true);

      expect(
        policy.resolve(
          duration: BLabMotion.durSurface,
          role: BLabTransitionRole.nonEssential,
        ),
        Duration.zero,
      );
      expect(
        policy.resolve(
          duration: BLabMotion.durSurface,
          role: BLabTransitionRole.essentialOpacity,
        ),
        BLabMotion.durPress,
      );
    });

    testWidgets('resolves both MediaQuery reduction signals', (tester) async {
      late BLabReducedMotionPolicy policy;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            disableAnimations: false,
            accessibleNavigation: true,
          ),
          child: Builder(
            builder: (context) {
              policy = BLabReducedMotionPolicy.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(policy.reduceMotion, isTrue);
    });
  });

  group('high contrast resolution', () {
    const cases = <(Brightness, bool, BLabVisualMode)>[
      (Brightness.light, false, BLabVisualMode.light),
      (Brightness.dark, false, BLabVisualMode.dark),
      (Brightness.light, true, BLabVisualMode.highContrastLight),
      (Brightness.dark, true, BLabVisualMode.highContrastDark),
    ];

    for (final (brightness, highContrast, expected) in cases) {
      test('resolves $brightness highContrast=$highContrast', () {
        final result = BLabVisualModeResolver.resolve(
          brightness: brightness,
          highContrast: highContrast,
        );

        expect(result.mode, expected);
        expect(result.tokens, BLabTokenTheme.forMode(expected));
      });
    }

    testWidgets('integrates Theme brightness and MediaQuery highContrast', (
      tester,
    ) async {
      late BLabResolvedVisualMode resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(highContrast: true),
            child: Builder(
              builder: (context) {
                resolved = BLabVisualModeResolver.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved.mode, BLabVisualMode.highContrastDark);
      expect(resolved.tokens, BLabTokenTheme.highContrastDark);
    });
  });

  group('focus visual foundation', () {
    test('exposes canonical outline and distinct-ring geometry', () {
      final style = BLabFocusVisualResolver.resolve(
        tokens: BLabTokenTheme.light,
        surface: BLabFocusSurface.canvas,
      );

      expect(style.outlineWidth, 2);
      expect(style.ringWidth, 3);
    });

    final cases = <(BLabTokenTheme, BLabFocusSurface, Color, Color, String)>[
      (
        BLabTokenTheme.light,
        BLabFocusSurface.canvas,
        Color(0xFF5B7FFF),
        Color(0xFFFAFAFA),
        'light canvas',
      ),
      (
        BLabTokenTheme.light,
        BLabFocusSurface.surface,
        Color(0xFF5B7FFF),
        Colors.white,
        'light surface',
      ),
      (
        BLabTokenTheme.light,
        BLabFocusSurface.accent,
        Colors.white,
        Color(0xFF5B7FFF),
        'light accent',
      ),
      (
        BLabTokenTheme.dark,
        BLabFocusSurface.canvas,
        Color(0xFF5B7FFF),
        Color(0xFF121212),
        'dark canvas',
      ),
      (
        BLabTokenTheme.dark,
        BLabFocusSurface.surface,
        Color(0xFF5B7FFF),
        Color(0xFF1E1E1E),
        'dark surface',
      ),
      (
        BLabTokenTheme.dark,
        BLabFocusSurface.accent,
        Colors.white,
        Color(0xFF5B7FFF),
        'dark accent',
      ),
      (
        BLabTokenTheme.highContrastLight,
        BLabFocusSurface.canvas,
        Colors.black,
        Colors.white,
        'high-contrast light canvas',
      ),
      (
        BLabTokenTheme.highContrastLight,
        BLabFocusSurface.surface,
        Colors.black,
        Colors.white,
        'high-contrast light surface',
      ),
      (
        BLabTokenTheme.highContrastDark,
        BLabFocusSurface.canvas,
        Colors.white,
        Color(0xFF121212),
        'high-contrast dark canvas',
      ),
      (
        BLabTokenTheme.highContrastDark,
        BLabFocusSurface.surface,
        Colors.white,
        Color(0xFF121212),
        'high-contrast dark surface',
      ),
      (
        BLabTokenTheme.highContrastLight,
        BLabFocusSurface.accent,
        Colors.black,
        Color(0xFF5B7FFF),
        'high-contrast accent',
      ),
      (
        BLabTokenTheme.highContrastDark,
        BLabFocusSurface.accent,
        Colors.black,
        Color(0xFF5B7FFF),
        'high-contrast dark accent',
      ),
    ];

    for (final (tokens, surface, expected, adjacent, label) in cases) {
      test('$label resolves canonical color with at least 3:1 contrast', () {
        final style = BLabFocusVisualResolver.resolve(
          tokens: tokens,
          surface: surface,
        );

        expect(style.color, expected);
        expect(_contrastRatio(style.color, adjacent), greaterThanOrEqualTo(3));
      });
    }
  });

  group('haptic policy', () {
    test(
      'allows one explicit touch action when every policy gate is enabled',
      () {
        final decision = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: const BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: true,
          ),
        );

        expect(decision.shouldTrigger, isTrue);
        expect(decision.reason, BLabHapticDecisionReason.allowed);
      },
    );

    test(
      'suppresses accessibility, keyboard, busy, no-op, and repeat cases',
      () {
        final accessibilityDisabled = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: false,
            componentHapticsEnabled: true,
          ),
        );
        final keyboard = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.keyboard,
          configuration: _enabledHaptics,
        );
        final busy = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
          busy: true,
        );
        final noOp = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.selection,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
          noOp: true,
        );
        final platformDisabled = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: const BLabHapticConfiguration(
            platformSupportsHaptics: false,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: true,
          ),
        );
        final systemDisabled = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: const BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: false,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: true,
          ),
        );

        expect(accessibilityDisabled.shouldTrigger, isFalse);
        expect(keyboard.shouldTrigger, isFalse);
        expect(busy.shouldTrigger, isFalse);
        expect(noOp.shouldTrigger, isFalse);
        expect(
          platformDisabled.reason,
          BLabHapticDecisionReason.unsupportedPlatform,
        );
        expect(systemDisabled.reason, BLabHapticDecisionReason.systemDisabled);
      },
    );

    test('configuration is default-deny and every gate must be explicit', () {
      final decision = BLabHapticPolicy.resolve(
        intent: BLabHapticIntent.action,
        trigger: BLabHapticTrigger.touch,
        configuration: BLabHapticConfiguration.disabled,
      );

      expect(decision.shouldTrigger, isFalse);
      expect(decision.reason, BLabHapticDecisionReason.unsupportedPlatform);
    });

    test('every explicit eligibility gate denies independently', () {
      const cases = <(BLabHapticConfiguration, BLabHapticDecisionReason)>[
        (
          BLabHapticConfiguration(
            platformSupportsHaptics: false,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: true,
          ),
          BLabHapticDecisionReason.unsupportedPlatform,
        ),
        (
          BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: false,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: true,
          ),
          BLabHapticDecisionReason.systemDisabled,
        ),
        (
          BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: false,
            componentHapticsEnabled: true,
          ),
          BLabHapticDecisionReason.accessibilityDisabled,
        ),
        (
          BLabHapticConfiguration(
            platformSupportsHaptics: true,
            systemHapticsEnabled: true,
            accessibilityHapticsEnabled: true,
            componentHapticsEnabled: false,
          ),
          BLabHapticDecisionReason.componentDisabled,
        ),
      ];

      for (final (configuration, reason) in cases) {
        final decision = BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: configuration,
        );
        expect(decision.shouldTrigger, isFalse);
        expect(decision.reason, reason);
      }
      expect(
        BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.none,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
        ).reason,
        BLabHapticDecisionReason.noIntent,
      );
      expect(
        BLabHapticPolicy.resolve(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
          enabled: false,
        ).reason,
        BLabHapticDecisionReason.disabledControl,
      );
    });

    test(
      'action-cycle guard allows at most one pulse per committed action',
      () {
        final cycle = BLabHapticActionCycle();
        addTearDown(cycle.dispose);

        final first = cycle.resolveCommittedAction(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
        );
        final repeated = cycle.resolveCommittedAction(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
        );
        cycle.resetForNextAction();
        final nextAction = cycle.resolveCommittedAction(
          intent: BLabHapticIntent.action,
          trigger: BLabHapticTrigger.touch,
          configuration: _enabledHaptics,
        );

        expect(first.reason, BLabHapticDecisionReason.allowed);
        expect(repeated.reason, BLabHapticDecisionReason.repeatedAction);
        expect(nextAction.reason, BLabHapticDecisionReason.allowed);
      },
    );

    test('action-cycle guard is lifecycle-safe and side-effect free', () {
      final cycle = BLabHapticActionCycle();
      cycle.dispose();
      cycle.dispose();

      final afterDispose = cycle.resolveCommittedAction(
        intent: BLabHapticIntent.action,
        trigger: BLabHapticTrigger.touch,
        configuration: _enabledHaptics,
      );
      cycle.resetForNextAction();

      expect(afterDispose.shouldTrigger, isFalse);
      expect(afterDispose.reason, BLabHapticDecisionReason.disposed);
    });

    test('action-cycle guard evaluates every policy gate before reserving', () {
      final cycle = BLabHapticActionCycle();
      addTearDown(cycle.dispose);
      final denied = cycle.resolveCommittedAction(
        intent: BLabHapticIntent.action,
        trigger: BLabHapticTrigger.touch,
        configuration: BLabHapticConfiguration.disabled,
      );
      final allowed = cycle.resolveCommittedAction(
        intent: BLabHapticIntent.action,
        trigger: BLabHapticTrigger.touch,
        configuration: _enabledHaptics,
      );

      expect(denied.shouldTrigger, isFalse);
      expect(allowed.shouldTrigger, isTrue);
    });
  });

  group('focus-owned overlays', () {
    testWidgets('first-focus policy selects the first traversable child', (
      tester,
    ) async {
      final first = FocusNode(debugLabel: 'first-auto');
      final second = FocusNode(debugLabel: 'second-auto');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusOwnedOverlay(
            onDismiss: () {},
            child: Column(
              children: [
                Focus(focusNode: first, child: const Text('first')),
                Focus(focusNode: second, child: const Text('second')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(first.hasFocus, isTrue);
      expect(second.hasFocus, isFalse);
    });

    testWidgets(
      'initial focus, Escape dismissal, and focus return are ordered',
      (tester) async {
        final outside = FocusNode(debugLabel: 'outside');
        final inside = FocusNode(debugLabel: 'inside');
        addTearDown(outside.dispose);
        addTearDown(inside.dispose);
        var visible = false;
        late StateSetter update;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Column(
                  children: [
                    Focus(focusNode: outside, child: const Text('outside')),
                    if (visible)
                      BLabFocusOwnedOverlay(
                        initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                        initialFocusNode: inside,
                        onDismiss: () => setState(() => visible = false),
                        child: Focus(
                          focusNode: inside,
                          child: const Text('inside'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );

        outside.requestFocus();
        await tester.pump();
        expect(outside.hasFocus, isTrue);

        update(() => visible = true);
        await tester.pump();
        expect(inside.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(outside.hasFocus, isTrue);
      },
    );

    testWidgets('Tab traversal remains contained in a closed loop', (
      tester,
    ) async {
      final first = FocusNode(debugLabel: 'first');
      final second = FocusNode(debugLabel: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusOwnedOverlay(
            initialFocusPolicy: BLabInitialFocusPolicy.explicit,
            initialFocusNode: first,
            onDismiss: () {},
            child: Column(
              children: [
                Focus(focusNode: first, child: const Text('first')),
                Focus(focusNode: second, child: const Text('second')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(first.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(first.hasFocus, isTrue);
    });

    testWidgets('directional traversal remains contained in a closed loop', (
      tester,
    ) async {
      final first = FocusNode(debugLabel: 'first-directional');
      final second = FocusNode(debugLabel: 'second-directional');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusOwnedOverlay(
            initialFocusPolicy: BLabInitialFocusPolicy.explicit,
            initialFocusNode: first,
            onDismiss: () {},
            child: Row(
              children: [
                Focus(focusNode: first, child: const Text('first')),
                Focus(focusNode: second, child: const Text('second')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(second.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(first.hasFocus, isTrue);
    });

    testWidgets('platform back dismisses once and restores previous focus', (
      tester,
    ) async {
      final outside = FocusNode(debugLabel: 'outside-platform-back');
      addTearDown(outside.dispose);
      var visible = false;
      var dismissals = 0;
      BLabOverlayDismissIntent? intent;
      late StateSetter update;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  Focus(focusNode: outside, child: const Text('outside')),
                  if (visible)
                    BLabFocusOwnedOverlay(
                      onDismiss: () {
                        dismissals += 1;
                        setState(() => visible = false);
                      },
                      onDismissIntent: (value) => intent = value,
                      child: const Focus(child: Text('inside')),
                    ),
                ],
              );
            },
          ),
        ),
      );
      outside.requestFocus();
      await tester.pump();
      update(() => visible = true);
      await tester.pump();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      expect(dismissals, 1);
      expect(intent, BLabOverlayDismissIntent.platformBack);
      expect(outside.hasFocus, isTrue);
    });

    testWidgets(
      'nested platform back dismisses only the top focus owner per event',
      (tester) async {
        final outside = FocusNode(debugLabel: 'outside-nested-platform-back');
        final parent = FocusNode(debugLabel: 'parent-nested-platform-back');
        final child = FocusNode(debugLabel: 'child-nested-platform-back');
        addTearDown(outside.dispose);
        addTearDown(parent.dispose);
        addTearDown(child.dispose);
        var parentVisible = false;
        var childVisible = false;
        var parentDismissals = 0;
        var childDismissals = 0;
        final intents = <BLabOverlayDismissIntent>[];
        late StateSetter update;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Column(
                  children: [
                    Focus(focusNode: outside, child: const Text('outside')),
                    if (parentVisible)
                      BLabFocusOwnedOverlay(
                        initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                        initialFocusNode: parent,
                        onDismiss: () {
                          parentDismissals += 1;
                          setState(() => parentVisible = false);
                        },
                        onDismissIntent: intents.add,
                        child: Column(
                          children: [
                            Focus(
                              focusNode: parent,
                              child: const Text('parent'),
                            ),
                            if (childVisible)
                              BLabFocusOwnedOverlay(
                                initialFocusPolicy:
                                    BLabInitialFocusPolicy.explicit,
                                initialFocusNode: child,
                                onDismiss: () {
                                  childDismissals += 1;
                                  setState(() => childVisible = false);
                                },
                                onDismissIntent: intents.add,
                                child: Focus(
                                  focusNode: child,
                                  child: const Text('child'),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
        outside.requestFocus();
        await tester.pump();
        update(() => parentVisible = true);
        await tester.pump();
        expect(parent.hasFocus, isTrue);
        update(() => childVisible = true);
        await tester.pump();
        expect(child.hasFocus, isTrue);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pump();
        expect(childDismissals, 1);
        expect(parentDismissals, 0);
        expect(childVisible, isFalse);
        expect(parentVisible, isTrue);
        expect(parent.hasFocus, isTrue);
        expect(intents, [BLabOverlayDismissIntent.platformBack]);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pump();
        expect(childDismissals, 1);
        expect(parentDismissals, 1);
        expect(parentVisible, isFalse);
        expect(outside.hasFocus, isTrue);
        expect(intents, [
          BLabOverlayDismissIntent.platformBack,
          BLabOverlayDismissIntent.platformBack,
        ]);
      },
    );

    testWidgets(
      'nested platform back stays blocked by a non-dismissible child owner',
      (tester) async {
        final parent = FocusNode(
          debugLabel: 'parent-nondismissible-platform-back',
        );
        final child = FocusNode(
          debugLabel: 'child-nondismissible-platform-back',
        );
        addTearDown(parent.dispose);
        addTearDown(child.dispose);
        var parentDismissals = 0;
        var childDismissals = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: BLabFocusOwnedOverlay(
              initialFocusPolicy: BLabInitialFocusPolicy.explicit,
              initialFocusNode: parent,
              onDismiss: () => parentDismissals += 1,
              child: Column(
                children: [
                  Focus(focusNode: parent, child: const Text('parent')),
                  BLabFocusOwnedOverlay(
                    initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                    initialFocusNode: child,
                    dismissOnPlatformBack: false,
                    onDismiss: () => childDismissals += 1,
                    child: Focus(focusNode: child, child: const Text('child')),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(child.hasFocus, isTrue);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pump();
        expect(childDismissals, 0);
        expect(parentDismissals, 0);
        expect(child.hasFocus, isTrue);
        expect(parent.hasFocus, isFalse);
      },
    );

    testWidgets('invalid explicit focus safely falls back inside the scope', (
      tester,
    ) async {
      final external = FocusNode(debugLabel: 'external');
      final inside = FocusNode(debugLabel: 'inside-fallback');
      addTearDown(external.dispose);
      addTearDown(inside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Focus(focusNode: external, child: const Text('external')),
              BLabFocusOwnedOverlay(
                initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                initialFocusNode: external,
                onDismiss: () {},
                child: Focus(focusNode: inside, child: const Text('inside')),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(inside.hasFocus, isTrue);
      expect(external.hasFocus, isFalse);
    });

    testWidgets('unattached explicit focus safely falls back inside scope', (
      tester,
    ) async {
      final unattached = FocusNode(debugLabel: 'unattached');
      final inside = FocusNode(debugLabel: 'inside-unattached-fallback');
      addTearDown(unattached.dispose);
      addTearDown(inside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusOwnedOverlay(
            initialFocusPolicy: BLabInitialFocusPolicy.explicit,
            initialFocusNode: unattached,
            onDismiss: () {},
            child: Focus(focusNode: inside, child: const Text('inside')),
          ),
        ),
      );
      await tester.pump();

      expect(inside.hasFocus, isTrue);
    });

    testWidgets('unrequestable explicit focus falls back to next focusable', (
      tester,
    ) async {
      final unrequestable = FocusNode(
        debugLabel: 'unrequestable',
        canRequestFocus: false,
      );
      final inside = FocusNode(debugLabel: 'inside-requestable-fallback');
      addTearDown(unrequestable.dispose);
      addTearDown(inside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BLabFocusOwnedOverlay(
            initialFocusPolicy: BLabInitialFocusPolicy.explicit,
            initialFocusNode: unrequestable,
            onDismiss: () {},
            child: Column(
              children: [
                Focus(
                  focusNode: unrequestable,
                  child: const Text('unrequestable'),
                ),
                Focus(focusNode: inside, child: const Text('inside')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(inside.hasFocus, isTrue);
      expect(unrequestable.hasFocus, isFalse);
    });

    testWidgets('nested overlays restore focus to their immediate owner', (
      tester,
    ) async {
      final parentNode = FocusNode(debugLabel: 'parent');
      final childNode = FocusNode(debugLabel: 'child');
      addTearDown(parentNode.dispose);
      addTearDown(childNode.dispose);
      var childVisible = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => BLabFocusOwnedOverlay(
              initialFocusPolicy: BLabInitialFocusPolicy.explicit,
              initialFocusNode: parentNode,
              onDismiss: () {},
              child: Column(
                children: [
                  Focus(focusNode: parentNode, child: const Text('parent')),
                  if (childVisible)
                    BLabFocusOwnedOverlay(
                      initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                      initialFocusNode: childNode,
                      onDismiss: () => setState(() => childVisible = false),
                      child: Focus(
                        focusNode: childNode,
                        child: const Text('child'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(childNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(parentNode.hasFocus, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('complete nested removal restores the original tree focus', (
      tester,
    ) async {
      final outside = FocusNode(debugLabel: 'outside-tree');
      final parent = FocusNode(debugLabel: 'parent-tree');
      final child = FocusNode(debugLabel: 'child-tree');
      addTearDown(outside.dispose);
      addTearDown(parent.dispose);
      addTearDown(child.dispose);
      var parentVisible = false;
      var childVisible = false;
      late StateSetter update;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  Focus(focusNode: outside, child: const Text('outside')),
                  if (parentVisible)
                    BLabFocusOwnedOverlay(
                      initialFocusPolicy: BLabInitialFocusPolicy.explicit,
                      initialFocusNode: parent,
                      onDismiss: () {},
                      child: Column(
                        children: [
                          Focus(focusNode: parent, child: const Text('parent')),
                          if (childVisible)
                            BLabFocusOwnedOverlay(
                              initialFocusPolicy:
                                  BLabInitialFocusPolicy.explicit,
                              initialFocusNode: child,
                              onDismiss: () {},
                              child: Focus(
                                focusNode: child,
                                child: const Text('child'),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
      outside.requestFocus();
      await tester.pump();
      update(() => parentVisible = true);
      await tester.pump();
      update(() => childVisible = true);
      await tester.pump();
      expect(child.hasFocus, isTrue);

      update(() {
        childVisible = false;
        parentVisible = false;
      });
      await tester.pump();
      expect(outside.hasFocus, isTrue);
    });
  });
}

const _enabledHaptics = BLabHapticConfiguration(
  platformSupportsHaptics: true,
  systemHapticsEnabled: true,
  accessibilityHapticsEnabled: true,
  componentHapticsEnabled: true,
);

double _contrastRatio(Color first, Color second) {
  final lighter = math.max(first.computeLuminance(), second.computeLuminance());
  final darker = math.min(first.computeLuminance(), second.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize + 7;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}
