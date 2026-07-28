import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/haptic_policy.dart';
import '../foundation/interactive_target.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';

void _noopPressableTap() {}

class BLabPressableWrapper extends StatefulWidget {
  final Widget child;

  /// Legacy non-null callback surface retained for source compatibility.
  ///
  /// When the constructor receives `onTap: null`, this field is a stable no-op.
  /// It must not be used to infer whether this widget is actionable; internal
  /// interaction and semantics use the nullable constructor input instead.
  final VoidCallback onTap;
  final VoidCallback? _onTapInput;
  final VoidCallback? onLongPress;
  final double scaleEnd;
  final double brightnessEnd;
  final Duration animationDuration;
  final bool enableHaptic;
  final String? semanticLabel;
  final String? semanticHint;
  final BorderRadius? borderRadius;
  final BLabHapticConfiguration hapticConfiguration;

  /// Creates a pressable wrapper.
  ///
  /// The required nullable [onTap] input is the source of truth for tap
  /// actionability. A null input keeps pointer, keyboard, focus, and semantic
  /// tap behavior inert even though the legacy public [onTap] field remains a
  /// non-null no-op for source compatibility.
  const BLabPressableWrapper({
    super.key,
    required this.child,
    required VoidCallback? onTap,
    this.onLongPress,
    this.scaleEnd = 0.96,
    this.brightnessEnd = 0.1,
    this.animationDuration = BLabMotion.durPress,
    this.enableHaptic = true,
    this.semanticLabel,
    this.semanticHint,
    this.borderRadius,
    this.hapticConfiguration = BLabHapticConfiguration.disabled,
  }) : onTap = onTap ?? _noopPressableTap,
       _onTapInput = onTap;

  /// Nullable callback used by all actual interaction and semantic behavior.
  ///
  /// This deliberately does not fall back to the public legacy [onTap] field.
  VoidCallback? get _effectiveOnTap => _onTapInput;

  @override
  State<BLabPressableWrapper> createState() => _BLabPressableWrapperState();
}

class _BLabPressableWrapperState extends State<BLabPressableWrapper>
    with WidgetsBindingObserver {
  static const double _legacyDefaultBrightness = 0.1;

  final BLabKeyboardActivationController _keyboardController =
      BLabKeyboardActivationController();
  final BLabHapticActionCycle _hapticCycle = BLabHapticActionCycle();
  final FocusNode _focusNode = FocusNode(debugLabel: 'BLabPressableWrapper');

  bool _hovered = false;
  bool _pointerPressed = false;
  bool _keyboardPressed = false;
  PointerDeviceKind? _pointerKind;

  bool get _actionable =>
      widget._effectiveOnTap != null || widget.onLongPress != null;
  bool get _pressed => _pointerPressed || _keyboardPressed;
  VoidCallback? get _primaryAction =>
      widget._effectiveOnTap ?? widget.onLongPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(BLabPressableWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_actionable) {
      _keyboardController.reset();
      _resetInteractionState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _keyboardController.reset();
    _resetInteractionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _keyboardController.reset();
    _hapticCycle.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _keyboardController.reset();
      _keyboardPressed = false;
    }
    if (mounted) setState(() {});
  }

  void _resetInteractionState() {
    if (!mounted) return;
    setState(() {
      _hovered = false;
      _pointerPressed = false;
      _keyboardPressed = false;
      _pointerKind = null;
    });
  }

  void _registerPointer(
    BLabFocusVisibilityController focusVisibility,
    PointerDownEvent event,
  ) {
    focusVisibility.registerPointer(event.kind);
    _pointerKind = event.kind;
    _hapticCycle.resetForNextAction();
  }

  KeyEventResult _handleKeyEvent(
    BLabFocusVisibilityController focusVisibility,
    FocusNode node,
    KeyEvent event,
  ) {
    focusVisibility.registerKeyboardIntent(
      event.logicalKey,
      shiftPressed: HardwareKeyboard.instance.isShiftPressed,
    );
    final isActivationKey =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (isActivationKey && event is KeyDownEvent && _actionable) {
      setState(() => _keyboardPressed = true);
    } else if (isActivationKey && event is KeyUpEvent) {
      setState(() => _keyboardPressed = false);
    }
    return _keyboardController.handleKeyEvent(
      event,
      onActivate: () => _commit(_primaryAction, BLabHapticTrigger.keyboard),
      enabled: _actionable,
    );
  }

  void _commit(VoidCallback? callback, BLabHapticTrigger trigger) {
    if (callback == null) return;
    final decision = _hapticCycle.resolveCommittedAction(
      intent: BLabHapticIntent.action,
      trigger: trigger,
      configuration: widget.hapticConfiguration,
      enabled: widget.enableHaptic,
    );
    if (decision.shouldTrigger) {
      HapticFeedback.selectionClick();
    }
    callback();
  }

  void _validateSemantics() {
    final label = widget.semanticLabel;
    final hint = widget.semanticHint;
    if (label != null && label.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'semanticLabel',
        'An actionable semantic label must be nonblank.',
      );
    }
    if (hint != null && hint.trim().isEmpty) {
      throw ArgumentError.value(
        hint,
        'semanticHint',
        'A semantic hint must be nonblank.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _validateSemantics();
    if (BLabFocusVisibilityScope.maybeOf(context) == null) {
      return BLabFocusVisibilityScope(
        child: Builder(builder: _buildInteraction),
      );
    }
    return _buildInteraction(context);
  }

  Widget _buildInteraction(BuildContext context) {
    final focusVisibility = BLabFocusVisibilityScope.of(context);
    final tokens = BLabVisualModeResolver.of(context).tokens;
    final radius = widget.borderRadius ?? BLabRadius.mdRect;
    final showFocus = focusVisibility.shouldShowVisibleFocus(
      hasFocus: _focusNode.hasFocus,
    );
    final duration = BLabReducedMotionPolicy.of(context).resolve(
      duration: widget.animationDuration,
      role: BLabTransitionRole.nonEssential,
    );
    final pressedColor = widget.brightnessEnd == _legacyDefaultBrightness
        ? tokens.pressablePressedOverlay
        : tokens.pressablePressedOverlay.withValues(
            alpha: widget.brightnessEnd,
          );
    final interactionColor = _pressed
        ? pressedColor
        : _hovered
        ? tokens.pressableHoverOverlay
        : Colors.transparent;

    final focusedContent = Stack(
      clipBehavior: Clip.none,
      children: [
        if (showFocus)
          Positioned.fill(
            left: -tokens.focusRingWidth,
            top: -tokens.focusRingWidth,
            right: -tokens.focusRingWidth,
            bottom: -tokens.focusRingWidth,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>('BLabPressable.focusRing'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.pressableFocusOuterRing,
                    width: tokens.focusRingWidth,
                  ),
                  borderRadius: _expandRadius(radius, tokens.focusRingWidth),
                ),
              ),
            ),
          ),
        Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  key: const ValueKey<String>('BLabPressable.interaction'),
                  duration: duration,
                  curve: BLabMotion.ease,
                  decoration: BoxDecoration(
                    color: interactionColor,
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showFocus)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>('BLabPressable.focusOutline'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.pressableFocusOutline,
                    width: tokens.focusOutlineWidth,
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
      ],
    );

    final visual = BLabInteractiveTarget(
      child: AnimatedScale(
        key: const ValueKey<String>('BLabPressable.scale'),
        duration: duration,
        curve: BLabMotion.ease,
        scale: _pressed ? widget.scaleEnd : 1,
        child: focusedContent,
      ),
    );

    return Semantics(
      key: const ValueKey<String>('BLabPressable.semantics'),
      container: true,
      excludeSemantics: widget.semanticLabel != null,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: widget._effectiveOnTap == null ? null : true,
      focusable: _actionable,
      focused: _actionable ? _focusNode.hasFocus : null,
      onTap: widget._effectiveOnTap == null
          ? null
          : () =>
                _commit(widget._effectiveOnTap, BLabHapticTrigger.programmatic),
      onLongPress: widget.onLongPress == null
          ? null
          : () => _commit(widget.onLongPress, BLabHapticTrigger.programmatic),
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: _actionable,
        onKeyEvent: (node, event) =>
            _handleKeyEvent(focusVisibility, node, event),
        child: MouseRegion(
          cursor: _actionable
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: _actionable
              ? (event) {
                  if (event.kind != PointerDeviceKind.touch) {
                    setState(() => _hovered = true);
                  }
                }
              : null,
          onExit: (_) {
            if (_hovered) setState(() => _hovered = false);
          },
          child: Listener(
            onPointerDown: _actionable
                ? (event) => _registerPointer(focusVisibility, event)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown:
                  widget._effectiveOnTap != null || widget.onLongPress != null
                  ? (_) => setState(() => _pointerPressed = true)
                  : null,
              onTapCancel: _actionable
                  ? () => setState(() => _pointerPressed = false)
                  : null,
              onTapUp: !_actionable
                  ? null
                  : (_) => setState(() => _pointerPressed = false),
              onTap: widget._effectiveOnTap == null
                  ? null
                  : () {
                      setState(() => _pointerPressed = false);
                      _commit(
                        widget._effectiveOnTap,
                        _pointerKind == PointerDeviceKind.touch
                            ? BLabHapticTrigger.touch
                            : BLabHapticTrigger.pointer,
                      );
                    },
              onLongPressStart: widget.onLongPress == null
                  ? null
                  : (_) => setState(() => _pointerPressed = true),
              onLongPressCancel: widget.onLongPress == null
                  ? null
                  : () => setState(() => _pointerPressed = false),
              onLongPressEnd: widget.onLongPress == null
                  ? null
                  : (_) => setState(() => _pointerPressed = false),
              onLongPress: widget.onLongPress == null
                  ? null
                  : () => _commit(
                      widget.onLongPress,
                      _pointerKind == PointerDeviceKind.touch
                          ? BLabHapticTrigger.touch
                          : BLabHapticTrigger.pointer,
                    ),
              child: visual,
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _expandRadius(BorderRadius radius, double amount) {
    Radius expand(Radius value) =>
        Radius.elliptical(value.x + amount, value.y + amount);
    return BorderRadius.only(
      topLeft: expand(radius.topLeft),
      topRight: expand(radius.topRight),
      bottomLeft: expand(radius.bottomLeft),
      bottomRight: expand(radius.bottomRight),
    );
  }
}
