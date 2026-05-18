import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          children: const [
            AppearanceSection(),
            SizedBox(height: 12),
            SmartLearningSection(),
            SizedBox(height: 12),
            NotificationsSection(),
            SizedBox(height: 12),
            OfflineSection(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
