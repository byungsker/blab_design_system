import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum BLabInitialFocusPolicy { firstFocusable, scope, explicit }

enum BLabOverlayDismissIntent { escape, platformBack }

class _BLabPlatformBackCoordinator {
  static final List<_BLabFocusOwnedOverlayState> _owners =
      <_BLabFocusOwnedOverlayState>[];
  static bool _eventClaimed = false;

  static void register(_BLabFocusOwnedOverlayState owner) {
    _owners.add(owner);
  }

  static void unregister(_BLabFocusOwnedOverlayState owner) {
    _owners.remove(owner);
  }

  static bool tryClaim(_BLabFocusOwnedOverlayState owner) {
    if (_eventClaimed) return false;
    final primaryFocus = FocusManager.instance.primaryFocus;
    _BLabFocusOwnedOverlayState? topOwner;
    for (final candidate in _owners.reversed) {
      if (candidate.mounted &&
          !candidate._dismissed &&
          (primaryFocus == null || candidate._ownsFocus(primaryFocus))) {
        topOwner = candidate;
        break;
      }
    }
    if (!identical(topOwner, owner)) return false;
    _eventClaimed = true;
    scheduleMicrotask(() => _eventClaimed = false);
    return true;
  }
}

/// Focus ownership boundary for modal and overlay surfaces.
///
/// It contains sequential and directional traversal, handles Escape exactly
/// once, and restores the focus owner captured immediately before activation.
class BLabFocusOwnedOverlay extends StatefulWidget {
  const BLabFocusOwnedOverlay({
    super.key,
    required this.onDismiss,
    required this.child,
    this.initialFocusPolicy = BLabInitialFocusPolicy.firstFocusable,
    this.initialFocusNode,
    this.dismissOnEscape = true,
    this.dismissOnPlatformBack = true,
    this.onDismissIntent,
  }) : assert(
         initialFocusPolicy != BLabInitialFocusPolicy.explicit ||
             initialFocusNode != null,
         'An explicit initial focus node is required for explicit policy.',
       );

  final VoidCallback onDismiss;
  final Widget child;
  final BLabInitialFocusPolicy initialFocusPolicy;
  final FocusNode? initialFocusNode;
  final bool dismissOnEscape;
  final bool dismissOnPlatformBack;
  final ValueChanged<BLabOverlayDismissIntent>? onDismissIntent;

  @override
  State<BLabFocusOwnedOverlay> createState() => _BLabFocusOwnedOverlayState();
}

class _BLabFocusOwnedOverlayState extends State<BLabFocusOwnedOverlay> {
  late final FocusScopeNode _scopeNode;
  FocusNode? _previousFocus;
  bool _dismissed = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _scopeNode = FocusScopeNode(
      debugLabel: 'BLabFocusOwnedOverlay',
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      directionalTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    );
    _previousFocus = FocusManager.instance.primaryFocus;
    _BLabPlatformBackCoordinator.register(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
  }

  void _requestInitialFocus() {
    if (!mounted || _dismissed) return;
    switch (widget.initialFocusPolicy) {
      case BLabInitialFocusPolicy.explicit:
        final initial = widget.initialFocusNode;
        if (initial != null &&
            initial.canRequestFocus &&
            _scopeNode.descendants.contains(initial)) {
          _scopeNode.requestFocus(initial);
        } else {
          _requestFirstFocusableOrScope();
        }
      case BLabInitialFocusPolicy.scope:
        _scopeNode.requestFocus();
      case BLabInitialFocusPolicy.firstFocusable:
        _requestFirstFocusableOrScope();
    }
  }

  void _requestFirstFocusableOrScope() {
    _scopeNode.requestFocus();
    _scopeNode.nextFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.dismissOnEscape &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss(BLabOverlayDismissIntent.escape);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _dismiss(BLabOverlayDismissIntent intent) {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismissIntent?.call(intent);
    widget.onDismiss();
    _restorePreviousFocus();
  }

  void _handlePlatformBack(bool didPop, Object? result) {
    if (didPop) return;
    if (!_BLabPlatformBackCoordinator.tryClaim(this)) return;
    if (!widget.dismissOnPlatformBack) return;
    _dismiss(BLabOverlayDismissIntent.platformBack);
  }

  bool _ownsFocus(FocusNode focus) {
    return identical(focus, _scopeNode) ||
        _scopeNode.descendants.contains(focus);
  }

  void _restorePreviousFocus() {
    if (_restored) return;
    _restored = true;
    final previous = _previousFocus;
    if (previous != null &&
        previous.context != null &&
        previous.canRequestFocus) {
      previous.requestFocus();
    }
  }

  @override
  void dispose() {
    _BLabPlatformBackCoordinator.unregister(this);
    _restorePreviousFocus();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handlePlatformBack,
      child: FocusScope.withExternalFocusNode(
        focusScopeNode: _scopeNode,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _handleKeyEvent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
