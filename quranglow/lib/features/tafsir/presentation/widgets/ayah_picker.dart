import 'package:flutter/material.dart';

class AyahPicker extends StatelessWidget {
  const AyahPicker({
    super.key,
    required this.maxAyat,
    required this.ayah,
    required this.onAyahChange,
  });

  final int maxAyat;
  final int ayah;
  final void Function(int ayah) onAyahChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Using the same design as SelectionCard for consistency
    final Color primaryColor = const Color(0xFF1B4D3E);
    final Color accentColor = const Color(0xFFD4AF37);

    return DropdownButtonFormField<int>(
      value: ayah.clamp(1, maxAyat),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.15)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
        labelText: 'الآية',
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Tajawal',
        ),
      ),
      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Tajawal'),
      items: [
        for (int i = 1; i <= maxAyat; i++)
          DropdownMenuItem(value: i, child: Text(i.toString())),
      ],
      onChanged: (v) {
        if (v != null) onAyahChange(v);
      },
    );
  }
}
