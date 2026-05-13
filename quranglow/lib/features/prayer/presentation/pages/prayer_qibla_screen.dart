// ignore_for_file: dangling_library_doc_comments
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/prayer/presentation/widgets/prayer_clock_visualizer.dart';
import 'package:quranglow/features/qibla/presentation/widgets/qibla_compass.dart';

class PrayerQiblaScreen extends ConsumerStatefulWidget {
  const PrayerQiblaScreen({super.key});

  @override
  ConsumerState<PrayerQiblaScreen> createState() => _PrayerQiblaScreenState();
}

class _PrayerQiblaScreenState extends ConsumerState<PrayerQiblaScreen> {
  @override
  Widget build(BuildContext context) {
    final prayersAsync = ref.watch(todayPrayersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ProAppBar(
        title: 'المصلى',
        subtitle: 'مواقيت الصلاة واتجاه القبلة بدقة عالية',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface,
              cs.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: prayersAsync.when(
            data: (data) => RefreshIndicator(
              onRefresh: () => ref.refresh(todayPrayersProvider.future),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110), // extra padding for stack navbar
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Section 1: Real-time Clock Visualizer
                    PrayerClockVisualizer(data: data),
                    const SizedBox(height: 28),

                    // Section 2: Dynamic Prayer Times Schedule Grid
                    _buildPrayerTimes(context, data),
                    const SizedBox(height: 28),

                    // Section 3: Qibla Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'اتجاه القبلة',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section 4: Integrated Real Compass Widget
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const QiblaCompass(
                        showEffects: true,
                        showCalibrationCard: false, // keep it clean
                        showHintCard: true,         // but give them hint
                        showInfoCards: true,        // and basic degrees
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildErrorState(context, err),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimes(BuildContext context, PrayerTimesData data) {
    final cs = Theme.of(context).colorScheme;
    
    // Group and sort today's prayers
    final prayersList = data.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'جدول مواقيت اليوم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.methodName,
                  textAlign: TextAlign.left, // opposite end alignment in RTL
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: prayersList.length,
            itemBuilder: (context, index) {
              final entry = prayersList[index];
              final isNext = entry.key == data.nextPrayerName;
              return _buildPrayerCard(
                context,
                entry.key,
                entry.value,
                isNext,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    String englishKey,
    DateTime time,
    bool isNext,
  ) {
    final cs = Theme.of(context).colorScheme;
    final formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final arabicTitle = _arabicName(englishKey);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isNext
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.22),
                  cs.primary.withValues(alpha: 0.08),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  cs.surfaceContainerLowest.withValues(alpha: 0.2),
                ],
              ),
        border: Border.all(
          color: isNext
              ? cs.primary.withValues(alpha: 0.55)
              : cs.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(englishKey),
                  size: 16,
                  color: isNext ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  arabicTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isNext ? cs.primary : cs.onSurface,
                    fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isNext ? cs.primary : cs.onSurface,
                fontWeight: FontWeight.w900,
                fontFamily: 'System',
                letterSpacing: 0.5,
              ),
            ),
            if (isNext) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'القادمة',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _arabicName(String key) {
    switch (key) {
      case 'Fajr':
        return 'الفجر';
      case 'Sunrise':
        return 'الشروق';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return key;
    }
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'Fajr':
        return Icons.wb_twilight_rounded;
      case 'Sunrise':
        return Icons.light_mode_rounded;
      case 'Dhuhr':
        return Icons.wb_sunny_rounded;
      case 'Asr':
        return Icons.wb_cloudy_rounded;
      case 'Maghrib':
        return Icons.nights_stay_rounded;
      case 'Isha':
        return Icons.bedtime_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: cs.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'تعذر جلب مواقيت الصلاة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                height: 1.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(todayPrayersProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Tajawal'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
