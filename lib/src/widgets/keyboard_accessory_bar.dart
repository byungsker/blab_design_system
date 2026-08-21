import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/blab_token_theme.dart';

/// A host-placed keyboard accessory surface with independent button actions.
///
/// The host owns safe-area, keyboard-inset, and overlay placement. Optional
/// semantic labels let products override the platform-derived legacy names
/// with localized action-specific copy.
class BLabKeyboardAccessoryBar extends StatefulWidget {
  final VoidCallback onDone;
  final bool isDark;
  final IconData? icon;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCopy;
  final VoidCallback? onClearAll;
  final bool showNavigation;
  final bool canGoUp;
  final bool canGoDown;
  final bool canUndo;
  final bool canRedo;
  final bool canCopy;
  final bool canClearAll;
  final String? upSemanticLabel;
  final String? downSemanticLabel;
  final String? copySemanticLabel;
  final String? clearAllSemanticLabel;
  final String? undoSemanticLabel;
  final String? redoSemanticLabel;
  final String? doneSemanticLabel;

  const BLabKeyboardAccessoryBar({
    super.key,
    required this.onDone,
    required this.isDark,
    this.icon,
    this.onUp,
    this.onDown,
    this.onUndo,
    this.onRedo,
    this.onCopy,
    this.onClearAll,
    this.showNavigation = false,
    this.canGoUp = true,
    this.canGoDown = true,
    this.canUndo = false,
    this.canRedo = false,
    this.canCopy = false,
    this.canClearAll = false,
    this.upSemanticLabel,
    this.downSemanticLabel,
    this.copySemanticLabel,
    this.clearAllSemanticLabel,
    this.undoSemanticLabel,
    this.redoSemanticLabel,
    this.doneSemanticLabel,
  });

  @override
  State<BLabKeyboardAccessoryBar> createState() =>
      _BLabKeyboardAccessoryBarState();
}

enum _KeyboardAccessoryAction { undo, redo }

class _BLabKeyboardAccessoryBarState extends State<BLabKeyboardAccessoryBar>
    with WidgetsBindingObserver {
  static const Duration _initialRepeatDelay = Duration(milliseconds: 500);
  static const Duration _repeatInterval = Duration(milliseconds: 100);
  static const double _horizontalPadding = 32;
  static const double _actionExtent = 48;
  static const double _dividerExtent = 1;
  static const Map<String, double> _logicalActionOrder = <String, double>{
    'up': 0,
    'down': 1,
    'copy': 2,
    'clearAll': 3,
    'undo': 4,
    'redo': 5,
    'done': 6,
  };

  final BLabFocusVisibilityController _focusVisibility =
      BLabFocusVisibilityController();
  final ScrollController _overflowController = ScrollController();
  final GlobalKey _overflowViewportKey = GlobalKey(
    debugLabel: 'KeyboardAccessory overflow viewport',
  );
  final Map<String, GlobalKey<_KeyboardAccessoryButtonState>> _actionKeys = {
    for (final id in const <String>[
      'up',
      'down',
      'copy',
      'clearAll',
      'undo',
      'redo',
      'done',
    ])
      id: GlobalKey<_KeyboardAccessoryButtonState>(
        debugLabel: 'KeyboardAccessory $id',
      ),
  };
  final Map<String, GlobalKey> _actionRevealKeys = {
    for (final id in const <String>[
      'up',
      'down',
      'copy',
      'clearAll',
      'undo',
      'redo',
      'done',
    ])
      id: GlobalKey(debugLabel: 'KeyboardAccessory $id reveal target'),
  };

  Timer? _repeatDelayTimer;
  Timer? _repeatCadenceTimer;
  _KeyboardAccessoryAction? _repeatingAction;
  bool _hasOverflow = false;
  double? _overflowMaxWidth;
  String _overflowComposition = '';
  TextDirection? _overflowDirection;
  Duration _overflowRevealDuration = BLabMotion.durPress;
  String? _focusedActionId;
  int _scheduledRevealGeneration = 0;

  bool get _repeatActive => _repeatingAction != null;

  @override
  void initState() {
    super.initState();
    _validateSemanticLabels();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(BLabKeyboardAccessoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateSemanticLabels();
    final repeatingAction = _repeatingAction;
    if (repeatingAction == null) return;
    final callbackChanged = switch (repeatingAction) {
      _KeyboardAccessoryAction.undo => !identical(
        oldWidget.onUndo,
        widget.onUndo,
      ),
      _KeyboardAccessoryAction.redo => !identical(
        oldWidget.onRedo,
        widget.onRedo,
      ),
    };
    if (callbackChanged || !_isRepeatActionEnabled(repeatingAction)) {
      _stopRepeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _stopRepeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelRepeatTimers();
    _scheduledRevealGeneration += 1;
    _overflowController.dispose();
    _focusVisibility.dispose();
    super.dispose();
  }

  void _validateSemanticLabels() {
    final labels = <String, String?>{
      'upSemanticLabel': widget.upSemanticLabel,
      'downSemanticLabel': widget.downSemanticLabel,
      'copySemanticLabel': widget.copySemanticLabel,
      'clearAllSemanticLabel': widget.clearAllSemanticLabel,
      'undoSemanticLabel': widget.undoSemanticLabel,
      'redoSemanticLabel': widget.redoSemanticLabel,
      'doneSemanticLabel': widget.doneSemanticLabel,
    };
    for (final entry in labels.entries) {
      final value = entry.value;
      if (value != null && value.trim().isEmpty) {
        throw ArgumentError.value(
          value,
          entry.key,
          'A supplied semantic label must be nonblank.',
        );
      }
    }
  }

  bool _isRepeatActionEnabled(_KeyboardAccessoryAction action) {
    return switch (action) {
      _KeyboardAccessoryAction.undo => widget.onUndo != null && widget.canUndo,
      _KeyboardAccessoryAction.redo => widget.onRedo != null && widget.canRedo,
    };
  }

  VoidCallback? _repeatCallback(_KeyboardAccessoryAction action) {
    return switch (action) {
      _KeyboardAccessoryAction.undo => widget.onUndo,
      _KeyboardAccessoryAction.redo => widget.onRedo,
    };
  }

  void _startRepeat(_KeyboardAccessoryAction action) {
    _stopRepeat();
    if (!_isRepeatActionEnabled(action)) return;
    _repeatingAction = action;
    if (mounted) setState(() {});
    _invokeRepeatAction();
    if (_repeatingAction != action) return;
    _repeatDelayTimer = Timer(_initialRepeatDelay, () {
      if (_repeatingAction != action) return;
      _invokeRepeatAction();
      if (_repeatingAction != action) return;
      _repeatCadenceTimer = Timer.periodic(_repeatInterval, (_) {
        if (_repeatingAction != action) return;
        _invokeRepeatAction();
      });
    });
  }

  void _invokeRepeatAction() {
    final action = _repeatingAction;
    if (action == null || !_isRepeatActionEnabled(action)) {
      _stopRepeat();
      return;
    }
    final callback = _repeatCallback(action);
    if (callback == null) {
      _stopRepeat();
      return;
    }
    try {
      callback();
    } on Object {
      _stopRepeat();
      rethrow;
    }
  }

  void _cancelRepeatTimers() {
    _repeatDelayTimer?.cancel();
    _repeatCadenceTimer?.cancel();
    _repeatDelayTimer = null;
    _repeatCadenceTimer = null;
  }

  void _stopRepeat() {
    final wasActive = _repeatActive;
    _cancelRepeatTimers();
    _repeatingAction = null;
    if (wasActive && mounted) setState(() {});
  }

  String _resolvedLabel(String? supplied, String fallback) {
    return supplied?.trim() ?? fallback.trim();
  }

  void _handleActionFocusChange(String id, bool hasFocus) {
    if (hasFocus) {
      _focusedActionId = id;
      if (id != 'done') _reveal(id, immediate: false);
    } else if (_focusedActionId == id) {
      _focusedActionId = null;
    }
  }

  void _handleAccessibilityFocus(String id) {
    if (id != 'done') _reveal(id, immediate: true);
  }

  void _registerScrollPointer(PointerEvent event) {
    _focusVisibility.registerPointer(event.kind);
  }

  void _cancelInteractionsForManualScroll() {
    _stopRepeat();
    for (final key in _actionKeys.values) {
      key.currentState?._cancelForScroll();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _cancelInteractionsForManualScroll();
    }
    return false;
  }

  void _configureOverflow({
    required bool hasOverflow,
    required double maxWidth,
    required String composition,
    required TextDirection direction,
    required Duration revealDuration,
    required Set<String> scrollingActionIds,
  }) {
    final enteringOverflow = hasOverflow && !_hasOverflow;
    final exitingOverflow = !hasOverflow && _hasOverflow;
    final directionChanged =
        _overflowDirection != null && _overflowDirection != direction;
    final geometryChanged =
        _overflowMaxWidth != maxWidth ||
        _overflowComposition != composition ||
        directionChanged;

    _hasOverflow = hasOverflow;
    _overflowMaxWidth = maxWidth;
    _overflowComposition = composition;
    _overflowDirection = direction;
    _overflowRevealDuration = revealDuration;

    if (exitingOverflow || !hasOverflow) {
      _scheduledRevealGeneration += 1;
      return;
    }
    if (!enteringOverflow && !geometryChanged) return;

    final focusedId = scrollingActionIds.contains(_focusedActionId)
        ? _focusedActionId
        : null;
    final resetToLogicalStart = enteringOverflow || directionChanged;
    final immediate = enteringOverflow || directionChanged;
    final generation = ++_scheduledRevealGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _scheduledRevealGeneration ||
          !_hasOverflow ||
          !_overflowController.hasClients) {
        return;
      }
      final position = _overflowController.position;
      if (!position.hasContentDimensions) return;
      if (resetToLogicalStart) {
        _overflowController.jumpTo(position.minScrollExtent);
      } else {
        final clamped = position.pixels.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if ((clamped - position.pixels).abs() > 0.01) {
          _overflowController.jumpTo(clamped);
        }
      }
      if (focusedId != null) {
        _reveal(focusedId, immediate: immediate);
      }
    });
  }

  void _reveal(String id, {required bool immediate}) {
    if (!_hasOverflow || !_overflowController.hasClients) return;
    final targetContext = _actionRevealKeys[id]?.currentContext;
    final viewportContext = _overflowViewportKey.currentContext;
    final targetBox = targetContext?.findRenderObject();
    final viewportBox = viewportContext?.findRenderObject();
    if (targetBox is! RenderBox || viewportBox is! RenderBox) return;

    final position = _overflowController.position;
    if (!position.hasContentDimensions) return;
    final targetRect = targetBox.localToGlobal(Offset.zero) & targetBox.size;
    final viewportRect =
        viewportBox.localToGlobal(Offset.zero) & viewportBox.size;
    double physicalDelta = 0;
    if (targetRect.left < viewportRect.left) {
      physicalDelta = targetRect.left - viewportRect.left;
    } else if (targetRect.right > viewportRect.right) {
      physicalDelta = targetRect.right - viewportRect.right;
    }
    if (physicalDelta.abs() <= 0.01) return;

    final targetOffset = switch (position.axisDirection) {
      AxisDirection.right => position.pixels + physicalDelta,
      AxisDirection.left => position.pixels - physicalDelta,
      _ => position.pixels,
    }.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((targetOffset - position.pixels).abs() <= 0.01) return;

    if (immediate || _overflowRevealDuration == Duration.zero) {
      _overflowController.jumpTo(targetOffset);
    } else {
      unawaited(
        _overflowController.animateTo(
          targetOffset,
          duration: _overflowRevealDuration,
          curve: BLabMotion.ease,
        ),
      );
    }
  }

  List<Widget> _withDividers(
    List<Widget> actions,
    BLabTokenTheme tokens,
    String group,
  ) {
    return <Widget>[
      for (var index = 0; index < actions.length; index += 1) ...[
        if (index > 0)
          SizedBox(
            key: ValueKey<String>(
              'BLabKeyboardAccessoryBar.$group.divider.$index',
            ),
            width: 1,
            height: 20,
            child: ColoredBox(color: tokens.keyboardAccessoryDivider),
          ),
        actions[index],
      ],
    ];
  }

  Widget _button({
    required String id,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool enabled,
    required BLabTokenTheme tokens,
    required Duration interactionDuration,
    _KeyboardAccessoryAction? repeatAction,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(_logicalActionOrder[id]!),
      child: KeyedSubtree(
        key: ValueKey<String>('BLabKeyboardAccessoryBar.$id'),
        child: _KeyboardAccessoryButton(
          key: _actionKeys[id],
          revealKey: _actionRevealKeys[id]!,
          id: id,
          icon: icon,
          semanticLabel: label,
          onPressed: onPressed,
          enabled: enabled,
          tokens: tokens,
          interactionDuration: interactionDuration,
          focusVisibility: _focusVisibility,
          repeatActive:
              repeatAction != null && _repeatingAction == repeatAction,
          onFocusChange: (hasFocus) => _handleActionFocusChange(id, hasFocus),
          onAccessibilityFocus: () => _handleAccessibilityFocus(id),
          onRepeatStart: repeatAction == null
              ? null
              : () => _startRepeat(repeatAction),
          onRepeatStop: repeatAction == null ? null : _stopRepeat,
        ),
      ),
    );
  }

  Widget _surface({
    required Widget child,
    required BLabTokenTheme tokens,
    required bool highContrast,
  }) {
    final decoration = BoxDecoration(
      color: highContrast ? tokens.keyboardAccessorySurfaceStart : null,
      gradient: highContrast
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tokens.keyboardAccessorySurfaceStart,
                tokens.keyboardAccessorySurfaceEnd,
              ],
            ),
      borderRadius: BLabRadius.pillRect,
      border: Border.all(
        color: tokens.keyboardAccessoryBorder,
        width: highContrast ? 2 : 1,
      ),
      boxShadow: highContrast
          ? const <BoxShadow>[]
          : <BoxShadow>[
              BoxShadow(
                color: tokens.keyboardAccessoryShadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );
    final surface = DecoratedBox(
      key: const ValueKey<String>('BLabKeyboardAccessoryBar.surface'),
      decoration: decoration,
      child: child,
    );
    if (highContrast) return surface;
    return BackdropFilter(
      key: const ValueKey<String>('BLabKeyboardAccessoryBar.blur'),
      filter: ImageFilter.blur(
        sigmaX: tokens.keyboardAccessoryBlur,
        sigmaY: tokens.keyboardAccessoryBlur,
      ),
      child: surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = BLabVisualModeResolver.resolve(
      brightness: widget.isDark ? Brightness.dark : Brightness.light,
      highContrast: MediaQuery.highContrastOf(context),
    );
    final tokens = resolved.tokens;
    final highContrast =
        resolved.mode == BLabVisualMode.highContrastLight ||
        resolved.mode == BLabVisualMode.highContrastDark;
    final interactionDuration = BLabReducedMotionPolicy.of(context).resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );
    final material = MaterialLocalizations.of(context);
    final cupertino = CupertinoLocalizations.of(context);
    final direction = Directionality.of(context);

    final leadingActions = <Widget>[
      if (widget.showNavigation)
        _button(
          id: 'up',
          icon: CupertinoIcons.chevron_up,
          label: _resolvedLabel(
            widget.upSemanticLabel,
            material.previousPageTooltip,
          ),
          onPressed: widget.onUp ?? () {},
          enabled: widget.onUp != null && widget.canGoUp,
          tokens: tokens,
          interactionDuration: interactionDuration,
        ),
      if (widget.showNavigation)
        _button(
          id: 'down',
          icon: CupertinoIcons.chevron_down,
          label: _resolvedLabel(
            widget.downSemanticLabel,
            material.nextPageTooltip,
          ),
          onPressed: widget.onDown ?? () {},
          enabled: widget.onDown != null && widget.canGoDown,
          tokens: tokens,
          interactionDuration: interactionDuration,
        ),
      if (widget.onCopy != null)
        _button(
          id: 'copy',
          icon: CupertinoIcons.doc_on_doc,
          label: _resolvedLabel(
            widget.copySemanticLabel,
            material.copyButtonLabel,
          ),
          onPressed: widget.onCopy!,
          enabled: widget.canCopy,
          tokens: tokens,
          interactionDuration: interactionDuration,
        ),
      if (widget.onClearAll != null)
        _button(
          id: 'clearAll',
          icon: CupertinoIcons.trash,
          label: _resolvedLabel(
            widget.clearAllSemanticLabel,
            cupertino.clearButtonLabel,
          ),
          onPressed: widget.onClearAll!,
          enabled: widget.canClearAll,
          tokens: tokens,
          interactionDuration: interactionDuration,
        ),
    ];
    final historyActions = <Widget>[
      if (widget.onUndo != null)
        _button(
          id: 'undo',
          icon: direction == TextDirection.ltr
              ? CupertinoIcons.arrow_uturn_left
              : CupertinoIcons.arrow_uturn_right,
          label: _resolvedLabel(
            widget.undoSemanticLabel,
            LogicalKeyboardKey.undo.keyLabel,
          ),
          onPressed: widget.onUndo!,
          enabled: widget.canUndo,
          tokens: tokens,
          interactionDuration: interactionDuration,
          repeatAction: _KeyboardAccessoryAction.undo,
        ),
      if (widget.onRedo != null)
        _button(
          id: 'redo',
          icon: direction == TextDirection.ltr
              ? CupertinoIcons.arrow_uturn_right
              : CupertinoIcons.arrow_uturn_left,
          label: _resolvedLabel(
            widget.redoSemanticLabel,
            LogicalKeyboardKey.redo.keyLabel,
          ),
          onPressed: widget.onRedo!,
          enabled: widget.canRedo,
          tokens: tokens,
          interactionDuration: interactionDuration,
          repeatAction: _KeyboardAccessoryAction.redo,
        ),
    ];
    final doneAction = _button(
      id: 'done',
      icon: widget.icon ?? CupertinoIcons.keyboard_chevron_compact_down,
      label: _resolvedLabel(
        widget.doneSemanticLabel,
        material.closeButtonLabel,
      ),
      onPressed: widget.onDone,
      enabled: true,
      tokens: tokens,
      interactionDuration: interactionDuration,
    );
    final trailingActions = <Widget>[...historyActions, doneAction];

    return LayoutBuilder(
      builder: (context, constraints) {
        final leadingCount = leadingActions.length;
        final historyCount = historyActions.length;
        final hasScrollingActions = leadingCount + historyCount > 0;
        final leadingDividerCount = leadingCount > 0 ? leadingCount - 1 : 0;
        final requiredWidth =
            _horizontalPadding +
            _actionExtent * (leadingCount + historyCount + 1) +
            _dividerExtent * leadingDividerCount +
            _dividerExtent * historyCount;
        final minimumValidHostWidth =
            _horizontalPadding +
            _actionExtent +
            (hasScrollingActions ? _actionExtent : 0) +
            (historyCount > 0 ? _dividerExtent : 0);
        assert(() {
          if (constraints.maxWidth.isFinite &&
              constraints.maxWidth < minimumValidHostWidth) {
            throw FlutterError.fromParts([
              ErrorSummary(
                'BLabKeyboardAccessoryBar host width is below the valid '
                'minimum.',
              ),
              ErrorDescription(
                'This action composition requires at least '
                '${minimumValidHostWidth}px, but received a finite maxWidth '
                'of ${constraints.maxWidth}px.',
              ),
              ErrorHint(
                'Allocate 80px for Done only, 128px when leading actions are '
                'rendered without history, or 129px when Undo or Redo is '
                'rendered. Non-Done actions require one full 48px viewport; '
                'history also requires the 1px divider before Done.',
              ),
            ]);
          }
          return true;
        }());
        final hasOverflow =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth < requiredWidth &&
            hasScrollingActions;
        final scrollingActionIds = <String>{
          if (widget.showNavigation) 'up',
          if (widget.showNavigation) 'down',
          if (widget.onCopy != null) 'copy',
          if (widget.onClearAll != null) 'clearAll',
          if (widget.onUndo != null) 'undo',
          if (widget.onRedo != null) 'redo',
        };
        final composition = scrollingActionIds.join('|');
        _configureOverflow(
          hasOverflow: hasOverflow,
          maxWidth: constraints.maxWidth,
          composition: composition,
          direction: direction,
          revealDuration: interactionDuration,
          scrollingActionIds: scrollingActionIds,
        );

        final fixedContent = Row(
          children: [
            ..._withDividers(leadingActions, tokens, 'leading'),
            const Spacer(),
            ..._withDividers(trailingActions, tokens, 'trailing'),
          ],
        );
        final overflowContent = Row(
          children: [
            Expanded(
              child: Listener(
                onPointerDown: _registerScrollPointer,
                onPointerSignal: (event) {
                  _registerScrollPointer(event);
                  _cancelInteractionsForManualScroll();
                },
                onPointerPanZoomStart: (event) {
                  _registerScrollPointer(event);
                  _cancelInteractionsForManualScroll();
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: ClipRect(
                    key: _overflowViewportKey,
                    child: SingleChildScrollView(
                      key: const ValueKey<String>(
                        'BLabKeyboardAccessoryBar.horizontalOverflow',
                      ),
                      controller: _overflowController,
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._withDividers(leadingActions, tokens, 'leading'),
                          ..._withDividers(historyActions, tokens, 'history'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (historyActions.isNotEmpty)
              SizedBox(
                key: const ValueKey<String>(
                  'BLabKeyboardAccessoryBar.pinnedDoneDivider',
                ),
                width: 1,
                height: 20,
                child: ColoredBox(color: tokens.keyboardAccessoryDivider),
              ),
            doneAction,
          ],
        );

        final component = BLabFocusVisibilityScope(
          controller: _focusVisibility,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Padding(
              key: const ValueKey<String>(
                'BLabKeyboardAccessoryBar.hostPlacement',
              ),
              padding: EdgeInsets.symmetric(
                horizontal: BLabSpacing.md,
                vertical: BLabSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: BLabRadius.pillRect,
                child: _surface(
                  tokens: tokens,
                  highContrast: highContrast,
                  child: hasOverflow ? overflowContent : fixedContent,
                ),
              ),
            ),
          ),
        );
        if (!constraints.maxWidth.isFinite) {
          return SizedBox(width: requiredWidth, child: component);
        }
        return component;
      },
    );
  }
}

class _KeyboardAccessoryButton extends StatefulWidget {
  const _KeyboardAccessoryButton({
    super.key,
    required this.revealKey,
    required this.id,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.enabled,
    required this.tokens,
    required this.interactionDuration,
    required this.focusVisibility,
    required this.repeatActive,
    required this.onFocusChange,
    required this.onAccessibilityFocus,
    this.onRepeatStart,
    this.onRepeatStop,
  });

  final GlobalKey revealKey;
  final String id;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool enabled;
  final BLabTokenTheme tokens;
  final Duration interactionDuration;
  final BLabFocusVisibilityController focusVisibility;
  final bool repeatActive;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onAccessibilityFocus;
  final VoidCallback? onRepeatStart;
  final VoidCallback? onRepeatStop;

  @override
  State<_KeyboardAccessoryButton> createState() =>
      _KeyboardAccessoryButtonState();
}

class _KeyboardAccessoryButtonState extends State<_KeyboardAccessoryButton> {
  final BLabKeyboardActivationController _keyboardActivation =
      BLabKeyboardActivationController();
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'KeyboardAccessory ${widget.id}',
  );

  bool _hovered = false;
  bool _pointerPressed = false;
  bool _keyboardPressed = false;

  bool get _pressed =>
      _pointerPressed || _keyboardPressed || widget.repeatActive;

  bool get _showsFocus => widget.focusVisibility.shouldShowVisibleFocus(
    hasFocus: _focusNode.hasFocus,
  );

  @override
  void initState() {
    super.initState();
    widget.focusVisibility.addListener(_handleVisualChange);
  }

  @override
  void didUpdateWidget(_KeyboardAccessoryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.focusVisibility, widget.focusVisibility)) {
      oldWidget.focusVisibility.removeListener(_handleVisualChange);
      widget.focusVisibility.addListener(_handleVisualChange);
    }
    if (!widget.enabled && oldWidget.enabled) {
      _keyboardActivation.reset();
      _clearInteraction();
      widget.onRepeatStop?.call();
    }
  }

  @override
  void dispose() {
    widget.focusVisibility.removeListener(_handleVisualChange);
    _keyboardActivation.reset();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleVisualChange() {
    if (mounted) setState(() {});
  }

  void _clearInteraction() {
    if (!_hovered && !_pointerPressed && !_keyboardPressed) return;
    setState(() {
      _hovered = false;
      _pointerPressed = false;
      _keyboardPressed = false;
    });
  }

  void _handleFocusChange(bool hasFocus) {
    if (!hasFocus) {
      _keyboardActivation.reset();
      _keyboardPressed = false;
    }
    if (mounted) setState(() {});
    widget.onFocusChange(hasFocus);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    widget.focusVisibility.registerKeyboardIntent(event.logicalKey);
    final isActivationKey =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (isActivationKey) {
      if (event is KeyDownEvent && widget.enabled) {
        setState(() => _keyboardPressed = true);
      } else if (event is KeyUpEvent || !widget.enabled) {
        setState(() => _keyboardPressed = false);
      }
    }
    return _keyboardActivation.handleKeyEvent(
      event,
      onActivate: widget.onPressed,
      enabled: widget.enabled,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    widget.focusVisibility.registerPointer(event.kind);
    if (!widget.enabled) return;
    widget.onRepeatStop?.call();
    _focusNode.requestFocus();
    setState(() => _pointerPressed = true);
  }

  void _handlePointerEnd() {
    widget.onRepeatStop?.call();
    if (_pointerPressed && mounted) {
      setState(() => _pointerPressed = false);
    }
  }

  void _cancelForScroll() {
    _keyboardActivation.reset();
    if (!_pointerPressed && !_keyboardPressed) return;
    setState(() {
      _pointerPressed = false;
      _keyboardPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final interactionColor = !widget.enabled
        ? Colors.transparent
        : _pressed
        ? widget.tokens.keyboardAccessoryPressedOverlay
        : _hovered
        ? widget.tokens.keyboardAccessoryHoverOverlay
        : Colors.transparent;

    return Semantics(
      key: ValueKey<String>('BLabKeyboardAccessoryBar.${widget.id}.semantics'),
      container: true,
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onPressed : null,
      onDidGainAccessibilityFocus: widget.onAccessibilityFocus,
      excludeSemantics: true,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: widget.enabled,
        skipTraversal: !widget.enabled,
        onFocusChange: _handleFocusChange,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: widget.enabled
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: (_) => _clearInteraction(),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePointerDown,
            onPointerUp: (_) => _handlePointerEnd(),
            onPointerCancel: (_) => _handlePointerEnd(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? widget.onPressed : null,
              onTapCancel: _handlePointerEnd,
              onTapUp: (_) => _handlePointerEnd(),
              onLongPressStart: widget.enabled && widget.onRepeatStart != null
                  ? (_) => widget.onRepeatStart!.call()
                  : null,
              onLongPressEnd: widget.onRepeatStop == null
                  ? null
                  : (_) => widget.onRepeatStop!.call(),
              onLongPressCancel: widget.onRepeatStop,
              child: ConstrainedBox(
                key: ValueKey<String>(
                  'BLabKeyboardAccessoryBar.${widget.id}.minimumTarget',
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: SizedBox(
                  key: widget.revealKey,
                  width: 48,
                  height: 48,
                  child: SizedBox(
                    key: ValueKey<String>(
                      'BLabKeyboardAccessoryBar.${widget.id}.target',
                    ),
                    width: 48,
                    height: 48,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedContainer(
                          key: ValueKey<String>(
                            'BLabKeyboardAccessoryBar.'
                            '${widget.id}.interaction',
                          ),
                          duration: widget.interactionDuration,
                          curve: BLabMotion.ease,
                          decoration: BoxDecoration(
                            color: interactionColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (_showsFocus)
                          DecoratedBox(
                            key: ValueKey<String>(
                              'BLabKeyboardAccessoryBar.${widget.id}.focusRing',
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget
                                    .tokens
                                    .keyboardAccessoryFocusOuterRing,
                                width: widget.tokens.focusRingWidth,
                              ),
                            ),
                          ),
                        if (_showsFocus)
                          Positioned.fill(
                            left: widget.tokens.focusRingWidth,
                            top: widget.tokens.focusRingWidth,
                            right: widget.tokens.focusRingWidth,
                            bottom: widget.tokens.focusRingWidth,
                            child: DecoratedBox(
                              key: ValueKey<String>(
                                'BLabKeyboardAccessoryBar.'
                                '${widget.id}.focusOutline',
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget
                                      .tokens
                                      .keyboardAccessoryFocusOutline,
                                  width: widget.tokens.focusOutlineWidth,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: widget.enabled
                                ? widget.tokens.keyboardAccessoryForeground
                                : widget
                                      .tokens
                                      .keyboardAccessoryDisabledForeground,
                          ),
                        ),
                      ],
                    ),
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
