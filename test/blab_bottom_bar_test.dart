import 'dart:ui' show Tristate;
import 'dart:math' as math;

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabBottomBar compatibility and controlled selection', () {
    testWidgets(
      'preserves legacy defaults, 62 baseline, and equal allocation',
      (tester) async {
        await tester.pumpWidget(_harness(_bar()));

        final bar = tester.widget<BLabBottomBar>(find.byType(BLabBottomBar));
        expect(bar, isA<StatefulWidget>());
        expect(bar.actionSemanticLabel, isNull);
        expect(bar.firstTabChevronSemanticLabel, isNull);
        expect(bar.firstTabChevronExpanded, isNull);
        expect(bar.noMargin, isFalse);
        expect(tester.getSize(_surfaceFinder).height, 62);

        final widths = [
          for (var index = 0; index < 3; index += 1)
            tester.getSize(_targetFinder(index)).width,
        ];
        expect(widths[0], closeTo(widths[1], 0.01));
        expect(widths[1], closeTo(widths[2], 0.01));
        for (var index = 0; index < 3; index += 1) {
          expect(
            tester.getSize(_targetFinder(index)).height,
            greaterThanOrEqualTo(44),
          );
          expect(
            tester.getSize(_targetFinder(index)).width,
            greaterThanOrEqualTo(44),
          );
        }
      },
    );

    testWidgets('selected reactivation and changed selection notify once', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(_harness(_bar(onTabSelected: calls.add)));

      await tester.tap(_targetFinder(0));
      await tester.pump();
      await tester.tap(_targetFinder(2));
      await tester.pump();

      expect(calls, [0, 2]);
    });

    testWidgets('external selection is controlled and callback-free', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final calls = <int>[];
      late StateSetter update;
      var selected = 0;
      await tester.pumpWidget(
        _harness(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return _bar(selectedIndex: selected, onTabSelected: calls.add);
            },
          ),
        ),
      );

      update(() => selected = 2);
      await tester.pump();
      expect(calls, isEmpty);
      expect(
        tester.getSemantics(_itemSemanticsFinder(2)).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });
  });

  group('BLabBottomBar semantics and optional controls', () {
    testWidgets('uses native tabBar/tab roles and product labels only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(_bar()));

      expect(
        tester.getSemantics(_semanticsFinder).getSemanticsData().role,
        SemanticsRole.tabBar,
      );
      for (var index = 0; index < 3; index += 1) {
        final node = tester.getSemantics(_itemSemanticsFinder(index));
        expect(node.getSemanticsData().role, SemanticsRole.tab);
        expect(node.label, _items[index].label);
        expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        expect(
          node.flagsCollection.isSelected,
          index == 0 ? Tristate.isTrue : Tristate.isFalse,
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    });

    testWidgets('labeled action is a separate 44x44 button', (tester) async {
      final handle = tester.ensureSemantics();
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          _bar(
            onSearchTap: (_, _) => calls += 1,
            actionSemanticLabel: 'Search carts',
          ),
        ),
      );

      final action = tester.getSemantics(_actionSemanticsFinder);
      expect(action.label, 'Search carts');
      expect(action.flagsCollection.isButton, isTrue);
      expect(
        tester.getSize(_actionTargetFinder).width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(_actionTargetFinder).height,
        greaterThanOrEqualTo(44),
      );
      tester.semantics.tap(find.semantics.byLabel('Search carts'));
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets(
      'legacy unlabeled action compiles but is excluded from semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _harness(_bar(onSearchTap: (_, _) {}, actionIcon: Icons.search)),
        );

        expect(_actionTargetFinder, findsOneWidget);
        expect(_actionSemanticsFinder, findsNothing);
        handle.dispose();
      },
    );

    testWidgets(
      'complete chevron contract creates a separate disclosure button',
      (tester) async {
        final handle = tester.ensureSemantics();
        var calls = 0;
        await tester.pumpWidget(
          _harness(
            _bar(
              showFirstTabChevron: true,
              onFirstTabChevronTap: () => calls += 1,
              firstTabChevronSemanticLabel: 'Collapse cart choices',
              firstTabChevronExpanded: true,
            ),
          ),
        );

        final disclosure = tester.getSemantics(_chevronSemanticsFinder);
        final tabBar = tester.getSemantics(_semanticsFinder);
        final directRoles = <SemanticsRole?>[];
        tabBar.visitChildren((child) {
          directRoles.add(child.getSemanticsData().role);
          return true;
        });
        expect(directRoles, everyElement(SemanticsRole.tab));
        expect(_hasAncestorRole(disclosure, SemanticsRole.tabBar), isFalse);
        expect(disclosure.label, 'Collapse cart choices');
        expect(disclosure.flagsCollection.isButton, isTrue);
        expect(disclosure.flagsCollection.isExpanded, Tristate.isTrue);
        expect(tester.getSize(_chevronTargetFinder), const Size(44, 44));
        tester.semantics.tap(find.semantics.byLabel('Collapse cart choices'));
        await tester.pump();
        expect(calls, 1);
        handle.dispose();
      },
    );

    testWidgets('blank optional-control labels stay legacy nonconformant', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final label in <String>['', '  \n']) {
        await tester.pumpWidget(
          _harness(
            _bar(
              key: ValueKey<String>(label),
              onSearchTap: (_, _) {},
              actionSemanticLabel: label,
              showFirstTabChevron: true,
              onFirstTabChevronTap: () {},
              firstTabChevronSemanticLabel: label,
              firstTabChevronExpanded: false,
            ),
          ),
        );

        expect(_actionTargetFinder, findsOneWidget);
        expect(_actionSemanticsFinder, findsNothing);
        expect(_chevronTargetFinder, findsOneWidget);
        expect(_chevronSemanticsFinder, findsNothing);
      }
      handle.dispose();
    });
  });

  group('BLabBottomBar keyboard, pointer, and drag', () {
    testWidgets('roving arrows do not select until Enter or Space', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(_harness(_bar(onTabSelected: calls.add)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'BottomBar Two');
      expect(calls, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [1, 2]);
    });

    testWidgets(
      'RTL reverses horizontal arrows while Home and End stay logical',
      (tester) async {
        await tester.pumpWidget(
          _harness(_bar(), textDirection: TextDirection.rtl),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'BottomBar Three',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'BottomBar One');
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'BottomBar Three',
        );
      },
    );

    testWidgets('pointer tap owns focus without keyboard-visible decoration', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_bar()));
      await tester.tap(_targetFinder(1));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'BottomBar Two');
      expect(_focusOutlineFinder(1), findsNothing);
      expect(_focusRingFinder(1), findsNothing);
    });

    testWidgets('pressed replaces hover while selected surface persists', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_bar()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(_targetFinder(0)));
      await tester.pump();
      expect(
        _decoration(tester, 'item.0.interaction').color,
        const Color(0x14000000),
      );
      await mouse.down(tester.getCenter(_targetFinder(0)));
      await tester.pump();
      expect(
        _decoration(tester, 'item.0.interaction').color,
        const Color(0x1F000000),
      );
      expect(_selectedFinder, findsOneWidget);
      await mouse.up();
    });

    testWidgets(
      'keyboard focus composes 2px outline and 3px ring with selection',
      (tester) async {
        await tester.pumpWidget(_harness(_bar()));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusOutlineFinder(0), findsOneWidget);
        expect(_focusRingFinder(0), findsOneWidget);
        expect(_decoration(tester, 'item.0.focusOutline').border!.top.width, 2);
        expect(_decoration(tester, 'item.0.focusRing').border!.top.width, 3);
        expect(_selectedFinder, findsOneWidget);
      },
    );

    testWidgets(
      'touch long-press drag is RTL-correct and haptics default deny',
      (tester) async {
        final channelCalls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                channelCalls.add(call);
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final calls = <int>[];
        await tester.pumpWidget(
          _harness(
            SizedBox(width: 240, child: _bar(onTabSelected: calls.add)),
            textDirection: TextDirection.rtl,
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(_targetFinder(0)),
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
        await gesture.moveTo(tester.getCenter(_targetFinder(2)));
        await tester.pump();
        await gesture.up();
        await tester.pump();
        expect(calls, [2]);
        expect(channelCalls, isEmpty);
      },
    );

    testWidgets('rejected touch drag returns to controlled selection', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(
        _harness(SizedBox(width: 240, child: _bar(onTabSelected: calls.add))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_targetFinder(0)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
      await gesture.moveTo(tester.getCenter(_targetFinder(2)));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(calls, [2]);
      expect(
        tester.getCenter(_selectedFinder).dx,
        closeTo(tester.getCenter(_targetFinder(0)).dx, 0.01),
      );
    });

    testWidgets(
      'pointer cancel clears drag and restores controlled selection',
      (tester) async {
        final calls = <int>[];
        await tester.pumpWidget(_harness(_bar(onTabSelected: calls.add)));
        final gesture = await tester.startGesture(
          tester.getCenter(_targetFinder(0)),
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
        await gesture.moveTo(tester.getCenter(_targetFinder(2)));
        await tester.pump();
        expect(
          _decoration(tester, 'item.2.interaction').color,
          const Color(0x26000000),
        );

        await gesture.cancel();
        await tester.pumpAndSettle();

        expect(calls, isEmpty);
        expect(
          _decoration(tester, 'item.2.interaction').color,
          Colors.transparent,
        );
        expect(
          tester.getCenter(_selectedFinder).dx,
          closeTo(tester.getCenter(_targetFinder(0)).dx, 0.01),
        );
      },
    );

    testWidgets('focus loss resets an incomplete Space key cycle', (
      tester,
    ) async {
      final calls = <int>[];
      await tester.pumpWidget(_harness(_bar(onTabSelected: calls.add)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(
        _decoration(tester, 'item.0.interaction').color,
        const Color(0x1F000000),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'BottomBar Two');
      expect(calls, isEmpty);
      expect(
        _decoration(tester, 'item.0.interaction').color,
        Colors.transparent,
      );
    });
  });

  group('BLabBottomBar environment and motion', () {
    testWidgets(
      'four modes resolve tokens and high contrast removes glass effects',
      (tester) async {
        for (final mode in _modes) {
          await tester.pumpWidget(
            _harness(
              _bar(key: ValueKey<String>(mode.label)),
              brightness: mode.brightness,
              highContrast: mode.highContrast,
            ),
          );
          await tester.pumpAndSettle();
          expect(_decoration(tester, 'surface').color, mode.surface);
          expect(_decoration(tester, 'selected').color, mode.selected);
          final resolvedSurface = _composite(mode.surface, mode.base);
          final resolvedSelected = _composite(mode.selected, resolvedSurface);
          expect(
            _contrastRatio(
              _composite(mode.selectedForeground, resolvedSelected),
              resolvedSelected,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${mode.label} selected text',
          );
          expect(
            _contrastRatio(
              _composite(mode.unselectedForeground, resolvedSurface),
              resolvedSurface,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${mode.label} unselected text',
          );
          for (final overlay in [mode.hover, mode.pressed]) {
            final interactionSurface = _composite(overlay, resolvedSurface);
            expect(
              _contrastRatio(
                _composite(mode.unselectedForeground, interactionSurface),
                interactionSurface,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '${mode.label} interaction text',
            );
          }
          expect(
            _contrastRatio(mode.focusOutline, resolvedSurface),
            greaterThanOrEqualTo(3),
            reason: '${mode.label} focus outline',
          );
          expect(
            _contrastRatio(mode.focusRing, mode.base),
            greaterThanOrEqualTo(3),
            reason: '${mode.label} focus ring adjacency',
          );
          expect(
            _contrastRatio(
              _composite(mode.actionForeground, resolvedSurface),
              resolvedSurface,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${mode.label} action',
          );
          expect(
            _decoration(tester, 'item.1.interaction').color,
            Colors.transparent,
          );
          expect(
            find.ancestor(
              of: _surfaceFinder,
              matching: find.byType(BackdropFilter),
            ),
            mode.highContrast ? findsNothing : findsOneWidget,
          );
        }
      },
    );

    testWidgets('ambient text scaling grows without clipping', (tester) async {
      for (final scaler in <TextScaler>[
        const TextScaler.linear(2),
        const _NonlinearScaler(),
      ]) {
        await tester.pumpWidget(
          _harness(_bar(key: ValueKey<TextScaler>(scaler)), textScaler: scaler),
        );
        expect(tester.getSize(_surfaceFinder).height, greaterThanOrEqualTo(62));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('safe-area inset stays outside the 62 baseline and noMargin', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_bar(), viewPadding: const EdgeInsets.only(bottom: 20)),
      );
      expect(tester.getSize(_surfaceFinder).height, 62);
      expect(tester.getSize(find.byType(BLabBottomBar)).height, 82);

      await tester.pumpWidget(
        _harness(
          _bar(noMargin: true),
          viewPadding: const EdgeInsets.only(bottom: 20),
        ),
      );
      expect(tester.getSize(find.byType(BLabBottomBar)).height, 62);

      await tester.pumpWidget(
        _harness(
          SafeArea(maintainBottomViewPadding: true, child: _bar()),
          viewPadding: const EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.zero,
        ),
      );
      expect(tester.getSize(find.byType(SafeArea)).height, 82);
      expect(tester.getSize(find.byType(BLabBottomBar)).height, 62);
    });

    testWidgets('zero-inset SafeArea preserves the legacy 22 fallback', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(SafeArea(child: _bar())));

      expect(tester.getSize(_surfaceFinder).height, 62);
      expect(tester.getSize(find.byType(BLabBottomBar)).height, 84);
      expect(tester.getSize(find.byType(SafeArea)).height, 84);
    });

    testWidgets(
      'nested bottom owner and bottom:false SafeArea avoid double inset',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            SafeArea(
              maintainBottomViewPadding: true,
              child: SafeArea(bottom: false, child: _bar()),
            ),
            viewPadding: const EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.zero,
          ),
        );

        expect(tester.getSize(_surfaceFinder).height, 62);
        expect(tester.getSize(find.byType(BLabBottomBar)).height, 62);
        expect(tester.getSize(find.byType(SafeArea).first).height, 82);
      },
    );

    testWidgets(
      'selection motion is standard and reduced motion is immediate',
      (tester) async {
        late StateSetter update;
        var selected = 0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return _bar(selectedIndex: selected);
              },
            ),
          ),
        );
        final start = tester.getTopLeft(_selectedFinder).dx;
        update(() => selected = 2);
        await tester.pump();
        await tester.pump(BLabMotion.durSurface ~/ 2);
        final midpoint = tester.getTopLeft(_selectedFinder).dx;
        expect(midpoint, greaterThan(start));
        expect(midpoint, lessThan(tester.getTopLeft(_targetFinder(2)).dx + 1));

        selected = 0;
        await tester.pumpWidget(
          _harness(
            StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return _bar(selectedIndex: selected);
              },
            ),
            disableAnimations: true,
          ),
        );
        update(() => selected = 2);
        await tester.pump();
        expect(
          tester.getCenter(_selectedFinder).dx,
          closeTo(tester.getCenter(_targetFinder(2)).dx, 0.01),
        );
      },
    );
  });
}

const _items = <BLabBottomBarItem>[
  BLabBottomBarItem(
    icon: CupertinoIcons.cart,
    activeIcon: CupertinoIcons.cart_fill,
    label: 'One',
  ),
  BLabBottomBarItem(
    icon: CupertinoIcons.archivebox,
    activeIcon: CupertinoIcons.archivebox_fill,
    label: 'Two',
  ),
  BLabBottomBarItem(
    icon: CupertinoIcons.person,
    activeIcon: CupertinoIcons.person_fill,
    label: 'Three',
  ),
];

BLabBottomBar _bar({
  Key? key,
  int selectedIndex = 0,
  ValueChanged<int>? onTabSelected,
  void Function(Offset, double)? onSearchTap,
  IconData? actionIcon,
  String? actionSemanticLabel,
  bool showFirstTabChevron = false,
  VoidCallback? onFirstTabChevronTap,
  String? firstTabChevronSemanticLabel,
  bool? firstTabChevronExpanded,
  bool noMargin = false,
}) {
  return BLabBottomBar(
    key: key,
    tabs: _items,
    selectedIndex: selectedIndex,
    onTabSelected: onTabSelected ?? (_) {},
    onSearchTap: onSearchTap,
    actionIcon: actionIcon,
    actionSemanticLabel: actionSemanticLabel,
    showFirstTabChevron: showFirstTabChevron,
    onFirstTabChevronTap: onFirstTabChevronTap,
    firstTabChevronSemanticLabel: firstTabChevronSemanticLabel,
    firstTabChevronExpanded: firstTabChevronExpanded,
    noMargin: noMargin,
  );
}

Widget _harness(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets viewPadding = EdgeInsets.zero,
  EdgeInsets? padding,
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
        padding: padding ?? viewPadding,
        viewPadding: viewPadding,
      ),
      child: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
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
    find.byKey(ValueKey<String>('BLabBottomBar.item.$index.target'));
Finder _itemSemanticsFinder(int index) =>
    find.byKey(ValueKey<String>('BLabBottomBar.item.$index.semantics'));
final _semanticsFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.semantics'),
);
final _surfaceFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.surface'),
);
final _selectedFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.selected'),
);
final _actionTargetFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.action.target'),
);
final _actionSemanticsFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.action.semantics'),
);
final _chevronTargetFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.chevron.target'),
);
final _chevronSemanticsFinder = find.byKey(
  const ValueKey<String>('BLabBottomBar.chevron.semantics'),
);
Finder _focusOutlineFinder(int index) =>
    find.byKey(ValueKey<String>('BLabBottomBar.item.$index.focusOutline'));
Finder _focusRingFinder(int index) =>
    find.byKey(ValueKey<String>('BLabBottomBar.item.$index.focusRing'));

bool _hasAncestorRole(SemanticsNode node, SemanticsRole role) {
  for (
    var ancestor = node.parent;
    ancestor != null;
    ancestor = ancestor.parent
  ) {
    if (ancestor.getSemanticsData().role == role) return true;
  }
  return false;
}

BoxDecoration _decoration(WidgetTester tester, String suffix) {
  final widget = tester.widget(
    find.byKey(ValueKey<String>('BLabBottomBar.$suffix')),
  );
  return switch (widget) {
    DecoratedBox() => widget.decoration as BoxDecoration,
    AnimatedContainer() => widget.decoration! as BoxDecoration,
    _ => throw StateError('Unsupported decoration widget: $widget'),
  };
}

class _Mode {
  const _Mode({
    required this.label,
    required this.brightness,
    required this.highContrast,
    required this.surface,
    required this.selected,
    required this.base,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.hover,
    required this.pressed,
    required this.focusOutline,
    required this.focusRing,
    required this.actionForeground,
  });

  final String label;
  final Brightness brightness;
  final bool highContrast;
  final Color surface;
  final Color selected;
  final Color base;
  final Color selectedForeground;
  final Color unselectedForeground;
  final Color hover;
  final Color pressed;
  final Color focusOutline;
  final Color focusRing;
  final Color actionForeground;
}

const _modes = <_Mode>[
  _Mode(
    label: 'light',
    brightness: Brightness.light,
    highContrast: false,
    surface: Color(0x14000000),
    selected: Color(0x1F000000),
    base: Color(0xFFFAFAFA),
    selectedForeground: Color(0xFF000000),
    unselectedForeground: Color(0xDD000000),
    hover: Color(0x14000000),
    pressed: Color(0x1F000000),
    focusOutline: Color(0xFF000000),
    focusRing: Color(0xFF5B7FFF),
    actionForeground: Color(0xFF000000),
  ),
  _Mode(
    label: 'dark',
    brightness: Brightness.dark,
    highContrast: false,
    surface: Color(0x1FFFFFFF),
    selected: Color(0x38FFFFFF),
    base: Color(0xFF121212),
    selectedForeground: Color(0xFFFFFFFF),
    unselectedForeground: Color(0xDDFFFFFF),
    hover: Color(0x14FFFFFF),
    pressed: Color(0x1FFFFFFF),
    focusOutline: Color(0xFFFFFFFF),
    focusRing: Color(0xFF5B7FFF),
    actionForeground: Color(0xFFFFFFFF),
  ),
  _Mode(
    label: 'high-contrast-light',
    brightness: Brightness.light,
    highContrast: true,
    surface: Color(0xFFFFFFFF),
    selected: Color(0xFF000000),
    base: Color(0xFFFAFAFA),
    selectedForeground: Color(0xFFFFFFFF),
    unselectedForeground: Color(0xFF000000),
    hover: Color(0x1F000000),
    pressed: Color(0x33000000),
    focusOutline: Color(0xFF000000),
    focusRing: Color(0xFF000000),
    actionForeground: Color(0xFF000000),
  ),
  _Mode(
    label: 'high-contrast-dark',
    brightness: Brightness.dark,
    highContrast: true,
    surface: Color(0xFF121212),
    selected: Color(0xFFFFFFFF),
    base: Color(0xFF121212),
    selectedForeground: Color(0xFF000000),
    unselectedForeground: Color(0xFFFFFFFF),
    hover: Color(0x1FFFFFFF),
    pressed: Color(0x33FFFFFF),
    focusOutline: Color(0xFFFFFFFF),
    focusRing: Color(0xFFFFFFFF),
    actionForeground: Color(0xFFFFFFFF),
  ),
];

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize < 12 ? 2.4 : 1.8);

  @override
  double get textScaleFactor => 2;
}

Color _composite(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

double _contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}
