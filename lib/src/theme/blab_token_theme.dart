// GENERATED CODE - DO NOT EDIT.
// Source: contracts/blab.design.yaml + contracts/tokens/blab.tokens.yaml
// Contract version: 0.2.0
// Source checksum (SHA-256): 2187c652f2b82e22c038bcf3a7dbc58d81b0537db5b6c663981e0fa45c873863
// Content checksum (SHA-256, body only): 8a5b4f14f95b1641d187758db5a1b585ed287a267a3aa89389a0c8e6dfeb6923

import 'package:flutter/material.dart';

enum BLabVisualMode { light, dark, highContrastLight, highContrastDark }

@immutable
class BLabTokenTheme extends ThemeExtension<BLabTokenTheme> {
  const BLabTokenTheme({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.glassSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.focusRing,
    this.focusCanvas = const Color(0xFF5B7FFF),
    this.focusSurface = const Color(0xFF5B7FFF),
    this.focusAccent = const Color(0xFFFFFFFF),
    required this.actionPrimary,
    required this.actionPrimaryForeground,
    required this.actionDestructive,
    required this.actionDestructiveForeground,
    this.buttonPrimaryHoverOverlay = const Color(0x14000000),
    this.buttonSecondaryHoverOverlay = const Color(0x14000000),
    this.buttonDestructiveHoverOverlay = const Color(0x14000000),
    this.buttonPrimaryFocusOutline = const Color(0xFFFFFFFF),
    this.buttonSecondaryFocusOutline = const Color(0xFF000000),
    this.buttonDestructiveFocusOutline = const Color(0xFFFFFFFF),
    this.buttonFocusOuterRing = const Color(0xFF5B7FFF),
    this.textFieldLabel = const Color(0xB3000000),
    this.textFieldHint = const Color(0x99000000),
    this.textFieldHoverBorder = const Color(0x26000000),
    this.textFieldFocusOutline = const Color(0xFF000000),
    this.textFieldFocusOuterRing = const Color(0xFF5B7FFF),
    this.textFieldErrorBorder = const Color(0xFFFF3B30),
    this.textFieldClearBackground = const Color(0x99000000),
    this.textFieldClearForeground = const Color(0xFFFFFFFF),
    this.segmentedContainerSurface = const Color(0xFFF5F5F5),
    this.segmentedContainerBorder = const Color(0x00000000),
    this.segmentedSelectedSurface = const Color(0xFFFFFFFF),
    this.segmentedSelectedIndicator = const Color(0xFF5B7FFF),
    this.segmentedSelectedForeground = const Color(0xFF000000),
    this.segmentedUnselectedForeground = const Color(0xDD000000),
    this.segmentedDisabledForeground = const Color(0xFF68707D),
    this.segmentedHoverOverlay = const Color(0x14000000),
    this.segmentedPressedOverlay = const Color(0x1F000000),
    this.segmentedFocusOutline = const Color(0xFF000000),
    this.segmentedFocusOuterRing = const Color(0xFF5B7FFF),
    this.segmentedSelectedShadow = const Color(0x14000000),
    this.snackbarSurface = const Color(0xFFFFFFFF),
    this.snackbarForeground = const Color(0xFF000000),
    this.snackbarBorder = const Color(0x14000000),
    this.snackbarBadgeSuccess = const Color(0xFF10B981),
    this.snackbarBadgeError = const Color(0xFFFF3B30),
    this.snackbarBadgeWarning = const Color(0xFFFF9500),
    this.snackbarBadgeInfo = const Color(0xFF4ECDC4),
    this.snackbarBadgeGlyph = const Color(0xFF000000),
    this.snackbarBadgeOutline = const Color(0x00000000),
    this.keyboardAccessorySurfaceStart = const Color(0x99FFFFFF),
    this.keyboardAccessorySurfaceEnd = const Color(0x4DFFFFFF),
    this.keyboardAccessoryBorder = const Color(0x66FFFFFF),
    this.keyboardAccessoryForeground = const Color(0xB3000000),
    this.keyboardAccessoryDisabledForeground = const Color(0x36000000),
    this.keyboardAccessoryDivider = const Color(0x1A000000),
    this.keyboardAccessoryHoverOverlay = const Color(0x14000000),
    this.keyboardAccessoryPressedOverlay = const Color(0x1F000000),
    this.keyboardAccessoryFocusOutline = const Color(0xFF000000),
    this.keyboardAccessoryFocusOuterRing = const Color(0xFF5B7FFF),
    this.keyboardAccessoryShadow = const Color(0x26000000),
    this.cardSurface = const Color(0x14000000),
    this.cardBorder = const Color(0x14000000),
    this.pressableHoverOverlay = const Color(0x14000000),
    this.pressablePressedOverlay = const Color(0x1F000000),
    this.pressableFocusOutline = const Color(0xFF000000),
    this.pressableFocusOuterRing = const Color(0xFF5B7FFF),
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarning,
    required this.statusInfo,
    required this.statusForeground,
    required this.disabledForeground,
    this.focusOutlineWidth = 2,
    this.focusRingWidth = 3,
    this.keyboardAccessoryBlur = 20,
    required this.glassBlur,
    required this.glassSaturation,
    required this.glassHighlight,
    required this.glassShadowEnabled,
  });

  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color glassSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color focusRing;
  final Color focusCanvas;
  final Color focusSurface;
  final Color focusAccent;
  final Color actionPrimary;
  final Color actionPrimaryForeground;
  final Color actionDestructive;
  final Color actionDestructiveForeground;
  final Color buttonPrimaryHoverOverlay;
  final Color buttonSecondaryHoverOverlay;
  final Color buttonDestructiveHoverOverlay;
  final Color buttonPrimaryFocusOutline;
  final Color buttonSecondaryFocusOutline;
  final Color buttonDestructiveFocusOutline;
  final Color buttonFocusOuterRing;
  final Color textFieldLabel;
  final Color textFieldHint;
  final Color textFieldHoverBorder;
  final Color textFieldFocusOutline;
  final Color textFieldFocusOuterRing;
  final Color textFieldErrorBorder;
  final Color textFieldClearBackground;
  final Color textFieldClearForeground;
  final Color segmentedContainerSurface;
  final Color segmentedContainerBorder;
  final Color segmentedSelectedSurface;
  final Color segmentedSelectedIndicator;
  final Color segmentedSelectedForeground;
  final Color segmentedUnselectedForeground;
  final Color segmentedDisabledForeground;
  final Color segmentedHoverOverlay;
  final Color segmentedPressedOverlay;
  final Color segmentedFocusOutline;
  final Color segmentedFocusOuterRing;
  final Color segmentedSelectedShadow;
  final Color snackbarSurface;
  final Color snackbarForeground;
  final Color snackbarBorder;
  final Color snackbarBadgeSuccess;
  final Color snackbarBadgeError;
  final Color snackbarBadgeWarning;
  final Color snackbarBadgeInfo;
  final Color snackbarBadgeGlyph;
  final Color snackbarBadgeOutline;
  final Color keyboardAccessorySurfaceStart;
  final Color keyboardAccessorySurfaceEnd;
  final Color keyboardAccessoryBorder;
  final Color keyboardAccessoryForeground;
  final Color keyboardAccessoryDisabledForeground;
  final Color keyboardAccessoryDivider;
  final Color keyboardAccessoryHoverOverlay;
  final Color keyboardAccessoryPressedOverlay;
  final Color keyboardAccessoryFocusOutline;
  final Color keyboardAccessoryFocusOuterRing;
  final Color keyboardAccessoryShadow;
  final Color cardSurface;
  final Color cardBorder;
  final Color pressableHoverOverlay;
  final Color pressablePressedOverlay;
  final Color pressableFocusOutline;
  final Color pressableFocusOuterRing;
  final Color statusSuccess;
  final Color statusError;
  final Color statusWarning;
  final Color statusInfo;
  final Color statusForeground;
  final Color disabledForeground;
  final double focusOutlineWidth;
  final double focusRingWidth;
  final double keyboardAccessoryBlur;
  final double glassBlur;
  final double glassSaturation;
  final Color? glassHighlight;
  final bool glassShadowEnabled;

  static const BLabTokenTheme light = BLabTokenTheme(
    surfaceBase: Color(0xFFFAFAFA),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFFFFFFF),
    glassSurface: Color(0x14000000),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xDD000000),
    textTertiary: Color(0x99000000),
    textInverse: Color(0xFFFFFFFF),
    borderSubtle: Color(0x0D000000),
    borderDefault: Color(0x14000000),
    borderStrong: Color(0x26000000),
    focusRing: Color(0xFF5B7FFF),
    focusCanvas: Color(0xFF5B7FFF),
    focusSurface: Color(0xFF5B7FFF),
    focusAccent: Color(0xFFFFFFFF),
    actionPrimary: Color(0xFF5B7FFF),
    actionPrimaryForeground: Color(0xFF000000),
    actionDestructive: Color(0xFFFF3B30),
    actionDestructiveForeground: Color(0xFF000000),
    buttonPrimaryHoverOverlay: Color(0x14000000),
    buttonSecondaryHoverOverlay: Color(0x14000000),
    buttonDestructiveHoverOverlay: Color(0x14000000),
    buttonPrimaryFocusOutline: Color(0xFFFFFFFF),
    buttonSecondaryFocusOutline: Color(0xFF000000),
    buttonDestructiveFocusOutline: Color(0xFFFFFFFF),
    buttonFocusOuterRing: Color(0xFF5B7FFF),
    textFieldLabel: Color(0xB3000000),
    textFieldHint: Color(0x99000000),
    textFieldHoverBorder: Color(0x26000000),
    textFieldFocusOutline: Color(0xFF000000),
    textFieldFocusOuterRing: Color(0xFF5B7FFF),
    textFieldErrorBorder: Color(0xFFFF3B30),
    textFieldClearBackground: Color(0x99000000),
    textFieldClearForeground: Color(0xFFFFFFFF),
    segmentedContainerSurface: Color(0xFFF5F5F5),
    segmentedContainerBorder: Color(0x00000000),
    segmentedSelectedSurface: Color(0xFFFFFFFF),
    segmentedSelectedIndicator: Color(0xFF5B7FFF),
    segmentedSelectedForeground: Color(0xFF000000),
    segmentedUnselectedForeground: Color(0xDD000000),
    segmentedDisabledForeground: Color(0xFF68707D),
    segmentedHoverOverlay: Color(0x14000000),
    segmentedPressedOverlay: Color(0x1F000000),
    segmentedFocusOutline: Color(0xFF000000),
    segmentedFocusOuterRing: Color(0xFF5B7FFF),
    segmentedSelectedShadow: Color(0x14000000),
    snackbarSurface: Color(0xFFFFFFFF),
    snackbarForeground: Color(0xFF000000),
    snackbarBorder: Color(0x14000000),
    snackbarBadgeSuccess: Color(0xFF10B981),
    snackbarBadgeError: Color(0xFFFF3B30),
    snackbarBadgeWarning: Color(0xFFFF9500),
    snackbarBadgeInfo: Color(0xFF4ECDC4),
    snackbarBadgeGlyph: Color(0xFF000000),
    snackbarBadgeOutline: Color(0x00000000),
    keyboardAccessorySurfaceStart: Color(0x99FFFFFF),
    keyboardAccessorySurfaceEnd: Color(0x4DFFFFFF),
    keyboardAccessoryBorder: Color(0x66FFFFFF),
    keyboardAccessoryForeground: Color(0xB3000000),
    keyboardAccessoryDisabledForeground: Color(0x36000000),
    keyboardAccessoryDivider: Color(0x1A000000),
    keyboardAccessoryHoverOverlay: Color(0x14000000),
    keyboardAccessoryPressedOverlay: Color(0x1F000000),
    keyboardAccessoryFocusOutline: Color(0xFF000000),
    keyboardAccessoryFocusOuterRing: Color(0xFF5B7FFF),
    keyboardAccessoryShadow: Color(0x26000000),
    cardSurface: Color(0x14000000),
    cardBorder: Color(0x14000000),
    pressableHoverOverlay: Color(0x14000000),
    pressablePressedOverlay: Color(0x1F000000),
    pressableFocusOutline: Color(0xFF000000),
    pressableFocusOuterRing: Color(0xFF5B7FFF),
    statusSuccess: Color(0xFF10B981),
    statusError: Color(0xFFFF3B30),
    statusWarning: Color(0xFFFF9500),
    statusInfo: Color(0xFF4ECDC4),
    statusForeground: Color(0xFFFFFFFF),
    disabledForeground: Color(0xFF6B7280),
    focusOutlineWidth: 2,
    focusRingWidth: 3,
    keyboardAccessoryBlur: 20,
    glassBlur: 25,
    glassSaturation: 1.8,
    glassHighlight: Color(0x99FFFFFF),
    glassShadowEnabled: true,
  );

  static const BLabTokenTheme dark = BLabTokenTheme(
    surfaceBase: Color(0xFF121212),
    surfaceRaised: Color(0xFF1E1E1E),
    surfaceOverlay: Color(0xFF1E1E1E),
    glassSurface: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xDDFFFFFF),
    textTertiary: Color(0x99FFFFFF),
    textInverse: Color(0xFF000000),
    borderSubtle: Color(0x14FFFFFF),
    borderDefault: Color(0x26FFFFFF),
    borderStrong: Color(0x38FFFFFF),
    focusRing: Color(0xFF5B7FFF),
    focusCanvas: Color(0xFF5B7FFF),
    focusSurface: Color(0xFF5B7FFF),
    focusAccent: Color(0xFFFFFFFF),
    actionPrimary: Color(0xFF5B7FFF),
    actionPrimaryForeground: Color(0xFF000000),
    actionDestructive: Color(0xFFFF3B30),
    actionDestructiveForeground: Color(0xFF000000),
    buttonPrimaryHoverOverlay: Color(0x14000000),
    buttonSecondaryHoverOverlay: Color(0x14FFFFFF),
    buttonDestructiveHoverOverlay: Color(0x14000000),
    buttonPrimaryFocusOutline: Color(0xFFFFFFFF),
    buttonSecondaryFocusOutline: Color(0xFFFFFFFF),
    buttonDestructiveFocusOutline: Color(0xFFFFFFFF),
    buttonFocusOuterRing: Color(0xFF5B7FFF),
    textFieldLabel: Color(0xB3FFFFFF),
    textFieldHint: Color(0x99FFFFFF),
    textFieldHoverBorder: Color(0x38FFFFFF),
    textFieldFocusOutline: Color(0xFFFFFFFF),
    textFieldFocusOuterRing: Color(0xFF5B7FFF),
    textFieldErrorBorder: Color(0xFFFF3B30),
    textFieldClearBackground: Color(0x99FFFFFF),
    textFieldClearForeground: Color(0xFF000000),
    segmentedContainerSurface: Color(0xFF232323),
    segmentedContainerBorder: Color(0x00000000),
    segmentedSelectedSurface: Color(0xFF2C2C2E),
    segmentedSelectedIndicator: Color(0xFF5B7FFF),
    segmentedSelectedForeground: Color(0xFFFFFFFF),
    segmentedUnselectedForeground: Color(0xDDFFFFFF),
    segmentedDisabledForeground: Color(0xFF9CA3AF),
    segmentedHoverOverlay: Color(0x14FFFFFF),
    segmentedPressedOverlay: Color(0x1FFFFFFF),
    segmentedFocusOutline: Color(0xFFFFFFFF),
    segmentedFocusOuterRing: Color(0xFF5B7FFF),
    segmentedSelectedShadow: Color(0x14000000),
    snackbarSurface: Color(0xFF1E1E1E),
    snackbarForeground: Color(0xFFFFFFFF),
    snackbarBorder: Color(0x26FFFFFF),
    snackbarBadgeSuccess: Color(0xFF10B981),
    snackbarBadgeError: Color(0xFFFF3B30),
    snackbarBadgeWarning: Color(0xFFFF9500),
    snackbarBadgeInfo: Color(0xFF4ECDC4),
    snackbarBadgeGlyph: Color(0xFF000000),
    snackbarBadgeOutline: Color(0x00000000),
    keyboardAccessorySurfaceStart: Color(0x26FFFFFF),
    keyboardAccessorySurfaceEnd: Color(0x14FFFFFF),
    keyboardAccessoryBorder: Color(0x33FFFFFF),
    keyboardAccessoryForeground: Color(0xE6FFFFFF),
    keyboardAccessoryDisabledForeground: Color(0x45FFFFFF),
    keyboardAccessoryDivider: Color(0x33FFFFFF),
    keyboardAccessoryHoverOverlay: Color(0x14FFFFFF),
    keyboardAccessoryPressedOverlay: Color(0x1FFFFFFF),
    keyboardAccessoryFocusOutline: Color(0xFFFFFFFF),
    keyboardAccessoryFocusOuterRing: Color(0xFF5B7FFF),
    keyboardAccessoryShadow: Color(0x26000000),
    cardSurface: Color(0x1FFFFFFF),
    cardBorder: Color(0x26FFFFFF),
    pressableHoverOverlay: Color(0x14FFFFFF),
    pressablePressedOverlay: Color(0x1FFFFFFF),
    pressableFocusOutline: Color(0xFFFFFFFF),
    pressableFocusOuterRing: Color(0xFF5B7FFF),
    statusSuccess: Color(0xFF10B981),
    statusError: Color(0xFFFF3B30),
    statusWarning: Color(0xFFFF9500),
    statusInfo: Color(0xFF4ECDC4),
    statusForeground: Color(0xFFFFFFFF),
    disabledForeground: Color(0xFF9CA3AF),
    focusOutlineWidth: 2,
    focusRingWidth: 3,
    keyboardAccessoryBlur: 20,
    glassBlur: 25,
    glassSaturation: 1.8,
    glassHighlight: Color(0x26FFFFFF),
    glassShadowEnabled: true,
  );

  static const BLabTokenTheme highContrastLight = BLabTokenTheme(
    surfaceBase: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFFFFFFF),
    glassSurface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000),
    textTertiary: Color(0xFF000000),
    textInverse: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFF000000),
    borderDefault: Color(0xFF000000),
    borderStrong: Color(0xFF000000),
    focusRing: Color(0xFF000000),
    focusCanvas: Color(0xFF000000),
    focusSurface: Color(0xFF000000),
    focusAccent: Color(0xFF000000),
    actionPrimary: Color(0xFF5B7FFF),
    actionPrimaryForeground: Color(0xFF000000),
    actionDestructive: Color(0xFFFF3B30),
    actionDestructiveForeground: Color(0xFF000000),
    buttonPrimaryHoverOverlay: Color(0x1FFFFFFF),
    buttonSecondaryHoverOverlay: Color(0x1F000000),
    buttonDestructiveHoverOverlay: Color(0x1FFFFFFF),
    buttonPrimaryFocusOutline: Color(0xFF000000),
    buttonSecondaryFocusOutline: Color(0xFF000000),
    buttonDestructiveFocusOutline: Color(0xFF000000),
    buttonFocusOuterRing: Color(0xFF000000),
    textFieldLabel: Color(0xFF000000),
    textFieldHint: Color(0xFF000000),
    textFieldHoverBorder: Color(0xFF000000),
    textFieldFocusOutline: Color(0xFF000000),
    textFieldFocusOuterRing: Color(0xFF000000),
    textFieldErrorBorder: Color(0xFFFF3B30),
    textFieldClearBackground: Color(0xFF000000),
    textFieldClearForeground: Color(0xFFFFFFFF),
    segmentedContainerSurface: Color(0xFFFFFFFF),
    segmentedContainerBorder: Color(0xFF000000),
    segmentedSelectedSurface: Color(0xFFFFFFFF),
    segmentedSelectedIndicator: Color(0xFF000000),
    segmentedSelectedForeground: Color(0xFF000000),
    segmentedUnselectedForeground: Color(0xFF000000),
    segmentedDisabledForeground: Color(0xFF6B7280),
    segmentedHoverOverlay: Color(0x1F000000),
    segmentedPressedOverlay: Color(0x33000000),
    segmentedFocusOutline: Color(0xFF000000),
    segmentedFocusOuterRing: Color(0xFF000000),
    segmentedSelectedShadow: Color(0x00000000),
    snackbarSurface: Color(0xFFFFFFFF),
    snackbarForeground: Color(0xFF000000),
    snackbarBorder: Color(0xFF000000),
    snackbarBadgeSuccess: Color(0xFF10B981),
    snackbarBadgeError: Color(0xFFFF3B30),
    snackbarBadgeWarning: Color(0xFFFF9500),
    snackbarBadgeInfo: Color(0xFF4ECDC4),
    snackbarBadgeGlyph: Color(0xFF000000),
    snackbarBadgeOutline: Color(0xFF000000),
    keyboardAccessorySurfaceStart: Color(0xFFFFFFFF),
    keyboardAccessorySurfaceEnd: Color(0xFFFFFFFF),
    keyboardAccessoryBorder: Color(0xFF000000),
    keyboardAccessoryForeground: Color(0xFF000000),
    keyboardAccessoryDisabledForeground: Color(0xFF6B7280),
    keyboardAccessoryDivider: Color(0xFF000000),
    keyboardAccessoryHoverOverlay: Color(0x1F000000),
    keyboardAccessoryPressedOverlay: Color(0x33000000),
    keyboardAccessoryFocusOutline: Color(0xFF000000),
    keyboardAccessoryFocusOuterRing: Color(0xFF000000),
    keyboardAccessoryShadow: Color(0x00000000),
    cardSurface: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF000000),
    pressableHoverOverlay: Color(0x1F000000),
    pressablePressedOverlay: Color(0x33000000),
    pressableFocusOutline: Color(0xFF000000),
    pressableFocusOuterRing: Color(0xFF000000),
    statusSuccess: Color(0xFF10B981),
    statusError: Color(0xFFFF3B30),
    statusWarning: Color(0xFFFF9500),
    statusInfo: Color(0xFF4ECDC4),
    statusForeground: Color(0xFF000000),
    disabledForeground: Color(0xFF6B7280),
    focusOutlineWidth: 2,
    focusRingWidth: 3,
    keyboardAccessoryBlur: 0,
    glassBlur: 0,
    glassSaturation: 1.0,
    glassHighlight: null,
    glassShadowEnabled: false,
  );

  static const BLabTokenTheme highContrastDark = BLabTokenTheme(
    surfaceBase: Color(0xFF121212),
    surfaceRaised: Color(0xFF121212),
    surfaceOverlay: Color(0xFF121212),
    glassSurface: Color(0xFF121212),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFFFFFFF),
    textTertiary: Color(0xFFFFFFFF),
    textInverse: Color(0xFF000000),
    borderSubtle: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFFFFFFF),
    borderStrong: Color(0xFFFFFFFF),
    focusRing: Color(0xFFFFFFFF),
    focusCanvas: Color(0xFFFFFFFF),
    focusSurface: Color(0xFFFFFFFF),
    focusAccent: Color(0xFF000000),
    actionPrimary: Color(0xFF5B7FFF),
    actionPrimaryForeground: Color(0xFF000000),
    actionDestructive: Color(0xFFFF3B30),
    actionDestructiveForeground: Color(0xFF000000),
    buttonPrimaryHoverOverlay: Color(0x1FFFFFFF),
    buttonSecondaryHoverOverlay: Color(0x1FFFFFFF),
    buttonDestructiveHoverOverlay: Color(0x1FFFFFFF),
    buttonPrimaryFocusOutline: Color(0xFF000000),
    buttonSecondaryFocusOutline: Color(0xFFFFFFFF),
    buttonDestructiveFocusOutline: Color(0xFF000000),
    buttonFocusOuterRing: Color(0xFFFFFFFF),
    textFieldLabel: Color(0xFFFFFFFF),
    textFieldHint: Color(0xFFFFFFFF),
    textFieldHoverBorder: Color(0xFFFFFFFF),
    textFieldFocusOutline: Color(0xFFFFFFFF),
    textFieldFocusOuterRing: Color(0xFFFFFFFF),
    textFieldErrorBorder: Color(0xFFFF3B30),
    textFieldClearBackground: Color(0xFFFFFFFF),
    textFieldClearForeground: Color(0xFF000000),
    segmentedContainerSurface: Color(0xFF121212),
    segmentedContainerBorder: Color(0xFFFFFFFF),
    segmentedSelectedSurface: Color(0xFF121212),
    segmentedSelectedIndicator: Color(0xFFFFFFFF),
    segmentedSelectedForeground: Color(0xFFFFFFFF),
    segmentedUnselectedForeground: Color(0xFFFFFFFF),
    segmentedDisabledForeground: Color(0xFF9CA3AF),
    segmentedHoverOverlay: Color(0x1FFFFFFF),
    segmentedPressedOverlay: Color(0x33FFFFFF),
    segmentedFocusOutline: Color(0xFFFFFFFF),
    segmentedFocusOuterRing: Color(0xFFFFFFFF),
    segmentedSelectedShadow: Color(0x00000000),
    snackbarSurface: Color(0xFF121212),
    snackbarForeground: Color(0xFFFFFFFF),
    snackbarBorder: Color(0xFFFFFFFF),
    snackbarBadgeSuccess: Color(0xFF10B981),
    snackbarBadgeError: Color(0xFFFF3B30),
    snackbarBadgeWarning: Color(0xFFFF9500),
    snackbarBadgeInfo: Color(0xFF4ECDC4),
    snackbarBadgeGlyph: Color(0xFF000000),
    snackbarBadgeOutline: Color(0xFFFFFFFF),
    keyboardAccessorySurfaceStart: Color(0xFF121212),
    keyboardAccessorySurfaceEnd: Color(0xFF121212),
    keyboardAccessoryBorder: Color(0xFFFFFFFF),
    keyboardAccessoryForeground: Color(0xFFFFFFFF),
    keyboardAccessoryDisabledForeground: Color(0xFF9CA3AF),
    keyboardAccessoryDivider: Color(0xFFFFFFFF),
    keyboardAccessoryHoverOverlay: Color(0x1FFFFFFF),
    keyboardAccessoryPressedOverlay: Color(0x33FFFFFF),
    keyboardAccessoryFocusOutline: Color(0xFFFFFFFF),
    keyboardAccessoryFocusOuterRing: Color(0xFFFFFFFF),
    keyboardAccessoryShadow: Color(0x00000000),
    cardSurface: Color(0xFF121212),
    cardBorder: Color(0xFFFFFFFF),
    pressableHoverOverlay: Color(0x1FFFFFFF),
    pressablePressedOverlay: Color(0x33FFFFFF),
    pressableFocusOutline: Color(0xFFFFFFFF),
    pressableFocusOuterRing: Color(0xFFFFFFFF),
    statusSuccess: Color(0xFF10B981),
    statusError: Color(0xFFFF3B30),
    statusWarning: Color(0xFFFF9500),
    statusInfo: Color(0xFF4ECDC4),
    statusForeground: Color(0xFF000000),
    disabledForeground: Color(0xFF9CA3AF),
    focusOutlineWidth: 2,
    focusRingWidth: 3,
    keyboardAccessoryBlur: 0,
    glassBlur: 0,
    glassSaturation: 1.0,
    glassHighlight: null,
    glassShadowEnabled: false,
  );

  static BLabTokenTheme forMode(BLabVisualMode mode) {
    return switch (mode) {
      BLabVisualMode.light => light,
      BLabVisualMode.dark => dark,
      BLabVisualMode.highContrastLight => highContrastLight,
      BLabVisualMode.highContrastDark => highContrastDark,
    };
  }

  @override
  BLabTokenTheme copyWith({
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? glassSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? focusRing,
    Color? focusCanvas,
    Color? focusSurface,
    Color? focusAccent,
    Color? actionPrimary,
    Color? actionPrimaryForeground,
    Color? actionDestructive,
    Color? actionDestructiveForeground,
    Color? buttonPrimaryHoverOverlay,
    Color? buttonSecondaryHoverOverlay,
    Color? buttonDestructiveHoverOverlay,
    Color? buttonPrimaryFocusOutline,
    Color? buttonSecondaryFocusOutline,
    Color? buttonDestructiveFocusOutline,
    Color? buttonFocusOuterRing,
    Color? textFieldLabel,
    Color? textFieldHint,
    Color? textFieldHoverBorder,
    Color? textFieldFocusOutline,
    Color? textFieldFocusOuterRing,
    Color? textFieldErrorBorder,
    Color? textFieldClearBackground,
    Color? textFieldClearForeground,
    Color? segmentedContainerSurface,
    Color? segmentedContainerBorder,
    Color? segmentedSelectedSurface,
    Color? segmentedSelectedIndicator,
    Color? segmentedSelectedForeground,
    Color? segmentedUnselectedForeground,
    Color? segmentedDisabledForeground,
    Color? segmentedHoverOverlay,
    Color? segmentedPressedOverlay,
    Color? segmentedFocusOutline,
    Color? segmentedFocusOuterRing,
    Color? segmentedSelectedShadow,
    Color? snackbarSurface,
    Color? snackbarForeground,
    Color? snackbarBorder,
    Color? snackbarBadgeSuccess,
    Color? snackbarBadgeError,
    Color? snackbarBadgeWarning,
    Color? snackbarBadgeInfo,
    Color? snackbarBadgeGlyph,
    Color? snackbarBadgeOutline,
    Color? keyboardAccessorySurfaceStart,
    Color? keyboardAccessorySurfaceEnd,
    Color? keyboardAccessoryBorder,
    Color? keyboardAccessoryForeground,
    Color? keyboardAccessoryDisabledForeground,
    Color? keyboardAccessoryDivider,
    Color? keyboardAccessoryHoverOverlay,
    Color? keyboardAccessoryPressedOverlay,
    Color? keyboardAccessoryFocusOutline,
    Color? keyboardAccessoryFocusOuterRing,
    Color? keyboardAccessoryShadow,
    Color? cardSurface,
    Color? cardBorder,
    Color? pressableHoverOverlay,
    Color? pressablePressedOverlay,
    Color? pressableFocusOutline,
    Color? pressableFocusOuterRing,
    Color? statusSuccess,
    Color? statusError,
    Color? statusWarning,
    Color? statusInfo,
    Color? statusForeground,
    Color? disabledForeground,
    double? focusOutlineWidth,
    double? focusRingWidth,
    double? keyboardAccessoryBlur,
    double? glassBlur,
    double? glassSaturation,
    Color? glassHighlight,
    bool clearGlassHighlight = false,
    bool? glassShadowEnabled,
  }) {
    return BLabTokenTheme(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      glassSurface: glassSurface ?? this.glassSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      focusRing: focusRing ?? this.focusRing,
      focusCanvas: focusCanvas ?? this.focusCanvas,
      focusSurface: focusSurface ?? this.focusSurface,
      focusAccent: focusAccent ?? this.focusAccent,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryForeground:
          actionPrimaryForeground ?? this.actionPrimaryForeground,
      actionDestructive: actionDestructive ?? this.actionDestructive,
      actionDestructiveForeground:
          actionDestructiveForeground ?? this.actionDestructiveForeground,
      buttonPrimaryHoverOverlay:
          buttonPrimaryHoverOverlay ?? this.buttonPrimaryHoverOverlay,
      buttonSecondaryHoverOverlay:
          buttonSecondaryHoverOverlay ?? this.buttonSecondaryHoverOverlay,
      buttonDestructiveHoverOverlay:
          buttonDestructiveHoverOverlay ?? this.buttonDestructiveHoverOverlay,
      buttonPrimaryFocusOutline:
          buttonPrimaryFocusOutline ?? this.buttonPrimaryFocusOutline,
      buttonSecondaryFocusOutline:
          buttonSecondaryFocusOutline ?? this.buttonSecondaryFocusOutline,
      buttonDestructiveFocusOutline:
          buttonDestructiveFocusOutline ?? this.buttonDestructiveFocusOutline,
      buttonFocusOuterRing: buttonFocusOuterRing ?? this.buttonFocusOuterRing,
      textFieldLabel: textFieldLabel ?? this.textFieldLabel,
      textFieldHint: textFieldHint ?? this.textFieldHint,
      textFieldHoverBorder: textFieldHoverBorder ?? this.textFieldHoverBorder,
      textFieldFocusOutline:
          textFieldFocusOutline ?? this.textFieldFocusOutline,
      textFieldFocusOuterRing:
          textFieldFocusOuterRing ?? this.textFieldFocusOuterRing,
      textFieldErrorBorder: textFieldErrorBorder ?? this.textFieldErrorBorder,
      textFieldClearBackground:
          textFieldClearBackground ?? this.textFieldClearBackground,
      textFieldClearForeground:
          textFieldClearForeground ?? this.textFieldClearForeground,
      segmentedContainerSurface:
          segmentedContainerSurface ?? this.segmentedContainerSurface,
      segmentedContainerBorder:
          segmentedContainerBorder ?? this.segmentedContainerBorder,
      segmentedSelectedSurface:
          segmentedSelectedSurface ?? this.segmentedSelectedSurface,
      segmentedSelectedIndicator:
          segmentedSelectedIndicator ?? this.segmentedSelectedIndicator,
      segmentedSelectedForeground:
          segmentedSelectedForeground ?? this.segmentedSelectedForeground,
      segmentedUnselectedForeground:
          segmentedUnselectedForeground ?? this.segmentedUnselectedForeground,
      segmentedDisabledForeground:
          segmentedDisabledForeground ?? this.segmentedDisabledForeground,
      segmentedHoverOverlay:
          segmentedHoverOverlay ?? this.segmentedHoverOverlay,
      segmentedPressedOverlay:
          segmentedPressedOverlay ?? this.segmentedPressedOverlay,
      segmentedFocusOutline:
          segmentedFocusOutline ?? this.segmentedFocusOutline,
      segmentedFocusOuterRing:
          segmentedFocusOuterRing ?? this.segmentedFocusOuterRing,
      segmentedSelectedShadow:
          segmentedSelectedShadow ?? this.segmentedSelectedShadow,
      snackbarSurface: snackbarSurface ?? this.snackbarSurface,
      snackbarForeground: snackbarForeground ?? this.snackbarForeground,
      snackbarBorder: snackbarBorder ?? this.snackbarBorder,
      snackbarBadgeSuccess: snackbarBadgeSuccess ?? this.snackbarBadgeSuccess,
      snackbarBadgeError: snackbarBadgeError ?? this.snackbarBadgeError,
      snackbarBadgeWarning: snackbarBadgeWarning ?? this.snackbarBadgeWarning,
      snackbarBadgeInfo: snackbarBadgeInfo ?? this.snackbarBadgeInfo,
      snackbarBadgeGlyph: snackbarBadgeGlyph ?? this.snackbarBadgeGlyph,
      snackbarBadgeOutline: snackbarBadgeOutline ?? this.snackbarBadgeOutline,
      keyboardAccessorySurfaceStart:
          keyboardAccessorySurfaceStart ?? this.keyboardAccessorySurfaceStart,
      keyboardAccessorySurfaceEnd:
          keyboardAccessorySurfaceEnd ?? this.keyboardAccessorySurfaceEnd,
      keyboardAccessoryBorder:
          keyboardAccessoryBorder ?? this.keyboardAccessoryBorder,
      keyboardAccessoryForeground:
          keyboardAccessoryForeground ?? this.keyboardAccessoryForeground,
      keyboardAccessoryDisabledForeground:
          keyboardAccessoryDisabledForeground ??
          this.keyboardAccessoryDisabledForeground,
      keyboardAccessoryDivider:
          keyboardAccessoryDivider ?? this.keyboardAccessoryDivider,
      keyboardAccessoryHoverOverlay:
          keyboardAccessoryHoverOverlay ?? this.keyboardAccessoryHoverOverlay,
      keyboardAccessoryPressedOverlay:
          keyboardAccessoryPressedOverlay ??
          this.keyboardAccessoryPressedOverlay,
      keyboardAccessoryFocusOutline:
          keyboardAccessoryFocusOutline ?? this.keyboardAccessoryFocusOutline,
      keyboardAccessoryFocusOuterRing:
          keyboardAccessoryFocusOuterRing ??
          this.keyboardAccessoryFocusOuterRing,
      keyboardAccessoryShadow:
          keyboardAccessoryShadow ?? this.keyboardAccessoryShadow,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      pressableHoverOverlay:
          pressableHoverOverlay ?? this.pressableHoverOverlay,
      pressablePressedOverlay:
          pressablePressedOverlay ?? this.pressablePressedOverlay,
      pressableFocusOutline:
          pressableFocusOutline ?? this.pressableFocusOutline,
      pressableFocusOuterRing:
          pressableFocusOuterRing ?? this.pressableFocusOuterRing,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      statusWarning: statusWarning ?? this.statusWarning,
      statusInfo: statusInfo ?? this.statusInfo,
      statusForeground: statusForeground ?? this.statusForeground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      focusOutlineWidth: focusOutlineWidth ?? this.focusOutlineWidth,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      keyboardAccessoryBlur:
          keyboardAccessoryBlur ?? this.keyboardAccessoryBlur,
      glassBlur: glassBlur ?? this.glassBlur,
      glassSaturation: glassSaturation ?? this.glassSaturation,
      glassHighlight: clearGlassHighlight
          ? null
          : glassHighlight ?? this.glassHighlight,
      glassShadowEnabled: glassShadowEnabled ?? this.glassShadowEnabled,
    );
  }

  @override
  BLabTokenTheme lerp(covariant BLabTokenTheme? other, double t) {
    if (other == null) return this;
    return BLabTokenTheme(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      focusCanvas: Color.lerp(focusCanvas, other.focusCanvas, t)!,
      focusSurface: Color.lerp(focusSurface, other.focusSurface, t)!,
      focusAccent: Color.lerp(focusAccent, other.focusAccent, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryForeground: Color.lerp(
        actionPrimaryForeground,
        other.actionPrimaryForeground,
        t,
      )!,
      actionDestructive: Color.lerp(
        actionDestructive,
        other.actionDestructive,
        t,
      )!,
      actionDestructiveForeground: Color.lerp(
        actionDestructiveForeground,
        other.actionDestructiveForeground,
        t,
      )!,
      buttonPrimaryHoverOverlay: Color.lerp(
        buttonPrimaryHoverOverlay,
        other.buttonPrimaryHoverOverlay,
        t,
      )!,
      buttonSecondaryHoverOverlay: Color.lerp(
        buttonSecondaryHoverOverlay,
        other.buttonSecondaryHoverOverlay,
        t,
      )!,
      buttonDestructiveHoverOverlay: Color.lerp(
        buttonDestructiveHoverOverlay,
        other.buttonDestructiveHoverOverlay,
        t,
      )!,
      buttonPrimaryFocusOutline: Color.lerp(
        buttonPrimaryFocusOutline,
        other.buttonPrimaryFocusOutline,
        t,
      )!,
      buttonSecondaryFocusOutline: Color.lerp(
        buttonSecondaryFocusOutline,
        other.buttonSecondaryFocusOutline,
        t,
      )!,
      buttonDestructiveFocusOutline: Color.lerp(
        buttonDestructiveFocusOutline,
        other.buttonDestructiveFocusOutline,
        t,
      )!,
      buttonFocusOuterRing: Color.lerp(
        buttonFocusOuterRing,
        other.buttonFocusOuterRing,
        t,
      )!,
      textFieldLabel: Color.lerp(textFieldLabel, other.textFieldLabel, t)!,
      textFieldHint: Color.lerp(textFieldHint, other.textFieldHint, t)!,
      textFieldHoverBorder: Color.lerp(
        textFieldHoverBorder,
        other.textFieldHoverBorder,
        t,
      )!,
      textFieldFocusOutline: Color.lerp(
        textFieldFocusOutline,
        other.textFieldFocusOutline,
        t,
      )!,
      textFieldFocusOuterRing: Color.lerp(
        textFieldFocusOuterRing,
        other.textFieldFocusOuterRing,
        t,
      )!,
      textFieldErrorBorder: Color.lerp(
        textFieldErrorBorder,
        other.textFieldErrorBorder,
        t,
      )!,
      textFieldClearBackground: Color.lerp(
        textFieldClearBackground,
        other.textFieldClearBackground,
        t,
      )!,
      textFieldClearForeground: Color.lerp(
        textFieldClearForeground,
        other.textFieldClearForeground,
        t,
      )!,
      segmentedContainerSurface: Color.lerp(
        segmentedContainerSurface,
        other.segmentedContainerSurface,
        t,
      )!,
      segmentedContainerBorder: Color.lerp(
        segmentedContainerBorder,
        other.segmentedContainerBorder,
        t,
      )!,
      segmentedSelectedSurface: Color.lerp(
        segmentedSelectedSurface,
        other.segmentedSelectedSurface,
        t,
      )!,
      segmentedSelectedIndicator: Color.lerp(
        segmentedSelectedIndicator,
        other.segmentedSelectedIndicator,
        t,
      )!,
      segmentedSelectedForeground: Color.lerp(
        segmentedSelectedForeground,
        other.segmentedSelectedForeground,
        t,
      )!,
      segmentedUnselectedForeground: Color.lerp(
        segmentedUnselectedForeground,
        other.segmentedUnselectedForeground,
        t,
      )!,
      segmentedDisabledForeground: Color.lerp(
        segmentedDisabledForeground,
        other.segmentedDisabledForeground,
        t,
      )!,
      segmentedHoverOverlay: Color.lerp(
        segmentedHoverOverlay,
        other.segmentedHoverOverlay,
        t,
      )!,
      segmentedPressedOverlay: Color.lerp(
        segmentedPressedOverlay,
        other.segmentedPressedOverlay,
        t,
      )!,
      segmentedFocusOutline: Color.lerp(
        segmentedFocusOutline,
        other.segmentedFocusOutline,
        t,
      )!,
      segmentedFocusOuterRing: Color.lerp(
        segmentedFocusOuterRing,
        other.segmentedFocusOuterRing,
        t,
      )!,
      segmentedSelectedShadow: Color.lerp(
        segmentedSelectedShadow,
        other.segmentedSelectedShadow,
        t,
      )!,
      snackbarSurface: Color.lerp(snackbarSurface, other.snackbarSurface, t)!,
      snackbarForeground: Color.lerp(
        snackbarForeground,
        other.snackbarForeground,
        t,
      )!,
      snackbarBorder: Color.lerp(snackbarBorder, other.snackbarBorder, t)!,
      snackbarBadgeSuccess: Color.lerp(
        snackbarBadgeSuccess,
        other.snackbarBadgeSuccess,
        t,
      )!,
      snackbarBadgeError: Color.lerp(
        snackbarBadgeError,
        other.snackbarBadgeError,
        t,
      )!,
      snackbarBadgeWarning: Color.lerp(
        snackbarBadgeWarning,
        other.snackbarBadgeWarning,
        t,
      )!,
      snackbarBadgeInfo: Color.lerp(
        snackbarBadgeInfo,
        other.snackbarBadgeInfo,
        t,
      )!,
      snackbarBadgeGlyph: Color.lerp(
        snackbarBadgeGlyph,
        other.snackbarBadgeGlyph,
        t,
      )!,
      snackbarBadgeOutline: Color.lerp(
        snackbarBadgeOutline,
        other.snackbarBadgeOutline,
        t,
      )!,
      keyboardAccessorySurfaceStart: Color.lerp(
        keyboardAccessorySurfaceStart,
        other.keyboardAccessorySurfaceStart,
        t,
      )!,
      keyboardAccessorySurfaceEnd: Color.lerp(
        keyboardAccessorySurfaceEnd,
        other.keyboardAccessorySurfaceEnd,
        t,
      )!,
      keyboardAccessoryBorder: Color.lerp(
        keyboardAccessoryBorder,
        other.keyboardAccessoryBorder,
        t,
      )!,
      keyboardAccessoryForeground: Color.lerp(
        keyboardAccessoryForeground,
        other.keyboardAccessoryForeground,
        t,
      )!,
      keyboardAccessoryDisabledForeground: Color.lerp(
        keyboardAccessoryDisabledForeground,
        other.keyboardAccessoryDisabledForeground,
        t,
      )!,
      keyboardAccessoryDivider: Color.lerp(
        keyboardAccessoryDivider,
        other.keyboardAccessoryDivider,
        t,
      )!,
      keyboardAccessoryHoverOverlay: Color.lerp(
        keyboardAccessoryHoverOverlay,
        other.keyboardAccessoryHoverOverlay,
        t,
      )!,
      keyboardAccessoryPressedOverlay: Color.lerp(
        keyboardAccessoryPressedOverlay,
        other.keyboardAccessoryPressedOverlay,
        t,
      )!,
      keyboardAccessoryFocusOutline: Color.lerp(
        keyboardAccessoryFocusOutline,
        other.keyboardAccessoryFocusOutline,
        t,
      )!,
      keyboardAccessoryFocusOuterRing: Color.lerp(
        keyboardAccessoryFocusOuterRing,
        other.keyboardAccessoryFocusOuterRing,
        t,
      )!,
      keyboardAccessoryShadow: Color.lerp(
        keyboardAccessoryShadow,
        other.keyboardAccessoryShadow,
        t,
      )!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      pressableHoverOverlay: Color.lerp(
        pressableHoverOverlay,
        other.pressableHoverOverlay,
        t,
      )!,
      pressablePressedOverlay: Color.lerp(
        pressablePressedOverlay,
        other.pressablePressedOverlay,
        t,
      )!,
      pressableFocusOutline: Color.lerp(
        pressableFocusOutline,
        other.pressableFocusOutline,
        t,
      )!,
      pressableFocusOuterRing: Color.lerp(
        pressableFocusOuterRing,
        other.pressableFocusOuterRing,
        t,
      )!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      statusForeground: Color.lerp(
        statusForeground,
        other.statusForeground,
        t,
      )!,
      disabledForeground: Color.lerp(
        disabledForeground,
        other.disabledForeground,
        t,
      )!,
      focusOutlineWidth:
          focusOutlineWidth + (other.focusOutlineWidth - focusOutlineWidth) * t,
      focusRingWidth:
          focusRingWidth + (other.focusRingWidth - focusRingWidth) * t,
      keyboardAccessoryBlur:
          keyboardAccessoryBlur +
          (other.keyboardAccessoryBlur - keyboardAccessoryBlur) * t,
      glassBlur: glassBlur + (other.glassBlur - glassBlur) * t,
      glassSaturation:
          glassSaturation + (other.glassSaturation - glassSaturation) * t,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t),
      glassShadowEnabled: t < 0.5
          ? glassShadowEnabled
          : other.glassShadowEnabled,
    );
  }
}
