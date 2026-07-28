import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/blab_token_theme.dart';

/// An item for [BLabSegmentedControl].
class BLabSegmentedItem<T> {
  const BLabSegmentedItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;

  /// Whether this item can receive focus and activation.
  final bool enabled;
}

/// A controlled segmented navigation control.
///
/// Selection is owned by [selectedValue]. Pointer, semantics, and keyboard
/// activation report the requested value through [onChanged]; the visual
/// selection changes only when the caller supplies a new [selectedValue].
class BLabSegmentedControl<T> extends StatelessWidget {
  const BLabSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.enabled = true,
    this.height = 40,
    this.borderRadius = BLabRadius.sm,
    this.padding = 3,
  });

  final List<BLabSegmentedItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  /// Whether every item in this control is available.
  final bool enabled;

  /// Minimum visible height of the control. Defaults to 40.
  ///
  /// The layout may grow for ambient text scaling and the interactive target
  /// remains at least 44 logical pixels high.
  final double height;

  /// Border radius of the outer container. Defaults to [BLabRadius.sm] (10).
  final double borderRadius;

  /// Padding inside the outer container. Defaults to 3.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return _BLabSegmentedControlBody<T>(
      items: items,
      selectedValue: selectedValue,
      onChanged: onChanged,
      enabled: enabled,
      height: height,
      borderRadius: borderRadius,
      padding: padding,
    );
  }
}

class _BLabSegmentedControlBody<T> extends StatefulWidget {
  const _BLabSegmentedControlBody({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.enabled,
    required this.height,
    required this.borderRadius,
    required this.padding,
  });

  final List<BLabSegmentedItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final double height;
  final double borderRadius;
  final double padding;

  @override
  State<_BLabSegmentedControlBody<T>> createState() =>
      _BLabSegmentedControlState<T>();
}

class _BLabSegmentedControlState<T> extends State<_BLabSegmentedControlBody<T>>
    with WidgetsBindingObserver {
  final BLabKeyboardActivationController _keyboardActivation =
      BLabKeyboardActivationController();
  final List<FocusNode> _focusNodes = <FocusNode>[];
  final ScrollController _scrollController = ScrollController();

  int? _rovingIndex;
  int? _hoveredIndex;
  int? _pressedIndex;
  bool _hasScrollableOverflow = false;
  double _overflowViewportWidth = 0;
  double _overflowContentWidth = 0;
  double _overflowItemWidth = 0;
  TextDirection? _overflowDirection;
  Duration _overflowRevealDuration = BLabMotion.durPress;
  int _scheduledRevealGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reconcileFocusNodes();
    _rovingIndex = _entryIndex();
  }

  @override
  void didUpdateWidget(_BLabSegmentedControlBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedValueChanged =
        oldWidget.selectedValue != widget.selectedValue;
    final focusedBefore = _focusedIndex();
    _reconcileFocusNodes();
    final focusedIndex =
        focusedBefore != null && focusedBefore < widget.items.length
        ? focusedBefore
        : null;

    if (!widget.enabled) {
      _clearTransientInteraction();
      _keyboardActivation.reset();
      if (focusedIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNodes[focusedIndex].unfocus();
        });
      }
      _rovingIndex = null;
      if (selectedValueChanged) {
        _scheduleReveal(_selectedIndex());
      }
      return;
    }

    if (focusedIndex != null && !_isEnabled(focusedIndex)) {
      final replacement = _nextThenPreviousEnabled(focusedIndex);
      _rovingIndex = replacement;
      _clearTransientInteraction();
      _keyboardActivation.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (replacement == null) {
          _focusNodes[focusedIndex].unfocus();
        } else {
          _focusNodes[replacement].requestFocus();
          _scheduleReveal(replacement);
        }
      });
      return;
    }

    if (selectedValueChanged) {
      final selected = _selectedIndex();
      final selectedEnabled = selected != null && _isEnabled(selected)
          ? selected
          : null;
      if (focusedBefore != null) {
        if (selectedEnabled != null) {
          _rovingIndex = selectedEnabled;
          if (focusedIndex != selectedEnabled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _focusNodes[selectedEnabled].requestFocus();
              _scheduleReveal(selectedEnabled);
            });
          } else {
            _scheduleReveal(selectedEnabled);
          }
        } else if (focusedIndex != null && _isEnabled(focusedIndex)) {
          _scheduleReveal(focusedIndex);
        }
      } else if (selected != null) {
        _scheduleReveal(selected);
        if (selectedEnabled != null) {
          _rovingIndex = selectedEnabled;
        }
      }
    }
    if (_rovingIndex == null || !_isEnabled(_rovingIndex!)) {
      _rovingIndex = _firstEnabledIndex();
    }

    if (_hoveredIndex != null && !_isEnabled(_hoveredIndex!)) {
      _hoveredIndex = null;
    }
    if (_pressedIndex != null && !_isEnabled(_pressedIndex!)) {
      _pressedIndex = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _keyboardActivation.reset();
    _clearTransientInteraction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardActivation.reset();
    _scheduledRevealGeneration += 1;
    _scrollController.dispose();
    for (final node in _focusNodes) {
      node
        ..removeListener(_handleFocusChange)
        ..dispose();
    }
    super.dispose();
  }

  void _reconcileFocusNodes() {
    while (_focusNodes.length < widget.items.length) {
      final index = _focusNodes.length;
      final node = FocusNode(debugLabel: widget.items[index].label)
        ..addListener(_handleFocusChange);
      _focusNodes.add(node);
    }
    while (_focusNodes.length > widget.items.length) {
      final node = _focusNodes.removeLast();
      node
        ..removeListener(_handleFocusChange)
        ..dispose();
    }
    for (var index = 0; index < _focusNodes.length; index += 1) {
      _focusNodes[index].debugLabel = widget.items[index].label;
    }
  }

  void _handleFocusChange() {
    if (_focusedIndex() == null) {
      _keyboardActivation.reset();
      _pressedIndex = null;
    }
    if (mounted) setState(() {});
  }

  void _clearTransientInteraction() {
    if (!mounted) return;
    setState(() {
      _hoveredIndex = null;
      _pressedIndex = null;
    });
  }

  bool _isEnabled(int index) => widget.enabled && widget.items[index].enabled;

  int? _focusedIndex() {
    for (var index = 0; index < _focusNodes.length; index += 1) {
      if (_focusNodes[index].hasFocus) return index;
    }
    return null;
  }

  int? _selectedIndex() {
    for (var index = 0; index < widget.items.length; index += 1) {
      if (widget.items[index].value == widget.selectedValue) return index;
    }
    return null;
  }

  int? _selectedEnabledIndex() {
    final selected = _selectedIndex();
    return selected != null && _isEnabled(selected) ? selected : null;
  }

  int? _firstEnabledIndex() {
    for (var index = 0; index < widget.items.length; index += 1) {
      if (_isEnabled(index)) return index;
    }
    return null;
  }

  int? _lastEnabledIndex() {
    for (var index = widget.items.length - 1; index >= 0; index -= 1) {
      if (_isEnabled(index)) return index;
    }
    return null;
  }

  int? _entryIndex() => _selectedEnabledIndex() ?? _firstEnabledIndex();

  int? _nextThenPreviousEnabled(int from) {
    for (var index = from + 1; index < widget.items.length; index += 1) {
      if (_isEnabled(index)) return index;
    }
    for (var index = from - 1; index >= 0; index -= 1) {
      if (_isEnabled(index)) return index;
    }
    return null;
  }

  int? _wrappedEnabled(int from, int step) {
    if (widget.items.isEmpty) return null;
    for (var distance = 1; distance <= widget.items.length; distance += 1) {
      final candidate =
          (from + step * distance + widget.items.length * distance) %
          widget.items.length;
      if (_isEnabled(candidate)) return candidate;
    }
    return null;
  }

  void _moveAndRequest(int? index) {
    if (index == null || !_isEnabled(index)) return;
    setState(() => _rovingIndex = index);
    _focusNodes[index].requestFocus();
    _scheduleReveal(index);
    widget.onChanged(widget.items[index].value);
  }

  void _activate(int index) {
    if (!_isEnabled(index)) return;
    widget.onChanged(widget.items[index].value);
  }

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    int index,
    KeyEvent event,
  ) {
    final visibility = BLabFocusVisibilityScope.of(context);
    visibility.registerKeyboardIntent(
      event.logicalKey,
      shiftPressed: HardwareKeyboard.instance.isShiftPressed,
    );

    if (!_isEnabled(index)) {
      _keyboardActivation.reset();
      return KeyEventResult.handled;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) return KeyEventResult.ignored;

    final isNavigation =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.home ||
        key == LogicalKeyboardKey.end;
    if (isNavigation) {
      if (event is KeyDownEvent) {
        final direction = Directionality.of(context);
        final target = switch (key) {
          LogicalKeyboardKey.arrowRight => _wrappedEnabled(
            index,
            direction == TextDirection.ltr ? 1 : -1,
          ),
          LogicalKeyboardKey.arrowLeft => _wrappedEnabled(
            index,
            direction == TextDirection.ltr ? -1 : 1,
          ),
          LogicalKeyboardKey.arrowUp => _wrappedEnabled(index, -1),
          LogicalKeyboardKey.arrowDown => _wrappedEnabled(index, 1),
          LogicalKeyboardKey.home => _firstEnabledIndex(),
          LogicalKeyboardKey.end => _lastEnabledIndex(),
          _ => null,
        };
        _moveAndRequest(target);
      }
      return KeyEventResult.handled;
    }

    final isActivation =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
    if (isActivation && event is KeyDownEvent) {
      setState(() => _pressedIndex = index);
    } else if (isActivation && event is KeyUpEvent) {
      setState(() => _pressedIndex = null);
    }
    return _keyboardActivation.handleKeyEvent(
      event,
      onActivate: () => _activate(index),
      enabled: _isEnabled(index),
    );
  }

  void _handlePointerDown(
    BLabFocusVisibilityController visibility,
    int index,
    PointerDownEvent event,
  ) {
    if (!_isEnabled(index)) return;
    visibility.registerPointer(event.kind);
  }

  void _handleConfirmedPointerTap(int index) {
    if (!_isEnabled(index)) return;
    setState(() => _rovingIndex = index);
    _focusNodes[index].requestFocus();
    _activate(index);
  }

  void _configureOverflow({
    required bool hasOverflow,
    required double viewportWidth,
    required double contentWidth,
    required Duration revealDuration,
    required TextDirection direction,
  }) {
    final itemWidth = widget.items.isEmpty
        ? 0.0
        : (contentWidth - widget.padding * 2) / widget.items.length;
    final geometryChanged =
        _hasScrollableOverflow != hasOverflow ||
        _overflowViewportWidth != viewportWidth ||
        _overflowContentWidth != contentWidth ||
        _overflowItemWidth != itemWidth ||
        _overflowDirection != direction;
    final firstOverflowLayout = hasOverflow && !_hasScrollableOverflow;

    _hasScrollableOverflow = hasOverflow;
    _overflowViewportWidth = viewportWidth;
    _overflowContentWidth = contentWidth;
    _overflowItemWidth = itemWidth;
    _overflowDirection = direction;
    _overflowRevealDuration = revealDuration;

    if (!hasOverflow) {
      _scheduledRevealGeneration += 1;
      return;
    }
    if (firstOverflowLayout || geometryChanged) {
      final focused = _focusedIndex();
      _scheduleReveal(
        focused != null && _isEnabled(focused) ? focused : _selectedIndex(),
        immediate: true,
      );
    }
  }

  void _scheduleReveal(int? index, {bool immediate = false}) {
    if (index == null || index < 0 || index >= widget.items.length) return;
    final generation = ++_scheduledRevealGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _scheduledRevealGeneration) return;
      _reveal(index, immediate: immediate);
    });
  }

  void _reveal(int index, {required bool immediate}) {
    if (!_hasScrollableOverflow ||
        !_scrollController.hasClients ||
        index < 0 ||
        index >= widget.items.length) {
      return;
    }
    final position = _scrollController.position;
    if (!position.hasContentDimensions || _overflowItemWidth <= 0) return;

    const focusRingAllowance = 3.0;
    final itemStart =
        widget.padding + index * _overflowItemWidth - focusRingAllowance;
    final itemEnd =
        widget.padding + (index + 1) * _overflowItemWidth + focusRingAllowance;
    final current = position.pixels;
    var target = current;
    if (itemStart < current) {
      target = itemStart;
    } else if (itemEnd > current + _overflowViewportWidth) {
      target = itemEnd - _overflowViewportWidth;
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - current).abs() <= 0.01) return;

    if (immediate || _overflowRevealDuration == Duration.zero) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: _overflowRevealDuration,
        curve: BLabMotion.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualMode = BLabVisualModeResolver.of(context);
    final highContrast =
        visualMode.mode == BLabVisualMode.highContrastLight ||
        visualMode.mode == BLabVisualMode.highContrastDark;
    final reducedMotion = BLabReducedMotionPolicy.of(context);
    final selectionDuration = reducedMotion.resolve(
      duration: BLabMotion.durSegment,
      role: BLabTransitionRole.nonEssential,
    );
    final interactionDuration = reducedMotion.resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );
    final visibility = BLabFocusVisibilityScope.of(context);
    final targetHeight = math.max(44.0, widget.height + 4);
    final innerRadius = math.max(0.0, widget.borderRadius - widget.padding);
    final minimumControlWidth = widget.items.length * 44.0 + widget.padding * 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedWidth = constraints.hasBoundedWidth;
        final availableWidth = boundedWidth
            ? constraints.maxWidth
            : minimumControlWidth;
        final contentWidth = math.max(minimumControlWidth, availableWidth);
        final frame = SizedBox(
          width: contentWidth,
          child: _buildFrame(
            context,
            contentWidth: contentWidth,
            targetHeight: targetHeight,
            innerRadius: innerRadius,
            selectionDuration: selectionDuration,
            interactionDuration: interactionDuration,
            highContrast: highContrast,
            visibility: visibility,
          ),
        );
        final hasOverflow =
            boundedWidth && minimumControlWidth > availableWidth;
        _configureOverflow(
          hasOverflow: hasOverflow,
          viewportWidth: availableWidth,
          contentWidth: contentWidth,
          revealDuration: interactionDuration,
          direction: Directionality.of(context),
        );
        if (hasOverflow) {
          return SingleChildScrollView(
            key: const ValueKey<String>(
              'BLabSegmentedControl.horizontalOverflow',
            ),
            controller: _scrollController,
            primary: false,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const ClampingScrollPhysics(),
            child: frame,
          );
        }
        return frame;
      },
    );
  }

  Widget _buildFrame(
    BuildContext context, {
    required double contentWidth,
    required double targetHeight,
    required double innerRadius,
    required Duration selectionDuration,
    required Duration interactionDuration,
    required bool highContrast,
    required BLabFocusVisibilityController visibility,
  }) {
    final tokens = BLabVisualModeResolver.of(context).tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: targetHeight),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            top: (targetHeight - widget.height) / 2,
            bottom: (targetHeight - widget.height) / 2,
            child: DecoratedBox(
              key: const ValueKey<String>('BLabSegmentedControl.container'),
              decoration: BoxDecoration(
                color: tokens.segmentedContainerSurface,
                border: Border.all(
                  color: tokens.segmentedContainerBorder,
                  width: highContrast ? 1 : 0,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var index = 0; index < widget.items.length; index += 1)
                  Expanded(
                    child: _buildItem(
                      context,
                      index: index,
                      innerRadius: innerRadius,
                      selectionDuration: selectionDuration,
                      interactionDuration: interactionDuration,
                      highContrast: highContrast,
                      visibility: visibility,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required double innerRadius,
    required Duration selectionDuration,
    required Duration interactionDuration,
    required bool highContrast,
    required BLabFocusVisibilityController visibility,
  }) {
    final item = widget.items[index];
    final tokens = BLabVisualModeResolver.of(context).tokens;
    final enabled = _isEnabled(index);
    final selected = item.value == widget.selectedValue;
    final hovered = enabled && _hoveredIndex == index;
    final pressed = enabled && _pressedIndex == index;
    final focused = enabled && _focusNodes[index].hasFocus;
    final showKeyboardFocus = visibility.shouldShowVisibleFocus(
      hasFocus: focused,
    );
    final foreground = enabled
        ? selected
              ? tokens.segmentedSelectedForeground
              : tokens.segmentedUnselectedForeground
        : tokens.segmentedDisabledForeground;
    final interaction = pressed
        ? tokens.segmentedPressedOverlay
        : hovered
        ? tokens.segmentedHoverOverlay
        : Colors.transparent;
    final indicatorColor = selected && !enabled
        ? tokens.segmentedDisabledForeground
        : tokens.segmentedSelectedIndicator;
    final itemTargetHeight = math.max(44.0, widget.height + 4);

    final surface = ConstrainedBox(
      constraints: BoxConstraints(minHeight: itemTargetHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2 + widget.padding),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                key: ValueKey<String>(
                  'BLabSegmentedControl.item.$index.surface',
                ),
                duration: selectionDuration,
                curve: BLabMotion.ease,
                decoration: BoxDecoration(
                  color: selected
                      ? tokens.segmentedSelectedSurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(innerRadius),
                  boxShadow: selected && !highContrast
                      ? [
                          BoxShadow(
                            color: tokens.segmentedSelectedShadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : const [],
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                key: ValueKey<String>(
                  'BLabSegmentedControl.item.$index.interaction',
                ),
                duration: interactionDuration,
                curve: BLabMotion.ease,
                decoration: BoxDecoration(
                  color: interaction,
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2,
              child: AnimatedOpacity(
                key: ValueKey<String>(
                  'BLabSegmentedControl.item.$index.indicator',
                ),
                opacity: selected ? 1 : 0,
                duration: selectionDuration,
                curve: BLabMotion.ease,
                child: AnimatedContainer(
                  key: ValueKey<String>(
                    'BLabSegmentedControl.item.$index.indicator.decoration',
                  ),
                  duration: selectionDuration,
                  curve: BLabMotion.ease,
                  decoration: BoxDecoration(color: indicatorColor),
                ),
              ),
            ),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );

    final focusVisual = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (showKeyboardFocus)
          Positioned.fill(
            left: -tokens.focusRingWidth,
            top: -tokens.focusRingWidth,
            right: -tokens.focusRingWidth,
            bottom: -tokens.focusRingWidth,
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey<String>(
                  'BLabSegmentedControl.item.$index.focusRing',
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.segmentedFocusOuterRing,
                    width: tokens.focusRingWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius + tokens.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
        surface,
        if (showKeyboardFocus)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey<String>(
                  'BLabSegmentedControl.item.$index.focusOutline',
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.segmentedFocusOutline,
                    width: tokens.focusOutlineWidth,
                  ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
          ),
      ],
    );

    final target = ConstrainedBox(
      key: ValueKey<String>('BLabSegmentedControl.item.$index.target'),
      constraints: BoxConstraints(minHeight: itemTargetHeight),
      child: focusVisual,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: item.label,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      focusable: enabled,
      focused: enabled ? focused : null,
      onTap: enabled ? () => _activate(index) : null,
      child: Focus(
        key: ValueKey<String>('BLabSegmentedControl.item.$index.focus'),
        focusNode: _focusNodes[index],
        canRequestFocus: enabled,
        skipTraversal: !enabled || _rovingIndex != index,
        onKeyEvent: (node, event) => _handleKeyEvent(context, index, event),
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: enabled
              ? (event) {
                  if (event.kind != PointerDeviceKind.touch) {
                    setState(() => _hoveredIndex = index);
                  }
                }
              : null,
          onExit: (_) {
            if (_hoveredIndex == index) {
              setState(() => _hoveredIndex = null);
            }
          },
          child: Listener(
            onPointerDown: enabled
                ? (event) => _handlePointerDown(visibility, index, event)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown: enabled
                  ? (_) => setState(() => _pressedIndex = index)
                  : null,
              onTapCancel: enabled
                  ? () => setState(() => _pressedIndex = null)
                  : null,
              onTapUp: enabled
                  ? (_) => setState(() => _pressedIndex = null)
                  : null,
              onTap: enabled ? () => _handleConfirmedPointerTap(index) : null,
              child: target,
            ),
          ),
        ),
      ),
    );
  }
}
