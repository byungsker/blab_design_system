import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

enum BLabTransitionRole { nonEssential, essentialOpacity }

/// Resolves approved Blab transition durations from platform accessibility
/// signals without changing the underlying motion tokens.
@immutable
class BLabReducedMotionPolicy {
  const BLabReducedMotionPolicy({required this.reduceMotion});

  factory BLabReducedMotionPolicy.fromMediaQuery(MediaQueryData data) {
    return BLabReducedMotionPolicy(
      reduceMotion: data.disableAnimations || data.accessibleNavigation,
    );
  }

  factory BLabReducedMotionPolicy.of(BuildContext context) {
    return BLabReducedMotionPolicy.fromMediaQuery(MediaQuery.of(context));
  }

  final bool reduceMotion;

  Duration resolve({
    required Duration duration,
    required BLabTransitionRole role,
  }) {
    if (!reduceMotion) return duration;
    if (role == BLabTransitionRole.nonEssential) return Duration.zero;
    if (duration == Duration.zero) return Duration.zero;
    return duration > BLabMotion.durPress ? BLabMotion.durPress : duration;
  }
}
