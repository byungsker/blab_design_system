import 'dart:async';

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BLabSnackbar compatibility and visual states', () {
    testWidgets('preserves legacy defaults and renders four distinct types', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final icons = <IconData>{};

      for (final type in BLabSnackbarType.values) {
        final controller = BLabSnackbar.showManaged(
          harness.context,
          message: type.name,
          type: type,
        );
        await _finishEntry(tester);

        expect(
          find.byKey(ValueKey<String>('BLabSnackbar.badge.${type.name}')),
          findsOneWidget,
        );
        icons.add(
          tester
              .widgetList<Icon>(
                find.descendant(
                  of: find.byKey(
                    ValueKey<String>('BLabSnackbar.badge.${type.name}'),
                  ),
                  matching: find.byType(Icon),
                ),
              )
              .single
              .icon!,
        );
        controller.dismiss();
        await _finishExit(tester);
      }

      expect(icons, hasLength(4));
      expect(BLabSnackbarType.values, [
        BLabSnackbarType.success,
        BLabSnackbarType.error,
        BLabSnackbarType.info,
        BLabSnackbarType.warning,
      ]);
    });

    testWidgets('uses opaque semantic surface without glass decoration', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      BLabSnackbar.show(harness.context, message: 'Opaque');
      await _finishEntry(tester);

      final material = tester.widget<Material>(
        find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
      );
      expect(material.color, const Color(0xFFFFFFFF));
      expect(material.color!.a, 1);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('uses exact Snackbar tokens in all four visual modes', (
      tester,
    ) async {
      const cases = <(Brightness, bool, BLabTokenTheme)>[
        (Brightness.light, false, BLabTokenTheme.light),
        (Brightness.dark, false, BLabTokenTheme.dark),
        (Brightness.light, true, BLabTokenTheme.highContrastLight),
        (Brightness.dark, true, BLabTokenTheme.highContrastDark),
      ];

      for (final (brightness, highContrast, tokens) in cases) {
        final harness = await _pumpHarness(
          tester,
          brightness: brightness,
          mediaQuery: MediaQueryData(
            size: const Size(800, 800),
            highContrast: highContrast,
          ),
        );
        final controller = BLabSnackbar.showManaged(
          harness.context,
          message: '${brightness.name}-$highContrast',
          persist: true,
        );
        await _finishEntry(tester);

        final material = tester.widget<Material>(
          find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
        );
        final shape = material.shape! as RoundedRectangleBorder;
        final text = tester.widget<Text>(
          find.byKey(const ValueKey<String>('BLabSnackbar.message')),
        );
        final badge = tester.widget<Container>(
          find.byKey(const ValueKey<String>('BLabSnackbar.badge.success')),
        );
        final badgeDecoration = badge.decoration! as BoxDecoration;
        final decoration = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey<String>('BLabSnackbar.decoration')),
        );
        final boxDecoration = decoration.decoration as BoxDecoration;

        expect(material.color, tokens.snackbarSurface);
        expect(material.color!.a, 1);
        expect(text.style!.color, tokens.snackbarForeground);
        expect(shape.side.color, tokens.snackbarBorder);
        expect(shape.side.width, highContrast ? 2 : 1);
        expect(badgeDecoration.color, tokens.snackbarBadgeSuccess);
        if (highContrast) {
          expect(badgeDecoration.border, isNotNull);
          expect(
            (badgeDecoration.border! as Border).top.color,
            tokens.snackbarBadgeOutline,
          );
          expect((badgeDecoration.border! as Border).top.width, 2);
          expect(boxDecoration.boxShadow, isEmpty);
        } else {
          expect(badgeDecoration.border, isNull);
          expect(boxDecoration.boxShadow, isNotEmpty);
        }
        expect(find.byType(BackdropFilter), findsNothing);

        controller.dismiss();
        await _finishExit(tester);
      }
    });
  });

  group('BLabSnackbar semantics, controls, and focus', () {
    testWidgets('creates one visible message-only live region', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpHarness(tester);
      BLabSnackbar.showManaged(
        harness.context,
        message: 'Upload complete',
        action: BLabSnackbarAction(label: 'View', onPressed: () {}),
        showDismissAction: true,
        dismissSemanticLabel: 'Dismiss upload notice',
      );

      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('BLabSnackbar.liveRegion')),
        findsNothing,
      );
      await _finishEntry(tester);

      final liveRegions = find.byKey(
        const ValueKey<String>('BLabSnackbar.liveRegion'),
      );
      expect(liveRegions, findsOneWidget);
      final properties = tester.widget<Semantics>(liveRegions).properties;
      expect(properties.liveRegion, isTrue);
      expect(properties.label, 'Upload complete');
      expect(find.semantics.byLabel('View'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey<String>('BLabSnackbar.dismiss')),
            )
            .label,
        contains('Dismiss upload notice'),
      );
      semantics.dispose();
    });

    testWidgets('sends one explicit polite announcement when supported', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          size: Size(800, 800),
          supportsAnnounce: true,
        ),
      );
      tester.takeAnnouncements();
      BLabSnackbar.showManaged(
        harness.context,
        message: 'Polite update',
        persist: true,
      );

      await _finishEntry(tester);
      final liveRegion = find.byKey(
        const ValueKey<String>('BLabSnackbar.liveRegion'),
      );
      expect(liveRegion, findsOneWidget);
      expect(
        MediaQuery.of(tester.element(liveRegion)).supportsAnnounce,
        isTrue,
      );
      expect(
        tester.widget<Semantics>(liveRegion).properties.liveRegion,
        isFalse,
      );
      final announcements = tester.takeAnnouncements();
      expect(announcements, hasLength(1));
      expect(announcements.single.message, 'Polite update');
      expect(announcements.single.assertiveness, Assertiveness.polite);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey<String>('BLabSnackbar.liveRegion')),
            )
            .properties
            .liveRegion,
        isFalse,
      );
      await tester.pump();
      expect(tester.takeAnnouncements(), isEmpty);
      semantics.dispose();
    });

    testWidgets('sends one explicit assertive announcement when requested', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          size: Size(800, 800),
          supportsAnnounce: true,
        ),
      );
      tester.takeAnnouncements();
      BLabSnackbar.showManaged(
        harness.context,
        message: 'Assertive update',
        announcementPriority: BLabSnackbarAnnouncementPriority.assertive,
        persist: true,
      );

      await _finishEntry(tester);
      final announcements = tester.takeAnnouncements();
      expect(announcements, hasLength(1));
      expect(announcements.single.message, 'Assertive update');
      expect(announcements.single.assertiveness, Assertiveness.assertive);
      expect(
        tester
            .widget<Semantics>(
              find.byKey(const ValueKey<String>('BLabSnackbar.liveRegion')),
            )
            .properties
            .liveRegion,
        isFalse,
      );
      semantics.dispose();
    });

    testWidgets(
      'falls back to an implicit live region without explicit event',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final harness = await _pumpHarness(
          tester,
          mediaQuery: const MediaQueryData(
            size: Size(800, 800),
            supportsAnnounce: false,
          ),
        );
        tester.takeAnnouncements();
        BLabSnackbar.showManaged(
          harness.context,
          message: 'Implicit update',
          persist: true,
        );

        await _finishEntry(tester);
        expect(tester.takeAnnouncements(), isEmpty);
        final properties = tester
            .widget<Semantics>(
              find.byKey(const ValueKey<String>('BLabSnackbar.liveRegion')),
            )
            .properties;
        expect(properties.liveRegion, isTrue);
        expect(properties.label, 'Implicit update');
        semantics.dispose();
      },
    );

    testWidgets('announcement failure does not block timeout lifecycle', (
      tester,
    ) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (_) async => throw StateError('announcement unavailable'),
      );
      addTearDown(
        () => messenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
      );
      final harness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          size: Size(800, 800),
          supportsAnnounce: true,
        ),
      );
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Failed announcement',
        duration: const Duration(milliseconds: 50),
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);

      await _finishEntry(tester);
      await tester.pump(const Duration(milliseconds: 60));
      await _finishExit(tester);
      expect(reason, BLabSnackbarClosedReason.timeout);
    });

    testWidgets('unresolved announcement does not block timeout lifecycle', (
      tester,
    ) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      final response = Completer<dynamic>();
      var announcementAttempted = false;
      messenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (_) {
          announcementAttempted = true;
          return response.future;
        },
      );
      addTearDown(() {
        if (!response.isCompleted) response.complete(null);
        messenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        );
      });
      final harness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          size: Size(800, 800),
          supportsAnnounce: true,
        ),
      );
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Unresolved announcement',
        duration: const Duration(milliseconds: 50),
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);

      await _finishEntry(tester);
      expect(announcementAttempted, isTrue);
      expect(response.isCompleted, isFalse);
      await tester.pump(const Duration(milliseconds: 60));
      await _finishExit(tester);
      expect(reason, BLabSnackbarClosedReason.timeout);
      expect(response.isCompleted, isFalse);
    });

    testWidgets('validates caller-owned control labels', (tester) async {
      final harness = await _pumpHarness(tester);

      expect(
        () => BLabSnackbarAction(label: ' \n', onPressed: () {}),
        throwsArgumentError,
      );
      expect(
        () => BLabSnackbar.showManaged(
          harness.context,
          message: 'Message',
          showDismissAction: true,
          dismissSemanticLabel: ' ',
        ),
        throwsArgumentError,
      );
    });

    testWidgets('does not steal focus and restores it conditionally', (
      tester,
    ) async {
      final prior = FocusNode(debugLabel: 'Snackbar prior focus');
      addTearDown(prior.dispose);
      final harness = await _pumpHarness(tester, priorFocus: prior);
      prior.requestFocus();
      await tester.pump();

      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Focusable',
        action: BLabSnackbarAction(
          label: 'Keep open',
          dismissOnPressed: false,
          onPressed: () {},
        ),
      );
      await tester.pump();
      await _finishEntry(tester);
      expect(FocusManager.instance.primaryFocus, prior);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(prior));
      controller.dismiss();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(FocusManager.instance.primaryFocus, prior);
    });

    testWidgets('queued Snackbar captures focus only when it becomes current', (
      tester,
    ) async {
      final firstPrior = FocusNode(debugLabel: 'First queued prior');
      final secondPrior = FocusNode(debugLabel: 'Second queued prior');
      addTearDown(firstPrior.dispose);
      addTearDown(secondPrior.dispose);
      final harness = await _pumpHarness(
        tester,
        priorFocus: firstPrior,
        alternateFocus: secondPrior,
      );
      firstPrior.requestFocus();
      await tester.pump();

      final first = BLabSnackbar.showManaged(
        harness.context,
        message: 'First queued focus',
        persist: true,
      );
      final second = BLabSnackbar.showManaged(
        harness.context,
        message: 'Second queued focus',
        persist: true,
        action: BLabSnackbarAction(
          label: 'Focus action',
          dismissOnPressed: false,
          onPressed: () {},
        ),
      );
      await _finishEntry(tester);

      secondPrior.requestFocus();
      await tester.pump();
      first.dismiss();
      await _finishExit(tester);
      await _finishEntry(tester);
      expect(FocusManager.instance.primaryFocus, secondPrior);

      _requestFocusWithin(
        tester,
        find.byKey(const ValueKey<String>('BLabSnackbar.action')),
      );
      await tester.pump();
      second.dismiss();
      await _finishExit(tester);
      expect(FocusManager.instance.primaryFocus, secondPrior);
    });

    testWidgets('does not restore over a user focus move during exit', (
      tester,
    ) async {
      final prior = FocusNode(debugLabel: 'Exit prior');
      final userTarget = FocusNode(debugLabel: 'Exit user target');
      addTearDown(prior.dispose);
      addTearDown(userTarget.dispose);
      final harness = await _pumpHarness(
        tester,
        priorFocus: prior,
        alternateFocus: userTarget,
      );
      prior.requestFocus();
      await tester.pump();

      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Exit focus move',
        persist: true,
        action: BLabSnackbarAction(
          label: 'Own focus',
          dismissOnPressed: false,
          onPressed: () {},
        ),
      );
      await _finishEntry(tester);
      _requestFocusWithin(
        tester,
        find.byKey(const ValueKey<String>('BLabSnackbar.action')),
      );
      await tester.pump();

      controller.dismiss();
      await tester.pump();
      userTarget.requestFocus();
      await tester.pump();
      await _finishExit(tester);
      expect(FocusManager.instance.primaryFocus, userTarget);
    });

    testWidgets('Escape dismisses only while Snackbar owns focus', (
      tester,
    ) async {
      final prior = FocusNode(debugLabel: 'Escape prior focus');
      addTearDown(prior.dispose);
      final harness = await _pumpHarness(tester, priorFocus: prior);
      prior.requestFocus();
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Escape',
        persist: true,
        action: BLabSnackbarAction(
          label: 'Focus me',
          dismissOnPressed: false,
          onPressed: () {},
        ),
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);
      await _finishEntry(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Escape'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _finishExit(tester);
      expect(reason, BLabSnackbarClosedReason.dismiss);
    });

    testWidgets('action and dismiss activate exactly once and meet targets', (
      tester,
    ) async {
      var actionCalls = 0;
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Controls',
        persist: true,
        action: BLabSnackbarAction(
          label: 'Undo',
          dismissOnPressed: false,
          onPressed: () => actionCalls += 1,
        ),
        showDismissAction: true,
        dismissSemanticLabel: 'Dismiss controls',
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);
      await _finishEntry(tester);

      _requestFocusWithin(
        tester,
        find.byKey(const ValueKey<String>('BLabSnackbar.action')),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(actionCalls, 2);
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('BLabSnackbar.dismiss')))
            .width,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('BLabSnackbar.dismiss')))
            .height,
        greaterThanOrEqualTo(44),
      );

      _requestFocusWithin(
        tester,
        find.byKey(const ValueKey<String>('BLabSnackbar.dismiss')),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _finishExit(tester);
      expect(reason, BLabSnackbarClosedReason.dismiss);
    });

    testWidgets('unsupported semantic states remain absent', (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Neutral semantics',
        persist: true,
        action: BLabSnackbarAction(
          label: 'Acknowledge',
          dismissOnPressed: false,
          onPressed: () {},
        ),
      );
      await tester.pump();
      await _finishEntry(tester);

      final properties = tester
          .widget<Semantics>(
            find.byKey(const ValueKey<String>('BLabSnackbar.liveRegion')),
          )
          .properties;
      expect(properties.selected, isNull);
      expect(properties.expanded, isNull);
      expect(properties.textField, isNull);
      controller.dismiss();
      await _finishExit(tester);
      semantics.dispose();
    });
  });

  group('BLabSnackbar manager and timing', () {
    testWidgets('queues FIFO with one visible record', (tester) async {
      final harness = await _pumpHarness(tester);
      final first = BLabSnackbar.showManaged(
        harness.context,
        message: 'First',
        persist: true,
      );
      final second = BLabSnackbar.showManaged(
        harness.context,
        message: 'Second',
        persist: true,
      );
      final third = BLabSnackbar.showManaged(
        harness.context,
        message: 'Third',
        persist: true,
      );
      await _finishEntry(tester);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);

      first.dismiss();
      await _finishExit(tester);
      await _finishEntry(tester);
      expect(find.text('Second'), findsOneWidget);
      second.dismiss();
      await _finishExit(tester);
      await _finishEntry(tester);
      expect(find.text('Third'), findsOneWidget);
      third.dismiss();
      await _finishExit(tester);
    });

    testWidgets('replace exits current before showing replacement', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final first = BLabSnackbar.showManaged(
        harness.context,
        message: 'Old',
        persist: true,
      );
      BLabSnackbarClosedReason? firstReason;
      first.closed.then((value) => firstReason = value);
      await _finishEntry(tester);
      final replacement = BLabSnackbar.showManaged(
        harness.context,
        message: 'New',
        persist: true,
        queuePolicy: BLabSnackbarQueuePolicy.replaceCurrent,
      );

      expect(find.text('Old'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      await _finishExit(tester);
      expect(firstReason, BLabSnackbarClosedReason.replaced);
      await _finishEntry(tester);
      expect(find.text('New'), findsOneWidget);
      replacement.dismiss();
      await _finishExit(tester);
    });

    testWidgets('drops duplicate by type, message, and action label', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final first = BLabSnackbar.showManaged(
        harness.context,
        message: 'Duplicate',
        type: BLabSnackbarType.warning,
        persist: true,
        action: BLabSnackbarAction(label: 'Retry', onPressed: () {}),
      );
      final duplicate = BLabSnackbar.showManaged(
        harness.context,
        message: 'Duplicate',
        type: BLabSnackbarType.warning,
        action: BLabSnackbarAction(label: 'Retry', onPressed: () {}),
        queuePolicy: BLabSnackbarQueuePolicy.dropDuplicate,
      );
      expect(identical(first, duplicate), isTrue);
      await _finishEntry(tester);
      expect(find.text('Duplicate'), findsOneWidget);
      first.dismiss();
      await _finishExit(tester);
    });

    testWidgets('controller dismiss is idempotent and closes once', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final reasons = <BLabSnackbarClosedReason>[];
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Programmatic',
        persist: true,
      );
      controller.closed.then(reasons.add);
      await _finishEntry(tester);
      controller
        ..dismiss()
        ..dismiss();
      await _finishExit(tester);
      expect(reasons.single, BLabSnackbarClosedReason.programmatic);
      expect(reasons, [BLabSnackbarClosedReason.programmatic]);
    });

    testWidgets('route pop closes current and pending route-owned records', (
      tester,
    ) async {
      late BuildContext rootContext;
      late BuildContext pushedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              rootContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      unawaited(
        Navigator.of(rootContext).push<void>(
          MaterialPageRoute<void>(
            builder: (context) {
              pushedContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final first = BLabSnackbar.showManaged(
        pushedContext,
        message: 'Route current',
        persist: true,
        rootOverlay: true,
      );
      final pending = BLabSnackbar.showManaged(
        pushedContext,
        message: 'Route pending',
        persist: true,
        rootOverlay: true,
      );
      BLabSnackbarClosedReason? firstReason;
      BLabSnackbarClosedReason? pendingReason;
      first.closed.then((value) => firstReason = value);
      pending.closed.then((value) => pendingReason = value);
      await _finishEntry(tester);

      Navigator.of(pushedContext).pop();
      await tester.pumpAndSettle();
      await tester.pump();
      expect(firstReason, BLabSnackbarClosedReason.routeDisposed);
      expect(pendingReason, BLabSnackbarClosedReason.routeDisposed);
      expect(find.text('Route current'), findsNothing);
      expect(find.text('Route pending'), findsNothing);
    });

    testWidgets('interactive timeout is at least four seconds', (tester) async {
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Interactive timer',
        duration: const Duration(milliseconds: 10),
        action: BLabSnackbarAction(label: 'Undo', onPressed: () {}),
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);
      await _finishEntry(tester);
      expect(
        MediaQuery.of(
          tester.element(
            find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
          ),
        ).accessibleNavigation,
        isFalse,
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('BLabSnackbar focus scope'),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(reason, isNull);
      expect(find.text('Interactive timer'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(reason, BLabSnackbarClosedReason.routeDisposed);
    });

    testWidgets('zero noninteractive duration closes with timeout reason', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Immediate timeout',
        duration: Duration.zero,
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);

      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(reason, BLabSnackbarClosedReason.timeout);
    });

    testWidgets('persist and accessible navigation suppress timeout', (
      tester,
    ) async {
      final persistentHarness = await _pumpHarness(tester);
      final persistent = BLabSnackbar.showManaged(
        persistentHarness.context,
        message: 'Persistent',
        duration: const Duration(milliseconds: 1),
        persist: true,
      );
      await _finishEntry(tester);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Persistent'), findsOneWidget);
      persistent.dismiss();
      await _finishExit(tester);

      final accessibleHarness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(accessibleNavigation: true),
      );
      final accessible = BLabSnackbar.showManaged(
        accessibleHarness.context,
        message: 'Accessible',
        duration: const Duration(milliseconds: 1),
        action: BLabSnackbarAction(label: 'Undo', onPressed: () {}),
      );
      await _finishEntry(tester);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Accessible'), findsOneWidget);
      accessible.dismiss();
      await _finishExit(tester);
    });

    testWidgets('hover and inactive lifecycle pause the timer', (tester) async {
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Paused timer',
        duration: Duration.zero,
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);
      await tester.pump();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await mouse.addPointer(
        location: tester.getCenter(
          find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
        ),
      );
      await _finishEntry(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Paused timer'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Paused timer'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(reason, BLabSnackbarClosedReason.timeout);
    });

    testWidgets('pause and resume preserves a nonzero remaining duration', (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final controller = BLabSnackbar.showManaged(
        harness.context,
        message: 'Partial timer',
        duration: const Duration(seconds: 1),
      );
      BLabSnackbarClosedReason? reason;
      controller.closed.then((value) => reason = value);
      await _finishEntry(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(
          find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(reason, isNull);

      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(reason, isNull);
      expect(find.text('Partial timer'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      await _finishExit(tester);
      await tester.pump(
        BLabMotion.durSurface + const Duration(milliseconds: 1),
      );
      await tester.pump();
      expect(reason, BLabSnackbarClosedReason.timeout);
    });
  });

  group('BLabSnackbar placement, scaling, and motion', () {
    testWidgets('uses live keyboard, safe-area, directional placement', (
      tester,
    ) async {
      late StateSetter updateMedia;
      var data = const MediaQueryData(
        viewPadding: EdgeInsets.fromLTRB(7, 0, 13, 24),
      );
      final harness = await _pumpHarness(
        tester,
        mediaQueryBuilder: (child) => StatefulBuilder(
          builder: (context, setState) {
            updateMedia = setState;
            return MediaQuery(data: data, child: child);
          },
        ),
        textDirection: TextDirection.rtl,
      );
      BLabSnackbar.showManaged(
        harness.context,
        message: 'Placement',
        aboveKeyboard: true,
        bottomOffset: 4,
        persist: true,
      );
      await _finishEntry(tester);

      var positioned = tester.widget<PositionedDirectional>(
        find.byType(PositionedDirectional),
      );
      expect(positioned.start, 33);
      expect(positioned.end, 27);
      expect(positioned.bottom, 32);

      updateMedia(() {
        data = const MediaQueryData(
          viewPadding: EdgeInsets.fromLTRB(7, 0, 13, 24),
          viewInsets: EdgeInsets.only(bottom: 280),
        );
      });
      await tester.pump();
      positioned = tester.widget<PositionedDirectional>(
        find.byType(PositionedDirectional),
      );
      expect(positioned.bottom, 288);
    });

    testWidgets('keeps ambient linear and nonlinear scaling unclamped', (
      tester,
    ) async {
      final baselineHarness = await _pumpHarness(tester);
      final baseline = BLabSnackbar.showManaged(
        baselineHarness.context,
        message: 'A message that wraps under large text scaling.',
        persist: true,
        action: BLabSnackbarAction(label: 'Action', onPressed: () {}),
      );
      await _finishEntry(tester);
      final baselineHeight = tester
          .getSize(find.byKey(const ValueKey<String>('BLabSnackbar.surface')))
          .height;
      baseline.dismiss();
      await _finishExit(tester);

      final scaledHarness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          textScaler: TextScaler.linear(2),
          size: Size(420, 800),
        ),
      );
      final scaled = BLabSnackbar.showManaged(
        scaledHarness.context,
        message: 'A message that wraps under large text scaling.',
        persist: true,
        action: BLabSnackbarAction(label: 'Action', onPressed: () {}),
      );
      await _finishEntry(tester);
      final scaledHeight = tester
          .getSize(find.byKey(const ValueKey<String>('BLabSnackbar.surface')))
          .height;
      expect(scaledHeight, greaterThan(baselineHeight));
      scaled.dismiss();
      await _finishExit(tester);

      final nonlinearHarness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(
          textScaler: _NonlinearTextScaler(),
          size: Size(420, 800),
        ),
      );
      BLabSnackbar.showManaged(
        nonlinearHarness.context,
        message: 'Nonlinear scaling remains ambient.',
        persist: true,
      );
      await _finishEntry(tester);
      final message = tester.widget<Text>(
        find.byKey(const ValueKey<String>('BLabSnackbar.message')),
      );
      expect(message.textScaler, isNull);
    });

    testWidgets('reduced motion removes translation and caps opacity', (
      tester,
    ) async {
      final harness = await _pumpHarness(
        tester,
        mediaQuery: const MediaQueryData(disableAnimations: true),
      );
      BLabSnackbar.showManaged(
        harness.context,
        message: 'Reduced motion',
        persist: true,
      );
      await tester.pump();
      await tester.pump();

      var slide = tester.widget<SlideTransition>(
        find.byKey(const ValueKey<String>('BLabSnackbar.motion')),
      );
      expect(slide.position.value, Offset.zero);
      await tester.pump(BLabMotion.durPress - const Duration(milliseconds: 1));
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('BLabSnackbar.motion')),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, lessThan(1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      slide = tester.widget<SlideTransition>(
        find.byKey(const ValueKey<String>('BLabSnackbar.motion')),
      );
      expect(slide.position.value, Offset.zero);
      expect(fade.opacity.value, 1);
    });
  });
}

class _Harness {
  const _Harness(this.context);

  final BuildContext context;
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  FocusNode? priorFocus,
  FocusNode? alternateFocus,
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(800, 800)),
  Widget Function(Widget child)? mediaQueryBuilder,
  TextDirection textDirection = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  late BuildContext context;
  final wrapMediaQuery =
      mediaQueryBuilder ??
      (Widget child) => MediaQuery(data: mediaQuery, child: child);
  final app = MaterialApp(
    theme: ThemeData(brightness: brightness),
    builder: (context, child) => wrapMediaQuery(child!),
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Builder(
          builder: (builderContext) {
            context = builderContext;
            return Column(
              children: [
                Expanded(
                  child: Focus(
                    focusNode: priorFocus,
                    child: const SizedBox.expand(),
                  ),
                ),
                if (alternateFocus != null)
                  Expanded(
                    child: Focus(
                      focusNode: alternateFocus,
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpWidget(app);
  return _Harness(context);
}

Future<void> _finishEntry(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(
    BLabMotion.durSurface * 2 + const Duration(milliseconds: 1),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _finishExit(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(
    BLabMotion.durSurface * 2 + const Duration(milliseconds: 1),
  );
  await tester.pump();
  await tester.pump();
}

void _requestFocusWithin(WidgetTester tester, Finder finder) {
  final text = find.descendant(of: finder, matching: find.byType(Text));
  final leaf = text.evaluate().isNotEmpty
      ? text.first
      : find.descendant(of: finder, matching: find.byType(Icon)).first;
  final focusContext = tester.element(leaf);
  Focus.of(focusContext).requestFocus();
}

class _NonlinearTextScaler implements TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) =>
      fontSize < 16 ? fontSize * 1.5 : fontSize * 2;

  @override
  double get textScaleFactor => 2;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    if (minScaleFactor == 0 && maxScaleFactor == double.infinity) return this;
    return TextScaler.linear(
      2.clamp(minScaleFactor, maxScaleFactor).toDouble(),
    );
  }
}
