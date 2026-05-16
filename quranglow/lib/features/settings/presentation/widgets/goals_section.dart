import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart' as di;
import 'package:quranglow/features/ui/routes/app_routes.dart';

import 'section_header.dart';

class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final goalsAsync = ref.watch(di.goalsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('الأهداف اليومية'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.goals),
          child: Container(
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
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('إدارة الأهداف'),
                  const Spacer(),
                  Icon(Icons.chevron_left, color: cs.primary),
                ],
              ),
              data: (goals) {
                final active = goals.where((g) => g.active).length;
                final reminders = goals.where((g) => g.reminderEnabled).length;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.track_changes_rounded, color: cs.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إدارة الأهداف والتحديات',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$active هدف مفعّل • $reminders إشعار',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left, color: cs.primary),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
