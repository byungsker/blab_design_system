import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The most recent user input channel observed by a Blab focus scope.
enum BLabInputModality { unknown, keyboard, pointer, touch }

/// Deterministic traversal intent derived from a keyboard event.
enum BLabTraversalIntent { none, next, previous, up, down, left, right }

/// Per-scope focus visibility state.
///
/// Instances are deliberately owned by callers or [BLabFocusVisibilityScope];
/// no process-wide modality singleton is used.
class BLabFocusVisibilityController extends ChangeNotifier {
  BLabInputModality _modality = BLabInputModality.unknown;
  BLabTraversalIntent _traversalIntent = BLabTraversalIntent.none;

  BLabInputModality get modality => _modality;
  BLabTraversalIntent get traversalIntent => _traversalIntent;

  bool shouldShowVisibleFocus({
    required bool hasFocus,
    bool alwaysShow = false,
  }) {
    return hasFocus && (alwaysShow || _modality == BLabInputModality.keyboard);
  }

  void registerPointer(PointerDeviceKind kind) {
    _update(
      kind == PointerDeviceKind.touch
          ? BLabInputModality.touch
          : BLabInputModality.pointer,
      BLabTraversalIntent.none,
    );
  }

  void registerKeyboardIntent(
    LogicalKeyboardKey key, {
    bool shiftPressed = false,
  }) {
    final traversal = switch (key) {
      LogicalKeyboardKey.tab =>
        shiftPressed ? BLabTraversalIntent.previous : BLabTraversalIntent.next,
      LogicalKeyboardKey.arrowUp => BLabTraversalIntent.up,
      LogicalKeyboardKey.arrowDown => BLabTraversalIntent.down,
      LogicalKeyboardKey.arrowLeft => BLabTraversalIntent.left,
      LogicalKeyboardKey.arrowRight => BLabTraversalIntent.right,
      _ => BLabTraversalIntent.none,
    };
    _update(BLabInputModality.keyboard, traversal);
  }

  void reset() {
    _update(BLabInputModality.unknown, BLabTraversalIntent.none);
  }

  void _update(
    BLabInputModality modality,
    BLabTraversalIntent traversalIntent,
  ) {
    if (_modality == modality && _traversalIntent == traversalIntent) return;
    _modality = modality;
    _traversalIntent = traversalIntent;
    notifyListeners();
  }
}

/// Tracks input modality for one widget subtree.
class BLabFocusVisibilityScope extends StatefulWidget {
  const BLabFocusVisibilityScope({
    super.key,
    this.controller,
    required this.child,
  });

  final BLabFocusVisibilityController? controller;
  final Widget child;

  static BLabFocusVisibilityController of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_BLabFocusVisibilityInherited>();
    assert(inherited != null, 'No BLabFocusVisibilityScope found in context.');
    return inherited!.notifier!;
  }

  static BLabFocusVisibilityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BLabFocusVisibilityInherited>()
        ?.notifier;
  }

  @override
  State<BLabFocusVisibilityScope> createState() =>
      _BLabFocusVisibilityScopeState();
}

class _BLabFocusVisibilityScopeState extends State<BLabFocusVisibilityScope> {
  late BLabFocusVisibilityController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
  }

  @override
  void didUpdateWidget(BLabFocusVisibilityScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    if (_ownsController) _controller.dispose();
    _setController(widget.controller);
  }

  void _setController(BLabFocusVisibilityController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? BLabFocusVisibilityController();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _controller.registerKeyboardIntent(
        event.logicalKey,
        shiftPressed: HardwareKeyboard.instance.isShiftPressed,
      );
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BLabFocusVisibilityInherited(
      notifier: _controller,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => _controller.registerPointer(event.kind),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _handleKeyEvent,
          child: widget.child,
        ),
      ),
    );
  }
}

class _BLabFocusVisibilityInherited
    extends InheritedNotifier<BLabFocusVisibilityController> {
  const _BLabFocusVisibilityInherited({
    required super.notifier,
    required super.child,
  });
}
