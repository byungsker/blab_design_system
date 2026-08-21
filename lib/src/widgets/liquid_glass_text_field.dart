import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/focus_visibility.dart';
import '../foundation/interactive_target.dart';
import '../foundation/reduced_motion.dart';
import '../foundation/visual_mode_resolver.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/blab_token_theme.dart';

class BLabTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool isRequired;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final int maxLines;

  const BLabTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.onTap,
    this.suffixIcon,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  State<BLabTextField> createState() => _BLabTextFieldState();
}

class _BLabTextFieldState extends State<BLabTextField>
    with WidgetsBindingObserver {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _hasText = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
    _setFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(BLabTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _hasText = widget.controller.text.isNotEmpty;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _replaceFocusNode(widget.focusNode);
    }
    if (!widget.enabled) {
      _hovered = false;
      _focusNode.unfocus();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hovered || !mounted) return;
    setState(() => _hovered = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _setFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode(debugLabel: 'BLabTextField');
    _focusNode.addListener(_onFocusChanged);
  }

  void _replaceFocusNode(FocusNode? focusNode) {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    _setFocusNode(focusNode);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText && mounted) {
      setState(() => _hasText = hasText);
    }
  }

  void _clearText() {
    if (!widget.enabled || widget.readOnly) return;
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (BLabFocusVisibilityScope.maybeOf(context) != null) {
      return _buildField(context);
    }
    return BLabFocusVisibilityScope(child: Builder(builder: _buildField));
  }

  Widget _buildField(BuildContext context) {
    final visualMode = BLabVisualModeResolver.of(context);
    final tokens = visualMode.tokens;
    final focusVisibility = BLabFocusVisibilityScope.of(context);
    final showKeyboardFocus =
        widget.enabled &&
        focusVisibility.shouldShowVisibleFocus(hasFocus: _focusNode.hasFocus);
    final reducedMotion = BLabReducedMotionPolicy.of(context);
    final interactionDuration = reducedMotion.resolve(
      duration: BLabMotion.durPress,
      role: BLabTransitionRole.nonEssential,
    );
    final supportText = widget.errorText ?? widget.helperText;
    final semanticHint = [
      widget.hintText,
      supportText,
    ].whereType<String>().where((value) => value.isNotEmpty).join('. ');
    final borderColor = switch ((
      widget.enabled,
      _focusNode.hasFocus,
      widget.errorText != null,
      _hovered,
    )) {
      (false, _, _, _) => tokens.borderDefault,
      (true, true, _, _) => tokens.textFieldFocusOutline,
      (true, false, true, _) => tokens.textFieldErrorBorder,
      (true, false, false, true) => tokens.textFieldHoverBorder,
      (true, false, false, false) => tokens.borderDefault,
    };
    final borderWidth =
        widget.enabled &&
            (_focusNode.hasFocus ||
                (!_focusNode.hasFocus && widget.errorText != null))
        ? tokens.focusOutlineWidth
        : 0.5;
    final primaryTextColor = widget.enabled
        ? tokens.textPrimary
        : tokens.disabledForeground;
    final hintColor = widget.enabled
        ? tokens.textFieldHint
        : tokens.disabledForeground;
    final labelColor = widget.enabled
        ? tokens.textFieldLabel
        : tokens.disabledForeground;

    final surface = ClipRRect(
      borderRadius: BLabRadius.mdRect,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.glassBlur,
          sigmaY: tokens.glassBlur,
        ),
        child: AnimatedContainer(
          key: const ValueKey<String>('BLabTextField.surface'),
          duration: interactionDuration,
          curve: BLabMotion.ease,
          decoration: BoxDecoration(
            color: tokens.glassSurface,
            borderRadius: BLabRadius.mdRect,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Semantics(
            key: const ValueKey<String>('BLabTextField.fieldSemantics'),
            container: true,
            label: widget.label,
            hint: semanticHint.isEmpty ? null : semanticHint,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscured: widget.obscureText,
            multiline: !widget.obscureText && widget.maxLines != 1,
            isRequired: widget.isRequired,
            validationResult: widget.errorText == null
                ? SemanticsValidationResult.none
                : SemanticsValidationResult.invalid,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              obscureText: widget.obscureText,
              autofocus: widget.autofocus,
              onTap: widget.onTap,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              style: BLabTypography.body.copyWith(color: primaryTextColor),
              cursorColor: primaryTextColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: BLabTypography.body.copyWith(color: hintColor),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BLabSpacing.md,
                  vertical: 14,
                ),
                suffixIcon: _buildSuffixIcon(context, tokens),
              ),
            ),
          ),
        ),
      ),
    );

    final focusedSurface = Stack(
      clipBehavior: Clip.none,
      children: [
        if (showKeyboardFocus)
          Positioned.fill(
            left: -tokens.focusRingWidth,
            top: -tokens.focusRingWidth,
            right: -tokens.focusRingWidth,
            bottom: -tokens.focusRingWidth,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey<String>('BLabTextField.focusRing'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.textFieldFocusOuterRing,
                    width: tokens.focusRingWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    BLabRadius.md + tokens.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
        surface,
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: BLabTypography.label.copyWith(color: labelColor),
            ),
          ),
          SizedBox(height: BLabSpacing.sm),
        ],
        Listener(
          onPointerDown: (event) => focusVisibility.registerPointer(event.kind),
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            onEnter: widget.enabled
                ? (event) {
                    if (event.kind != PointerDeviceKind.touch) {
                      setState(() => _hovered = true);
                    }
                  }
                : null,
            onExit: (_) {
              if (_hovered) setState(() => _hovered = false);
            },
            child: BLabInteractiveTarget(child: focusedSurface),
          ),
        ),
        if (supportText != null) ...[
          SizedBox(height: BLabSpacing.sm),
          ExcludeSemantics(
            child: Text(
              supportText,
              key: const ValueKey<String>('BLabTextField.supportText'),
              style: BLabTypography.caption.copyWith(
                color: widget.errorText != null
                    ? tokens.textPrimary
                    : tokens.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon(BuildContext context, BLabTokenTheme tokens) {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }
    if (!widget.enabled || widget.readOnly || !_hasText) {
      return null;
    }

    final tooltip = MaterialLocalizations.of(context).clearButtonTooltip;
    return Semantics(
      label: tooltip,
      button: true,
      enabled: true,
      onTap: _clearText,
      child: ExcludeSemantics(
        child: IconButton(
          key: const ValueKey<String>('BLabTextField.clearAction'),
          tooltip: tooltip,
          onPressed: _clearText,
          constraints: const BoxConstraints(
            minWidth: BLabInteractiveTargetPolicy.minimumWidth,
            minHeight: BLabInteractiveTargetPolicy.minimumHeight,
          ),
          padding: EdgeInsets.zero,
          icon: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.textFieldClearBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: BLabSpacing.md,
              child: Icon(
                Icons.clear,
                color: tokens.textFieldClearForeground,
                size: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
