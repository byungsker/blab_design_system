import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../generated/blab_token_data.g.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/blab_token_theme.dart';

/// Defines one product-labeled item in [BLabBottomBar].
class BLabBottomBarItem {
  const BLabBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  /// Icon used while the item is not selected.
  final IconData icon;

  /// Icon used while the item is selected.
  final IconData activeIcon;

  /// Caller-owned, localized product label.
  final String label;
}

/// Controlled Blab bottom navigation with supplemental touch drag.
///
/// [selectedIndex] remains caller-owned. Re-activating the selected item still
/// invokes [onTabSelected]. The optional action is accessibility-conformant
/// only when [actionSemanticLabel] is supplied. The optional first-tab
/// disclosure is conformant only when its callback, localized semantic label,
/// and expanded state are all supplied.
class BLabBottomBar extends StatefulWidget {
  const BLabBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onSearchTap,
    this.actionIcon,
    this.showFirstTabChevron = false,
    this.onFirstTabChevronTap,
    this.noMargin = false,
    this.actionSemanticLabel,
    this.firstTabChevronSemanticLabel,
    this.firstTabChevronExpanded,
  }) : assert(tabs.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < tabs.length);

  final List<BLabBottomBarItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// Optional separate action callback receiving its global origin and size.
  final void Function(Offset position, double size)? onSearchTap;

  /// Optional action icon. Defaults to [CupertinoIcons.search].
  final IconData? actionIcon;

  /// Caller-owned localized label for the optional action.
  ///
  /// A legacy action without this label remains source-compatible and
  /// pointer-operable, but is intentionally excluded from conformance claims.
  final String? actionSemanticLabel;

  /// Whether the legacy first-tab chevron is visible.
  final bool showFirstTabChevron;

  /// Optional first-tab chevron callback.
  final VoidCallback? onFirstTabChevronTap;

  /// Caller-owned localized label for the first-tab disclosure.
  final String? firstTabChevronSemanticLabel;

  /// Controlled expanded state for the first-tab disclosure.
  final bool? firstTabChevronExpanded;

  /// Removes the component-owned horizontal and safe-area outer spacing.
  final bool noMargin;

  @override
  State<BLabBottomBar> createState() => _BLabBottomBarState();
}

class _BLabBottomBarState extends State<BLabBottomBar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final BLabKeyboardActivationController _keyboardActivation =
      BLabKeyboardActivationController();
  final BLabKeyboardActivationController _actionKeyboardActivation =
      BLabKeyboardActivationController();
  final BLabKeyboardActivationController _chevronKeyboardActivation =
      BLabKeyboardActivationController();
  final BLabFocusVisibilityController _localFocusVisibility =
      BLabFocusVisibilityController();
  final List<FocusNode> _focusNodes = <FocusNode>[];
  final GlobalKey _actionKey = GlobalKey();
  final FocusNode _actionFocusNode = FocusNode(
    debugLabel: 'BottomBar optional action',
  );
  final FocusNode _chevronFocusNode = FocusNode(
    debugLabel: 'BottomBar first-tab disclosure',
  );

  late final AnimationController _selectionController;
  late Animation<double> _selectionAnimation;
  late int _rovingIndex;
  int? _hoveredIndex;
  int? _pressedIndex;
  bool _isDragging = false;
  bool _dragAwaitingControlledReconcile = false;
  double _dragPosition = 0;
  double _tabWidth = 0;
  PointerDeviceKind? _lastPointerKind;

  int get _tabCount => widget.tabs.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rovingIndex = widget.selectedIndex;
    _reconcileFocusNodes();
    _selectionController = AnimationController(
      duration: BLabMotion.durSurface,
      vsync: this,
    )..value = 1;
    _selectionAnimation = AlwaysStoppedAnimation<double>(
      widget.selectedIndex.toDouble(),
    );
  }

  @override
  void didUpdateWidget(BLabBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusedIndex = _focusedIndex();
    _reconcileFocusNodes();
    if (_rovingIndex >= _tabCount) {
      _rovingIndex = widget.selectedIndex;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex && !_isDragging) {
      if (!_dragAwaitingControlledReconcile) {
        _animateSelection(widget.selectedIndex.toDouble());
      }
      if (focusedIndex == null) _rovingIndex = widget.selectedIndex;
    }
  }

  void _reconcileFocusNodes() {
    while (_focusNodes.length < widget.tabs.length) {
      final index = _focusNodes.length;
      _focusNodes.add(
        FocusNode(debugLabel: 'BottomBar ${widget.tabs[index].label}'),
      );
    }
    while (_focusNodes.length > widget.tabs.length) {
      _focusNodes.removeLast().dispose();
    }
  }

  int? _focusedIndex() {
    for (var index = 0; index < _focusNodes.length; index += 1) {
      if (_focusNodes[index].hasFocus) return index;
    }
    return null;
  }

  BLabFocusVisibilityController _focusVisibility(BuildContext context) =>
      BLabFocusVisibilityScope.maybeOf(context) ?? _localFocusVisibility;

  void _animateSelection(double target) {
    final current = _selectionAnimation.value;
    final reduced = BLabReducedMotionPolicy.of(context);
    final duration = reduced.resolve(
      duration: BLabMotion.durSurface,
      role: BLabTransitionRole.nonEssential,
    );
    _selectionController.duration = duration == Duration.zero
        ? const Duration(microseconds: 1)
        : duration;
    _selectionAnimation = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _selectionController, curve: BLabMotion.ease),
    );
    if (duration == Duration.zero) {
      _selectionController.value = 1;
    } else {
      _selectionController.forward(from: 0);
    }
  }

  void _activate(int index, {required bool ownPointerFocus}) {
    if (ownPointerFocus) {
      setState(() => _rovingIndex = index);
      _focusNodes[index].requestFocus();
    }
    widget.onTabSelected(index);
  }

  void _moveFocus(int index) {
    if (_rovingIndex != index) setState(() => _rovingIndex = index);
    _focusNodes[index].requestFocus();
  }

  void _clearPressedIndex(int index) {
    if (_pressedIndex == index) setState(() => _pressedIndex = null);
  }

  void _cancelPointerInteraction() {
    final restoreSelection = _isDragging;
    if (!restoreSelection && _pressedIndex == null) return;
    setState(() {
      _pressedIndex = null;
      _isDragging = false;
      _dragAwaitingControlledReconcile = false;
    });
    if (restoreSelection) {
      _animateSelection(widget.selectedIndex.toDouble());
    }
  }

  KeyEventResult _handleTabKey(
    BuildContext context,
    int index,
    KeyEvent event,
  ) {
    final visibility = _focusVisibility(context);
    visibility.registerKeyboardIntent(
      event.logicalKey,
      shiftPressed: HardwareKeyboard.instance.isShiftPressed,
    );
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    final horizontal =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
    final boundary =
        key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end;
    if (horizontal || boundary) {
      if (event is KeyDownEvent) {
        final direction = Directionality.of(context);
        final step = switch (key) {
          LogicalKeyboardKey.arrowRight =>
            direction == TextDirection.ltr ? 1 : -1,
          LogicalKeyboardKey.arrowLeft =>
            direction == TextDirection.ltr ? -1 : 1,
          _ => 0,
        };
        final target = switch (key) {
          LogicalKeyboardKey.home => 0,
          LogicalKeyboardKey.end => _tabCount - 1,
          _ => (index + step + _tabCount) % _tabCount,
        };
        _moveFocus(target);
      }
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) &&
        event is KeyDownEvent) {
      setState(() => _pressedIndex = index);
    } else if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) &&
        event is KeyUpEvent) {
      setState(() => _pressedIndex = null);
    }
    return _keyboardActivation.handleKeyEvent(
      event,
      onActivate: () => _activate(index, ownPointerFocus: false),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_lastPointerKind != PointerDeviceKind.touch) return;
    setState(() {
      _pressedIndex = null;
      _isDragging = true;
      _dragPosition = _selectionAnimation.value;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDragging || _tabWidth <= 0) return;
    final physical =
        ((details.localPosition.dx - BLabSpacing.s2 - (_tabWidth / 2)) /
                _tabWidth)
            .clamp(0.0, (_tabCount - 1).toDouble());
    final direction = Directionality.of(context);
    final logical = direction == TextDirection.ltr
        ? physical
        : (_tabCount - 1) - physical;
    setState(() => _dragPosition = logical);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isDragging) return;
    final target = _dragPosition.round().clamp(0, _tabCount - 1);
    final committedPosition = _dragPosition;
    setState(() {
      _isDragging = false;
      _dragAwaitingControlledReconcile = true;
      _rovingIndex = target;
    });
    _selectionAnimation = AlwaysStoppedAnimation<double>(committedPosition);
    _selectionController.value = 1;
    _focusVisibility(context).registerPointer(PointerDeviceKind.touch);
    _focusNodes[target].requestFocus();
    widget.onTabSelected(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dragAwaitingControlledReconcile) return;
      _dragAwaitingControlledReconcile = false;
      _animateSelection(widget.selectedIndex.toDouble());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _keyboardActivation.reset();
    _actionKeyboardActivation.reset();
    _chevronKeyboardActivation.reset();
    if (_pressedIndex != null || _isDragging) {
      setState(() {
        _pressedIndex = null;
        _isDragging = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final node in _focusNodes) {
      node.dispose();
    }
    _actionFocusNode.dispose();
    _chevronFocusNode.dispose();
    _selectionController.dispose();
    _keyboardActivation.reset();
    _actionKeyboardActivation.reset();
    _chevronKeyboardActivation.reset();
    _localFocusVisibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = BLabVisualModeResolver.of(context);
    final colors = _BottomBarTokenColors.forMode(resolved.mode);
    final highContrast =
        resolved.mode == BLabVisualMode.highContrastLight ||
        resolved.mode == BLabVisualMode.highContrastDark;
    final interactionDuration = BLabReducedMotionPolicy.of(context).resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );

    final tabBar = Expanded(
      child: _buildTabBar(
        context,
        colors: colors,
        highContrast: highContrast,
        interactionDuration: interactionDuration,
        blur: resolved.tokens.glassBlur,
      ),
    );
    final children = <Widget>[tabBar];
    if (widget.onSearchTap != null) {
      children
        ..add(SizedBox(width: BLabSpacing.s4))
        ..add(
          _buildAction(
            context,
            colors: colors,
            highContrast: highContrast,
            blur: resolved.tokens.glassBlur,
          ),
        );
    }
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
    if (widget.noMargin) return content;

    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;
    final safeAreaAlreadyConsumed =
        safeBottom == 0 && media.viewPadding.bottom > 0;
    final outerBottom = safeBottom > 0
        ? safeBottom
        : safeAreaAlreadyConsumed
        ? 0.0
        : 22.0;
    return Padding(
      padding: EdgeInsets.only(
        left: BLabSpacing.s4,
        right: BLabSpacing.s4,
        bottom: outerBottom,
      ),
      child: content,
    );
  }

  Widget _buildTabBar(
    BuildContext context, {
    required _BottomBarTokenColors colors,
    required bool highContrast,
    required Duration interactionDuration,
    required double blur,
  }) {
    final surface = DecoratedBox(
      key: const ValueKey<String>('BLabBottomBar.surface'),
      decoration: BoxDecoration(
        color: colors.containerSurface,
        borderRadius: BLabRadius.pillRect,
        border: Border.all(color: colors.containerBorder, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(BLabSpacing.s2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _tabWidth = constraints.maxWidth / _tabCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildSelectedSurface(
                  colors,
                  constraints.maxWidth,
                  highContrast,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var index = 0; index < _tabCount; index += 1)
                      Expanded(
                        child: _buildTabItem(
                          context,
                          index,
                          colors,
                          interactionDuration,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    final clipped = ClipRRect(
      borderRadius: BLabRadius.pillRect,
      child: highContrast
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: surface,
            ),
    );
    final tabBar = Semantics(
      key: const ValueKey<String>('BLabBottomBar.semantics'),
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      child: Listener(
        onPointerDown: (event) => _lastPointerKind = event.kind,
        onPointerCancel: (_) => _cancelPointerInteraction(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          onLongPressEnd: _onLongPressEnd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: clipped,
          ),
        ),
      ),
    );
    if (!widget.showFirstTabChevron) return tabBar;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [tabBar, _buildChevron(context, colors)],
    );
  }

  Widget _buildSelectedSurface(
    _BottomBarTokenColors colors,
    double maxWidth,
    bool highContrast,
  ) {
    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, child) {
        final logicalPosition = _isDragging
            ? _dragPosition
            : _selectionAnimation.value;
        final direction = Directionality.of(context);
        final physicalPosition = direction == TextDirection.ltr
            ? logicalPosition
            : (_tabCount - 1) - logicalPosition;
        final width = maxWidth / _tabCount;
        return Positioned(
          left: physicalPosition * width,
          top: 0,
          bottom: 0,
          width: width,
          child: Padding(
            padding: EdgeInsets.all(BLabSpacing.s2),
            child: DecoratedBox(
              key: const ValueKey<String>('BLabBottomBar.selected'),
              decoration: BoxDecoration(
                color: colors.selectedSurface,
                borderRadius: BLabRadius.pillRect,
                boxShadow: highContrast
                    ? const <BoxShadow>[]
                    : <BoxShadow>[
                        BoxShadow(
                          color: colors.selectedShadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: highContrast
                  ? null
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BLabRadius.pillRect,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.selectedHighlight,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    _BottomBarTokenColors colors,
    Duration interactionDuration,
  ) {
    final selected = widget.selectedIndex == index;
    final visibility = _focusVisibility(context);
    final showFocus = visibility.shouldShowVisibleFocus(
      hasFocus: _focusNodes[index].hasFocus,
    );
    final dragActive = _isDragging && _dragPosition.round() == index;
    final interactionColor = dragActive
        ? colors.dragOverlay
        : _pressedIndex == index
        ? colors.pressedOverlay
        : _hoveredIndex == index
        ? colors.hoverOverlay
        : Colors.transparent;
    final foreground = selected
        ? colors.selectedForeground
        : colors.unselectedForeground;

    return Semantics(
      key: ValueKey<String>('BLabBottomBar.item.$index.semantics'),
      role: SemanticsRole.tab,
      container: true,
      label: widget.tabs[index].label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onTap: () => _activate(index, ownPointerFocus: false),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Focus(
            focusNode: _focusNodes[index],
            skipTraversal: _rovingIndex != index,
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _keyboardActivation.reset();
                if (_pressedIndex == index) _pressedIndex = null;
              }
              if (mounted) setState(() {});
            },
            onKeyEvent: (node, event) => _handleTabKey(context, index, event),
            child: ExcludeSemantics(
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() {
                  if (_hoveredIndex == index) _hoveredIndex = null;
                  if (_pressedIndex == index) _pressedIndex = null;
                }),
                child: Listener(
                  onPointerDown: (event) {
                    visibility.registerPointer(event.kind);
                    setState(() => _pressedIndex = index);
                  },
                  onPointerUp: (_) => _clearPressedIndex(index),
                  onPointerCancel: (_) => _clearPressedIndex(index),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTapCancel: () => _clearPressedIndex(index),
                    onTapUp: (_) => _clearPressedIndex(index),
                    onTap: () => _activate(index, ownPointerFocus: true),
                    child: ConstrainedBox(
                      key: ValueKey<String>('BLabBottomBar.item.$index.target'),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 54,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AnimatedContainer(
                              key: ValueKey<String>(
                                'BLabBottomBar.item.$index.interaction',
                              ),
                              duration: interactionDuration,
                              curve: BLabMotion.ease,
                              decoration: BoxDecoration(
                                color: interactionColor,
                                borderRadius: BLabRadius.pillRect,
                              ),
                            ),
                          ),
                          if (showFocus)
                            Positioned.fill(
                              child: DecoratedBox(
                                key: ValueKey<String>(
                                  'BLabBottomBar.item.$index.focusRing',
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.focusOuterRing,
                                    width: 3,
                                  ),
                                  borderRadius: BLabRadius.pillRect,
                                ),
                              ),
                            ),
                          if (showFocus)
                            Positioned.fill(
                              left: 3,
                              top: 3,
                              right: 3,
                              bottom: 3,
                              child: DecoratedBox(
                                key: ValueKey<String>(
                                  'BLabBottomBar.item.$index.focusOutline',
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colors.focusOutline,
                                    width: 2,
                                  ),
                                  borderRadius: BLabRadius.pillRect,
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  index == 0 && widget.showFirstTabChevron
                                  ? 20
                                  : 2,
                              vertical: 2,
                            ),
                            child: Center(
                              widthFactor: 1,
                              heightFactor: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selected
                                        ? widget.tabs[index].activeIcon
                                        : widget.tabs[index].icon,
                                    color: foreground,
                                    size: 24,
                                  ),
                                  SizedBox(height: BLabSpacing.xs),
                                  Text(
                                    widget.tabs[index].label,
                                    textAlign: TextAlign.center,
                                    style: BLabTypography.tab.copyWith(
                                      color: foreground,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildChevron(BuildContext context, _BottomBarTokenColors colors) {
    final visibility = _focusVisibility(context);
    final semanticLabel = widget.firstTabChevronSemanticLabel?.trim();
    final completeContract =
        widget.onFirstTabChevronTap != null &&
        semanticLabel?.isNotEmpty == true &&
        widget.firstTabChevronExpanded != null;
    final target = Focus(
      focusNode: _chevronFocusNode,
      canRequestFocus: completeContract,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _chevronKeyboardActivation.reset();
        if (mounted) setState(() {});
      },
      onKeyEvent: (node, event) => _chevronKeyboardActivation.handleKeyEvent(
        event,
        enabled: completeContract,
        onActivate: widget.onFirstTabChevronTap ?? () {},
      ),
      child: Listener(
        onPointerDown: (event) {
          visibility.registerPointer(event.kind);
          if (mounted) setState(() {});
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.onFirstTabChevronTap,
          child: SizedBox(
            key: const ValueKey<String>('BLabBottomBar.chevron.target'),
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (visibility.shouldShowVisibleFocus(
                  hasFocus: _chevronFocusNode.hasFocus,
                ))
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colors.focusOuterRing,
                        width: 3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (visibility.shouldShowVisibleFocus(
                  hasFocus: _chevronFocusNode.hasFocus,
                ))
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.focusOutline,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Icon(
                  CupertinoIcons.chevron_up_chevron_down,
                  color: widget.selectedIndex == 0
                      ? colors.selectedForeground
                      : colors.unselectedForeground,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final child = completeContract
        ? Tooltip(
            message: semanticLabel!,
            child: Semantics(
              key: const ValueKey<String>('BLabBottomBar.chevron.semantics'),
              button: true,
              label: semanticLabel,
              expanded: widget.firstTabChevronExpanded,
              onTap: widget.onFirstTabChevronTap,
              child: target,
            ),
          )
        : ExcludeSemantics(child: target);
    return PositionedDirectional(start: 0, top: 5, child: child);
  }

  Widget _buildAction(
    BuildContext context, {
    required _BottomBarTokenColors colors,
    required bool highContrast,
    required double blur,
  }) {
    const size = 62.0;
    final semanticLabel = widget.actionSemanticLabel?.trim();
    final completeContract = semanticLabel?.isNotEmpty == true;
    final visibility = _focusVisibility(context);

    void activate() {
      final renderBox =
          _actionKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      widget.onSearchTap?.call(renderBox.localToGlobal(Offset.zero), size);
    }

    final decorated = SizedBox(
      key: const ValueKey<String>('BLabBottomBar.action.target'),
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            key: const ValueKey<String>('BLabBottomBar.action.decoration'),
            decoration: BoxDecoration(
              color: colors.actionSurface,
              borderRadius: BLabRadius.pillRect,
              border: Border.all(color: colors.containerBorder, width: 1),
            ),
          ),
          if (visibility.shouldShowVisibleFocus(
            hasFocus: _actionFocusNode.hasFocus,
          ))
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.focusOuterRing, width: 3),
                shape: BoxShape.circle,
              ),
            ),
          if (visibility.shouldShowVisibleFocus(
            hasFocus: _actionFocusNode.hasFocus,
          ))
            Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.focusOutline, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Icon(
            widget.actionIcon ?? CupertinoIcons.search,
            color: colors.actionForeground,
            size: 22,
          ),
        ],
      ),
    );
    final surface = ClipRRect(
      borderRadius: BLabRadius.pillRect,
      child: highContrast
          ? decorated
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: decorated,
            ),
    );
    final target = Focus(
      focusNode: _actionFocusNode,
      canRequestFocus: completeContract,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _actionKeyboardActivation.reset();
        if (mounted) setState(() {});
      },
      onKeyEvent: (node, event) => _actionKeyboardActivation.handleKeyEvent(
        event,
        enabled: completeContract,
        onActivate: activate,
      ),
      child: Listener(
        onPointerDown: (event) {
          visibility.registerPointer(event.kind);
          if (mounted) setState(() {});
        },
        child: GestureDetector(
          key: _actionKey,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: activate,
          child: surface,
        ),
      ),
    );
    if (!completeContract) return ExcludeSemantics(child: target);
    return Tooltip(
      message: semanticLabel!,
      child: Semantics(
        key: const ValueKey<String>('BLabBottomBar.action.semantics'),
        button: true,
        label: semanticLabel,
        onTap: activate,
        child: target,
      ),
    );
  }
}

class _BottomBarTokenColors {
  const _BottomBarTokenColors({
    required this.containerSurface,
    required this.containerBorder,
    required this.selectedSurface,
    required this.selectedHighlight,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.hoverOverlay,
    required this.pressedOverlay,
    required this.dragOverlay,
    required this.focusOutline,
    required this.focusOuterRing,
    required this.actionSurface,
    required this.actionForeground,
    required this.selectedShadow,
  });

  factory _BottomBarTokenColors.forMode(BLabVisualMode mode) {
    final values = switch (mode) {
      BLabVisualMode.light => BlabGeneratedTokenData.light,
      BLabVisualMode.dark => BlabGeneratedTokenData.dark,
      BLabVisualMode.highContrastLight =>
        BlabGeneratedTokenData.highContrastLight,
      BLabVisualMode.highContrastDark =>
        BlabGeneratedTokenData.highContrastDark,
    };
    Color token(String name) => _parseGeneratedColor(values[name]!);
    return _BottomBarTokenColors(
      containerSurface: token('component.bottom-bar.container-surface'),
      containerBorder: token('component.bottom-bar.container-border'),
      selectedSurface: token('component.bottom-bar.selected-surface'),
      selectedHighlight: token('component.bottom-bar.selected-highlight'),
      selectedForeground: token('component.bottom-bar.selected-foreground'),
      unselectedForeground: token('component.bottom-bar.unselected-foreground'),
      hoverOverlay: token('component.bottom-bar.hover-overlay'),
      pressedOverlay: token('component.bottom-bar.pressed-overlay'),
      dragOverlay: token('component.bottom-bar.drag-overlay'),
      focusOutline: token('component.bottom-bar.focus-outline'),
      focusOuterRing: token('component.bottom-bar.focus-outer-ring'),
      actionSurface: token('component.bottom-bar.action-surface'),
      actionForeground: token('component.bottom-bar.action-foreground'),
      selectedShadow: token('component.bottom-bar.selected-shadow'),
    );
  }

  final Color containerSurface;
  final Color containerBorder;
  final Color selectedSurface;
  final Color selectedHighlight;
  final Color selectedForeground;
  final Color unselectedForeground;
  final Color hoverOverlay;
  final Color pressedOverlay;
  final Color dragOverlay;
  final Color focusOutline;
  final Color focusOuterRing;
  final Color actionSurface;
  final Color actionForeground;
  final Color selectedShadow;
}

Color _parseGeneratedColor(String source) {
  final hexadecimal = source.substring(1);
  final argb = hexadecimal.length == 6 ? 'FF$hexadecimal' : hexadecimal;
  return Color(int.parse(argb, radix: 16));
}
