import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/keyboard_activation.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../generated/blab_token_data.g.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';
import '../theme/blab_token_theme.dart';

/// A Blab-styled controlled tab bar for in-screen navigation.
///
/// Selection remains owned by the caller's [controller]. The public wrapper
/// stays stateless while a private delegate owns transient interaction, roving
/// focus, and scroll-reveal state.
class BLabTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// The [TabController] that drives this tab bar.
  final TabController controller;

  /// Localized labels for each tab.
  final List<String> tabs;

  /// Color of the selection indicator. Defaults to the Tab component token.
  final Color? indicatorColor;

  /// Text color for the selected tab.
  final Color? labelColor;

  /// Text color for unselected tabs.
  final Color? unselectedLabelColor;

  /// Thickness of the indicator line.
  final double indicatorWeight;

  /// Style override for selected tab text.
  final TextStyle? labelStyle;

  /// Style override for unselected tab text.
  final TextStyle? unselectedLabelStyle;

  /// Whether the tab bar owns a private horizontal overflow viewport.
  final bool isScrollable;

  /// Post-activation notification for pointer, semantics, Enter, and Space.
  final ValueChanged<int>? onTap;

  /// Color of the bottom divider. Defaults to transparent.
  final Color? dividerColor;

  const BLabTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.indicatorWeight = 3,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.isScrollable = false,
    this.onTap,
    this.dividerColor,
  }) : assert(tabs.length > 0),
       assert(controller.length == tabs.length),
       assert(indicatorWeight > 0);

  @override
  Widget build(BuildContext context) {
    return _BLabTabBarBody(
      controller: controller,
      tabs: tabs,
      indicatorColor: indicatorColor,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      indicatorWeight: indicatorWeight,
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      isScrollable: isScrollable,
      onTap: onTap,
      dividerColor: dividerColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BLabTabBarBody extends StatefulWidget {
  const _BLabTabBarBody({
    required this.controller,
    required this.tabs,
    required this.indicatorColor,
    required this.labelColor,
    required this.unselectedLabelColor,
    required this.indicatorWeight,
    required this.labelStyle,
    required this.unselectedLabelStyle,
    required this.isScrollable,
    required this.onTap,
    required this.dividerColor,
  });

  final TabController controller;
  final List<String> tabs;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final double indicatorWeight;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final bool isScrollable;
  final ValueChanged<int>? onTap;
  final Color? dividerColor;

  @override
  State<_BLabTabBarBody> createState() => _BLabTabBarBodyState();
}

class _BLabTabBarBodyState extends State<_BLabTabBarBody>
    with WidgetsBindingObserver {
  final BLabKeyboardActivationController _keyboardActivation =
      BLabKeyboardActivationController();
  final List<FocusNode> _focusNodes = <FocusNode>[];
  final List<GlobalKey> _targetKeys = <GlobalKey>[];
  final ScrollController _scrollController = ScrollController();

  late int _rovingIndex;
  late int _lastControllerIndex;
  int? _hoveredIndex;
  int? _pressedIndex;
  int _scheduledRevealGeneration = 0;
  bool _initialRevealPending = true;
  ({
    double viewportWidth,
    double contentWidth,
    TextDirection direction,
    bool isScrollable,
    int selectedIndex,
  })?
  _lastLayoutSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastControllerIndex = widget.controller.index;
    _rovingIndex = widget.controller.index;
    _reconcileNodes();
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(_BLabTabBarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      _lastControllerIndex = widget.controller.index;
      _rovingIndex = widget.controller.index;
      _initialRevealPending = true;
    }
    _reconcileNodes();
    if (_rovingIndex >= widget.tabs.length) {
      _rovingIndex = widget.controller.index;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _keyboardActivation.reset();
    if (_pressedIndex != null && mounted) {
      setState(() => _pressedIndex = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleControllerChange);
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

  void _reconcileNodes() {
    while (_focusNodes.length < widget.tabs.length) {
      final index = _focusNodes.length;
      _focusNodes.add(
        FocusNode(debugLabel: widget.tabs[index])
          ..addListener(_handleFocusChange),
      );
      _targetKeys.add(GlobalKey(debugLabel: 'BLabTabBar target $index'));
    }
    while (_focusNodes.length > widget.tabs.length) {
      final node = _focusNodes.removeLast();
      node
        ..removeListener(_handleFocusChange)
        ..dispose();
      _targetKeys.removeLast();
    }
    for (var index = 0; index < widget.tabs.length; index += 1) {
      _focusNodes[index].debugLabel = widget.tabs[index];
    }
  }

  int? _focusedIndex() {
    for (var index = 0; index < _focusNodes.length; index += 1) {
      if (_focusNodes[index].hasFocus) return index;
    }
    return null;
  }

  void _handleFocusChange() {
    if (_focusedIndex() == null) {
      _keyboardActivation.reset();
      _pressedIndex = null;
    }
    if (mounted) setState(() {});
  }

  void _handleControllerChange() {
    final index = widget.controller.index;
    if (index == _lastControllerIndex) return;
    final focusWasInside = _focusedIndex() != null;
    _lastControllerIndex = index;
    if (!mounted) return;
    setState(() => _rovingIndex = index);
    if (focusWasInside && !_focusNodes[index].hasFocus) {
      _focusNodes[index].requestFocus();
    }
    _scheduleReveal(index);
  }

  void _selectWithoutNotification(int index) {
    if (index == widget.controller.index) return;
    widget.controller.animateTo(index);
  }

  void _activate(int index, {required bool ownPointerFocus}) {
    if (ownPointerFocus) {
      setState(() => _rovingIndex = index);
      _focusNodes[index].requestFocus();
    }
    _selectWithoutNotification(index);
    _scheduleReveal(index);
    widget.onTap?.call(index);
  }

  void _moveByKeyboard(int index) {
    if (index == _rovingIndex && index == widget.controller.index) {
      _focusNodes[index].requestFocus();
      _scheduleReveal(index);
      return;
    }
    setState(() => _rovingIndex = index);
    _focusNodes[index].requestFocus();
    _selectWithoutNotification(index);
    _scheduleReveal(index);
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
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }

    final isHorizontal =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
    final isBoundary =
        key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end;
    if (isHorizontal || isBoundary) {
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
          LogicalKeyboardKey.end => widget.tabs.length - 1,
          _ => (index + step + widget.tabs.length) % widget.tabs.length,
        };
        _moveByKeyboard(target);
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
      onActivate: () => _activate(index, ownPointerFocus: false),
    );
  }

  void _scheduleReveal(
    int index, {
    bool immediate = false,
    bool afterLayout = false,
  }) {
    if (!widget.isScrollable || index < 0 || index >= widget.tabs.length) {
      return;
    }
    final generation = ++_scheduledRevealGeneration;
    if (!afterLayout &&
        _scrollController.hasClients &&
        _targetKeys[index].currentContext != null) {
      _reveal(index, immediate: immediate);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _scheduledRevealGeneration) return;
      _reveal(index, immediate: immediate);
    });
  }

  void _reveal(int index, {required bool immediate}) {
    if (!_scrollController.hasClients) return;
    final targetContext = _targetKeys[index].currentContext;
    if (targetContext == null) return;
    final target = targetContext.findRenderObject();
    if (target is! RenderBox || !target.hasSize) {
      return;
    }
    final renderViewport = RenderAbstractViewport.of(target);
    if (renderViewport is! RenderBox) return;
    final viewport = renderViewport as RenderBox;
    final targetTopLeft = target.localToGlobal(Offset.zero, ancestor: viewport);
    final targetBottomRight = target.localToGlobal(
      target.size.bottomRight(Offset.zero),
      ancestor: viewport,
    );
    if (targetTopLeft.dx >= -0.01 &&
        targetBottomRight.dx <= viewport.size.width + 0.01) {
      return;
    }
    final position = _scrollController.position;
    final targetCenter = (targetTopLeft.dx + targetBottomRight.dx) / 2;
    final viewportCenter = viewport.size.width / 2;
    final visualShift = viewportCenter - targetCenter;
    final pixelShift = switch (position.axisDirection) {
      AxisDirection.right => -visualShift,
      AxisDirection.left => visualShift,
      AxisDirection.up || AxisDirection.down => 0.0,
    };
    final destination = (position.pixels + pixelShift).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((destination - position.pixels).abs() <= 0.01) return;
    final reduced = BLabReducedMotionPolicy.of(context);
    final duration = immediate
        ? Duration.zero
        : reduced.resolve(
            duration: BLabMotion.durPress,
            role: BLabTransitionRole.nonEssential,
          );
    if (duration == Duration.zero) {
      _scrollController.jumpTo(destination);
    } else {
      _scrollController.animateTo(
        destination,
        duration: duration,
        curve: BLabMotion.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.tabs.isNotEmpty);
    assert(widget.controller.length == widget.tabs.length);

    final mode = BLabVisualModeResolver.of(context).mode;
    final tokenColors = _TabTokenColors.forMode(mode);
    final reducedMotion = BLabReducedMotionPolicy.of(context);
    final selectionDuration = reducedMotion.resolve(
      duration: BLabMotion.durSurface,
      role: BLabTransitionRole.nonEssential,
    );
    final interactionDuration = reducedMotion.resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );
    final selectedStyle = BLabTypography.label
        .copyWith(fontWeight: FontWeight.w600)
        .merge(widget.labelStyle)
        .copyWith(
          color:
              widget.labelColor ??
              widget.labelStyle?.color ??
              tokenColors.selectedForeground,
        );
    final unselectedStyle = BLabTypography.label
        .copyWith(fontWeight: FontWeight.w400)
        .merge(widget.unselectedLabelStyle)
        .copyWith(
          color:
              widget.unselectedLabelColor ??
              widget.unselectedLabelStyle?.color ??
              tokenColors.unselectedForeground,
        );
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final intrinsicLabelWidths = <double>[
      for (var index = 0; index < widget.tabs.length; index += 1)
        _measureLabel(
          widget.tabs[index],
          index == widget.controller.index ? selectedStyle : unselectedStyle,
          textScaler,
          direction,
          maxLines: 1,
        ).width,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : widget.tabs.length * 44.0;
        final itemWidths = widget.isScrollable
            ? <double>[
                for (final width in intrinsicLabelWidths)
                  math.max(44, width + 32),
              ]
            : List<double>.filled(
                widget.tabs.length,
                availableWidth / widget.tabs.length,
              );
        final labelSizes = <Size>[
          for (var index = 0; index < widget.tabs.length; index += 1)
            _measureLabel(
              widget.tabs[index],
              index == widget.controller.index
                  ? selectedStyle
                  : unselectedStyle,
              textScaler,
              direction,
              maxWidth: itemWidths[index],
            ),
        ];
        final targetHeight = math.max(
          kToolbarHeight,
          labelSizes.map((size) => size.height).reduce(math.max) + 16,
        );
        final contentWidth = itemWidths.fold<double>(
          0,
          (sum, item) => sum + item,
        );
        final selectedIndex = widget.controller.index;
        final layoutSignature = (
          viewportWidth: availableWidth,
          contentWidth: contentWidth,
          direction: direction,
          isScrollable: widget.isScrollable,
          selectedIndex: selectedIndex,
        );
        final previousLayoutSignature = _lastLayoutSignature;
        _lastLayoutSignature = layoutSignature;
        final layoutEnvironmentChanged =
            previousLayoutSignature != null &&
            (previousLayoutSignature.viewportWidth !=
                    layoutSignature.viewportWidth ||
                previousLayoutSignature.direction !=
                    layoutSignature.direction ||
                previousLayoutSignature.isScrollable !=
                    layoutSignature.isScrollable ||
                previousLayoutSignature.selectedIndex !=
                    layoutSignature.selectedIndex ||
                previousLayoutSignature.contentWidth !=
                    layoutSignature.contentWidth);
        if (widget.isScrollable && layoutEnvironmentChanged) {
          _scheduleReveal(
            _focusedIndex() ?? selectedIndex,
            immediate: true,
            afterLayout: true,
          );
        }
        final selectedItemStart = _physicalItemStart(
          index: selectedIndex,
          widths: itemWidths,
          contentWidth: contentWidth,
          direction: direction,
        );
        final selectedIndicatorWidth = labelSizes[selectedIndex].width;
        final indicatorLeft =
            selectedItemStart +
            (itemWidths[selectedIndex] - selectedIndicatorWidth) / 2;

        final frame = SizedBox(
          width: contentWidth,
          height: targetHeight,
          child: DecoratedBox(
            key: const ValueKey<String>('BLabTabBar.container'),
            decoration: BoxDecoration(color: tokenColors.containerSurface),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  textDirection: direction,
                  children: [
                    for (var index = 0; index < widget.tabs.length; index += 1)
                      SizedBox(
                        width: itemWidths[index],
                        height: targetHeight,
                        child: _buildItem(
                          context,
                          index: index,
                          selected: index == selectedIndex,
                          selectedStyle: selectedStyle,
                          unselectedStyle: unselectedStyle,
                          selectionDuration: selectionDuration,
                          interactionDuration: interactionDuration,
                          tokenColors: tokenColors,
                        ),
                      ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 1,
                  child: DecoratedBox(
                    key: const ValueKey<String>('BLabTabBar.divider'),
                    decoration: BoxDecoration(
                      color: widget.dividerColor ?? tokenColors.divider,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  key: const ValueKey<String>('BLabTabBar.indicator'),
                  duration: selectionDuration,
                  curve: BLabMotion.ease,
                  left: indicatorLeft,
                  width: selectedIndicatorWidth,
                  bottom: 0,
                  height: widget.indicatorWeight,
                  child: AnimatedContainer(
                    key: const ValueKey<String>(
                      'BLabTabBar.indicator.decoration',
                    ),
                    duration: selectionDuration,
                    curve: BLabMotion.ease,
                    decoration: BoxDecoration(
                      color:
                          widget.indicatorColor ??
                          tokenColors.selectedIndicator,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.indicatorWeight),
                        topRight: Radius.circular(widget.indicatorWeight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final semanticTabBar = Semantics(
          key: const ValueKey<String>('BLabTabBar.semantics'),
          role: SemanticsRole.tabBar,
          container: true,
          explicitChildNodes: true,
          child: frame,
        );
        if (!widget.isScrollable) return semanticTabBar;
        final scroll = SingleChildScrollView(
          key: const ValueKey<String>('BLabTabBar.horizontalScroll'),
          controller: _scrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.none,
          child: semanticTabBar,
        );
        if (_initialRevealPending) {
          _initialRevealPending = false;
          _scheduleReveal(selectedIndex, immediate: true);
        }
        return scroll;
      },
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required bool selected,
    required TextStyle selectedStyle,
    required TextStyle unselectedStyle,
    required Duration selectionDuration,
    required Duration interactionDuration,
    required _TabTokenColors tokenColors,
  }) {
    final visibility = BLabFocusVisibilityScope.of(context);
    final hasFocus = _focusNodes[index].hasFocus;
    final showFocus = visibility.shouldShowVisibleFocus(hasFocus: hasFocus);
    final interactionColor = _pressedIndex == index
        ? tokenColors.pressedOverlay
        : _hoveredIndex == index
        ? tokenColors.hoverOverlay
        : Colors.transparent;
    final textStyle = selected ? selectedStyle : unselectedStyle;
    final localizedPosition = MaterialLocalizations.of(
      context,
    ).tabLabel(tabIndex: index + 1, tabCount: widget.tabs.length);

    return Semantics(
      key: ValueKey<String>('BLabTabBar.item.$index.semantics'),
      role: SemanticsRole.tab,
      container: true,
      label: '${widget.tabs[index]}, $localizedPosition',
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onTap: () => _activate(index, ownPointerFocus: false),
      child: Focus(
        focusNode: _focusNodes[index],
        skipTraversal: _rovingIndex != index,
        onKeyEvent: (node, event) => _handleKeyEvent(context, index, event),
        child: ExcludeSemantics(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() {
              if (_hoveredIndex == index) _hoveredIndex = null;
              if (_pressedIndex == index) _pressedIndex = null;
            }),
            child: Listener(
              onPointerDown: (event) => visibility.registerPointer(event.kind),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapDown: (_) => setState(() => _pressedIndex = index),
                onTapCancel: () => setState(() {
                  if (_pressedIndex == index) _pressedIndex = null;
                }),
                onTapUp: (_) => setState(() {
                  if (_pressedIndex == index) _pressedIndex = null;
                }),
                onTap: () => _activate(index, ownPointerFocus: true),
                child: KeyedSubtree(
                  key: _targetKeys[index],
                  child: Container(
                    key: ValueKey<String>('BLabTabBar.item.$index.target'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedContainer(
                          key: ValueKey<String>(
                            'BLabTabBar.item.$index.interaction',
                          ),
                          duration: interactionDuration,
                          curve: BLabMotion.ease,
                          decoration: BoxDecoration(color: interactionColor),
                        ),
                        if (showFocus)
                          Positioned.fill(
                            child: DecoratedBox(
                              key: ValueKey<String>(
                                'BLabTabBar.item.$index.focusRing',
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: tokenColors.focusOuterRing,
                                  width: 3,
                                ),
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
                                'BLabTabBar.item.$index.focusOutline',
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: tokenColors.focusOutline,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: AnimatedDefaultTextStyle(
                            duration: selectionDuration,
                            curve: BLabMotion.ease,
                            style: textStyle,
                            child: Text(
                              widget.tabs[index],
                              textAlign: TextAlign.center,
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
      ),
    );
  }
}

Size _measureLabel(
  String label,
  TextStyle style,
  TextScaler textScaler,
  TextDirection direction, {
  double maxWidth = double.infinity,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textScaler: textScaler,
    textDirection: direction,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  return painter.size;
}

double _physicalItemStart({
  required int index,
  required List<double> widths,
  required double contentWidth,
  required TextDirection direction,
}) {
  final before = widths.take(index).fold<double>(0, (sum, item) => sum + item);
  if (direction == TextDirection.ltr) return before;
  return contentWidth - before - widths[index];
}

class _TabTokenColors {
  const _TabTokenColors({
    required this.containerSurface,
    required this.selectedIndicator,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.hoverOverlay,
    required this.pressedOverlay,
    required this.focusOutline,
    required this.focusOuterRing,
    required this.divider,
  });

  factory _TabTokenColors.forMode(BLabVisualMode mode) {
    final values = switch (mode) {
      BLabVisualMode.light => BlabGeneratedTokenData.light,
      BLabVisualMode.dark => BlabGeneratedTokenData.dark,
      BLabVisualMode.highContrastLight =>
        BlabGeneratedTokenData.highContrastLight,
      BLabVisualMode.highContrastDark =>
        BlabGeneratedTokenData.highContrastDark,
    };
    Color token(String name) => _parseGeneratedColor(values[name]!);
    return _TabTokenColors(
      containerSurface: token('component.tab.container-surface'),
      selectedIndicator: token('component.tab.selected-indicator'),
      selectedForeground: token('component.tab.selected-foreground'),
      unselectedForeground: token('component.tab.unselected-foreground'),
      hoverOverlay: token('component.tab.hover-overlay'),
      pressedOverlay: token('component.tab.pressed-overlay'),
      focusOutline: token('component.tab.focus-outline'),
      focusOuterRing: token('component.tab.focus-outer-ring'),
      divider: token('component.tab.divider'),
    );
  }

  final Color containerSurface;
  final Color selectedIndicator;
  final Color selectedForeground;
  final Color unselectedForeground;
  final Color hoverOverlay;
  final Color pressedOverlay;
  final Color focusOutline;
  final Color focusOuterRing;
  final Color divider;
}

Color _parseGeneratedColor(String source) {
  final hexadecimal = source.substring(1);
  final argb = hexadecimal.length == 6 ? 'FF$hexadecimal' : hexadecimal;
  return Color(int.parse(argb, radix: 16));
}
