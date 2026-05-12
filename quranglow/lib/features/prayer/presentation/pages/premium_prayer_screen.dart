// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

/// Premium Prayer Times + Qibla Screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quranglow/core/models/prayer_models.dart';
import 'package:quranglow/core/providers/location_providers.dart';
import 'package:quranglow/core/providers/prayer_providers.dart';
import 'package:quranglow/core/providers/qibla_providers.dart';
import 'package:quranglow/features/prayer/presentation/widgets/prayer_countdown.dart';
import 'package:quranglow/features/prayer/presentation/widgets/premium_prayer_card.dart';
import 'package:quranglow/features/prayer/presentation/widgets/qibla_compass.dart';
import 'package:quranglow/features/prayer/presentation/widgets/streak_reward_card.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

class PremiumPrayerScreen extends ConsumerWidget {
  const PremiumPrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final positionAsync = ref.watch(userPositionProvider);
    final compassHeadingAsync = ref.watch(compassHeadingProvider);
    final prayerStreakState = ref.watch(prayerStreakProvider);
    final prayerXPState = ref.watch(prayerXPProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Prayer Times',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => _showSettings(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.settings, color: Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.tealAccent.shade200, Colors.blue.shade50],
          ),
        ),
        child: positionAsync.when(
          data: (position) {
            if (position == null) {
              return _buildLocationError(context);
            }

            return _buildPrayerContent(
              context,
              ref,
              position,
              compassHeadingAsync,
              prayerStreakState,
              prayerXPState,
            );
          },
          error: (error, stackTrace) => _buildLocationError(context),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 100),
            child: PremiumSkeletonCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationError(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Location Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable location services to see prayer times',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Implement location request
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Enable Location',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerContent(
    BuildContext context,
    WidgetRef ref,
    position,
    AsyncValue<double> compassHeadingAsync,
    PrayerStreakState prayerStreakState,
    PrayerXPState prayerXPState,
  ) {
    // Mock prayer data for demo
    final now = DateTime.now();
    final prayers = [
      PrayerTime(
        type: PrayerType.fajr,
        time: now.subtract(const Duration(hours: 2)),
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
      PrayerTime(
        type: PrayerType.dhuhr,
        time: now.add(const Duration(hours: 1)),
      ),
      PrayerTime(type: PrayerType.asr, time: now.add(const Duration(hours: 5))),
      PrayerTime(
        type: PrayerType.maghrib,
        time: now.add(const Duration(hours: 8)),
      ),
      PrayerTime(
        type: PrayerType.isha,
        time: now.add(const Duration(hours: 10)),
      ),
    ];

    final nextPrayer = prayers.firstWhere(
      (p) => p.time.isAfter(now),
      orElse: () => prayers.last,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            // Hijri Date Header
            _buildHijriDateHeader(),

            const SizedBox(height: 24),

            // Qibla Compass
            compassHeadingAsync.when(
              data: (heading) {
                final qiblaDirection =
                    ref.watch(qiblaDirectionProvider(position)) ?? 0;
                final isFacingQibla = ref.watch(isFacingQiblaProvider);

                return Column(
                  children: [
                    const Text(
                      'Qibla Direction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QiblaCompass(
                      deviceHeading: heading,
                      qiblaDirection: qiblaDirection,
                      isFacingQibla: isFacingQibla,
                      size: 280,
                    ),
                  ],
                );
              },
              error: (error, stackTrace) => const SizedBox.shrink(),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.deepOrangeAccent),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Prayer countdown for next prayer
            PrayerCountdown(
              timeRemaining: nextPrayer.time.difference(now),
              prayerName: nextPrayer.type.englishName,
            ),

            const SizedBox(height: 20),

            // Streak and XP Card
            StreakRewardCard(
              currentStreak: prayerStreakState.currentStreak,
              longestStreak: prayerStreakState.longestStreak,
              totalXP: prayerXPState.totalXP,
              level: prayerXPState.level,
              xpToNextLevel: prayerXPState.xpForNextLevel,
            ),

            const SizedBox(height: 20),

            // Prayer Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Today\'s Prayers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...prayers.map(
              (prayer) => PremiumPrayerCard(
                prayer: prayer,
                isNext: prayer.type == nextPrayer.type,
                onTap: () => _showPrayerDetails(context, prayer),
                isCompleted: prayer.isCompleted,
                onToggleComplete: () {
                  // Implement toggle completion
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHijriDateHeader() {
    // Get Hijri date (this is a simplified version - use hijri_time package for accuracy)
    final gregorianDate = DateTime.now();
    final formatter = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      children: [
        Text(
          formatter.format(gregorianDate),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Hijri Calendar Integration', // Replace with actual Hijri date
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showPrayerDetails(BuildContext context, PrayerTime prayer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prayer.type.englishName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(prayer.type.arabicName, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(
              'Time: ${DateFormat('hh:mm a').format(prayer.time)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade400,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Implementation for settings
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
  }
}
