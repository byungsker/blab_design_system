/// BLab Design System
///
/// A Flutter UI component library with Liquid Glass design language.
///
/// Authoritative design contract: `contracts/blab.design.yaml`.
/// Phase 1A adds deterministic typed-token outputs while preserving the
/// existing standard-mode Dart and CSS sources as compatibility evidence.
library;

// Theme — Tokens
export 'src/theme/app_colors.dart';
export 'src/theme/app_typography.dart';
export 'src/theme/app_spacing.dart';
export 'src/theme/app_radius.dart';
export 'src/theme/app_shadow.dart';
export 'src/theme/app_motion.dart';
export 'src/theme/app_glass.dart';

// Theme — Composite
export 'src/theme/app_theme.dart';
export 'src/theme/blab_token_theme.dart';

// Shared interaction and accessibility foundation
export 'src/foundation/focus_visibility.dart';
export 'src/foundation/focus_visual.dart';
export 'src/foundation/keyboard_activation.dart';
export 'src/foundation/semantic_interaction.dart';
export 'src/foundation/interactive_target.dart';
export 'src/foundation/text_scaling.dart';
export 'src/foundation/reduced_motion.dart';
export 'src/foundation/visual_mode_resolver.dart';
export 'src/foundation/haptic_policy.dart';
export 'src/foundation/focus_owned_overlay.dart';

// Widgets
export 'src/widgets/liquid_glass_card.dart';
export 'src/widgets/liquid_glass_button.dart';
export 'src/widgets/liquid_glass_text_field.dart';
export 'src/widgets/liquid_glass_bottom_bar.dart';
export 'src/widgets/pressable_wrapper.dart';
export 'src/widgets/blab_snackbar.dart';
export 'src/widgets/liquid_glass_tab_bar.dart';
export 'src/widgets/blab_segmented_control.dart';
export 'src/widgets/keyboard_accessory_bar.dart';
