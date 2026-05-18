import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/settings/presentation/widgets/section_header.dart';

class TasbihSection extends ConsumerWidget {
  const TasbihSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('خطأ: $error'),
      ),
      data: (st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('إعدادات المسبحة'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 Target Selection Header
                const Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'هدف الدورة (تسبيحة)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 🏷️ Goal Chips
                Wrap(
                  spacing: 8,
                  children: [33, 66, 99, 100].map((goal) {
                    final isSelected = st.tasbihTarget == goal;
                    return ChoiceChip(
                      label: Text('$goal'),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (selected) {
                          await ref
                              .read(settingsProvider.notifier)
                              .setTasbihTarget(goal);
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide.none,
                      showCheckmark: false,
                    );
                  }).toList(),
                ),

              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


}
