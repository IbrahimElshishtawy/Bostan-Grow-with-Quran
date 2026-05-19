import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/settings/presentation/widgets/appearance_section.dart';
import 'package:quranglow/features/settings/presentation/widgets/notifications_section.dart';
import 'package:quranglow/features/settings/presentation/widgets/offline_section.dart';
import 'package:quranglow/features/settings/presentation/widgets/smart_learning_section.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: ProAppBar(
          title: 'الإعدادات',
          subtitle: 'خصص القراءة والإشعارات والتعلم الذكي',
          onBack: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            }
          },
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const AppearanceSection(),
            const SizedBox(height: 12),
            const SmartLearningSection(),
            const SizedBox(height: 12),
            const NotificationsSection(),
            const SizedBox(height: 12),
            const OfflineSection(),
            const SizedBox(height: 12),
            // كارت التحقق من التحديثات
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              color: cs.surfaceContainerLow.withValues(alpha: 0.6),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref.read(appUpdateServiceProvider).checkForUpdate(context, forceShow: true);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.system_update_rounded, color: cs.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحديث التطبيق',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'التحقق يدويًا من وجود إصدارات جديدة متوفرة',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

