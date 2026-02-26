import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A Liquid Glass–styled tab bar for in-screen tab switching.
///
/// Wraps Flutter's [TabBar] with BLab design tokens (colors, typography,
/// dark/light mode support). Implements [PreferredSizeWidget] so it can be
/// used as an [AppBar.bottom] or placed inline.
///
/// Usage:
/// ```dart
/// BLabTabBar(
///   controller: _tabController,
///   tabs: const ['진행 중', '완료'],
/// )
/// ```
class BLabTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// The [TabController] that drives this tab bar.
  final TabController controller;

  /// Labels for each tab.
  final List<String> tabs;

  /// Color of the selection indicator. Defaults to theme-aware black/white.
  final Color? indicatorColor;

  /// Text color for the selected tab. Defaults to theme-aware primary text.
  final Color? labelColor;

  /// Text color for unselected tabs. Defaults to grey.
  final Color? unselectedLabelColor;

  /// Thickness of the indicator line.
  final double indicatorWeight;

  /// Style override for selected tab text.
  final TextStyle? labelStyle;

  /// Style override for unselected tab text.
  final TextStyle? unselectedLabelStyle;

  /// Whether this tab bar is scrollable (for many tabs).
  /// Defaults to `false` (evenly distributed).
  final bool isScrollable;

  /// Optional callback when a tab is tapped.
  final ValueChanged<int>? onTap;

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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: controller,
      isScrollable: isScrollable,
      labelColor: labelColor ?? BLabColors.textPrimary(context),
      unselectedLabelColor:
          unselectedLabelColor ??
          (isDark ? Colors.grey[600] : Colors.grey[400]),
      indicatorColor: indicatorColor ?? (isDark ? Colors.white : Colors.black),
      indicatorWeight: indicatorWeight,
      labelStyle:
          labelStyle ??
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          unselectedLabelStyle ??
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
      dividerColor: Colors.transparent,
      onTap: onTap,
      tabs: tabs.map((tab) => Tab(text: tab)).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
