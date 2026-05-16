import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/settings/presentation/widgets/section_header.dart';

class OfflineSection extends ConsumerStatefulWidget {
  const OfflineSection({super.key});

  @override
  ConsumerState<OfflineSection> createState() => _OfflineSectionState();
}

class _OfflineSectionState extends ConsumerState<OfflineSection> {
  bool _isSyncing = false;
  double _progress = 0;
  String _statusText = '';

  Future<void> _syncFullQuran() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _progress = 0;
      _statusText = 'جاري الاتصال بالسيرفر...';
    });

    try {
      final quranSvc = ref.read(quranServiceProvider);
      const editionId = 'quran-uthmani';
      
      setState(() => _statusText = 'جاري تحميل النص القرآني الكامل...');
      
      // We'll fetch it and QuranService already caches it in ApiCacheManager (Hive)
      // but we want to ensure it's fully available offline.
      final allSurahs = await quranSvc.getQuranAllText(editionId);
      
      setState(() {
        _progress = 1.0;
        _statusText = 'تم تحميل النص بنجاح! 🎉';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت مزامنة المصحف الشريف للاستخدام الأوفلاين'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _statusText = 'فشل التحميل: $e');
    } finally {
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isSyncing = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('الوصول الأوفلاين'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.primary.withOpacity(0.1), width: 1.5),
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
              Row(
                children: [
                  Icon(Icons.offline_pin_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'المحتوى الأوفلاين',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'يمكنك تحميل النص القرآني كاملاً لتصفحه في أي وقت بدون إنترنت، كما يمكنك تحميل السور الصوتية من داخل صفحة المصحف.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (_isSyncing) ...[
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _syncFullQuran,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text(
                      'مزامنة النص القرآني كاملاً',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
