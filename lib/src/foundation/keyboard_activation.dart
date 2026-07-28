import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Framework-neutral activation intent for button-like controls.
enum BLabActivationIntent { enter, space }

/// De-duplicates physical Enter and Space key cycles.
class BLabKeyboardActivationController {
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  KeyEventResult handleKeyEvent(
    KeyEvent event, {
    required VoidCallback onActivate,
    bool enabled = true,
    bool busy = false,
  }) {
    final intent = _intentFor(event.logicalKey);
    if (intent == null) return KeyEventResult.ignored;

    if (!enabled || busy) {
      _pressedKeys.remove(event.logicalKey);
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
      final firstDown = _pressedKeys.add(event.logicalKey);
      if (firstDown && intent == BLabActivationIntent.enter) onActivate();
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) return KeyEventResult.handled;

    if (event is KeyUpEvent) {
      final wasPressed = _pressedKeys.remove(event.logicalKey);
      if (wasPressed && intent == BLabActivationIntent.space) onActivate();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void reset() => _pressedKeys.clear();

  static BLabActivationIntent? _intentFor(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return BLabActivationIntent.enter;
    }
    if (key == LogicalKeyboardKey.space) return BLabActivationIntent.space;
    return null;
  }
}

/// Adds deterministic Enter/Space activation to a button-like child.
class BLabKeyboardActivator extends StatefulWidget {
  const BLabKeyboardActivator({
    super.key,
    required this.onActivate,
    required this.child,
    this.enabled = true,
    this.busy = false,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback onActivate;
  final Widget child;
  final bool enabled;
  final bool busy;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<BLabKeyboardActivator> createState() => _BLabKeyboardActivatorState();
}

class _BLabKeyboardActivatorState extends State<BLabKeyboardActivator>
    with WidgetsBindingObserver {
  final BLabKeyboardActivationController _controller =
      BLabKeyboardActivationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(BLabKeyboardActivator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.enabled && oldWidget.enabled) ||
        (widget.busy && !oldWidget.busy)) {
      _controller.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.enabled && !widget.busy,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _controller.reset();
      },
      onKeyEvent: (node, event) => _controller.handleKeyEvent(
        event,
        onActivate: widget.onActivate,
        enabled: widget.enabled,
        busy: widget.busy,
      ),
      child: widget.child,
    );
  }
}
