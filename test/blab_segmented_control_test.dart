import 'dart:ui' show Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabSegmentedControl compatibility and visuals', () {
    testWidgets('keeps existing API defaults and 44x44 item targets', (
      tester,
    ) async {
      const firstItem = BLabSegmentedItem(value: _Choice.first, label: 'First');
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              firstItem,
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );

      final control = tester.widget<BLabSegmentedControl<_Choice>>(
        find.byType(BLabSegmentedControl<_Choice>),
      );
      expect(control.enabled, isTrue);
      expect(control.height, 40);
      expect(control.padding, 3);
      expect(control.borderRadius, BLabRadius.sm);
      expect(firstItem.enabled, isTrue);
      expect(control, isA<StatelessWidget>());
      for (var index = 0; index < 2; index += 1) {
        final target = find.byKey(
          ValueKey<String>('BLabSegmentedControl.item.$index.target'),
        );
        expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets(
      'uses explicit horizontal overflow and preserves 44x44 targets when narrow',
      (tester) async {
        for (final testCase in <({double width, int itemCount})>[
          (width: 80, itemCount: 2),
          (width: 120, itemCount: 3),
        ]) {
          final semantics = tester.ensureSemantics();
          final items = <BLabSegmentedItem<int>>[
            for (var index = 0; index < testCase.itemCount; index += 1)
              BLabSegmentedItem(value: index, label: 'Item $index'),
          ];
          await tester.pumpWidget(
            _harness(
              Align(
                child: SizedBox(
                  width: testCase.width,
                  child: BLabSegmentedControl<int>(
                    items: items,
                    selectedValue: 0,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          );

          expect(
            find.byKey(
              const ValueKey<String>('BLabSegmentedControl.horizontalOverflow'),
            ),
            findsOneWidget,
          );
          for (var index = 0; index < testCase.itemCount; index += 1) {
            final target = find.byKey(
              ValueKey<String>('BLabSegmentedControl.item.$index.target'),
            );
            final semanticNode = tester.getSemantics(
              find.bySemanticsLabel('Item $index'),
            );
            expect(
              tester.getSize(target).width,
              greaterThanOrEqualTo(44),
              reason: '${testCase.itemCount} items in ${testCase.width}px',
            );
            expect(
              tester.getSize(target).height,
              greaterThanOrEqualTo(44),
              reason: '${testCase.itemCount} items in ${testCase.width}px',
            );
            expect(
              semanticNode.rect.width,
              greaterThanOrEqualTo(44),
              reason: 'semantic target $index',
            );
            expect(
              semanticNode.rect.height,
              greaterThanOrEqualTo(44),
              reason: 'semantic target $index',
            );
          }
          expect(tester.takeException(), isNull);
          semantics.dispose();
        }
      },
    );

    testWidgets('resolves exact four-mode tokens and contrast minima', (
      tester,
    ) async {
      for (final mode in _visualModes) {
        await tester.pumpWidget(
          _harness(
            BLabSegmentedControl<_Choice>(
              items: const [
                BLabSegmentedItem(value: _Choice.first, label: 'First'),
                BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              ],
              selectedValue: _Choice.first,
              onChanged: (_) {},
            ),
            brightness: mode.brightness,
            highContrast: mode.highContrast,
          ),
        );
        await tester.pumpAndSettle();

        final container = _decoration(tester, 'container');
        final selected = _itemDecoration(tester, 0, 'surface');
        final indicator = _itemDecoration(tester, 0, 'indicator.decoration');
        final selectedText = tester.widget<Text>(find.text('First')).style!;
        final unselectedText = tester.widget<Text>(find.text('Second')).style!;

        expect(
          container.color,
          mode.tokens.segmentedContainerSurface,
          reason: mode.label,
        );
        expect(
          container.border!.top.color,
          mode.tokens.segmentedContainerBorder,
          reason: mode.label,
        );
        expect(
          container.border!.top.width,
          mode.highContrast ? 1 : 0,
          reason: mode.label,
        );
        expect(
          selected.color,
          mode.tokens.segmentedSelectedSurface,
          reason: mode.label,
        );
        expect(
          indicator.color,
          mode.tokens.segmentedSelectedIndicator,
          reason: mode.label,
        );
        expect(
          selectedText.color,
          mode.tokens.segmentedSelectedForeground,
          reason: mode.label,
        );
        expect(selectedText.fontWeight, FontWeight.w600, reason: mode.label);
        expect(
          unselectedText.color,
          mode.tokens.segmentedUnselectedForeground,
          reason: mode.label,
        );
        expect(unselectedText.fontWeight, FontWeight.w400, reason: mode.label);
        expect(
          _contrastRatio(
            Color.alphaBlend(
              mode.tokens.segmentedSelectedForeground,
              mode.tokens.segmentedSelectedSurface,
            ),
            mode.tokens.segmentedSelectedSurface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${mode.label} selected text',
        );
        expect(
          _contrastRatio(
            Color.alphaBlend(
              mode.tokens.segmentedUnselectedForeground,
              mode.tokens.segmentedContainerSurface,
            ),
            mode.tokens.segmentedContainerSurface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${mode.label} unselected text',
        );
        expect(
          _contrastRatio(
            mode.tokens.segmentedSelectedIndicator,
            mode.tokens.segmentedSelectedSurface,
          ),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} indicator',
        );
        expect(
          _contrastRatio(
            mode.tokens.segmentedFocusOutline,
            mode.tokens.segmentedSelectedSurface,
          ),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} focus outline',
        );
        expect(
          _contrastRatio(
            mode.tokens.segmentedFocusOuterRing,
            mode.tokens.surfaceBase,
          ),
          greaterThanOrEqualTo(3),
          reason: '${mode.label} outer ring',
        );
        expect(
          _contrastRatio(
            mode.tokens.segmentedDisabledForeground,
            mode.tokens.segmentedSelectedSurface,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${mode.label} disabled selected text',
        );
        expect(
          selected.boxShadow,
          mode.highContrast ? isEmpty : isNotEmpty,
          reason: mode.label,
        );
      }
    });

    testWidgets(
      'uses exact text composites and actual outer-ring adjacencies',
      (tester) async {
        for (
          var modeIndex = 0;
          modeIndex < _visualModes.length;
          modeIndex += 1
        ) {
          final mode = _visualModes[modeIndex];
          final expected = _expectedContrastPairs[modeIndex];
          await tester.pumpWidget(
            _harness(
              BLabSegmentedControl<_Choice>(
                items: const [
                  BLabSegmentedItem(value: _Choice.first, label: 'First'),
                  BLabSegmentedItem(value: _Choice.second, label: 'Second'),
                  BLabSegmentedItem(
                    value: _Choice.third,
                    label: 'Third',
                    enabled: false,
                  ),
                ],
                selectedValue: _Choice.first,
                onChanged: (_) {},
              ),
              brightness: mode.brightness,
              highContrast: mode.highContrast,
            ),
          );
          await tester.pumpAndSettle();

          final container = _decoration(tester, 'container').color!;
          final selected = _itemDecoration(tester, 0, 'surface').color!;
          final selectedForeground = tester
              .widget<Text>(find.text('First'))
              .style!
              .color!;
          final unselectedForeground = tester
              .widget<Text>(find.text('Second'))
              .style!
              .color!;
          final disabledForeground = tester
              .widget<Text>(find.text('Third'))
              .style!
              .color!;
          final unselectedText = Color.alphaBlend(
            unselectedForeground,
            container,
          );
          final disabledUnselectedText = Color.alphaBlend(
            disabledForeground,
            container,
          );
          final disabledSelectedText = Color.alphaBlend(
            disabledForeground,
            selected,
          );
          final hoverContainer = Color.alphaBlend(
            mode.tokens.segmentedHoverOverlay,
            container,
          );
          final pressedContainer = Color.alphaBlend(
            mode.tokens.segmentedPressedOverlay,
            container,
          );
          final hoverSelected = Color.alphaBlend(
            mode.tokens.segmentedHoverOverlay,
            selected,
          );
          final pressedSelected = Color.alphaBlend(
            mode.tokens.segmentedPressedOverlay,
            selected,
          );

          _expectExactContrast(
            unselectedText,
            container,
            expected.unselected,
            '${mode.label} unselected/container',
          );
          _expectExactContrast(
            disabledUnselectedText,
            container,
            expected.disabledUnselected,
            '${mode.label} disabled/container',
          );
          _expectExactContrast(
            disabledSelectedText,
            selected,
            expected.disabledSelected,
            '${mode.label} disabled/selected',
          );
          _expectExactContrast(
            Color.alphaBlend(unselectedForeground, hoverContainer),
            hoverContainer,
            expected.unselectedHover,
            '${mode.label} unselected hover composite',
          );
          _expectExactContrast(
            Color.alphaBlend(unselectedForeground, pressedContainer),
            pressedContainer,
            expected.unselectedPressed,
            '${mode.label} unselected pressed composite',
          );
          _expectExactContrast(
            Color.alphaBlend(selectedForeground, hoverSelected),
            hoverSelected,
            expected.selectedHover,
            '${mode.label} selected hover composite',
          );
          _expectExactContrast(
            Color.alphaBlend(selectedForeground, pressedSelected),
            pressedSelected,
            expected.selectedPressed,
            '${mode.label} selected pressed composite',
          );

          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final ringFinder = find.byKey(
            const ValueKey<String>('BLabSegmentedControl.item.0.focusRing'),
          );
          final ring = _itemDecoration(tester, 0, 'focusRing');
          final ringRect = tester.getRect(ringFinder);
          final targetRect = tester.getRect(
            find.byKey(
              const ValueKey<String>('BLabSegmentedControl.item.0.target'),
            ),
          );
          expect(ringRect.left, targetRect.left - 3);
          expect(ringRect.top, targetRect.top - 3);
          _expectExactContrast(
            ring.border!.top.color,
            mode.tokens.surfaceBase,
            expected.ringCanvas,
            '${mode.label} ring/canvas outer edge',
            minimum: 3,
          );
          _expectExactContrast(
            ring.border!.top.color,
            container,
            expected.ringContainer,
            '${mode.label} ring/container side adjacency',
            minimum: 3,
          );
          _expectExactContrast(
            ring.border!.top.color,
            selected,
            expected.ringSelected,
            '${mode.label} ring/selected inner adjacency',
            minimum: 3,
          );
        }
      },
    );

    testWidgets('honors ambient linear and nonlinear text scaling unclamped', (
      tester,
    ) async {
      for (final scaler in <TextScaler>[
        TextScaler.noScaling,
        TextScaler.linear(2),
        const _NonlinearScaler(),
      ]) {
        await tester.pumpWidget(
          _harness(
            BLabSegmentedControl<_Choice>(
              items: const [
                BLabSegmentedItem(value: _Choice.first, label: 'First'),
                BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              ],
              selectedValue: _Choice.first,
              onChanged: (_) {},
            ),
            textScaler: scaler,
          ),
        );
        final text = tester.widget<Text>(find.text('First'));
        expect(text.textScaler, isNull);
        expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey<String>('BLabSegmentedControl.item.0.target'),
                ),
              )
              .height,
          greaterThanOrEqualTo(44),
        );
      }

      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
          textScaler: TextScaler.linear(4),
        ),
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('BLabSegmentedControl.item.0.target'),
              ),
            )
            .height,
        greaterThan(44),
      );
    });
  });

  group('BLabSegmentedControl semantics and disabled precedence', () {
    testWidgets('uses caller labels and native mutually-exclusive selection', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );

      final first = tester.getSemantics(find.bySemanticsLabel('First'));
      final second = tester.getSemantics(find.bySemanticsLabel('Second'));
      expect(first.label, 'First');
      expect(first.value, isEmpty);
      expect(first.flagsCollection.isSelected, Tristate.isTrue);
      expect(second.flagsCollection.isSelected, Tristate.isFalse);
      expect(first.flagsCollection.isEnabled, Tristate.isTrue);
      expect(first.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(first.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(first.label, isNot(contains(_Choice.first.toString())));
      expect(first.label, isNot(contains('1/2')));
      semantics.dispose();
    });

    testWidgets(
      'disabled control suppresses focus, activation, and traversal',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var calls = 0;
        await tester.pumpWidget(
          _harness(
            BLabSegmentedControl<_Choice>(
              enabled: false,
              items: const [
                BLabSegmentedItem(value: _Choice.first, label: 'First'),
                BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              ],
              selectedValue: _Choice.first,
              onChanged: (_) => calls += 1,
            ),
          ),
        );

        await tester.tap(find.text('Second'));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(calls, 0);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('First'))
              .flagsCollection
              .isEnabled,
          Tristate.isFalse,
        );
        expect(
          find.byKey(
            const ValueKey<String>('BLabSegmentedControl.item.0.focusOutline'),
          ),
          findsNothing,
        );
        expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('First'));
        semantics.dispose();
      },
    );

    testWidgets(
      'disabled selected item keeps selected surface and disabled indicator',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            BLabSegmentedControl<_Choice>(
              items: const [
                BLabSegmentedItem(
                  value: _Choice.first,
                  label: 'First',
                  enabled: false,
                ),
                BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              ],
              selectedValue: _Choice.first,
              onChanged: (_) {},
            ),
          ),
        );

        expect(
          _itemDecoration(tester, 0, 'surface').color,
          BLabTokenTheme.light.segmentedSelectedSurface,
        );
        expect(
          _itemDecoration(tester, 0, 'indicator.decoration').color,
          BLabTokenTheme.light.segmentedDisabledForeground,
        );
        final text = tester.widget<Text>(find.text('First')).style!;
        expect(text.fontWeight, FontWeight.w600);
        expect(text.color, BLabTokenTheme.light.segmentedDisabledForeground);
      },
    );

    testWidgets('all-disabled is valid and exposes no tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(
                value: _Choice.first,
                label: 'First',
                enabled: false,
              ),
              BLabSegmentedItem(
                value: _Choice.second,
                label: 'Second',
                enabled: false,
              ),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );
      for (final label in const ['First', 'Second']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      }
      semantics.dispose();
    });
  });

  group('BLabSegmentedControl interaction precedence and motion', () {
    testWidgets('hover is pointer-only and pressed replaces hover', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );
      final second = find.byKey(
        const ValueKey<String>('BLabSegmentedControl.item.1.target'),
      );
      final center = tester.getCenter(second);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: center);
      await tester.pump();
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        BLabTokenTheme.light.segmentedHoverOverlay,
      );
      await mouse.down(center);
      await tester.pump();
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        BLabTokenTheme.light.segmentedPressedOverlay,
      );
      await mouse.up();
      await mouse.removePointer();

      final touch = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await touch.up();
      await tester.pump();
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        Colors.transparent,
      );
    });

    testWidgets('keyboard focus composes outline and ring with selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final outline = _itemDecoration(tester, 0, 'focusOutline');
      final ring = _itemDecoration(tester, 0, 'focusRing');
      expect(
        outline.border!.top.color,
        BLabTokenTheme.light.segmentedFocusOutline,
      );
      expect(outline.border!.top.width, 2);
      expect(
        ring.border!.top.color,
        BLabTokenTheme.light.segmentedFocusOuterRing,
      );
      expect(ring.border!.top.width, 3);
      expect(
        _itemDecoration(tester, 0, 'surface').color,
        BLabTokenTheme.light.segmentedSelectedSurface,
      );
    });

    testWidgets('pointer focus owns roving focus without focus decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Second'));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');
      expect(
        find.byKey(
          const ValueKey<String>('BLabSegmentedControl.item.1.focusOutline'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('BLabSegmentedControl.item.1.focusRing'),
        ),
        findsNothing,
      );
    });

    testWidgets('reduced motion makes selection and interaction immediate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: (_) {},
          ),
          disableAnimations: true,
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>('BLabSegmentedControl.item.0.surface'),
              ),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>(
                  'BLabSegmentedControl.item.0.interaction',
                ),
              ),
            )
            .duration,
        Duration.zero,
      );
    });

    testWidgets(
      'per-item indicators fade in place for 180ms through a midpoint',
      (tester) async {
        late StateSetter setHarnessState;
        var selected = _Choice.first;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return BLabSegmentedControl<_Choice>(
                  items: const [
                    BLabSegmentedItem(value: _Choice.first, label: 'First'),
                    BLabSegmentedItem(value: _Choice.second, label: 'Second'),
                  ],
                  selectedValue: selected,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final first = _indicatorFinder(0);
        final second = _indicatorFinder(1);
        expect(first, findsOneWidget);
        expect(second, findsOneWidget);
        expect(find.byType(AnimatedPositioned), findsNothing);
        final firstElement = tester.element(first);
        final secondElement = tester.element(second);
        final firstPosition = tester.getTopLeft(first);
        final secondPosition = tester.getTopLeft(second);
        expect(
          tester.widget<AnimatedOpacity>(first).duration,
          BLabMotion.durSegment,
        );
        expect(
          tester.widget<AnimatedOpacity>(second).duration,
          BLabMotion.durSegment,
        );
        expect(_indicatorOpacity(tester, first), 1);
        expect(_indicatorOpacity(tester, second), 0);

        setHarnessState(() => selected = _Choice.second);
        await tester.pump();
        expect(identical(tester.element(first), firstElement), isTrue);
        expect(identical(tester.element(second), secondElement), isTrue);
        expect(tester.getTopLeft(first), firstPosition);
        expect(tester.getTopLeft(second), secondPosition);

        await tester.pump(const Duration(milliseconds: 90));
        expect(_indicatorOpacity(tester, first), inExclusiveRange(0, 1));
        expect(_indicatorOpacity(tester, second), inExclusiveRange(0, 1));
        expect(tester.getTopLeft(first), firstPosition);
        expect(tester.getTopLeft(second), secondPosition);

        await tester.pump(const Duration(milliseconds: 90));
        expect(_indicatorOpacity(tester, first), 0);
        expect(_indicatorOpacity(tester, second), 1);
        expect(tester.getTopLeft(first), firstPosition);
        expect(tester.getTopLeft(second), secondPosition);
      },
    );

    testWidgets(
      'per-item indicators transition immediately under reduced motion',
      (tester) async {
        late StateSetter setHarnessState;
        var selected = _Choice.first;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return BLabSegmentedControl<_Choice>(
                  items: const [
                    BLabSegmentedItem(value: _Choice.first, label: 'First'),
                    BLabSegmentedItem(value: _Choice.second, label: 'Second'),
                  ],
                  selectedValue: selected,
                  onChanged: (_) {},
                );
              },
            ),
            disableAnimations: true,
          ),
        );
        final first = _indicatorFinder(0);
        final second = _indicatorFinder(1);
        final firstPosition = tester.getTopLeft(first);
        final secondPosition = tester.getTopLeft(second);
        expect(tester.widget<AnimatedOpacity>(first).duration, Duration.zero);
        expect(tester.widget<AnimatedOpacity>(second).duration, Duration.zero);

        setHarnessState(() => selected = _Choice.second);
        await tester.pump();
        expect(_indicatorOpacity(tester, first), 0);
        expect(_indicatorOpacity(tester, second), 1);
        expect(tester.getTopLeft(first), firstPosition);
        expect(tester.getTopLeft(second), secondPosition);
      },
    );
  });

  group('BLabSegmentedControl scrollable overflow addendum', () {
    testWidgets('scrolls only below the exact finite minimum width', (
      tester,
    ) async {
      Widget control() => BLabSegmentedControl<int>(
        items: const [
          BLabSegmentedItem(value: 0, label: 'Zero'),
          BLabSegmentedItem(value: 1, label: 'One'),
        ],
        selectedValue: 0,
        onChanged: (_) {},
      );

      await tester.pumpWidget(_harness(_fixedWidth(93, control())));
      expect(_overflowFinder, findsOneWidget);
      final overflow = tester.widget<SingleChildScrollView>(_overflowFinder);
      expect(overflow.primary, isFalse);
      expect(overflow.controller, isNotNull);
      expect(
        overflow.controller,
        isNot(
          same(
            PrimaryScrollController.maybeOf(tester.element(_overflowFinder)),
          ),
        ),
      );

      await tester.pumpWidget(_harness(_fixedWidth(94, control())));
      expect(_overflowFinder, findsNothing);

      await tester.pumpWidget(
        _harness(Row(mainAxisSize: MainAxisSize.min, children: [control()])),
      );
      expect(_overflowFinder, findsNothing);
    });

    testWidgets(
      'initial reveal is immediate in LTR and RTL and includes disabled selection',
      (tester) async {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            _harness(
              _fixedWidth(
                80,
                BLabSegmentedControl<int>(
                  items: const [
                    BLabSegmentedItem(value: 0, label: 'Zero'),
                    BLabSegmentedItem(value: 1, label: 'One'),
                    BLabSegmentedItem(value: 2, label: 'Two'),
                    BLabSegmentedItem(value: 3, label: 'Three'),
                    BLabSegmentedItem(value: 4, label: 'Four', enabled: false),
                  ],
                  selectedValue: 4,
                  onChanged: (_) {},
                ),
              ),
              textDirection: direction,
            ),
          );
          await tester.pump();
          _expectItemRingVisible(tester, 4);
          expect(
            _overflowController(tester).position.isScrollingNotifier.value,
            isFalse,
          );
          final viewport = tester.getRect(_overflowFinder);
          final selected = tester.getRect(_targetFinder(4));
          if (direction == TextDirection.ltr) {
            expect(selected.right, lessThanOrEqualTo(viewport.right + 0.01));
          } else {
            expect(selected.left, greaterThanOrEqualTo(viewport.left - 0.01));
          }
        }
      },
    );

    testWidgets(
      'Arrow Home and End reveal offscreen roving focus and rejected focus wins',
      (tester) async {
        final calls = <int>[];
        late StateSetter rebuild;
        var revision = 0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    Text('Revision $revision'),
                    _fixedWidth(
                      80,
                      BLabSegmentedControl<int>(
                        items: const [
                          BLabSegmentedItem(value: 0, label: 'Zero'),
                          BLabSegmentedItem(value: 1, label: 'One'),
                          BLabSegmentedItem(value: 2, label: 'Two'),
                          BLabSegmentedItem(value: 3, label: 'Three'),
                          BLabSegmentedItem(value: 4, label: 'Four'),
                        ],
                        selectedValue: 0,
                        onChanged: calls.add,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(calls, [4]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Four');
        _expectItemRingVisible(tester, 4);

        rebuild(() => revision += 1);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Four');
        _expectItemRingVisible(tester, 4);

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(calls, [4, 0]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Zero');
        _expectItemRingVisible(tester, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(calls, [4, 0, 4]);
        _expectItemRingVisible(tester, 4);
      },
    );

    testWidgets(
      'narrow RTL Home and End reveal both logical ends with ring allowance',
      (tester) async {
        final calls = <int>[];
        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              80,
              BLabSegmentedControl<int>(
                items: const [
                  BLabSegmentedItem(value: 0, label: 'Zero'),
                  BLabSegmentedItem(value: 1, label: 'One'),
                  BLabSegmentedItem(value: 2, label: 'Two'),
                  BLabSegmentedItem(value: 3, label: 'Three'),
                  BLabSegmentedItem(value: 4, label: 'Four'),
                ],
                selectedValue: 2,
                onChanged: calls.add,
              ),
            ),
            textDirection: TextDirection.rtl,
          ),
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(calls, [0]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Zero');
        _expectItemRingVisible(tester, 0);
        var viewport = tester.getRect(_overflowFinder);
        var target = tester.getRect(_targetFinder(0));
        expect(target.right + 3, closeTo(viewport.right, 0.01));

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(calls, [0, 4]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Four');
        _expectItemRingVisible(tester, 4);
        viewport = tester.getRect(_overflowFinder);
        target = tester.getRect(_targetFinder(4));
        expect(target.left - 3, closeTo(viewport.left, 0.01));
      },
    );

    testWidgets(
      'external selection reveals without stealing outside focus and syncs inside',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside overflow');
        addTearDown(outside.dispose);
        late StateSetter update;
        var selected = 0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Column(
                  children: [
                    Focus(focusNode: outside, child: const Text('Outside')),
                    _fixedWidth(
                      80,
                      BLabSegmentedControl<int>(
                        items: const [
                          BLabSegmentedItem(value: 0, label: 'Zero'),
                          BLabSegmentedItem(value: 1, label: 'One'),
                          BLabSegmentedItem(value: 2, label: 'Two'),
                          BLabSegmentedItem(value: 3, label: 'Three'),
                          BLabSegmentedItem(value: 4, label: 'Four'),
                        ],
                        selectedValue: selected,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pump();
        outside.requestFocus();
        await tester.pump();
        update(() => selected = 4);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, outside);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        _expectItemRingVisible(tester, 4);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Four');
        update(() => selected = 0);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Zero');
        _expectItemRingVisible(tester, 0);
      },
    );

    testWidgets('disabled external selection defers to enabled focus inside', (
      tester,
    ) async {
      final outside = FocusNode(debugLabel: 'Outside disabled overflow');
      addTearDown(outside.dispose);
      late StateSetter update;
      var selected = 0;
      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                children: [
                  Focus(focusNode: outside, child: const Text('Outside')),
                  _fixedWidth(
                    80,
                    BLabSegmentedControl<int>(
                      items: const [
                        BLabSegmentedItem(value: 0, label: 'Zero'),
                        BLabSegmentedItem(value: 1, label: 'One'),
                        BLabSegmentedItem(value: 2, label: 'Two'),
                        BLabSegmentedItem(value: 3, label: 'Three'),
                        BLabSegmentedItem(
                          value: 4,
                          label: 'Four',
                          enabled: false,
                        ),
                      ],
                      selectedValue: selected,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      update(() => selected = 4);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(BLabMotion.durPress);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Zero');
      _expectItemRingVisible(tester, 0);

      outside.requestFocus();
      await tester.pump();
      update(() => selected = 0);
      await tester.pump();
      await tester.pump();
      await tester.pump(BLabMotion.durPress);
      update(() => selected = 4);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(BLabMotion.durPress);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, outside);
      _expectItemRingVisible(tester, 4);
    });

    testWidgets(
      'narrow RTL external enabled and disabled selections reveal without focus theft',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside RTL overflow');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late StateSetter update;
        var selected = 2;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Column(
                  children: [
                    Focus(focusNode: outside, child: const Text('Outside')),
                    _fixedWidth(
                      80,
                      BLabSegmentedControl<int>(
                        items: const [
                          BLabSegmentedItem(value: 0, label: 'Zero'),
                          BLabSegmentedItem(value: 1, label: 'One'),
                          BLabSegmentedItem(value: 2, label: 'Two'),
                          BLabSegmentedItem(value: 3, label: 'Three'),
                          BLabSegmentedItem(
                            value: 4,
                            label: 'Four',
                            enabled: false,
                          ),
                        ],
                        selectedValue: selected,
                        onChanged: calls.add,
                      ),
                    ),
                  ],
                );
              },
            ),
            textDirection: TextDirection.rtl,
          ),
        );
        await tester.pump();
        outside.requestFocus();
        await tester.pump();

        update(() => selected = 0);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
        _expectItemRingVisible(tester, 0);
        var viewport = tester.getRect(_overflowFinder);
        var target = tester.getRect(_targetFinder(0));
        expect(target.right + 3, closeTo(viewport.right, 0.01));

        update(() => selected = 4);
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
        _expectItemRingVisible(tester, 4);
        viewport = tester.getRect(_overflowFinder);
        target = tester.getRect(_targetFinder(4));
        expect(target.left - 3, closeTo(viewport.left, 0.01));
      },
    );

    testWidgets(
      'programmatic reveal is 150ms, retargets latest, and reduced motion is immediate',
      (tester) async {
        late StateSetter update;
        var selected = 0;
        var disableAnimations = false;

        Widget scenario() => StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return _fixedWidth(
              80,
              BLabSegmentedControl<int>(
                items: const [
                  BLabSegmentedItem(value: 0, label: 'Zero'),
                  BLabSegmentedItem(value: 1, label: 'One'),
                  BLabSegmentedItem(value: 2, label: 'Two'),
                  BLabSegmentedItem(value: 3, label: 'Three'),
                  BLabSegmentedItem(value: 4, label: 'Four'),
                ],
                selectedValue: selected,
                onChanged: (_) {},
              ),
            );
          },
        );

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setOuterState) =>
                _harness(scenario(), disableAnimations: disableAnimations),
          ),
        );
        await tester.pump();
        final controller = _overflowController(tester);
        update(() => selected = 4);
        await tester.pump();
        expect(controller.position.isScrollingNotifier.value, isTrue);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(
          controller.offset,
          inExclusiveRange(0, controller.position.maxScrollExtent),
        );

        update(() => selected = 2);
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        _expectItemRingVisible(tester, 2);
        expect(controller.position.isScrollingNotifier.value, isFalse);

        final alreadyVisibleOffset = controller.offset;
        update(() {});
        await tester.pump();
        expect(controller.offset, alreadyVisibleOffset);
        expect(controller.position.isScrollingNotifier.value, isFalse);

        disableAnimations = true;
        await tester.pumpWidget(
          _harness(scenario(), disableAnimations: disableAnimations),
        );
        await tester.pump();
        update(() => selected = 4);
        await tester.pump();
        _expectItemRingVisible(tester, 4);
        expect(
          _overflowController(tester).position.isScrollingNotifier.value,
          isFalse,
        );
      },
    );

    testWidgets(
      'already-visible external selection does not restart scrolling',
      (tester) async {
        late StateSetter update;
        var selected = 0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return _fixedWidth(
                  120,
                  BLabSegmentedControl<int>(
                    items: const [
                      BLabSegmentedItem(value: 0, label: 'Zero'),
                      BLabSegmentedItem(value: 1, label: 'One'),
                      BLabSegmentedItem(value: 2, label: 'Two'),
                      BLabSegmentedItem(value: 3, label: 'Three'),
                      BLabSegmentedItem(value: 4, label: 'Four'),
                    ],
                    selectedValue: selected,
                    onChanged: (_) {},
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        final controller = _overflowController(tester);
        expect(controller.offset, 0);
        _expectItemRingVisible(tester, 0);
        _expectItemRingVisible(tester, 1);

        update(() => selected = 1);
        await tester.pump();
        await tester.pump();
        expect(controller.offset, 0);
        expect(controller.position.isScrollingNotifier.value, isFalse);
      },
    );

    testWidgets('manual scroll is neutral and vertical drag reaches ancestor', (
      tester,
    ) async {
      final calls = <int>[];
      var verticalUpdates = 0;
      await tester.pumpWidget(
        _harness(
          GestureDetector(
            onVerticalDragUpdate: (_) => verticalUpdates += 1,
            child: _fixedWidth(
              80,
              BLabSegmentedControl<int>(
                items: const [
                  BLabSegmentedItem(value: 0, label: 'Zero'),
                  BLabSegmentedItem(value: 1, label: 'One'),
                  BLabSegmentedItem(value: 2, label: 'Two'),
                  BLabSegmentedItem(value: 3, label: 'Three'),
                  BLabSegmentedItem(value: 4, label: 'Four'),
                ],
                selectedValue: 0,
                onChanged: calls.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.drag(_overflowFinder, const Offset(-60, 0));
      await tester.pumpAndSettle();
      final manualOffset = _overflowController(tester).offset;
      expect(manualOffset, greaterThan(0));
      expect(calls, isEmpty);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Zero'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      await tester.drag(_overflowFinder, const Offset(0, -40));
      await tester.pump();
      expect(verticalUpdates, greaterThan(0));
      expect(_overflowController(tester).offset, manualOffset);
      expect(calls, isEmpty);
    });

    testWidgets(
      'touch drag preserves outside focus and the existing roving Tab entry',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside touch drag');
        addTearDown(outside.dispose);
        final calls = <int>[];
        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                Focus(focusNode: outside, child: const Text('Outside')),
                _fixedWidth(
                  80,
                  BLabSegmentedControl<int>(
                    items: const [
                      BLabSegmentedItem(value: 0, label: 'Zero'),
                      BLabSegmentedItem(value: 1, label: 'One'),
                      BLabSegmentedItem(value: 2, label: 'Two'),
                      BLabSegmentedItem(value: 3, label: 'Three'),
                    ],
                    selectedValue: 0,
                    onChanged: calls.add,
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        outside.requestFocus();
        await tester.pump();

        final gesture = await tester.startGesture(
          tester.getCenter(_targetFinder(1)),
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(-48, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Zero'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(
          _itemDecoration(tester, 1, 'interaction').color,
          Colors.transparent,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Zero');
      },
    );

    testWidgets('native physical scroll semantics exist only during overflow', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _harness(
            _fixedWidth(
              80,
              BLabSegmentedControl<int>(
                key: ValueKey<TextDirection>(direction),
                items: const [
                  BLabSegmentedItem(value: 0, label: 'Zero'),
                  BLabSegmentedItem(value: 1, label: 'One'),
                  BLabSegmentedItem(value: 2, label: 'Two'),
                ],
                selectedValue: 0,
                onChanged: (_) {},
              ),
            ),
            textDirection: direction,
          ),
        );
        await tester.pump();
        await tester.pump();
        var node = tester.getSemantics(_overflowFinder);
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
      }

      await tester.pumpWidget(
        _harness(
          _fixedWidth(
            138,
            BLabSegmentedControl<int>(
              items: const [
                BLabSegmentedItem(value: 0, label: 'Zero'),
                BLabSegmentedItem(value: 1, label: 'One'),
                BLabSegmentedItem(value: 2, label: 'Two'),
              ],
              selectedValue: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(_overflowFinder, findsNothing);
      handle.dispose();
    });
  });

  group('BLabSegmentedControl controlled keyboard behavior', () {
    testWidgets('LTR arrows wrap enabled items and selection follows focus', (
      tester,
    ) async {
      final calls = <_Choice>[];
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(
                value: _Choice.second,
                label: 'Second',
                enabled: false,
              ),
              BLabSegmentedItem(value: _Choice.third, label: 'Third'),
            ],
            selectedValue: _Choice.first,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(calls, [_Choice.third]);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Third');
      expect(
        _itemDecoration(tester, 0, 'surface').color,
        BLabTokenTheme.light.segmentedSelectedSurface,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(calls, [_Choice.third, _Choice.first]);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'First');
    });

    testWidgets('RTL horizontal and direction-independent vertical keys work', (
      tester,
    ) async {
      final calls = <_Choice>[];
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              BLabSegmentedItem(value: _Choice.third, label: 'Third'),
            ],
            selectedValue: _Choice.second,
            onChanged: calls.add,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(calls, [_Choice.first, _Choice.second, _Choice.first]);
    });

    testWidgets('Home End Enter and Space invoke exactly once', (tester) async {
      final calls = <_Choice>[];
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
              BLabSegmentedItem(value: _Choice.third, label: 'Third'),
            ],
            selectedValue: _Choice.second,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, [
        _Choice.first,
        _Choice.third,
        _Choice.third,
        _Choice.third,
      ]);
    });

    testWidgets('reactivating selected calls back exactly once', (
      tester,
    ) async {
      final calls = <_Choice>[];
      await tester.pumpWidget(
        _harness(
          BLabSegmentedControl<_Choice>(
            items: const [
              BLabSegmentedItem(value: _Choice.first, label: 'First'),
              BLabSegmentedItem(value: _Choice.second, label: 'Second'),
            ],
            selectedValue: _Choice.first,
            onChanged: calls.add,
          ),
        ),
      );
      await tester.tap(find.text('First'));
      expect(calls, [_Choice.first]);
    });

    testWidgets('external selection sync never calls back or steals focus', (
      tester,
    ) async {
      final outside = FocusNode(debugLabel: 'Outside');
      addTearDown(outside.dispose);
      final calls = <_Choice>[];
      late StateSetter setHarnessState;
      var selected = _Choice.first;

      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return Column(
                children: [
                  Focus(focusNode: outside, child: const Text('Outside')),
                  BLabSegmentedControl<_Choice>(
                    items: const [
                      BLabSegmentedItem(value: _Choice.first, label: 'First'),
                      BLabSegmentedItem(value: _Choice.second, label: 'Second'),
                    ],
                    selectedValue: selected,
                    onChanged: calls.add,
                  ),
                ],
              );
            },
          ),
        ),
      );
      outside.requestFocus();
      await tester.pump();
      setHarnessState(() => selected = _Choice.second);
      await tester.pump();
      expect(calls, isEmpty);
      expect(FocusManager.instance.primaryFocus, outside);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');
    });

    testWidgets(
      'unrelated rebuild after rejected arrow selection preserves roving focus',
      (tester) async {
        final calls = <_Choice>[];
        late StateSetter setHarnessState;
        var unrelatedRevision = 0;

        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return Column(
                  children: [
                    Text('Revision $unrelatedRevision'),
                    BLabSegmentedControl<_Choice>(
                      items: const [
                        BLabSegmentedItem(value: _Choice.first, label: 'First'),
                        BLabSegmentedItem(
                          value: _Choice.second,
                          label: 'Second',
                        ),
                      ],
                      selectedValue: _Choice.first,
                      onChanged: calls.add,
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        expect(calls, [_Choice.second]);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');

        setHarnessState(() => unrelatedRevision += 1);
        await tester.pump();
        expect(find.text('Revision 1'), findsOneWidget);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');
        expect(calls, [_Choice.second]);
      },
    );

    testWidgets(
      'external enabled selection syncs inside focus; disabled selection retains it',
      (tester) async {
        final calls = <_Choice>[];
        late StateSetter setHarnessState;
        var selected = _Choice.first;
        var secondEnabled = true;

        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                setHarnessState = setState;
                return BLabSegmentedControl<_Choice>(
                  items: [
                    const BLabSegmentedItem(
                      value: _Choice.first,
                      label: 'First',
                    ),
                    BLabSegmentedItem(
                      value: _Choice.second,
                      label: 'Second',
                      enabled: secondEnabled,
                    ),
                  ],
                  selectedValue: selected,
                  onChanged: calls.add,
                );
              },
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'First');

        setHarnessState(() => selected = _Choice.second);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');
        expect(calls, isEmpty);

        setHarnessState(() {
          secondEnabled = false;
          selected = _Choice.second;
        });
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'First');
        expect(calls, isEmpty);
      },
    );

    testWidgets('one roving Tab stop enters selected item then exits control', (
      tester,
    ) async {
      final after = FocusNode(debugLabel: 'After');
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _harness(
          Column(
            children: [
              BLabSegmentedControl<_Choice>(
                items: const [
                  BLabSegmentedItem(value: _Choice.first, label: 'First'),
                  BLabSegmentedItem(value: _Choice.second, label: 'Second'),
                ],
                selectedValue: _Choice.second,
                onChanged: (_) {},
              ),
              Focus(focusNode: after, child: const Text('After')),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, after);
    });

    testWidgets('disabling focused item moves next then previous silently', (
      tester,
    ) async {
      final calls = <_Choice>[];
      late StateSetter setHarnessState;
      var secondEnabled = true;
      var thirdEnabled = true;

      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return BLabSegmentedControl<_Choice>(
                items: [
                  const BLabSegmentedItem(value: _Choice.first, label: 'First'),
                  BLabSegmentedItem(
                    value: _Choice.second,
                    label: 'Second',
                    enabled: secondEnabled,
                  ),
                  BLabSegmentedItem(
                    value: _Choice.third,
                    label: 'Third',
                    enabled: thirdEnabled,
                  ),
                ],
                selectedValue: _Choice.second,
                onChanged: calls.add,
              );
            },
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Second');

      setHarnessState(() => secondEnabled = false);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Third');
      expect(calls, isEmpty);

      setHarnessState(() => thirdEnabled = false);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'First');
      expect(calls, isEmpty);
    });

    testWidgets('removing the focused item safely restores selected focus', (
      tester,
    ) async {
      late StateSetter setHarnessState;
      var includeThird = true;
      var selected = _Choice.third;

      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return BLabSegmentedControl<_Choice>(
                items: [
                  const BLabSegmentedItem(value: _Choice.first, label: 'First'),
                  const BLabSegmentedItem(
                    value: _Choice.second,
                    label: 'Second',
                  ),
                  if (includeThird)
                    const BLabSegmentedItem(
                      value: _Choice.third,
                      label: 'Third',
                    ),
                ],
                selectedValue: selected,
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Third');

      setHarnessState(() {
        includeThird = false;
        selected = _Choice.first;
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'First');
    });
  });
}

enum _Choice { first, second, third }

Widget _fixedWidth(double width, Widget child) => Align(
  child: SizedBox(width: width, child: child),
);

Widget _harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
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
      child: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BLabFocusVisibilityScope(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester, String suffix) =>
    _keyDecoration(tester, 'BLabSegmentedControl.$suffix');

BoxDecoration _itemDecoration(WidgetTester tester, int index, String suffix) =>
    _keyDecoration(tester, 'BLabSegmentedControl.item.$index.$suffix');

final _overflowFinder = find.byKey(
  const ValueKey<String>('BLabSegmentedControl.horizontalOverflow'),
);

Finder _targetFinder(int index) =>
    find.byKey(ValueKey<String>('BLabSegmentedControl.item.$index.target'));

Finder _indicatorFinder(int index) =>
    find.byKey(ValueKey<String>('BLabSegmentedControl.item.$index.indicator'));

ScrollController _overflowController(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(_overflowFinder).controller!;

double _indicatorOpacity(WidgetTester tester, Finder indicator) {
  final fade = find.descendant(
    of: indicator,
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade).opacity.value;
}

void _expectItemRingVisible(WidgetTester tester, int index) {
  final viewport = tester.getRect(_overflowFinder);
  final item = tester.getRect(_targetFinder(index));
  expect(item.left - 3, greaterThanOrEqualTo(viewport.left - 0.01));
  expect(item.right + 3, lessThanOrEqualTo(viewport.right + 0.01));
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

BoxDecoration _keyDecoration(WidgetTester tester, String key) =>
    switch (tester.widget<Widget>(find.byKey(ValueKey<String>(key)))) {
      final AnimatedContainer widget => widget.decoration as BoxDecoration,
      final DecoratedBox widget => widget.decoration as BoxDecoration,
      final widget => throw StateError(
        'Unexpected segmented decoration widget: ${widget.runtimeType}',
      ),
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

void _expectExactContrast(
  Color foreground,
  Color background,
  double expected,
  String reason, {
  double minimum = 4.5,
}) {
  final actual = _contrastRatio(foreground, background);
  expect(actual, closeTo(expected, 0.000001), reason: reason);
  expect(actual, greaterThanOrEqualTo(minimum), reason: '$reason minimum');
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}

const _visualModes = <_VisualMode>[
  _VisualMode(
    label: 'light',
    brightness: Brightness.light,
    highContrast: false,
    tokens: BLabTokenTheme.light,
  ),
  _VisualMode(
    label: 'dark',
    brightness: Brightness.dark,
    highContrast: false,
    tokens: BLabTokenTheme.dark,
  ),
  _VisualMode(
    label: 'high-contrast-light',
    brightness: Brightness.light,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastLight,
  ),
  _VisualMode(
    label: 'high-contrast-dark',
    brightness: Brightness.dark,
    highContrast: true,
    tokens: BLabTokenTheme.highContrastDark,
  ),
];

class _VisualMode {
  const _VisualMode({
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

const _expectedContrastPairs = <_ContrastPairs>[
  _ContrastPairs(
    unselected: 14.828065,
    disabledUnselected: 4.583551,
    disabledSelected: 4.997129,
    unselectedHover: 12.827809,
    unselectedPressed: 11.776640,
    selectedHover: 17.615398,
    selectedPressed: 15.908084,
    ringCanvas: 3.395932,
    ringContainer: 3.251197,
    ringSelected: 3.544556,
  ),
  _ContrastPairs(
    unselected: 12.094355,
    disabledUnselected: 6.190552,
    disabledSelected: 5.489373,
    unselectedHover: 9.751737,
    unselectedPressed: 8.542605,
    selectedHover: 10.915317,
    selectedPressed: 9.471309,
    ringCanvas: 5.285193,
    ringContainer: 4.434075,
    ringSelected: 3.931845,
  ),
  _ContrastPairs(
    unselected: 21,
    disabledUnselected: 4.834490,
    disabledSelected: 4.834490,
    unselectedHover: 15.908084,
    unselectedPressed: 13.076547,
    selectedHover: 15.908084,
    selectedPressed: 13.076547,
    ringCanvas: 21,
    ringContainer: 21,
    ringSelected: 21,
  ),
  _ContrastPairs(
    unselected: 18.733664,
    disabledUnselected: 7.378825,
    disabledSelected: 7.378825,
    unselectedHover: 13.424353,
    unselectedPressed: 10.144430,
    selectedHover: 13.424353,
    selectedPressed: 10.144430,
    ringCanvas: 18.733664,
    ringContainer: 18.733664,
    ringSelected: 18.733664,
  ),
];

class _ContrastPairs {
  const _ContrastPairs({
    required this.unselected,
    required this.disabledUnselected,
    required this.disabledSelected,
    required this.unselectedHover,
    required this.unselectedPressed,
    required this.selectedHover,
    required this.selectedPressed,
    required this.ringCanvas,
    required this.ringContainer,
    required this.ringSelected,
  });

  final double unselected;
  final double disabledUnselected;
  final double disabledSelected;
  final double unselectedHover;
  final double unselectedPressed;
  final double selectedHover;
  final double selectedPressed;
  final double ringCanvas;
  final double ringContainer;
  final double ringSelected;
}
