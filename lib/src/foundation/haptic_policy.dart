import 'package:flutter/foundation.dart';

enum BLabHapticIntent { none, selection, action, destructive }

enum BLabHapticTrigger { touch, keyboard, pointer, focus, hover, programmatic }

enum BLabHapticDecisionReason {
  allowed,
  noIntent,
  unsupportedPlatform,
  systemDisabled,
  accessibilityDisabled,
  componentDisabled,
  nonTouchTrigger,
  disabledControl,
  busyControl,
  noOp,
  repeatedAction,
  disposed,
}

@immutable
class BLabHapticConfiguration {
  const BLabHapticConfiguration({
    required this.platformSupportsHaptics,
    required this.systemHapticsEnabled,
    required this.accessibilityHapticsEnabled,
    required this.componentHapticsEnabled,
  });

  static const disabled = BLabHapticConfiguration(
    platformSupportsHaptics: false,
    systemHapticsEnabled: false,
    accessibilityHapticsEnabled: false,
    componentHapticsEnabled: false,
  );

  final bool platformSupportsHaptics;
  final bool systemHapticsEnabled;
  final bool accessibilityHapticsEnabled;
  final bool componentHapticsEnabled;
}

@immutable
class BLabHapticDecision {
  const BLabHapticDecision({required this.shouldTrigger, required this.reason});

  final bool shouldTrigger;
  final BLabHapticDecisionReason reason;
}

/// Pure haptic eligibility policy. It never performs a platform side effect.
abstract final class BLabHapticPolicy {
  static BLabHapticDecision resolve({
    required BLabHapticIntent intent,
    required BLabHapticTrigger trigger,
    required BLabHapticConfiguration configuration,
    bool enabled = true,
    bool busy = false,
    bool noOp = false,
  }) {
    if (intent == BLabHapticIntent.none) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.noIntent,
      );
    }
    if (!configuration.platformSupportsHaptics) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.unsupportedPlatform,
      );
    }
    if (!configuration.systemHapticsEnabled) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.systemDisabled,
      );
    }
    if (!configuration.accessibilityHapticsEnabled) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.accessibilityDisabled,
      );
    }
    if (!configuration.componentHapticsEnabled) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.componentDisabled,
      );
    }
    if (trigger != BLabHapticTrigger.touch) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.nonTouchTrigger,
      );
    }
    if (!enabled) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.disabledControl,
      );
    }
    if (busy) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.busyControl,
      );
    }
    if (noOp) {
      return BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.noOp,
      );
    }
    return BLabHapticDecision(
      shouldTrigger: true,
      reason: BLabHapticDecisionReason.allowed,
    );
  }
}

/// Lifecycle-safe, side-effect-free pulse reservation for committed actions.
///
/// A caller resolves a committed action through this guard. A successful
/// pulse decision is reserved until [resetForNextAction], so repeated callback
/// paths cannot produce more than one pulse for the same action cycle.
class BLabHapticActionCycle {
  bool _pulseReserved = false;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  BLabHapticDecision resolveCommittedAction({
    required BLabHapticIntent intent,
    required BLabHapticTrigger trigger,
    required BLabHapticConfiguration configuration,
    bool enabled = true,
    bool busy = false,
    bool noOp = false,
  }) {
    if (_disposed) {
      return const BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.disposed,
      );
    }
    if (_pulseReserved) {
      return const BLabHapticDecision(
        shouldTrigger: false,
        reason: BLabHapticDecisionReason.repeatedAction,
      );
    }
    final decision = BLabHapticPolicy.resolve(
      intent: intent,
      trigger: trigger,
      configuration: configuration,
      enabled: enabled,
      busy: busy,
      noOp: noOp,
    );
    if (decision.shouldTrigger) {
      _pulseReserved = true;
    }
    return decision;
  }

  void resetForNextAction() {
    if (_disposed) return;
    _pulseReserved = false;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pulseReserved = false;
  }
}
