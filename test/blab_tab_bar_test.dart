import 'dart:ui' show Tristate;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabTabBar compatibility and visuals', () {
    testWidgets('preserves public defaults and equal 44x56 targets', (
      tester,
    ) async {
      late TabController controller;
      await tester.pumpWidget(
        _harness(
          _host(
            tabs: const ['One', 'Two', 'Three'],
            onController: (value) => controller = value,
            builder: (context, value) => BLabTabBar(
              controller: value,
              tabs: const ['One', 'Two', 'Three'],
            ),
          ),
        ),
      );

      final widget = tester.widget<BLabTabBar>(find.byType(BLabTabBar));
      expect(widget, isA<StatelessWidget>());
      expect(widget.controller, controller);
      expect(widget.indicatorWeight, 3);
      expect(widget.isScrollable, isFalse);
      expect(widget.dividerColor, isNull);
      expect(widget.preferredSize.height, 56);
      expect(
        () => BLabTabBar(
          controller: controller,
          tabs: const ['One', 'Two', 'Three'],
          indicatorWeight: 0,
        ),
        throwsAssertionError,
      );

      final widths = <double>[];
      for (var index = 0; index < 3; index += 1) {
        final target = _targetFinder(index);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(56));
        expect(tester.getSize(target).width, greaterThanOrEqualTo(44));
        widths.add(tester.getSize(target).width);
      }
      expect(widths[0], closeTo(widths[1], 0.01));
      expect(widths[1], closeTo(widths[2], 0.01));
    });

    testWidgets('resolves exact four-mode tokens and contrast pairs', (
      tester,
    ) async {
      for (final mode in _modes) {
        await tester.pumpWidget(
          _harness(
            _host(
              key: ValueKey<String>(mode.label),
              tabs: const ['Selected', 'Unselected'],
              builder: (context, controller) => BLabTabBar(
                controller: controller,
                tabs: const ['Selected', 'Unselected'],
              ),
            ),
            brightness: mode.brightness,
            highContrast: mode.highContrast,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _decoration(tester, 'container').color,
          mode.container,
          reason: mode.label,
        );
        expect(
          _decoration(tester, 'indicator.decoration').color,
          mode.indicator,
          reason: mode.label,
        );
        expect(
          _inheritedTextStyle(tester, 'Selected').color,
          mode.selected,
          reason: mode.label,
        );
        expect(
          _inheritedTextStyle(tester, 'Unselected').color,
          mode.unselected,
          reason: mode.label,
        );
        for (final surface in mode.surfaces.entries) {
          expect(
            _contrastRatio(
              _composite(mode.selected, surface.value),
              surface.value,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${mode.label} ${surface.key} selected',
          );
          expect(
            _contrastRatio(
              _composite(mode.unselected, surface.value),
              surface.value,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${mode.label} ${surface.key} unselected',
          );
          for (final overlay in [mode.hover, mode.pressed]) {
            final interactionSurface = _composite(overlay, surface.value);
            expect(
              _contrastRatio(
                _composite(mode.unselected, interactionSurface),
                interactionSurface,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '${mode.label} ${surface.key} overlay text',
            );
          }
          expect(
            _contrastRatio(mode.indicator, surface.value),
            greaterThanOrEqualTo(3),
            reason: '${mode.label} ${surface.key} indicator',
          );
          expect(
            _contrastRatio(mode.focusOutline, surface.value),
            greaterThanOrEqualTo(3),
            reason: '${mode.label} ${surface.key} outline',
          );
          expect(
            _contrastRatio(mode.focusRing, surface.value),
            greaterThanOrEqualTo(3),
            reason: '${mode.label} ${surface.key} ring',
          );
        }
      }
    });

    testWidgets('dedicated colors beat style colors which beat tokens', (
      tester,
    ) async {
      const dedicatedSelected = Color(0xFF123456);
      const dedicatedUnselected = Color(0xFF654321);
      const styleSelected = Color(0xFFABCDEF);
      const styleUnselected = Color(0xFFFEDCBA);
      const dedicatedIndicator = Color(0xFF112233);
      const dedicatedDivider = Color(0xFF445566);

      await tester.pumpWidget(
        _harness(
          _host(
            tabs: const ['One', 'Two'],
            builder: (context, controller) => BLabTabBar(
              controller: controller,
              tabs: const ['One', 'Two'],
              labelColor: dedicatedSelected,
              unselectedLabelColor: dedicatedUnselected,
              indicatorColor: dedicatedIndicator,
              dividerColor: dedicatedDivider,
              labelStyle: const TextStyle(color: styleSelected, fontSize: 17),
              unselectedLabelStyle: const TextStyle(
                color: styleUnselected,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
      final selected = _inheritedTextStyle(tester, 'One');
      final unselected = _inheritedTextStyle(tester, 'Two');
      expect(selected.color, dedicatedSelected);
      expect(selected.fontSize, 17);
      expect(unselected.color, dedicatedUnselected);
      expect(unselected.letterSpacing, 2);
      expect(
        _decoration(tester, 'indicator.decoration').color,
        dedicatedIndicator,
      );
      expect(_decoration(tester, 'divider').color, dedicatedDivider);

      await tester.pumpWidget(
        _harness(
          _host(
            tabs: const ['One', 'Two'],
            builder: (context, controller) => BLabTabBar(
              controller: controller,
              tabs: const ['One', 'Two'],
              labelStyle: const TextStyle(color: styleSelected),
              unselectedLabelStyle: const TextStyle(color: styleUnselected),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inheritedTextStyle(tester, 'One').color, styleSelected);
      expect(_inheritedTextStyle(tester, 'Two').color, styleUnselected);
    });

    testWidgets(
      'uses a label-width 3px indicator above an optional 1px divider',
      (tester) async {
        const divider = Color(0xFF445566);
        await tester.pumpWidget(
          _harness(
            _host(
              tabs: const ['Short', 'A much longer label'],
              builder: (context, controller) => BLabTabBar(
                controller: controller,
                tabs: const ['Short', 'A much longer label'],
                dividerColor: divider,
              ),
            ),
          ),
        );

        final indicator = tester.getRect(_indicatorFinder);
        final label = tester.getRect(find.text('Short'));
        expect(indicator.width, closeTo(label.width, 0.01));
        expect(indicator.height, closeTo(3, 0.01));
        final dividerRect = tester.getRect(_dividerFinder);
        expect(dividerRect.height, closeTo(1, 0.01));
        expect(indicator.bottom, closeTo(dividerRect.bottom, 0.01));
        expect(_decoration(tester, 'divider').color, divider);
        final radius =
            _decoration(tester, 'indicator.decoration').borderRadius!
                as BorderRadius;
        expect(radius.topLeft.x, 3);
        expect(radius.topRight.x, 3);
        expect(radius.bottomLeft.x, 0);
        expect(radius.bottomRight.x, 0);
      },
    );

    testWidgets(
      'honors ambient linear and nonlinear scaling without clipping',
      (tester) async {
        for (final scaler in <TextScaler>[
          const TextScaler.linear(2),
          const _NonlinearScaler(),
        ]) {
          await tester.pumpWidget(
            _harness(
              Align(
                child: SizedBox(
                  width: 96,
                  child: _host(
                    key: ValueKey<TextScaler>(scaler),
                    tabs: const [
                      'Long localized tab label',
                      'Second localized tab label',
                    ],
                    builder: (context, controller) => BLabTabBar(
                      controller: controller,
                      tabs: const [
                        'Long localized tab label',
                        'Second localized tab label',
                      ],
                    ),
                  ),
                ),
              ),
              textScaler: scaler,
            ),
          );
          expect(tester.takeException(), isNull);
          final firstTarget = tester.getRect(_targetFinder(0));
          final secondTarget = tester.getRect(_targetFinder(1));
          expect(firstTarget.width, closeTo(48, 0.01));
          expect(secondTarget.width, closeTo(48, 0.01));
          expect(firstTarget.height, greaterThan(56));
          for (final label in const [
            'Long localized tab label',
            'Second localized tab label',
          ]) {
            final text = tester.getRect(find.text(label));
            final target = tester.getRect(
              _targetFinder(label == 'Long localized tab label' ? 0 : 1),
            );
            expect(text.left, greaterThanOrEqualTo(target.left - 0.01));
            expect(text.right, lessThanOrEqualTo(target.right + 0.01));
            expect(text.top, greaterThanOrEqualTo(target.top - 0.01));
            expect(text.bottom, lessThanOrEqualTo(target.bottom + 0.01));
          }
          expect(tester.getSize(_indicatorFinder).width, lessThanOrEqualTo(48));
        }
      },
    );

    testWidgets('is unclipped as AppBar.bottom at 2x text scaling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BLabTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: DefaultTabController(
              length: 2,
              child: BLabFocusVisibilityScope(
                child: Builder(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      bottom: BLabTabBar(
                        controller: DefaultTabController.of(context),
                        tabs: const ['One', 'Two'],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final appBar = tester.getRect(find.byType(AppBar));
      for (var index = 0; index < 2; index += 1) {
        final target = tester.getRect(_targetFinder(index));
        final text = tester.getRect(find.text(index == 0 ? 'One' : 'Two'));
        expect(target.height, greaterThanOrEqualTo(56));
        expect(target.top, greaterThanOrEqualTo(appBar.top - 0.01));
        expect(target.bottom, lessThanOrEqualTo(appBar.bottom + 0.01));
        expect(text.top, greaterThanOrEqualTo(target.top - 0.01));
        expect(text.bottom, lessThanOrEqualTo(target.bottom + 0.01));
      }
    });

    testWidgets(
      'interpolates inherited label color and weight at 150ms and reduces immediately',
      (tester) async {
        const selectedColor = Color(0xFFFF0000);
        const unselectedColor = Color(0xFF0000FF);
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            _host(
              tabs: const ['One', 'Two'],
              onController: (value) => controller = value,
              builder: (context, value) => BLabTabBar(
                controller: value,
                tabs: const ['One', 'Two'],
                labelColor: selectedColor,
                unselectedLabelColor: unselectedColor,
              ),
            ),
          ),
        );
        expect(tester.widget<Text>(find.text('Two')).style, isNull);
        expect(_inheritedTextStyle(tester, 'Two').color, unselectedColor);
        expect(_inheritedTextStyle(tester, 'Two').fontWeight, FontWeight.w400);

        controller.index = 1;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        final midpoint = BLabMotion.ease.transform(0.5);
        final midpointStyle = _inheritedTextStyle(tester, 'Two');
        expect(
          midpointStyle.color,
          Color.lerp(unselectedColor, selectedColor, midpoint),
        );
        expect(
          midpointStyle.fontWeight,
          FontWeight.lerp(FontWeight.w400, FontWeight.w600, midpoint),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(_inheritedTextStyle(tester, 'Two').color, selectedColor);
        expect(_inheritedTextStyle(tester, 'Two').fontWeight, FontWeight.w600);

        late TabController reducedController;
        await tester.pumpWidget(
          _harness(
            _host(
              key: const ValueKey<String>('reduced-label-motion'),
              tabs: const ['One', 'Two'],
              onController: (value) => reducedController = value,
              builder: (context, value) => BLabTabBar(
                controller: value,
                tabs: const ['One', 'Two'],
                labelColor: selectedColor,
                unselectedLabelColor: unselectedColor,
              ),
            ),
            disableAnimations: true,
          ),
        );
        reducedController.index = 1;
        await tester.pump();
        expect(_inheritedTextStyle(tester, 'Two').color, selectedColor);
        expect(_inheritedTextStyle(tester, 'Two').fontWeight, FontWeight.w600);
      },
    );
  });

  group('BLabTabBar interaction and controller behavior', () {
    testWidgets(
      'exposes native tabBar and tab roles with localized position labels',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final calls = <int>[];
          late TabController controller;
          await tester.pumpWidget(
            _harness(
              _host(
                tabs: const ['Overview', 'Details'],
                onController: (value) => controller = value,
                builder: (context, value) => BLabTabBar(
                  controller: value,
                  tabs: const ['Overview', 'Details'],
                  onTap: calls.add,
                ),
              ),
            ),
          );

          final parent = tester.getSemantics(_tabBarSemanticsFinder);
          expect(parent.getSemanticsData().role, SemanticsRole.tabBar);

          final overview = tester.getSemantics(_itemSemanticsFinder(0));
          final details = tester.getSemantics(_itemSemanticsFinder(1));
          expect(overview.getSemanticsData().role, SemanticsRole.tab);
          expect(details.getSemanticsData().role, SemanticsRole.tab);
          expect(overview.getSemanticsData().flagsCollection.isButton, isFalse);
          expect(details.getSemanticsData().flagsCollection.isButton, isFalse);
          expect(overview.label, 'Overview, Tab 1 of 2');
          expect(details.label, 'Details, Tab 2 of 2');
          expect(
            overview.getSemanticsData().flagsCollection.isSelected,
            Tristate.isTrue,
          );
          expect(
            details.getSemanticsData().flagsCollection.isSelected,
            Tristate.isFalse,
          );
          expect(
            details.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );

          tester.semantics.tap(find.semantics.byLabel('Details, Tab 2 of 2'));
          await tester.pumpAndSettle();
          expect(controller.index, 1);
          expect(calls, [1]);
          expect(
            tester
                .getSemantics(_itemSemanticsFinder(1))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('pressed replaces hover and clears after activation', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(
        _harness(
          _host(
            tabs: const ['One', 'Two'],
            builder: (context, controller) => BLabTabBar(
              controller: controller,
              tabs: const ['One', 'Two'],
              onTap: calls.add,
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(_targetFinder(1)));
      await tester.pump(BLabMotion.durPress);
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        _modes.first.hover,
      );

      await mouse.down(tester.getCenter(_targetFinder(1)));
      await tester.pump(BLabMotion.durPress);
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        _modes.first.pressed,
      );
      await mouse.up();
      await tester.pumpAndSettle();
      expect(calls, [1]);
      expect(
        _itemDecoration(tester, 1, 'interaction').color,
        _modes.first.hover,
      );
    });

    testWidgets(
      'keyboard focus composes with selection and pointer focus does not',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            _host(
              tabs: const ['One', 'Two'],
              builder: (context, controller) => BLabTabBar(
                controller: controller,
                tabs: const ['One', 'Two'],
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusOutlineFinder(0), findsOneWidget);
        expect(_focusRingFinder(0), findsOneWidget);
        expect(_indicatorFinder, findsOneWidget);

        await tester.tap(find.text('Two'));
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Two');
        expect(_focusOutlineFinder(1), findsNothing);
        expect(_focusRingFinder(1), findsNothing);
      },
    );

    testWidgets('confirmed tap and selected reactivation notify exactly once', (
      tester,
    ) async {
      final calls = <int>[];
      late TabController controller;
      await tester.pumpWidget(
        _harness(
          _host(
            tabs: const ['One', 'Two'],
            onController: (value) => controller = value,
            builder: (context, value) => BLabTabBar(
              controller: value,
              tabs: const ['One', 'Two'],
              onTap: calls.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      expect(calls, [1]);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      expect(calls, [1, 1]);
    });

    testWidgets(
      'semantic tap after prior focused TabBar notifies exactly once',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final predecessorCalls = <int>[];
          await tester.pumpWidget(
            _harness(
              _host(
                key: const ValueKey<String>('predecessor'),
                tabs: const ['One', 'Two'],
                builder: (context, value) => BLabTabBar(
                  controller: value,
                  tabs: const ['One', 'Two'],
                  onTap: predecessorCalls.add,
                ),
              ),
            ),
          );
          await tester.tap(find.text('Two'));
          await tester.pumpAndSettle();
          expect(predecessorCalls, [1]);

          final calls = <int>[];
          late TabController controller;
          await tester.pumpWidget(
            _harness(
              _host(
                key: const ValueKey<String>('semantic-target'),
                tabs: const ['One', 'Two'],
                onController: (value) => controller = value,
                builder: (context, value) => BLabTabBar(
                  controller: value,
                  tabs: const ['One', 'Two'],
                  onTap: calls.add,
                ),
              ),
            ),
          );

          final target = find.semantics.byLabel('Two, Tab 2 of 2');
          expect(
            tester.getSemantics(find.bySemanticsLabel('Two, Tab 2 of 2')).owner,
            isNotNull,
          );

          // Dispatch through the located node's owner. A full ordered suite can
          // contain more than one pipeline/semantics owner.
          tester.semantics.tap(target);
          await tester.pumpAndSettle();
          expect(controller.index, 1);
          expect(calls, [1]);
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Two, Tab 2 of 2'))
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );

          tester.semantics.tap(target);
          await tester.pumpAndSettle();
          expect(controller.index, 1);
          expect(calls, [1, 1]);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'touch drag preserves outside focus selection callback and Tab entry',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside touch drag');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                Focus(focusNode: outside, child: const Text('Outside')),
                SizedBox(
                  width: 120,
                  child: _host(
                    tabs: const ['One', 'Two', 'Three', 'Four'],
                    onController: (value) => controller = value,
                    builder: (context, value) => BLabTabBar(
                      controller: value,
                      tabs: const ['One', 'Two', 'Three', 'Four'],
                      isScrollable: true,
                      onTap: calls.add,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        outside.requestFocus();
        await tester.pump();
        final gesture = await tester.startGesture(
          tester.getCenter(_targetFinder(1)),
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(-60, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, outside);
        expect(controller.index, 0);
        expect(calls, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'One');
      },
    );

    testWidgets(
      'external controller changes sync roving focus without callback theft',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside external');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                Focus(focusNode: outside, child: const Text('Outside')),
                _host(
                  tabs: const ['One', 'Two', 'Three'],
                  onController: (value) => controller = value,
                  builder: (context, value) => BLabTabBar(
                    controller: value,
                    tabs: const ['One', 'Two', 'Three'],
                    onTap: calls.add,
                  ),
                ),
              ],
            ),
          ),
        );
        outside.requestFocus();
        await tester.pump();
        controller.index = 2;
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Three');

        controller.index = 1;
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Two');
        expect(calls, isEmpty);
      },
    );
  });

  group('BLabTabBar keyboard and overflow', () {
    testWidgets('LTR and RTL arrows wrap; Home End select without callback', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        final calls = <int>[];
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            _host(
              key: ValueKey<TextDirection>(direction),
              tabs: const ['One', 'Two', 'Three'],
              initialIndex: 1,
              onController: (value) => controller = value,
              builder: (context, value) => BLabTabBar(
                controller: value,
                tabs: const ['One', 'Two', 'Three'],
                onTap: calls.add,
              ),
            ),
            textDirection: direction,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        expect(
          controller.index,
          direction == TextDirection.ltr ? 2 : 0,
          reason: direction.name,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        expect(controller.index, 2);
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        expect(controller.index, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        expect(
          controller.index,
          direction == TextDirection.ltr ? 2 : 1,
          reason: direction.name,
        );
        expect(calls, isEmpty);
      }
    });

    testWidgets('Up Down bubble and Enter Space activate once', (tester) async {
      final calls = <int>[];
      var verticalEvents = 0;
      late TabController controller;
      await tester.pumpWidget(
        _harness(
          Focus(
            canRequestFocus: false,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                      event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                verticalEvents += 1;
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: _host(
              tabs: const ['One', 'Two'],
              onController: (value) => controller = value,
              builder: (context, value) => BLabTabBar(
                controller: value,
                tabs: const ['One', 'Two'],
                onTap: calls.add,
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(verticalEvents, 2);
      expect(controller.index, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(calls, [0, 0]);
    });

    testWidgets(
      'scrollable controller is private non-primary and initially reveals current',
      (tester) async {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            _harness(
              SizedBox(
                width: 120,
                child: _host(
                  key: ValueKey<TextDirection>(direction),
                  tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                  initialIndex: 4,
                  builder: (context, controller) => BLabTabBar(
                    controller: controller,
                    tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                    isScrollable: true,
                  ),
                ),
              ),
              textDirection: direction,
            ),
          );
          await tester.pump();
          expect(_scrollFinder, findsOneWidget);
          final scroll = tester.widget<SingleChildScrollView>(_scrollFinder);
          expect(scroll.primary, isFalse);
          expect(scroll.controller, isNotNull);
          expect(
            scroll.controller,
            isNot(
              same(
                PrimaryScrollController.maybeOf(tester.element(_scrollFinder)),
              ),
            ),
          );
          _expectVisible(tester, 4);
        }
      },
    );

    testWidgets(
      'viewport shrink immediately reveals current without outside focus theft',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside viewport resize');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        late StateSetter updateConfiguration;
        var width = 340.0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                updateConfiguration = setState;
                return Column(
                  children: [
                    Focus(
                      focusNode: outside,
                      skipTraversal: true,
                      child: const Text('Outside viewport resize'),
                    ),
                    SizedBox(
                      width: width,
                      child: _host(
                        tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                        initialIndex: 4,
                        onController: (value) => controller = value,
                        builder: (context, value) => BLabTabBar(
                          controller: value,
                          tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                          isScrollable: true,
                          onTap: calls.add,
                        ),
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

        updateConfiguration(() => width = 120);
        await tester.pump();
        await tester.pump();

        _expectVisible(tester, 4);
        expect(controller.index, 4);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
      },
    );

    testWidgets(
      'selection width growth post-layout reveals end tab without side effects',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside selection width growth');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                Focus(
                  focusNode: outside,
                  skipTraversal: true,
                  child: const Text('Outside selection width growth'),
                ),
                SizedBox(
                  width: 120,
                  child: _host(
                    tabs: const ['A', 'B', 'C', 'D', 'End'],
                    onController: (value) => controller = value,
                    builder: (context, value) => BLabTabBar(
                      controller: value,
                      tabs: const ['A', 'B', 'C', 'D', 'End'],
                      isScrollable: true,
                      labelStyle: const TextStyle(fontSize: 28),
                      unselectedLabelStyle: const TextStyle(fontSize: 8),
                      onTap: calls.add,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        outside.requestFocus();
        await tester.pump();
        final unselectedWidth = tester.getSize(_targetFinder(4)).width;

        controller.index = 4;
        await tester.pump();
        final selectedWidth = tester.getSize(_targetFinder(4)).width;
        expect(selectedWidth, greaterThan(unselectedWidth));
        await tester.pump(BLabMotion.durPress);

        _expectVisible(tester, 4);
        expect(controller.index, 4);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
      },
    );

    testWidgets('equal-total-width selection change reveals grown middle tab', (
      tester,
    ) async {
      final outside = FocusNode(debugLabel: 'Outside equal total width');
      addTearDown(outside.dispose);
      final calls = <int>[];
      late TabController controller;
      await tester.pumpWidget(
        _harness(
          Column(
            children: [
              Focus(
                focusNode: outside,
                skipTraversal: true,
                child: const Text('Outside equal total width'),
              ),
              SizedBox(
                width: 120,
                child: _host(
                  tabs: const ['000', '111', '222'],
                  onController: (value) => controller = value,
                  builder: (context, value) => BLabTabBar(
                    controller: value,
                    tabs: const ['000', '111', '222'],
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 24,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                    ),
                    onTap: calls.add,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      outside.requestFocus();
      await tester.pump();
      final beforeWidths = [
        for (var index = 0; index < 3; index += 1)
          tester.getSize(_targetFinder(index)).width,
      ];

      controller.index = 1;
      await tester.pump();
      final afterWidths = [
        for (var index = 0; index < 3; index += 1)
          tester.getSize(_targetFinder(index)).width,
      ];
      expect(afterWidths[1], greaterThan(beforeWidths[1]));
      expect(afterWidths[1], lessThanOrEqualTo(120));
      expect(
        afterWidths.reduce((left, right) => left + right),
        closeTo(beforeWidths.reduce((left, right) => left + right), 0.01),
      );
      await tester.pump(BLabMotion.durPress);

      _expectVisible(tester, 1);
      expect(controller.index, 1);
      expect(FocusManager.instance.primaryFocus, outside);
      expect(calls, isEmpty);
    });

    testWidgets(
      'scrollable fixed scrollable re-entry reveals latest external selection',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside scrollable re-entry');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        late StateSetter updateConfiguration;
        var width = 120.0;
        var scrollable = true;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                updateConfiguration = setState;
                return Column(
                  children: [
                    Focus(
                      focusNode: outside,
                      skipTraversal: true,
                      child: const Text('Outside scrollable re-entry'),
                    ),
                    SizedBox(
                      width: width,
                      child: _host(
                        tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                        initialIndex: 4,
                        onController: (value) => controller = value,
                        builder: (context, value) => BLabTabBar(
                          controller: value,
                          tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                          isScrollable: scrollable,
                          onTap: calls.add,
                        ),
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

        updateConfiguration(() {
          width = 340;
          scrollable = false;
        });
        await tester.pump();
        controller.index = 0;
        await tester.pump();
        updateConfiguration(() {
          width = 120;
          scrollable = true;
        });
        await tester.pump();
        await tester.pump();

        _expectVisible(tester, 0);
        expect(controller.index, 0);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
      },
    );

    testWidgets(
      'Directionality change reveals current after neutral manual scroll',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside direction change');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        late StateSetter updateConfiguration;
        var direction = TextDirection.ltr;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                updateConfiguration = setState;
                return Directionality(
                  textDirection: direction,
                  child: Column(
                    children: [
                      Focus(
                        focusNode: outside,
                        skipTraversal: true,
                        child: const Text('Outside direction change'),
                      ),
                      SizedBox(
                        width: 120,
                        child: _host(
                          tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                          onController: (value) => controller = value,
                          builder: (context, value) => BLabTabBar(
                            controller: value,
                            tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                            isScrollable: true,
                            onTap: calls.add,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();
        outside.requestFocus();
        await tester.pump();
        await tester.drag(_scrollFinder, const Offset(-240, 0));
        await tester.pumpAndSettle();
        _expectNotFullyVisible(tester, 0);

        updateConfiguration(() => direction = TextDirection.rtl);
        await tester.pump();
        await tester.pump();

        _expectVisible(tester, 0);
        expect(controller.index, 0);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
      },
    );

    testWidgets(
      'scrollable keyboard and external changes reveal without outside focus theft',
      (tester) async {
        final outside = FocusNode(debugLabel: 'Outside overflow');
        addTearDown(outside.dispose);
        final calls = <int>[];
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            Column(
              children: [
                Focus(
                  focusNode: outside,
                  skipTraversal: true,
                  child: const Text('Outside'),
                ),
                SizedBox(
                  width: 120,
                  child: _host(
                    tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                    onController: (value) => controller = value,
                    builder: (context, value) => BLabTabBar(
                      controller: value,
                      tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                      isScrollable: true,
                      onTap: calls.add,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        expect(controller.index, 4);
        expect(calls, isEmpty);
        _expectVisible(tester, 4);

        outside.requestFocus();
        await tester.pump();
        controller.index = 0;
        await tester.pump();
        await tester.pump(BLabMotion.durPress);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);
        _expectVisible(tester, 0);
      },
    );

    testWidgets(
      'narrow RTL Arrow Home End and external changes reveal with physical semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        final outside = FocusNode(debugLabel: 'Outside RTL overflow');
        addTearDown(outside.dispose);
        try {
          late TabController controller;
          await tester.pumpWidget(
            _harness(
              Column(
                children: [
                  Focus(
                    focusNode: outside,
                    skipTraversal: true,
                    child: const Text('Outside RTL'),
                  ),
                  SizedBox(
                    width: 120,
                    child: _host(
                      tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                      initialIndex: 2,
                      onController: (value) => controller = value,
                      builder: (context, value) => BLabTabBar(
                        controller: value,
                        tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                        isScrollable: true,
                      ),
                    ),
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
            ),
          );
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);

          await tester.sendKeyEvent(LogicalKeyboardKey.home);
          await tester.pump();
          await tester.pump(BLabMotion.durPress);
          expect(controller.index, 0);
          _expectVisible(tester, 0);
          var root = _rootSemantics(tester.getSemantics(_scrollFinder));
          expect(
            _semanticsHasAction(root, SemanticsAction.scrollRight),
            isTrue,
          );
          expect(
            _semanticsHasAction(root, SemanticsAction.scrollLeft),
            isFalse,
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.end);
          await tester.pump();
          await tester.pump(BLabMotion.durPress);
          expect(controller.index, 4);
          _expectVisible(tester, 4);
          root = _rootSemantics(tester.getSemantics(_scrollFinder));
          expect(_semanticsHasAction(root, SemanticsAction.scrollLeft), isTrue);
          expect(
            _semanticsHasAction(root, SemanticsAction.scrollRight),
            isFalse,
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();
          await tester.pump(BLabMotion.durPress);
          expect(controller.index, 3);
          _expectVisible(tester, 3);

          outside.requestFocus();
          await tester.pump();
          controller.index = 2;
          await tester.pump();
          await tester.pump(BLabMotion.durPress);
          expect(FocusManager.instance.primaryFocus, outside);
          _expectVisible(tester, 2);
          root = _rootSemantics(tester.getSemantics(_scrollFinder));
          expect(_semanticsHasAction(root, SemanticsAction.scrollLeft), isTrue);
          expect(
            _semanticsHasAction(root, SemanticsAction.scrollRight),
            isTrue,
          );
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'manual horizontal scroll and vertical drag are neutral with native semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final outside = FocusNode(debugLabel: 'Outside manual');
        addTearDown(outside.dispose);
        final calls = <int>[];
        var verticalUpdates = 0;
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            Focus(
              focusNode: outside,
              child: GestureDetector(
                onVerticalDragUpdate: (_) => verticalUpdates += 1,
                child: SizedBox(
                  width: 120,
                  child: _host(
                    tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                    onController: (value) => controller = value,
                    builder: (context, value) => BLabTabBar(
                      controller: value,
                      tabs: const ['Zero', 'One', 'Two', 'Three', 'Four'],
                      isScrollable: true,
                      onTap: calls.add,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        outside.requestFocus();
        await tester.pump();
        await tester.drag(_scrollFinder, const Offset(-60, 0));
        await tester.pumpAndSettle();
        final scroll = tester.widget<SingleChildScrollView>(_scrollFinder);
        expect(scroll.controller!.offset, greaterThan(0));
        expect(controller.index, 0);
        expect(FocusManager.instance.primaryFocus, outside);
        expect(calls, isEmpty);

        var root = tester.getSemantics(_scrollFinder);
        while (root.parent != null) {
          root = root.parent!;
        }
        expect(_semanticsHasAction(root, SemanticsAction.scrollLeft), isTrue);

        final offset = scroll.controller!.offset;
        await tester.drag(_scrollFinder, const Offset(0, -40));
        await tester.pump();
        expect(verticalUpdates, greaterThan(0));
        expect(scroll.controller!.offset, offset);
        expect(calls, isEmpty);
        semantics.dispose();
      },
    );

    testWidgets(
      'normal motion uses 300 and 150ms; reduced motion is immediate',
      (tester) async {
        late TabController controller;
        await tester.pumpWidget(
          _harness(
            _host(
              tabs: const ['One', 'Two'],
              onController: (value) => controller = value,
              builder: (context, value) =>
                  BLabTabBar(controller: value, tabs: const ['One', 'Two']),
            ),
          ),
        );
        controller.index = 1;
        await tester.pump();
        expect(
          tester.widget<AnimatedPositioned>(_indicatorFinder).duration,
          BLabMotion.durSurface,
        );
        expect(
          tester
              .widget<AnimatedContainer>(
                find.byKey(
                  const ValueKey<String>('BLabTabBar.item.1.interaction'),
                ),
              )
              .duration,
          BLabMotion.durPress,
        );

        await tester.pumpWidget(
          _harness(
            _host(
              tabs: const ['One', 'Two'],
              initialIndex: 1,
              builder: (context, value) =>
                  BLabTabBar(controller: value, tabs: const ['One', 'Two']),
            ),
            disableAnimations: true,
          ),
        );
        expect(
          tester.widget<AnimatedPositioned>(_indicatorFinder).duration,
          Duration.zero,
        );
        expect(
          tester
              .widget<AnimatedContainer>(
                find.byKey(
                  const ValueKey<String>('BLabTabBar.item.1.interaction'),
                ),
              )
              .duration,
          Duration.zero,
        );
      },
    );
  });
}

Widget _host({
  Key? key,
  required List<String> tabs,
  int initialIndex = 0,
  ValueChanged<TabController>? onController,
  required Widget Function(BuildContext context, TabController controller)
  builder,
}) {
  return _ControllerHost(
    key: key,
    tabs: tabs,
    initialIndex: initialIndex,
    onController: onController,
    builder: builder,
  );
}

class _ControllerHost extends StatefulWidget {
  const _ControllerHost({
    super.key,
    required this.tabs,
    required this.initialIndex,
    required this.onController,
    required this.builder,
  });

  final List<String> tabs;
  final int initialIndex;
  final ValueChanged<TabController>? onController;
  final Widget Function(BuildContext context, TabController controller) builder;

  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost>
    with SingleTickerProviderStateMixin {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(
      length: widget.tabs.length,
      initialIndex: widget.initialIndex,
      vsync: this,
    );
    widget.onController?.call(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, controller);
}

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

Finder _targetFinder(int index) =>
    find.byKey(ValueKey<String>('BLabTabBar.item.$index.target'));

Finder _focusOutlineFinder(int index) =>
    find.byKey(ValueKey<String>('BLabTabBar.item.$index.focusOutline'));

Finder _focusRingFinder(int index) =>
    find.byKey(ValueKey<String>('BLabTabBar.item.$index.focusRing'));

final _tabBarSemanticsFinder = find.byKey(
  const ValueKey<String>('BLabTabBar.semantics'),
);

Finder _itemSemanticsFinder(int index) =>
    find.byKey(ValueKey<String>('BLabTabBar.item.$index.semantics'));

final _indicatorFinder = find.byKey(
  const ValueKey<String>('BLabTabBar.indicator'),
);
final _dividerFinder = find.byKey(const ValueKey<String>('BLabTabBar.divider'));
final _scrollFinder = find.byKey(
  const ValueKey<String>('BLabTabBar.horizontalScroll'),
);

BoxDecoration _decoration(WidgetTester tester, String suffix) =>
    _keyDecoration(tester, 'BLabTabBar.$suffix');

BoxDecoration _itemDecoration(WidgetTester tester, int index, String suffix) =>
    _keyDecoration(tester, 'BLabTabBar.item.$index.$suffix');

BoxDecoration _keyDecoration(WidgetTester tester, String key) =>
    switch (tester.widget<Widget>(find.byKey(ValueKey<String>(key)))) {
      final AnimatedContainer widget => widget.decoration as BoxDecoration,
      final DecoratedBox widget => widget.decoration as BoxDecoration,
      final widget => throw StateError(
        'Unexpected TabBar decoration widget: ${widget.runtimeType}',
      ),
    };

void _expectVisible(WidgetTester tester, int index) {
  final viewport = tester.getRect(_scrollFinder);
  final target = tester.getRect(_targetFinder(index));
  expect(target.left, greaterThanOrEqualTo(viewport.left - 0.01));
  expect(target.right, lessThanOrEqualTo(viewport.right + 0.01));
}

void _expectNotFullyVisible(WidgetTester tester, int index) {
  final viewport = tester.getRect(_scrollFinder);
  final target = tester.getRect(_targetFinder(index));
  expect(
    target.left < viewport.left - 0.01 || target.right > viewport.right + 0.01,
    isTrue,
  );
}

TextStyle _inheritedTextStyle(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style;

SemanticsNode _rootSemantics(SemanticsNode node) {
  var root = node;
  while (root.parent != null) {
    root = root.parent!;
  }
  return root;
}

bool _semanticsHasAction(SemanticsNode node, SemanticsAction action) {
  if (node.getSemanticsData().hasAction(action)) return true;
  return node
      .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
      .any((child) => _semanticsHasAction(child, action));
}

Color _composite(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

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

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize + (fontSize * fontSize / 100);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;
}

const _modes = <_Mode>[
  _Mode(
    label: 'light',
    brightness: Brightness.light,
    highContrast: false,
    surface: Color(0xFFFAFAFA),
    raisedSurface: Color(0xFFFFFFFF),
    overlaySurface: Color(0xFFFFFFFF),
    container: Color(0x00000000),
    indicator: Color(0xFF000000),
    selected: Color(0xFF000000),
    unselected: Color(0xDD000000),
    hover: Color(0x14000000),
    pressed: Color(0x1F000000),
    focusOutline: Color(0xFF000000),
    focusRing: Color(0xFF5B7FFF),
  ),
  _Mode(
    label: 'dark',
    brightness: Brightness.dark,
    highContrast: false,
    surface: Color(0xFF121212),
    raisedSurface: Color(0xFF1E1E1E),
    overlaySurface: Color(0xFF1E1E1E),
    container: Color(0x00000000),
    indicator: Color(0xFFFFFFFF),
    selected: Color(0xFFFFFFFF),
    unselected: Color(0xDDFFFFFF),
    hover: Color(0x14FFFFFF),
    pressed: Color(0x1FFFFFFF),
    focusOutline: Color(0xFFFFFFFF),
    focusRing: Color(0xFF5B7FFF),
  ),
  _Mode(
    label: 'high-contrast-light',
    brightness: Brightness.light,
    highContrast: true,
    surface: Color(0xFFFFFFFF),
    raisedSurface: Color(0xFFFFFFFF),
    overlaySurface: Color(0xFFFFFFFF),
    container: Color(0x00000000),
    indicator: Color(0xFF000000),
    selected: Color(0xFF000000),
    unselected: Color(0xFF000000),
    hover: Color(0x1F000000),
    pressed: Color(0x33000000),
    focusOutline: Color(0xFF000000),
    focusRing: Color(0xFF000000),
  ),
  _Mode(
    label: 'high-contrast-dark',
    brightness: Brightness.dark,
    highContrast: true,
    surface: Color(0xFF121212),
    raisedSurface: Color(0xFF121212),
    overlaySurface: Color(0xFF121212),
    container: Color(0x00000000),
    indicator: Color(0xFFFFFFFF),
    selected: Color(0xFFFFFFFF),
    unselected: Color(0xFFFFFFFF),
    hover: Color(0x1FFFFFFF),
    pressed: Color(0x33FFFFFF),
    focusOutline: Color(0xFFFFFFFF),
    focusRing: Color(0xFFFFFFFF),
  ),
];

class _Mode {
  const _Mode({
    required this.label,
    required this.brightness,
    required this.highContrast,
    required this.surface,
    required this.raisedSurface,
    required this.overlaySurface,
    required this.container,
    required this.indicator,
    required this.selected,
    required this.unselected,
    required this.hover,
    required this.pressed,
    required this.focusOutline,
    required this.focusRing,
  });

  final String label;
  final Brightness brightness;
  final bool highContrast;
  final Color surface;
  final Color raisedSurface;
  final Color overlaySurface;
  final Color container;
  final Color indicator;
  final Color selected;
  final Color unselected;
  final Color hover;
  final Color pressed;
  final Color focusOutline;
  final Color focusRing;

  Map<String, Color> get surfaces => <String, Color>{
    'base': surface,
    'raised': raisedSurface,
    'overlay': overlaySurface,
  };
}
