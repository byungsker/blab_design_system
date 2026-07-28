import 'dart:ui' show Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabKeyboardAccessoryBar compatibility and action matrix', () {
    testWidgets('preserves legacy constructor defaults and StatefulWidget', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final widget = BLabKeyboardAccessoryBar(onDone: () {}, isDark: false);
      expect(widget, isA<StatefulWidget>());
      expect(widget.icon, isNull);
      expect(widget.showNavigation, isFalse);
      expect(widget.canGoUp, isTrue);
      expect(widget.canGoDown, isTrue);
      expect(widget.canUndo, isFalse);
      expect(widget.canRedo, isFalse);
      expect(widget.canCopy, isFalse);
      expect(widget.canClearAll, isFalse);
      expect(widget.upSemanticLabel, isNull);
      expect(widget.downSemanticLabel, isNull);
      expect(widget.copySemanticLabel, isNull);
      expect(widget.clearAllSemanticLabel, isNull);
      expect(widget.undoSemanticLabel, isNull);
      expect(widget.redoSemanticLabel, isNull);
      expect(widget.doneSemanticLabel, isNull);

      await tester.pumpWidget(_harness(widget));
      expect(_action('done'), findsOneWidget);
      expect(tester.getSemantics(_semantics('done')).label.trim(), isNotEmpty);
      semantics.dispose();
    });

    testWidgets('renders and enables the exact conditional action table', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          BLabKeyboardAccessoryBar(
            isDark: false,
            showNavigation: true,
            onUp: null,
            onDown: () {},
            onCopy: () {},
            onClearAll: null,
            onUndo: () {},
            onRedo: null,
            onDone: () {},
            canGoDown: false,
            canCopy: true,
            canUndo: true,
          ),
        ),
      );

      expect(_action('up'), findsOneWidget);
      expect(_action('down'), findsOneWidget);
      expect(_action('copy'), findsOneWidget);
      expect(_action('clearAll'), findsNothing);
      expect(_action('undo'), findsOneWidget);
      expect(_action('redo'), findsNothing);
      expect(_action('done'), findsOneWidget);
      expect(
        tester.getSemantics(_semantics('up')).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(
        tester.getSemantics(_semantics('down')).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(
        tester.getSemantics(_semantics('copy')).flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_semantics('undo')).flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(_semantics('done')).flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      semantics.dispose();
    });

    testWidgets('uses one supplied name per native button', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_harness(_completeBar()));

      const labels = <String, String>{
        'up': 'Previous field',
        'down': 'Next field',
        'copy': 'Copy selection',
        'clearAll': 'Clear all text',
        'undo': 'Undo edit',
        'redo': 'Redo edit',
        'done': 'Dismiss keyboard',
      };
      for (final entry in labels.entries) {
        final node = tester.getSemantics(_semantics(entry.key));
        expect(node.label, entry.value);
        expect(node.flagsCollection.isButton, isTrue);
        expect(find.semantics.byLabel(entry.value), findsOneWidget);
      }
      expect(
        tester
            .getSemantics(_semantics('undo'))
            .getSemanticsData()
            .hasAction(SemanticsAction.longPress),
        isFalse,
      );
      semantics.dispose();
    });

    testWidgets('rejects every supplied blank label', (tester) async {
      await tester.pumpWidget(
        _harness(
          BLabKeyboardAccessoryBar(
            key: const ValueKey<String>('blank-label'),
            isDark: false,
            onDone: () {},
            undoSemanticLabel: ' \n ',
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('uses 48x48 natural targets with a 44x44 minimum', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_completeBar()));
      for (final id in _ids) {
        expect(tester.getSize(_target(id)), const Size(48, 48));
        final minimum = tester.widget<ConstrainedBox>(_minimumTarget(id));
        expect(minimum.constraints.minWidth, 44);
        expect(minimum.constraints.minHeight, 44);
      }
    });
  });

  group('BLabKeyboardAccessoryBar input, focus, and semantics', () {
    testWidgets('Tab stops are individual and exit without a trap', (
      tester,
    ) async {
      final after = FocusNode(debugLabel: 'After keyboard accessory');
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _harness(
          Column(
            children: [
              _completeBar(
                showNavigation: false,
                includeClearAll: false,
                includeRedo: false,
              ),
              Focus(
                focusNode: after,
                child: const SizedBox(width: 1, height: 1),
              ),
            ],
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'KeyboardAccessory copy',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'KeyboardAccessory undo',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'KeyboardAccessory done',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, after);
    });

    testWidgets('Enter, Space, pointer, and semantics activate exactly once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          BLabKeyboardAccessoryBar(
            isDark: false,
            onDone: () => calls += 1,
            doneSemanticLabel: 'Dismiss keyboard',
          ),
        ),
      );

      await tester.tap(_target('done'));
      expect(calls, 1);
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
      tester.semantics.tap(find.semantics.byLabel('Dismiss keyboard'));
      await tester.pump();
      expect(calls, 4);
      semantics.dispose();
    });

    testWidgets(
      'pointer focus has no ring; keyboard focus is exact 2px + 3px',
      (tester) async {
        await tester.pumpWidget(_harness(_completeBar()));

        await tester.tap(_target('copy'));
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'KeyboardAccessory copy',
        );
        expect(_focusOutline('copy'), findsNothing);
        expect(_focusRing('copy'), findsNothing);

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final outline = _decoration(tester, 'up.focusOutline');
        final ring = _decoration(tester, 'up.focusRing');
        expect(outline.border!.top.width, 2);
        expect(ring.border!.top.width, 3);
      },
    );

    testWidgets('hover and pressed use exact interaction tokens', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_completeBar()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(_target('copy')));
      await tester.pump();
      expect(
        tester.widget<AnimatedContainer>(_interaction('copy')).decoration,
        isA<BoxDecoration>().having(
          (decoration) => decoration.color,
          'color',
          BLabTokenTheme.light.keyboardAccessoryHoverOverlay,
        ),
      );
      await mouse.down(tester.getCenter(_target('copy')));
      await tester.pump();
      expect(
        tester.widget<AnimatedContainer>(_interaction('copy')).decoration,
        isA<BoxDecoration>().having(
          (decoration) => decoration.color,
          'color',
          BLabTokenTheme.light.keyboardAccessoryPressedOverlay,
        ),
      );
      await mouse.up();
    });

    testWidgets(
      'semantic activation of Undo is single-shot and never repeats',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var calls = 0;
        await tester.pumpWidget(
          _harness(
            _completeBar(
              onUndo: () => calls += 1,
              showNavigation: false,
              includeCopy: false,
              includeClearAll: false,
              includeRedo: false,
            ),
          ),
        );
        tester.semantics.tap(find.semantics.byLabel('Undo edit'));
        await tester.pump(const Duration(seconds: 2));
        expect(calls, 1);
        semantics.dispose();
      },
    );

    testWidgets('does not synthesize selected or invalid semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_harness(_completeBar()));
      final node = tester.getSemantics(_semantics('done'));
      expect(node.flagsCollection.isSelected, Tristate.none);
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.none,
      );
      semantics.dispose();
    });
  });

  group('BLabKeyboardAccessoryBar repeat lifecycle', () {
    testWidgets(
      'recognized long press calls once, waits 500ms, then repeats every 100ms',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _harness(
            _completeBar(
              onUndo: () => taps += 1,
              showNavigation: false,
              includeCopy: false,
              includeClearAll: false,
              includeRedo: false,
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(_target('undo')),
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(kLongPressTimeout - const Duration(milliseconds: 1));
        expect(taps, 0);
        await tester.pump(const Duration(milliseconds: 1));
        expect(taps, 1, reason: 'initial callback at recognition');
        await tester.pump(const Duration(milliseconds: 499));
        expect(taps, 1);
        await tester.pump(const Duration(milliseconds: 1));
        expect(taps, 2, reason: 'first repeat 500ms after recognition');
        await tester.pump(const Duration(milliseconds: 100));
        expect(taps, 3);
        await gesture.up();
        await tester.pump(const Duration(seconds: 1));
        expect(taps, 3, reason: 'pointer up cancels without a tap');
      },
    );

    testWidgets('pointer cancel stops repeat', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          _completeBar(
            onUndo: () => calls += 1,
            showNavigation: false,
            includeCopy: false,
            includeClearAll: false,
            includeRedo: false,
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_target('undo')),
      );
      await tester.pump(kLongPressTimeout);
      expect(calls, 1);
      await gesture.cancel();
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
    });

    testWidgets('callback and enabled changes cancel active repeat', (
      tester,
    ) async {
      late StateSetter update;
      var firstCalls = 0;
      var secondCalls = 0;
      var callback = () => firstCalls += 1;
      var enabled = true;
      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return _completeBar(
                showNavigation: false,
                includeCopy: false,
                includeClearAll: false,
                includeRedo: false,
                canUndo: enabled,
                onUndo: callback,
              );
            },
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_target('undo')),
      );
      await tester.pump(kLongPressTimeout);
      expect(firstCalls, 1);
      update(() => callback = () => secondCalls += 1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect((firstCalls, secondCalls), (1, 0));
      await gesture.up();

      final secondGesture = await tester.startGesture(
        tester.getCenter(_target('undo')),
      );
      await tester.pump(kLongPressTimeout);
      expect(secondCalls, 1);
      update(() => enabled = false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(secondCalls, 1);
      await secondGesture.up();
    });

    testWidgets(
      'lifecycle, disposal, and another repeat cancel the prior one',
      (tester) async {
        var undoCalls = 0;
        var redoCalls = 0;
        await tester.pumpWidget(
          _harness(
            _completeBar(
              showNavigation: false,
              includeCopy: false,
              includeClearAll: false,
              onUndo: () => undoCalls += 1,
              onRedo: () => redoCalls += 1,
            ),
          ),
        );
        final undoGesture = await tester.startGesture(
          tester.getCenter(_target('undo')),
          pointer: 1,
        );
        await tester.pump(kLongPressTimeout);
        expect(undoCalls, 1);
        final redoGesture = await tester.startGesture(
          tester.getCenter(_target('redo')),
          pointer: 2,
        );
        await tester.pump(kLongPressTimeout);
        expect(redoCalls, 1);
        await tester.pump(const Duration(milliseconds: 500));
        expect(undoCalls, 1);
        expect(redoCalls, 2);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 1));
        expect(redoCalls, 2);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await undoGesture.cancel();
        await redoGesture.cancel();

        await tester.pumpWidget(_harness(const SizedBox()));
        await tester.pump(const Duration(seconds: 1));
        expect((undoCalls, redoCalls), (1, 2));
      },
    );

    testWidgets('callback exception cancels repeat before rethrow', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          _completeBar(
            showNavigation: false,
            includeCopy: false,
            includeClearAll: false,
            includeRedo: false,
            onUndo: () {
              calls += 1;
              throw StateError('repeat failed');
            },
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_target('undo')),
      );
      await tester.pump(kLongPressTimeout);
      expect(tester.takeException(), isStateError);
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
      await gesture.up();
    });
  });

  group('BLabKeyboardAccessoryBar narrow-width overflow addendum', () {
    testWidgets(
      '320 and 360 complete matrices use exact owned viewport geometry',
      (tester) async {
        for (final width in const <double>[320, 360]) {
          await tester.pumpWidget(
            _harness(
              _fixedWidth(width, _completeBar(key: ValueKey<double>(width))),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(_overflow, findsOneWidget);
          final scroll = tester.widget<SingleChildScrollView>(_overflow);
          expect(scroll.primary, isFalse);
          expect(scroll.physics, isA<ClampingScrollPhysics>());
          expect(scroll.controller, isNotNull);
          expect(
            scroll.controller,
            isNot(
              same(PrimaryScrollController.maybeOf(tester.element(_overflow))),
            ),
          );
          expect(tester.getSize(_overflow).width, width == 320 ? 239 : 279);
          expect(_pinnedDoneDivider, findsOneWidget);
          expect(tester.getSize(_pinnedDoneDivider).width, 1);
          for (final id in _ids) {
            expect(tester.getSize(_target(id)), const Size(48, 48));
            final minimum = tester.widget<ConstrainedBox>(_minimumTarget(id));
            expect(minimum.constraints.minWidth, 44);
            expect(minimum.constraints.minHeight, 44);
          }
        }
      },
    );

    testWidgets('uses the exact 372 scrolling and 373 fixed boundary', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_fixedWidth(372, _completeBar())));
      await tester.pump();
      expect(_overflow, findsOneWidget);
      expect(_overflowController(tester).position.maxScrollExtent, 1);

      await tester.pumpWidget(_harness(_fixedWidth(373, _completeBar())));
      expect(_overflow, findsNothing);
      expect(_pinnedDoneDivider, findsNothing);
      expect(find.byType(Spacer), findsOneWidget);

      await tester.pumpWidget(
        _harness(
          Row(mainAxisSize: MainAxisSize.min, children: [_completeBar()]),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_overflow, findsNothing);
      expect(find.byType(Spacer), findsOneWidget);
      expect(tester.getSize(find.byType(BLabKeyboardAccessoryBar)).width, 373);
    });

    testWidgets(
      'enforces 79/80 Done-only, 127/128 leading, and 128/129 history boundaries',
      (tester) async {
        Widget doneOnly(Key key) => _completeBar(
          key: key,
          showNavigation: false,
          includeCopy: false,
          includeClearAll: false,
          includeUndo: false,
          includeRedo: false,
        );
        Widget leadingOnly(Key key) => _completeBar(
          key: key,
          showNavigation: false,
          includeUndo: false,
          includeRedo: false,
        );
        Widget historyOnly(Key key) => _completeBar(
          key: key,
          showNavigation: false,
          includeCopy: false,
          includeClearAll: false,
        );

        await tester.pumpWidget(
          _harness(
            _fixedWidth(80, doneOnly(const ValueKey<String>('done-valid'))),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_overflow, findsNothing);
        expect(tester.getSize(_target('done')), const Size(48, 48));

        await tester.pumpWidget(
          _harness(
            _fixedWidth(79, doneOnly(const ValueKey<String>('done-invalid'))),
          ),
        );
        _expectInvalidHostDiagnostic(tester, minimum: 80, actual: 79);

        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              128,
              leadingOnly(const ValueKey<String>('leading-valid')),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_overflow, findsOneWidget);
        expect(tester.getSize(_overflow).width, 48);
        expect(tester.getSize(_target('copy')), const Size(48, 48));
        expect(tester.getSize(_target('done')), const Size(48, 48));

        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              127,
              leadingOnly(const ValueKey<String>('leading-invalid')),
            ),
          ),
        );
        _expectInvalidHostDiagnostic(tester, minimum: 128, actual: 127);

        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              129,
              historyOnly(const ValueKey<String>('history-valid')),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_overflow, findsOneWidget);
        expect(tester.getSize(_overflow).width, 48);
        expect(tester.getSize(_pinnedDoneDivider).width, 1);
        expect(tester.getSize(_target('undo')), const Size(48, 48));
        expect(tester.getSize(_target('done')), const Size(48, 48));

        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              128,
              historyOnly(const ValueKey<String>('history-invalid')),
            ),
          ),
        );
        _expectInvalidHostDiagnostic(tester, minimum: 129, actual: 128);
      },
    );

    testWidgets(
      'a valid 48px viewport supports pointer, focus reveal, and semantics activation',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var copyCalls = 0;
        var clearCalls = 0;
        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              128,
              _completeBar(
                showNavigation: false,
                includeUndo: false,
                includeRedo: false,
                onCopy: () => copyCalls += 1,
                onClearAll: () => clearCalls += 1,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.getSize(_overflow).width, 48);
        _expectTargetFullyVisible(tester, 'copy');
        await tester.tap(_target('copy'));
        expect(copyCalls, 1);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'KeyboardAccessory clearAll',
        );
        _expectTargetFullyVisible(tester, 'clearAll');
        expect(_focusRing('clearAll'), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel('Clear all text'));
        await tester.pump();
        expect(clearCalls, 1);
        semantics.dispose();
      },
    );

    testWidgets('calculates the breakpoint from rendered action composition', (
      tester,
    ) async {
      Widget twoLeadingActions() => _completeBar(
        showNavigation: false,
        includeRedo: false,
        includeUndo: false,
      );

      await tester.pumpWidget(_harness(_fixedWidth(176, twoLeadingActions())));
      expect(_overflow, findsOneWidget);
      await tester.pumpWidget(_harness(_fixedWidth(177, twoLeadingActions())));
      expect(_overflow, findsNothing);

      Widget historyOnly() => _completeBar(
        showNavigation: false,
        includeCopy: false,
        includeClearAll: false,
      );
      await tester.pumpWidget(_harness(_fixedWidth(177, historyOnly())));
      expect(_overflow, findsOneWidget);
      await tester.pumpWidget(_harness(_fixedWidth(178, historyOnly())));
      expect(_overflow, findsNothing);
    });

    testWidgets('pins Done at logical trailing in LTR and RTL', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              320,
              _completeBar(key: ValueKey<TextDirection>(direction)),
            ),
            textDirection: direction,
          ),
        );
        await tester.pump();
        final surface = tester.getRect(
          find.byKey(
            const ValueKey<String>('BLabKeyboardAccessoryBar.surface'),
          ),
        );
        final doneBefore = tester.getRect(_target('done'));
        final viewport = tester.getRect(_overflow);
        final first = tester.getRect(_target('up'));
        if (direction == TextDirection.ltr) {
          expect(doneBefore.right, closeTo(surface.right, 0.01));
          expect(first.left, closeTo(viewport.left, 0.01));
        } else {
          expect(doneBefore.left, closeTo(surface.left, 0.01));
          expect(first.right, closeTo(viewport.right, 0.01));
        }
        _overflowController(
          tester,
        ).jumpTo(_overflowController(tester).position.maxScrollExtent);
        await tester.pump();
        expect(tester.getRect(_target('done')), doneBefore);
      }
    });

    testWidgets(
      'Tab order stays logical, skips disabled actions, reveals, and exits',
      (tester) async {
        final after = FocusNode(debugLabel: 'After narrow keyboard accessory');
        addTearDown(after.dispose);
        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              320,
              Column(
                children: [
                  BLabKeyboardAccessoryBar(
                    isDark: false,
                    showNavigation: true,
                    onUp: () {},
                    onDown: () {},
                    onCopy: () {},
                    onClearAll: () {},
                    onUndo: () {},
                    onRedo: () {},
                    onDone: () {},
                    canGoUp: true,
                    canGoDown: false,
                    canCopy: true,
                    canClearAll: true,
                    canUndo: false,
                    canRedo: true,
                    upSemanticLabel: 'Previous field',
                    downSemanticLabel: 'Next field',
                    copySemanticLabel: 'Copy selection',
                    clearAllSemanticLabel: 'Clear all text',
                    undoSemanticLabel: 'Undo edit',
                    redoSemanticLabel: 'Redo edit',
                    doneSemanticLabel: 'Dismiss keyboard',
                  ),
                  Focus(
                    focusNode: after,
                    child: const SizedBox(width: 1, height: 1),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        for (final label in const <String>[
          'KeyboardAccessory up',
          'KeyboardAccessory copy',
          'KeyboardAccessory clearAll',
          'KeyboardAccessory redo',
          'KeyboardAccessory done',
        ]) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.pump(BLabMotion.durPress);
          expect(FocusManager.instance.primaryFocus?.debugLabel, label);
          final id = label.split(' ').last;
          if (id != 'done') {
            _expectTargetFullyVisible(tester, id);
            expect(_focusRing(id), findsOneWidget);
          }
        }
        final offsetBeforeExit = _overflowController(tester).offset;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(FocusManager.instance.primaryFocus, after);
        expect(_overflowController(tester).offset, offsetBeforeExit);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'KeyboardAccessory done',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(FocusManager.instance.primaryFocus, after);
      },
    );

    testWidgets(
      'programmatic focus reveals without keyboard ring and accessibility focus is immediate',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_harness(_fixedWidth(320, _completeBar())));
        await tester.pump();

        _focusNode(tester, 'redo').requestFocus();
        await tester.pump();
        await tester.pump();
        expect(
          _overflowController(tester).position.isScrollingNotifier.value,
          isTrue,
        );
        await tester.pump(BLabMotion.durPress);
        _expectTargetFullyVisible(tester, 'redo');
        expect(_focusRing('redo'), findsNothing);
        expect(_focusOutline('redo'), findsNothing);

        FocusManager.instance.primaryFocus?.unfocus();
        _overflowController(
          tester,
        ).jumpTo(_overflowController(tester).position.minScrollExtent);
        await tester.pump();
        tester.semantics.didGainAccessibilityFocus(
          find.semantics.byLabel('Redo edit'),
        );
        await tester.pump();
        _expectTargetFullyVisible(tester, 'redo');
        expect(
          _overflowController(tester).position.isScrollingNotifier.value,
          isFalse,
        );
        expect(
          FocusManager.instance.primaryFocus,
          isNot(_focusNode(tester, 'redo')),
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'normal reveal is 150ms, latest target wins, visible target does not restart',
      (tester) async {
        await tester.pumpWidget(_harness(_fixedWidth(320, _completeBar())));
        await tester.pump();
        final controller = _overflowController(tester);

        _focusNode(tester, 'redo').requestFocus();
        await tester.pump();
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, isTrue);
        await tester.pump(const Duration(milliseconds: 75));
        expect(
          controller.offset,
          inExclusiveRange(0, controller.position.maxScrollExtent),
        );

        _focusNode(tester, 'up').requestFocus();
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        _expectTargetFullyVisible(tester, 'up');
        expect(controller.offset, controller.position.minScrollExtent);
        await tester.pumpAndSettle();
        expect(controller.position.isScrollingNotifier.value, isFalse);

        _focusNode(tester, 'down').requestFocus();
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, isFalse);
        _expectTargetFullyVisible(tester, 'down');
      },
    );

    testWidgets('reduced motion reveal is immediate', (tester) async {
      await tester.pumpWidget(
        _harness(_fixedWidth(320, _completeBar()), disableAnimations: true),
      );
      await tester.pump();
      _focusNode(tester, 'redo').requestFocus();
      await tester.pump();
      _expectTargetFullyVisible(tester, 'redo');
      expect(
        _overflowController(tester).position.isScrollingNotifier.value,
        isFalse,
      );
    });

    testWidgets(
      'native physical scroll semantics exist only for real overflow',
      (tester) async {
        final semantics = tester.ensureSemantics();
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            _harness(
              _fixedWidth(
                320,
                _completeBar(key: ValueKey<TextDirection>(direction)),
              ),
              textDirection: direction,
            ),
          );
          await tester.pump();
          await tester.pump();
          var node = tester.getSemantics(_overflow);
          while (node.parent != null) {
            node = node.parent!;
          }
          expect(
            _semanticsTreeHasAction(
              node,
              direction == TextDirection.ltr
                  ? SemanticsAction.scrollLeft
                  : SemanticsAction.scrollRight,
            ),
            isTrue,
            reason: '${direction.name}: ${_semanticsTreeActions(node)}',
          );
          final forwardAction = direction == TextDirection.ltr
              ? SemanticsAction.scrollLeft
              : SemanticsAction.scrollRight;
          tester.semantics.performAction(
            find.semantics.scrollable(),
            forwardAction,
          );
          await tester.pumpAndSettle();
          expect(
            _overflowController(tester).offset,
            _overflowController(tester).position.maxScrollExtent,
          );
          node = tester.getSemantics(_overflow);
          while (node.parent != null) {
            node = node.parent!;
          }
          expect(
            _semanticsTreeHasAction(
              node,
              direction == TextDirection.ltr
                  ? SemanticsAction.scrollRight
                  : SemanticsAction.scrollLeft,
            ),
            isTrue,
            reason: '${direction.name} max: ${_semanticsTreeActions(node)}',
          );
          for (final label in const <String>[
            'Previous field',
            'Next field',
            'Copy selection',
            'Clear all text',
            'Undo edit',
            'Redo edit',
            'Dismiss keyboard',
          ]) {
            expect(find.semantics.byLabel(label), findsOneWidget);
          }
        }

        await tester.pumpWidget(_harness(_fixedWidth(373, _completeBar())));
        expect(_overflow, findsNothing);
        semantics.dispose();
      },
    );

    testWidgets('offscreen semantic activation remains single-shot', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        _harness(_fixedWidth(320, _completeBar(onRedo: () => calls += 1))),
      );
      await tester.pump();
      expect(
        tester.getRect(_target('redo')).left,
        greaterThan(tester.getRect(_overflow).right),
      );
      tester.semantics.tap(find.semantics.byLabel('Redo edit'));
      await tester.pump(const Duration(seconds: 1));
      expect(calls, 1);
      semantics.dispose();
    });

    testWidgets('horizontal drag is neutral and cancels long press repeat', (
      tester,
    ) async {
      var undoCalls = 0;
      await tester.pumpWidget(
        _harness(_fixedWidth(320, _completeBar(onUndo: () => undoCalls += 1))),
      );
      await tester.pump();

      final controller = _overflowController(tester);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      final offsetBeforeDrag = controller.offset;
      await tester.drag(_target('undo'), const Offset(80, 0));
      await tester.pump(kLongPressTimeout);
      expect(undoCalls, 0);
      expect(controller.offset, lessThan(offsetBeforeDrag));

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      final repeating = await tester.startGesture(
        tester.getCenter(_target('undo')),
        pointer: 2,
      );
      await tester.pump(kLongPressTimeout);
      expect(undoCalls, 1);
      final scrolling = await tester.startGesture(
        tester.getCenter(_target('clearAll')),
        pointer: 3,
      );
      await scrolling.moveBy(const Offset(20, 0));
      await tester.pump();
      await scrolling.moveBy(const Offset(60, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(undoCalls, 1);
      expect(
        (tester.widget<AnimatedContainer>(_interaction('clearAll')).decoration!
                as BoxDecoration)
            .color,
        Colors.transparent,
      );
      await repeating.cancel();
      await scrolling.up();
    });

    testWidgets('vertical drag remains available to an ancestor scrollable', (
      tester,
    ) async {
      var calls = 0;
      final ancestor = ScrollController();
      addTearDown(ancestor.dispose);
      await tester.pumpWidget(
        _harness(
          _fixedWidth(
            320,
            SizedBox(
              height: 64,
              child: SingleChildScrollView(
                controller: ancestor,
                child: Column(
                  children: [
                    _completeBar(onUp: () => calls += 1),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final horizontal = _overflowController(tester);
      await tester.drag(_target('up'), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(ancestor.offset, greaterThan(0));
      expect(horizontal.offset, horizontal.position.minScrollExtent);
      expect(calls, 0);
    });

    testWidgets(
      'entry exit re-entry width composition and direction changes synchronize',
      (tester) async {
        late StateSetter update;
        var width = 320.0;
        var includeCopy = true;
        var direction = TextDirection.ltr;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Directionality(
                  textDirection: direction,
                  child: _fixedWidth(
                    width,
                    _completeBar(
                      includeCopy: includeCopy,
                      key: const ValueKey<String>('adaptive'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        var controller = _overflowController(tester);
        controller.jumpTo(controller.position.maxScrollExtent);

        update(() => width = 360);
        await tester.pump();
        await tester.pump();
        controller = _overflowController(tester);
        expect(controller.offset, controller.position.maxScrollExtent);

        update(() {
          width = 320;
          includeCopy = false;
        });
        await tester.pump();
        await tester.pump();
        expect(_overflow, findsOneWidget);
        controller = _overflowController(tester);
        expect(controller.offset, controller.position.maxScrollExtent);

        update(() => width = 373);
        await tester.pump();
        expect(_overflow, findsNothing);
        update(() {
          width = 320;
          includeCopy = true;
        });
        await tester.pump();
        await tester.pump();
        controller = _overflowController(tester);
        expect(controller.offset, controller.position.minScrollExtent);

        controller.jumpTo(controller.position.maxScrollExtent);
        update(() => direction = TextDirection.rtl);
        await tester.pump();
        await tester.pump();
        controller = _overflowController(tester);
        expect(controller.offset, controller.position.minScrollExtent);
      },
    );

    testWidgets(
      'direction change preserves focused action and reveals it immediately',
      (tester) async {
        late StateSetter update;
        var direction = TextDirection.ltr;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Directionality(
                  textDirection: direction,
                  child: _fixedWidth(320, _completeBar()),
                );
              },
            ),
          ),
        );
        await tester.pump();
        _focusNode(tester, 'redo').requestFocus();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        update(() => direction = TextDirection.rtl);
        await tester.pump();
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'KeyboardAccessory redo',
        );
        _expectTargetFullyVisible(tester, 'redo');
        expect(
          _overflowController(tester).position.isScrollingNotifier.value,
          isFalse,
        );
        expect(_icon(tester, 'undo'), CupertinoIcons.arrow_uturn_right);
        expect(_icon(tester, 'redo'), CupertinoIcons.arrow_uturn_left);
      },
    );

    for (final mode in _modes) {
      testWidgets('${mode.label} overflow adds no edge treatment', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(
            _fixedWidth(320, _completeBar(isDark: mode.isDark)),
            brightness: mode.isDark ? Brightness.dark : Brightness.light,
            highContrast: mode.highContrast,
          ),
        );
        await tester.pump();
        expect(_overflow, findsOneWidget);
        expect(find.byType(ShaderMask), findsNothing);
        final decoration = _decoration(tester, 'surface');
        if (mode.highContrast) {
          expect(decoration.gradient, isNull);
          expect(decoration.color!.a, 1);
        } else {
          expect(decoration.gradient, isA<LinearGradient>());
          expect(
            find
                .descendant(
                  of: find.byType(BLabKeyboardAccessoryBar),
                  matching: find.byType(DecoratedBox),
                )
                .evaluate()
                .where(
                  (element) =>
                      (element.widget as DecoratedBox).decoration
                          is BoxDecoration &&
                      ((element.widget as DecoratedBox).decoration
                                  as BoxDecoration)
                              .gradient !=
                          null,
                )
                .length,
            1,
          );
        }
      });
    }
  });

  group('BLabKeyboardAccessoryBar modes, direction, and ownership', () {
    for (final mode in _modes) {
      testWidgets('${mode.label} resolves exact component surface tokens', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(
            _completeBar(isDark: mode.isDark),
            brightness: mode.isDark ? Brightness.dark : Brightness.light,
            highContrast: mode.highContrast,
          ),
        );
        final decoration = _decoration(tester, 'surface');
        expect(
          decoration.border!.top.color,
          mode.tokens.keyboardAccessoryBorder,
        );
        if (mode.highContrast) {
          expect(decoration.color, mode.tokens.keyboardAccessorySurfaceStart);
          expect(decoration.color!.a, 1);
          expect(decoration.gradient, isNull);
          expect(decoration.boxShadow, isEmpty);
          expect(
            find.descendant(
              of: find.byType(BLabKeyboardAccessoryBar),
              matching: find.byType(BackdropFilter),
            ),
            findsNothing,
          );
        } else {
          final gradient = decoration.gradient! as LinearGradient;
          expect(gradient.colors, [
            mode.tokens.keyboardAccessorySurfaceStart,
            mode.tokens.keyboardAccessorySurfaceEnd,
          ]);
          expect(
            decoration.boxShadow!.single.color,
            mode.tokens.keyboardAccessoryShadow,
          );
          final filter = tester.widget<BackdropFilter>(
            find.byKey(const ValueKey<String>('BLabKeyboardAccessoryBar.blur')),
          );
          expect(filter.filter, isNotNull);
        }
      });
    }

    testWidgets('RTL mirrors groups and swaps Undo/Redo logical glyphs', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_completeBar()));
      final ltrUp = tester.getCenter(_target('up')).dx;
      final ltrDone = tester.getCenter(_target('done')).dx;
      final ltrUndo = _icon(tester, 'undo');
      final ltrRedo = _icon(tester, 'redo');
      expect(ltrUp, lessThan(ltrDone));
      expect(ltrUndo, CupertinoIcons.arrow_uturn_left);
      expect(ltrRedo, CupertinoIcons.arrow_uturn_right);

      await tester.pumpWidget(
        _harness(_completeBar(), textDirection: TextDirection.rtl),
      );
      expect(
        tester.getCenter(_target('up')).dx,
        greaterThan(tester.getCenter(_target('done')).dx),
      );
      expect(_icon(tester, 'undo'), CupertinoIcons.arrow_uturn_right);
      expect(_icon(tester, 'redo'), CupertinoIcons.arrow_uturn_left);
    });

    testWidgets(
      'reduced motion is immediate and ambient scaling is untouched',
      (tester) async {
        const scaler = _NonlinearScaler();
        await tester.pumpWidget(
          _harness(_completeBar(), disableAnimations: true, textScaler: scaler),
        );
        expect(
          tester.widget<AnimatedContainer>(_interaction('done')).duration,
          Duration.zero,
        );
        expect(
          MediaQuery.textScalerOf(tester.element(_target('done'))),
          same(scaler),
        );
      },
    );

    testWidgets('emits no haptics and owns no overlay, safe area, or insets', (
      tester,
    ) async {
      final platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              platformCalls.add(call);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        _harness(
          _completeBar(),
          viewInsets: const EdgeInsets.only(bottom: 320),
        ),
      );
      await tester.tap(_target('done'));
      final gesture = await tester.startGesture(
        tester.getCenter(_target('undo')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 600));
      await gesture.up();
      expect(platformCalls, isEmpty);
      expect(
        find.descendant(
          of: find.byType(BLabKeyboardAccessoryBar),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(BLabKeyboardAccessoryBar),
          matching: find.byType(Overlay),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('BLabKeyboardAccessoryBar.hostPlacement'),
        ),
        findsOneWidget,
      );
    });
  });
}

const _ids = <String>['up', 'down', 'copy', 'clearAll', 'undo', 'redo', 'done'];

final _overflow = find.byKey(
  const ValueKey<String>('BLabKeyboardAccessoryBar.horizontalOverflow'),
);
final _pinnedDoneDivider = find.byKey(
  const ValueKey<String>('BLabKeyboardAccessoryBar.pinnedDoneDivider'),
);

Finder _action(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id'));
Finder _target(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.target'));
Finder _minimumTarget(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.minimumTarget'));
Finder _semantics(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.semantics'));
Finder _interaction(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.interaction'));
Finder _focusOutline(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.focusOutline'));
Finder _focusRing(String id) =>
    find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id.focusRing'));

BoxDecoration _decoration(WidgetTester tester, String id) {
  if (id == 'surface') {
    return tester
            .widget<DecoratedBox>(
              find.byKey(
                const ValueKey<String>('BLabKeyboardAccessoryBar.surface'),
              ),
            )
            .decoration
        as BoxDecoration;
  }
  return tester
          .widget<DecoratedBox>(
            find.byKey(ValueKey<String>('BLabKeyboardAccessoryBar.$id')),
          )
          .decoration
      as BoxDecoration;
}

IconData? _icon(WidgetTester tester, String id) {
  return tester
      .widgetList<Icon>(
        find.descendant(of: _target(id), matching: find.byType(Icon)),
      )
      .single
      .icon;
}

ScrollController _overflowController(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(_overflow).controller!;

FocusNode _focusNode(WidgetTester tester, String id) => tester
    .widget<Focus>(
      find.descendant(of: _action(id), matching: find.byType(Focus)),
    )
    .focusNode!;

void _expectTargetFullyVisible(WidgetTester tester, String id) {
  final viewport = tester.getRect(_overflow);
  final target = tester.getRect(_target(id));
  expect(target.left, greaterThanOrEqualTo(viewport.left - 0.01));
  expect(target.right, lessThanOrEqualTo(viewport.right + 0.01));
}

void _expectInvalidHostDiagnostic(
  WidgetTester tester, {
  required int minimum,
  required int actual,
}) {
  final diagnostic = tester.takeException();
  expect(diagnostic, isA<FlutterError>());
  expect(
    diagnostic.toString(),
    allOf(
      contains('below the valid minimum'),
      contains('at least $minimum.0px'),
      contains('finite maxWidth of $actual.0px'),
    ),
  );
}

bool _semanticsTreeHasAction(SemanticsNode node, SemanticsAction action) {
  if (node.getSemanticsData().hasAction(action)) return true;
  return node
      .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
      .any((child) => _semanticsTreeHasAction(child, action));
}

Set<SemanticsAction> _semanticsTreeActions(SemanticsNode node) {
  final actions = <SemanticsAction>{
    for (final action in SemanticsAction.values)
      if (node.getSemanticsData().hasAction(action)) action,
  };
  for (final child in node.debugListChildrenInOrder(
    DebugSemanticsDumpOrder.traversalOrder,
  )) {
    actions.addAll(_semanticsTreeActions(child));
  }
  return actions;
}

BLabKeyboardAccessoryBar _completeBar({
  Key? key,
  bool isDark = false,
  bool showNavigation = true,
  VoidCallback? onUp,
  VoidCallback? onDown,
  VoidCallback? onCopy,
  VoidCallback? onClearAll,
  VoidCallback? onUndo,
  VoidCallback? onRedo,
  VoidCallback? onDone,
  bool canUndo = true,
  bool includeCopy = true,
  bool includeClearAll = true,
  bool includeUndo = true,
  bool includeRedo = true,
}) {
  return BLabKeyboardAccessoryBar(
    key: key,
    isDark: isDark,
    showNavigation: showNavigation,
    onUp: onUp ?? () {},
    onDown: onDown ?? () {},
    onCopy: includeCopy ? onCopy ?? () {} : null,
    onClearAll: includeClearAll ? onClearAll ?? () {} : null,
    onUndo: includeUndo ? onUndo ?? () {} : null,
    onRedo: includeRedo ? onRedo ?? () {} : null,
    onDone: onDone ?? () {},
    canCopy: true,
    canClearAll: true,
    canUndo: canUndo,
    canRedo: true,
    upSemanticLabel: 'Previous field',
    downSemanticLabel: 'Next field',
    copySemanticLabel: 'Copy selection',
    clearAllSemanticLabel: 'Clear all text',
    undoSemanticLabel: 'Undo edit',
    redoSemanticLabel: 'Redo edit',
    doneSemanticLabel: 'Dismiss keyboard',
  );
}

Widget _fixedWidth(double width, Widget child) => Align(
  alignment: Alignment.center,
  child: SizedBox(width: width, child: child),
);

Widget _harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        highContrast: highContrast,
        disableAnimations: disableAnimations,
        textScaler: textScaler,
        viewInsets: viewInsets,
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Center(child: SizedBox(width: 700, child: child)),
        ),
      ),
    ),
  );
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  double get textScaleFactor => 1;
}

class _Mode {
  const _Mode(this.label, this.isDark, this.highContrast, this.tokens);

  final String label;
  final bool isDark;
  final bool highContrast;
  final BLabTokenTheme tokens;
}

const _modes = <_Mode>[
  _Mode('light', false, false, BLabTokenTheme.light),
  _Mode('dark', true, false, BLabTokenTheme.dark),
  _Mode('high-contrast-light', false, true, BLabTokenTheme.highContrastLight),
  _Mode('high-contrast-dark', true, true, BLabTokenTheme.highContrastDark),
];
