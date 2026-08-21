import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/haptic_policy.dart';
import '../foundation/interactive_target.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_glass.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/blab_token_theme.dart';

enum BLabButtonVariant { primary, secondary, destructive }

class BLabButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BLabButtonVariant variant;
  final bool isFullWidth;
  final Widget? child;
  final BLabHapticConfiguration hapticConfiguration;

  const BLabButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = BLabButtonVariant.primary,
    this.isFullWidth = false,
    this.child,
    this.hapticConfiguration = BLabHapticConfiguration.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final interaction = _BLabButtonInteraction(button: this);
    if (BLabFocusVisibilityScope.maybeOf(context) != null) {
      return interaction;
    }
    return BLabFocusVisibilityScope(child: interaction);
  }
}

class _BLabButtonInteraction extends StatefulWidget {
  const _BLabButtonInteraction({required this.button});

  final BLabButton button;

  @override
  State<_BLabButtonInteraction> createState() => _BLabButtonInteractionState();
}

class _BLabButtonInteractionState extends State<_BLabButtonInteraction>
    with WidgetsBindingObserver {
  final BLabKeyboardActivationController _keyboardController =
      BLabKeyboardActivationController();
  final BLabHapticActionCycle _hapticCycle = BLabHapticActionCycle();
  final FocusNode _focusNode = FocusNode(debugLabel: 'BLabButton');

  bool _hovered = false;
  bool _pointerPressed = false;
  bool _keyboardPressed = false;
  PointerDeviceKind? _pointerKind;

  bool get _enabled => widget.button.onPressed != null;
  bool get _pressed => _pointerPressed || _keyboardPressed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_BLabButtonInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled) return;
    _keyboardController.reset();
    _resetInteractionState();
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
    if (isActivationKey && event is KeyDownEvent && _enabled) {
      setState(() => _keyboardPressed = true);
    } else if (isActivationKey && event is KeyUpEvent) {
      setState(() => _keyboardPressed = false);
    }

    return _keyboardController.handleKeyEvent(
      event,
      onActivate: () => _activate(BLabHapticTrigger.keyboard),
      enabled: _enabled,
    );
  }

  void _handlePointerDown(
    BLabFocusVisibilityController focusVisibility,
    PointerDownEvent event,
  ) {
    focusVisibility.registerPointer(event.kind);
    _pointerKind = event.kind;
    _hapticCycle.resetForNextAction();
  }

  void _activate(BLabHapticTrigger trigger) {
    final onPressed = widget.button.onPressed;
    if (onPressed == null) return;

    final intent = widget.button.variant == BLabButtonVariant.destructive
        ? BLabHapticIntent.destructive
        : BLabHapticIntent.action;
    final decision = _hapticCycle.resolveCommittedAction(
      intent: intent,
      trigger: trigger,
      configuration: widget.button.hapticConfiguration,
    );
    if (decision.shouldTrigger) {
      HapticFeedback.selectionClick();
    }
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final button = widget.button;
    final visualMode = BLabVisualModeResolver.of(context);
    final tokens = visualMode.tokens;
    final highContrast =
        visualMode.mode == BLabVisualMode.highContrastLight ||
        visualMode.mode == BLabVisualMode.highContrastDark;
    final focusOutlineColor = switch (button.variant) {
      BLabButtonVariant.primary => tokens.buttonPrimaryFocusOutline,
      BLabButtonVariant.secondary => tokens.buttonSecondaryFocusOutline,
      BLabButtonVariant.destructive => tokens.buttonDestructiveFocusOutline,
    };
    final focusRingColor = tokens.buttonFocusOuterRing;
    final focusVisibility = BLabFocusVisibilityScope.of(context);
    final showFocus = focusVisibility.shouldShowVisibleFocus(
      hasFocus: _focusNode.hasFocus,
    );
    final reducedMotion = BLabReducedMotionPolicy.of(context);
    final interactionDuration = reducedMotion.resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );

    final backgroundColor = switch (button.variant) {
      BLabButtonVariant.primary => tokens.actionPrimary,
      BLabButtonVariant.destructive => tokens.actionDestructive,
      BLabButtonVariant.secondary =>
        highContrast ? tokens.glassSurface : BLabGlass.fill(context),
    };
    final textColor = switch (button.variant) {
      BLabButtonVariant.primary => tokens.actionPrimaryForeground,
      BLabButtonVariant.destructive => tokens.actionDestructiveForeground,
      BLabButtonVariant.secondary => tokens.textPrimary,
    };
    final borderColor = button.variant == BLabButtonVariant.secondary
        ? (highContrast ? tokens.borderDefault : BLabGlass.border(context))
        : Colors.transparent;
    final hoverOverlayColor = switch (button.variant) {
      BLabButtonVariant.primary => tokens.buttonPrimaryHoverOverlay,
      BLabButtonVariant.secondary => tokens.buttonSecondaryHoverOverlay,
      BLabButtonVariant.destructive => tokens.buttonDestructiveHoverOverlay,
    };
    final overlayColor = _pressed
        ? const Color(0x1AFFFFFF)
        : _hovered
        ? hoverOverlayColor
        : Colors.transparent;

    final content = ClipRRect(
      borderRadius: BLabRadius.mdRect,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: highContrast ? tokens.glassBlur : BLabGlass.blur,
          sigmaY: highContrast ? tokens.glassBlur : BLabGlass.blur,
        ),
        child: SizedBox(
          width: button.isFullWidth ? double.infinity : null,
          child: DecoratedBox(
            key: const ValueKey<String>('BLabButton.surface'),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BLabRadius.mdRect,
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: button.child == null
                      ? Row(
                          mainAxisSize: button.isFullWidth
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (button.icon != null) ...[
                              Icon(button.icon, color: textColor, size: 20),
                              SizedBox(width: BLabSpacing.sm),
                            ],
                            Flexible(
                              child: Text(
                                button.text,
                                style: BLabTypography.button.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      : IconTheme.merge(
                          data: IconThemeData(color: textColor),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: textColor),
                            child: button.child!,
                          ),
                        ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      key: const ValueKey<String>(
                        'BLabButton.interactionAnimation',
                      ),
                      duration: interactionDuration,
                      curve: BLabMotion.ease,
                      decoration: BoxDecoration(
                        color: overlayColor,
                        borderRadius: BLabRadius.mdRect,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

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
                key: const ValueKey<String>('BLabButton.focusRing'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: focusRingColor,
                    width: tokens.focusRingWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    BLabRadius.md + tokens.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
        content,
        if (showFocus)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>('BLabButton.focusOutline'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: focusOutlineColor,
                    width: tokens.focusOutlineWidth,
                  ),
                  borderRadius: BLabRadius.mdRect,
                ),
              ),
            ),
          ),
      ],
    );

    final target = BLabInteractiveTarget(
      child: AnimatedScale(
        key: const ValueKey<String>('BLabButton.pressScale'),
        duration: interactionDuration,
        curve: BLabMotion.ease,
        scale: _pressed ? 0.96 : 1,
        child: focusedContent,
      ),
    );
    final visual = _enabled ? target : Opacity(opacity: 0.5, child: target);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: button.text,
      button: true,
      enabled: _enabled,
      focusable: _enabled,
      focused: _enabled ? _focusNode.hasFocus : null,
      onTap: _enabled ? () => _activate(BLabHapticTrigger.programmatic) : null,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: _enabled,
        onKeyEvent: (node, event) =>
            _handleKeyEvent(focusVisibility, node, event),
        child: MouseRegion(
          cursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: _enabled
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
            onPointerDown: _enabled
                ? (event) => _handlePointerDown(focusVisibility, event)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown: _enabled
                  ? (_) => setState(() => _pointerPressed = true)
                  : null,
              onTapCancel: _enabled
                  ? () => setState(() => _pointerPressed = false)
                  : null,
              onTapUp: _enabled
                  ? (_) => setState(() => _pointerPressed = false)
                  : null,
              onTap: _enabled
                  ? () => _activate(
                      _pointerKind == PointerDeviceKind.touch
                          ? BLabHapticTrigger.touch
                          : BLabHapticTrigger.pointer,
                    )
                  : null,
              child: visual,
            ),
          ),
        ),
      ),
    );
  }
}
