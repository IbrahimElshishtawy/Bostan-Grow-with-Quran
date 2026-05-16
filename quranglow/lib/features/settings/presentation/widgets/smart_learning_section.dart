import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/settings/presentation/widgets/section_header.dart';

class SmartLearningSection extends ConsumerWidget {
  const SmartLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;

    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('التعلم الذكي'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.primary.withOpacity(0.1),
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
                // 🧠 Smart Learning Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.psychology_rounded, color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تنبيهات التعلم النشط',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'تذكير ذكي عند الانقطاع عن القراءة أو التعلم',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: st.smartLearningEnabled,
                      onChanged: (val) => ref.read(settingsProvider.notifier).setSmartLearningEnabled(val),
                      activeColor: cs.primary,
                    ),
                  ],
                ),
                
                if (st.smartLearningEnabled) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'مستوى التحفيز',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 🏷️ Strictness Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _StrictnessChip(
                        label: 'لطيف',
                        value: 1,
                        currentValue: st.smartLearningStrictness,
                        onSelected: (val) => ref.read(settingsProvider.notifier).setSmartLearningStrictness(val),
                      ),
                      _StrictnessChip(
                        label: 'معتدل',
                        value: 2,
                        currentValue: st.smartLearningStrictness,
                        onSelected: (val) => ref.read(settingsProvider.notifier).setSmartLearningStrictness(val),
                      ),
                      _StrictnessChip(
                        label: 'مُلحّ',
                        value: 3,
                        currentValue: st.smartLearningStrictness,
                        onSelected: (val) => ref.read(settingsProvider.notifier).setSmartLearningStrictness(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    st.smartLearningStrictness == 3 
                      ? 'سيتم تذكيرك بشكل متكرر إذا لم تقم بفتح وردك اليومي.'
                      : st.smartLearningStrictness == 2
                        ? 'تنبيهات متوازنة تشجعك على الاستمرار في مسيرة التعلم.'
                        : 'تنبيهات هادئة تذكرك بلطف عند الغياب الطويل.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrictnessChip extends StatelessWidget {
  final String label;
  final int value;
  final int currentValue;
  final ValueChanged<int> onSelected;

  const _StrictnessChip({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;
    final cs = Theme.of(context).colorScheme;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : cs.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: cs.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
