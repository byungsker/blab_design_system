import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../foundation/interactive_target.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadow.dart';
import '../theme/app_spacing.dart';
import '../theme/blab_token_theme.dart';
import 'liquid_glass_button.dart';

enum BLabSnackbarType { success, error, info, warning }

enum BLabSnackbarAnnouncementPriority { polite, assertive }

enum BLabSnackbarQueuePolicy { enqueue, replaceCurrent, dropDuplicate }

enum BLabSnackbarClosedReason {
  timeout,
  action,
  dismiss,
  programmatic,
  replaced,
  routeDisposed,
}

@immutable
class BLabSnackbarAction {
  BLabSnackbarAction({
    required String label,
    required this.onPressed,
    this.dismissOnPressed = true,
  }) : label = _requireNonblank(label, 'label');

  final String label;
  final VoidCallback onPressed;
  final bool dismissOnPressed;
}

class BLabSnackbarController {
  BLabSnackbarController._(this._onDismiss, this._closed);

  VoidCallback? _onDismiss;
  final Future<BLabSnackbarClosedReason> _closed;
  bool _dismissRequested = false;

  Future<BLabSnackbarClosedReason> get closed => _closed;

  void dismiss() {
    final onDismiss = _onDismiss;
    if (_dismissRequested || onDismiss == null) return;
    _dismissRequested = true;
    onDismiss();
  }

  void _detach() => _onDismiss = null;
}

class BLabSnackbar {
  static final Expando<_SnackbarQueueManager> _managers =
      Expando<_SnackbarQueueManager>('BLabSnackbar.managers');

  /// 스낵바 표시
  /// [bottomOffset] - CTA 버튼이 있는 화면에서는 100 (기본값), 없는 화면에서는 32 사용
  /// [aboveKeyboard] - true면 키보드 위 8px에 표시 (bottomOffset 무시)
  static void show(
    BuildContext context, {
    required String message,
    BLabSnackbarType type = BLabSnackbarType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    bool rootOverlay = false,
    double bottomOffset = 100,
    bool aboveKeyboard = false,
  }) {
    showManaged(
      context,
      message: message,
      type: type,
      icon: icon,
      duration: duration,
      rootOverlay: rootOverlay,
      bottomOffset: bottomOffset,
      aboveKeyboard: aboveKeyboard,
    );
  }

  static BLabSnackbarController showManaged(
    BuildContext context, {
    required String message,
    BLabSnackbarType type = BLabSnackbarType.success,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    bool rootOverlay = false,
    double bottomOffset = 100,
    bool aboveKeyboard = false,
    BLabSnackbarAction? action,
    bool showDismissAction = false,
    String? dismissSemanticLabel,
    BLabSnackbarAnnouncementPriority announcementPriority =
        BLabSnackbarAnnouncementPriority.polite,
    BLabSnackbarQueuePolicy queuePolicy = BLabSnackbarQueuePolicy.enqueue,
    bool persist = false,
  }) {
    if (action != null) {
      _requireNonblank(action.label, 'action.label');
    }
    final validatedDismissLabel = showDismissAction
        ? _requireNonblank(dismissSemanticLabel, 'dismissSemanticLabel')
        : dismissSemanticLabel;
    final overlay = Overlay.of(context, rootOverlay: rootOverlay);
    final manager = _managers[overlay] ??= _SnackbarQueueManager(overlay);
    return manager.add(
      _SnackbarConfiguration(
        message: message,
        type: type,
        icon: icon,
        duration: duration,
        bottomOffset: bottomOffset,
        aboveKeyboard: aboveKeyboard,
        action: action,
        showDismissAction: showDismissAction,
        dismissSemanticLabel: validatedDismissLabel,
        announcementPriority: announcementPriority,
        persist: persist,
        textDirection: Directionality.of(context),
        routePopped: ModalRoute.of(context)?.popped,
      ),
      queuePolicy,
    );
  }
}

String _requireNonblank(String? value, String name) {
  if (value == null || value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      name,
      'A nonblank caller label is required.',
    );
  }
  return value;
}

@immutable
class _SnackbarConfiguration {
  const _SnackbarConfiguration({
    required this.message,
    required this.type,
    required this.icon,
    required this.duration,
    required this.bottomOffset,
    required this.aboveKeyboard,
    required this.action,
    required this.showDismissAction,
    required this.dismissSemanticLabel,
    required this.announcementPriority,
    required this.persist,
    required this.textDirection,
    required this.routePopped,
  });

  final String message;
  final BLabSnackbarType type;
  final IconData? icon;
  final Duration duration;
  final double bottomOffset;
  final bool aboveKeyboard;
  final BLabSnackbarAction? action;
  final bool showDismissAction;
  final String? dismissSemanticLabel;
  final BLabSnackbarAnnouncementPriority announcementPriority;
  final bool persist;
  final TextDirection textDirection;
  final Future<Object?>? routePopped;

  bool get hasControls => action != null || showDismissAction;

  bool hasSameDeduplicationKey(_SnackbarConfiguration other) {
    return type == other.type &&
        message == other.message &&
        action?.label == other.action?.label;
  }
}

class _SnackbarRecord {
  _SnackbarRecord({required this.manager, required this.configuration})
    : key = GlobalKey<_AnimatedSnackbarState>(),
      closedCompleter = Completer<BLabSnackbarClosedReason>() {
    controller = BLabSnackbarController._(
      () => manager.dismiss(this),
      closedCompleter.future,
    );
    final routePopped = configuration.routePopped;
    if (routePopped != null) {
      final weakRecord = WeakReference<_SnackbarRecord>(this);
      unawaited(
        routePopped.then((_) {
          final record = weakRecord.target;
          if (record != null) {
            record.manager.callerRouteDisposed(record);
          }
        }),
      );
    }
  }

  final _SnackbarQueueManager manager;
  final _SnackbarConfiguration configuration;
  FocusNode? previousFocus;
  final GlobalKey<_AnimatedSnackbarState> key;
  final Completer<BLabSnackbarClosedReason> closedCompleter;
  late final BLabSnackbarController controller;
  OverlayEntry? entry;
  BLabSnackbarClosedReason? pendingCloseReason;
  bool normalRemoval = false;

  bool get isClosed => closedCompleter.isCompleted;

  void complete(BLabSnackbarClosedReason reason) {
    if (isClosed) return;
    controller._detach();
    closedCompleter.complete(reason);
  }

  void requestClose(BLabSnackbarClosedReason reason) {
    if (isClosed || pendingCloseReason != null) return;
    pendingCloseReason = reason;
    key.currentState?.close(reason);
  }

  void attach(_AnimatedSnackbarState state) {
    final reason = pendingCloseReason;
    if (reason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.mounted) state.close(reason);
      });
    }
  }
}

class _SnackbarQueueManager {
  _SnackbarQueueManager(this.overlay);

  final OverlayState overlay;
  final Queue<_SnackbarRecord> _pending = Queue<_SnackbarRecord>();
  _SnackbarRecord? _current;

  BLabSnackbarController add(
    _SnackbarConfiguration configuration,
    BLabSnackbarQueuePolicy policy,
  ) {
    if (policy == BLabSnackbarQueuePolicy.dropDuplicate) {
      final duplicate = <_SnackbarRecord?>[_current, ..._pending]
          .whereType<_SnackbarRecord>()
          .where(
            (record) =>
                !record.isClosed &&
                record.configuration.hasSameDeduplicationKey(configuration),
          );
      if (duplicate.isNotEmpty) return duplicate.first.controller;
    }

    final record = _SnackbarRecord(manager: this, configuration: configuration);
    if (_current == null) {
      _show(record);
    } else if (policy == BLabSnackbarQueuePolicy.replaceCurrent) {
      _pending.addFirst(record);
      _current!.requestClose(BLabSnackbarClosedReason.replaced);
    } else {
      _pending.addLast(record);
    }
    return record.controller;
  }

  void dismiss(_SnackbarRecord record) {
    if (record.isClosed) return;
    if (identical(record, _current)) {
      record.requestClose(BLabSnackbarClosedReason.programmatic);
      return;
    }
    if (_pending.remove(record)) {
      record.complete(BLabSnackbarClosedReason.programmatic);
    }
  }

  void _show(_SnackbarRecord record) {
    if (!overlay.mounted) {
      record.complete(BLabSnackbarClosedReason.routeDisposed);
      _disposePendingForRoute();
      return;
    }
    _current = record;
    record.previousFocus = FocusManager.instance.primaryFocus;
    record.entry = OverlayEntry(
      builder: (context) => _AnimatedSnackbar(key: record.key, record: record),
    );
    overlay.insert(record.entry!);
  }

  void finish(_SnackbarRecord record, BLabSnackbarClosedReason reason) {
    if (!identical(_current, record) || record.isClosed) return;
    final restoreFocus = record.key.currentState?._ownsPrimaryFocus() ?? false;
    record.normalRemoval = true;
    final entry = record.entry;
    if (entry != null) entry.remove();
    record.entry = null;
    record.complete(reason);
    _current = null;

    if (restoreFocus) {
      final previous = record.previousFocus;
      final previousContext = previous?.context;
      if (previous != null &&
          previous.canRequestFocus &&
          previousContext != null &&
          previousContext.mounted) {
        previous.requestFocus();
      }
    }

    if (_pending.isNotEmpty) {
      _show(_pending.removeFirst());
    }
  }

  void routeDisposed(_SnackbarRecord record) {
    if (record.normalRemoval || record.isClosed) return;
    if (identical(_current, record)) {
      record.complete(BLabSnackbarClosedReason.routeDisposed);
      _current = null;
      _disposePendingForRoute();
    }
  }

  void callerRouteDisposed(_SnackbarRecord record) {
    if (record.normalRemoval || record.isClosed) return;
    if (_pending.remove(record)) {
      record.complete(BLabSnackbarClosedReason.routeDisposed);
      return;
    }
    if (!identical(_current, record)) return;
    record.normalRemoval = true;
    final entry = record.entry;
    if (entry != null) entry.remove();
    record.entry = null;
    record.complete(BLabSnackbarClosedReason.routeDisposed);
    _current = null;
    if (_pending.isNotEmpty) {
      _show(_pending.removeFirst());
    }
  }

  void _disposePendingForRoute() {
    while (_pending.isNotEmpty) {
      final record = _pending.removeFirst();
      if (!record.isClosed) {
        record.complete(BLabSnackbarClosedReason.routeDisposed);
      }
    }
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  const _AnimatedSnackbar({super.key, required this.record});

  final _SnackbarRecord record;

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late final FocusNode _focusScopeNode;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  final Stopwatch _timerElapsed = Stopwatch();
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _hovered = false;
  bool _focused = false;
  bool _visible = false;
  bool _closing = false;
  bool _actionInvoked = false;
  bool _dismissInvoked = false;
  bool _announced = false;
  bool? _lastReducedMotion;

  _SnackbarConfiguration get configuration => widget.record.configuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _focusScopeNode = FocusNode(
      debugLabel: 'BLabSnackbar focus scope',
      skipTraversal: true,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: BLabMotion.durSurface,
      reverseDuration: BLabMotion.durSurface,
    );
    _slideAnimation = const AlwaysStoppedAnimation<Offset>(Offset.zero);
    _fadeAnimation = _animationController;
    _remaining = _effectiveDuration();
    widget.record.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = BLabReducedMotionPolicy.of(context).reduceMotion;
    if (_lastReducedMotion != reducedMotion) {
      _lastReducedMotion = reducedMotion;
      final opacityDuration =
          BLabReducedMotionPolicy(reduceMotion: reducedMotion).resolve(
            duration: BLabMotion.durSurface,
            role: BLabTransitionRole.essentialOpacity,
          );
      _animationController
        ..duration = opacityDuration
        ..reverseDuration = opacityDuration;
      _slideAnimation =
          Tween<Offset>(
            begin: reducedMotion ? Offset.zero : const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: BLabMotion.ease,
              reverseCurve: BLabMotion.ease.flipped,
            ),
          );
      _fadeAnimation = CurvedAnimation(
        parent: _animationController,
        curve: BLabMotion.ease,
        reverseCurve: BLabMotion.ease.flipped,
      );
    }
    _syncTimer();
  }

  Duration _effectiveDuration() {
    final requested = configuration.duration.isNegative
        ? Duration.zero
        : configuration.duration;
    if (configuration.hasControls && requested < const Duration(seconds: 4)) {
      return const Duration(seconds: 4);
    }
    return requested;
  }

  Future<void> _enter() async {
    if (!mounted || _closing) return;
    try {
      await _animationController.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted || _closing) return;
    setState(() => _visible = true);
    _syncTimer();
    unawaited(_announceOnce());
  }

  Future<void> _announceOnce() async {
    if (_announced || !_visible) return;
    _announced = true;
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    try {
      await SemanticsService.sendAnnouncement(
        View.of(context),
        configuration.message,
        Directionality.of(context),
        assertiveness:
            configuration.announcementPriority ==
                BLabSnackbarAnnouncementPriority.assertive
            ? Assertiveness.assertive
            : Assertiveness.polite,
      );
    } on Object {
      // Announcements are best-effort and must not block Snackbar lifecycle.
    }
  }

  bool get _timeoutSuppressed {
    if (configuration.persist) return true;
    if (configuration.hasControls &&
        MediaQuery.maybeOf(context)?.accessibleNavigation == true) {
      return true;
    }
    return _hovered || _focused || _lifecycleState != AppLifecycleState.resumed;
  }

  void _syncTimer() {
    if (!mounted || !_visible || _closing || _timeoutSuppressed) {
      _pauseTimer();
      return;
    }
    if (_timer != null) return;
    if (_remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closing) {
          close(BLabSnackbarClosedReason.timeout);
        }
      });
      return;
    }
    _timerElapsed
      ..reset()
      ..start();
    _timer = Timer(_remaining, () => close(BLabSnackbarClosedReason.timeout));
  }

  void _pauseTimer() {
    final timer = _timer;
    if (timer == null) return;
    _timerElapsed.stop();
    final elapsed = _timerElapsed.elapsed;
    _remaining = elapsed >= _remaining ? Duration.zero : _remaining - elapsed;
    timer.cancel();
    _timer = null;
    _timerElapsed.reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncTimer();
  }

  Future<void> close(BLabSnackbarClosedReason reason) async {
    if (_closing || !mounted) return;
    _closing = true;
    _pauseTimer();
    if (_visible) setState(() => _visible = false);
    try {
      await _animationController.reverse().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    widget.record.manager.finish(widget.record, reason);
  }

  bool _ownsPrimaryFocus() {
    if (_focusScopeNode.hasFocus || _focused) return true;
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    if (identical(focusContext, context)) return true;
    if (focusContext.findAncestorStateOfType<_AnimatedSnackbarState>() ==
        this) {
      return true;
    }
    var owned = false;
    focusContext.visitAncestorElements((ancestor) {
      if (identical(ancestor, context)) {
        owned = true;
        return false;
      }
      return true;
    });
    return owned;
  }

  void _invokeAction() {
    if (_actionInvoked || _closing) return;
    _actionInvoked = true;
    final action = configuration.action!;
    try {
      action.onPressed();
    } finally {
      if (action.dismissOnPressed) {
        close(BLabSnackbarClosedReason.action);
      } else {
        _actionInvoked = false;
      }
    }
  }

  void _invokeDismiss() {
    if (_dismissInvoked || _closing) return;
    _dismissInvoked = true;
    close(BLabSnackbarClosedReason.dismiss);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        node.hasFocus) {
      _invokeDismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _animationController.dispose();
    _focusScopeNode.dispose();
    widget.record.manager.routeDisposed(widget.record);
    super.dispose();
  }

  IconData _icon() {
    final custom = configuration.icon;
    if (custom != null) return custom;
    return switch (configuration.type) {
      BLabSnackbarType.success => Icons.check_rounded,
      BLabSnackbarType.error => Icons.close_rounded,
      BLabSnackbarType.info => Icons.info_outline_rounded,
      BLabSnackbarType.warning => Icons.priority_high_rounded,
    };
  }

  Color _badgeColor(BLabTokenTheme tokens) {
    return switch (configuration.type) {
      BLabSnackbarType.success => tokens.snackbarBadgeSuccess,
      BLabSnackbarType.error => tokens.snackbarBadgeError,
      BLabSnackbarType.info => tokens.snackbarBadgeInfo,
      BLabSnackbarType.warning => tokens.snackbarBadgeWarning,
    };
  }

  Widget _message(BLabTokenTheme tokens) {
    final text = Text(
      configuration.message,
      key: const ValueKey<String>('BLabSnackbar.message'),
      style: TextStyle(
        color: tokens.snackbarForeground,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
    );
    if (!_visible) return ExcludeSemantics(child: text);
    final supportsExplicitAnnouncement = MediaQuery.supportsAnnounceOf(context);
    return Semantics(
      key: const ValueKey<String>('BLabSnackbar.liveRegion'),
      container: true,
      liveRegion: !supportsExplicitAnnouncement,
      label: configuration.message,
      child: ExcludeSemantics(child: text),
    );
  }

  Widget _badge(BLabTokenTheme tokens, bool highContrast) {
    return ExcludeSemantics(
      child: Container(
        key: ValueKey<String>('BLabSnackbar.badge.${configuration.type.name}'),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _badgeColor(tokens),
          border: highContrast
              ? Border.all(color: tokens.snackbarBadgeOutline, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(_icon(), color: tokens.snackbarBadgeGlyph, size: 20),
      ),
    );
  }

  Widget _controls() {
    final controls = <Widget>[
      if (configuration.action case final action?)
        BLabButton(
          key: const ValueKey<String>('BLabSnackbar.action'),
          text: action.label,
          variant: BLabButtonVariant.secondary,
          onPressed: _invokeAction,
        ),
      if (configuration.showDismissAction)
        BLabInteractiveTarget(
          child: Semantics(
            key: const ValueKey<String>('BLabSnackbar.dismiss'),
            container: true,
            button: true,
            label: configuration.dismissSemanticLabel,
            onTap: _invokeDismiss,
            excludeSemantics: true,
            child: IconButton(
              tooltip: configuration.dismissSemanticLabel,
              onPressed: _invokeDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ),
    ];
    return Wrap(
      key: const ValueKey<String>('BLabSnackbar.controls'),
      spacing: BLabSpacing.sm,
      runSpacing: BLabSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: controls,
    );
  }

  Widget _content(BLabTokenTheme tokens, bool highContrast) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(15);
        final stackControls =
            configuration.hasControls &&
            (constraints.maxWidth < 360 || scaledBody > 20);
        final message = _message(tokens);
        final leadingAndMessage = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _badge(tokens, highContrast),
            const SizedBox(width: 12),
            Expanded(child: message),
          ],
        );
        if (!configuration.hasControls) return leadingAndMessage;
        if (stackControls) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leadingAndMessage,
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _controls(),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: leadingAndMessage),
            const SizedBox(width: 12),
            _controls(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final resolved = BLabVisualModeResolver.of(context);
    final tokens = resolved.tokens;
    final highContrast =
        resolved.mode == BLabVisualMode.highContrastLight ||
        resolved.mode == BLabVisualMode.highContrastDark;
    final direction = configuration.textDirection;
    final startInset = direction == TextDirection.ltr
        ? mediaQuery.viewPadding.left
        : mediaQuery.viewPadding.right;
    final endInset = direction == TextDirection.ltr
        ? mediaQuery.viewPadding.right
        : mediaQuery.viewPadding.left;
    final bottom =
        configuration.aboveKeyboard && mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom + 8
        : configuration.bottomOffset > mediaQuery.viewPadding.bottom + 8
        ? configuration.bottomOffset
        : mediaQuery.viewPadding.bottom + 8;

    return PositionedDirectional(
      start: startInset + 20,
      end: endInset + 20,
      bottom: bottom,
      child: SlideTransition(
        key: const ValueKey<String>('BLabSnackbar.motion'),
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: MouseRegion(
            onEnter: (_) {
              _hovered = true;
              _syncTimer();
            },
            onExit: (_) {
              _hovered = false;
              _syncTimer();
            },
            child: Focus(
              focusNode: _focusScopeNode,
              canRequestFocus: true,
              onFocusChange: (focused) {
                _focused = focused;
                _syncTimer();
              },
              onKeyEvent: _handleKeyEvent,
              child: Material(
                key: const ValueKey<String>('BLabSnackbar.surface'),
                color: tokens.snackbarSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BLabRadius.lgRect,
                  side: BorderSide(
                    color: tokens.snackbarBorder,
                    width: highContrast ? 2 : 1,
                  ),
                ),
                elevation: 0,
                child: DecoratedBox(
                  key: const ValueKey<String>('BLabSnackbar.decoration'),
                  decoration: BoxDecoration(
                    borderRadius: BLabRadius.lgRect,
                    boxShadow: highContrast
                        ? const []
                        : BLabShadow.two(context),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: _content(tokens, highContrast),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
