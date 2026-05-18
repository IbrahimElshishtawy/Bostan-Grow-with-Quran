import 'package:flutter/material.dart';

class DhikrQuickList extends StatelessWidget {
  const DhikrQuickList({
    super.key,
    this.selectedItem,
    this.onTapItem,
  });

  final String? selectedItem;
  final ValueChanged<String>? onTapItem;

  static const items = <String>[
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'لا حول ولا قوة إلا بالله',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    final activeBgColor = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9);
    final inactiveBgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
    final activeBorderColor = isDark ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFF2E7D32).withOpacity(0.3);
    final inactiveBorderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) {
              final isSelected = selectedItem == item;
              return ChoiceChip(
                label: Text(item),
                avatar: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: isSelected ? primaryColor : (isDark ? Colors.white30 : Colors.black38),
                ),
                selected: isSelected,
                selectedColor: activeBgColor,
                backgroundColor: inactiveBgColor,
                side: BorderSide(
                  color: isSelected ? activeBorderColor : inactiveBorderColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                ),
                onSelected: (_) => onTapItem?.call(item),
                showCheckmark: false,
              );
            },
          )
          .toList(),
    );
  }
}
