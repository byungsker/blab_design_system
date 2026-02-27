import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An item for [BLabSegmentedControl].
class BLabSegmentedItem<T> {
  final T value;
  final String label;

  const BLabSegmentedItem({required this.value, required this.label});
}

/// A pill-shaped segmented control with card-style selection indicator.
///
/// Usage:
/// ```dart
/// BLabSegmentedControl<MyEnum>(
///   items: [
///     BLabSegmentedItem(value: MyEnum.first, label: 'First'),
///     BLabSegmentedItem(value: MyEnum.second, label: 'Second'),
///   ],
///   selectedValue: _selected,
///   onChanged: (value) => setState(() => _selected = value),
/// )
/// ```
class BLabSegmentedControl<T> extends StatelessWidget {
  final List<BLabSegmentedItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  /// Height of the control. Defaults to 40.
  final double height;

  /// Border radius of the outer container. Defaults to 10.
  final double borderRadius;

  /// Padding inside the outer container. Defaults to 3.
  final double padding;

  const BLabSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.height = 40,
    this.borderRadius = 10,
    this.padding = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = BLabColors.textPrimary(context);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.grey.shade100;

    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius - padding),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? BLabColors.primary
                          : textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
