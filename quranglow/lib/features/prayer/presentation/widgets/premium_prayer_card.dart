/// Premium Prayer Card Widget
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:quranglow/core/models/prayer_models.dart';

class PremiumPrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final bool isNext;
  final VoidCallback onTap;
  final bool isCompleted;
  final VoidCallback? onToggleComplete;

  const PremiumPrayerCard({
    super.key,
    required this.prayer,
    required this.isNext,
    required this.onTap,
    required this.isCompleted,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final timeRemaining = prayer.time.difference(DateTime.now());
    final isUpcoming = timeRemaining.isNegative == false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isNext
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Glassmorphism background
              ui.BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Prayer icon with color gradient
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.emerald.shade400,
                            Colors.emerald.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.emerald.withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getPrayerEmoji(prayer.type),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Prayer details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Prayer name
                          Text(
                            prayer.type.englishName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Prayer time
                          Text(
                            DateFormat('hh:mm a').format(prayer.time),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Time remaining / Status
                          if (isUpcoming && !isCompleted)
                            Text(
                              'In ${_formatDuration(timeRemaining)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isNext
                                    ? Colors.amber.shade600
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (isCompleted)
                            Text(
                              'Completed ✓',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              'Passed',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Completion checkbox
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green.shade400
                            : Colors.grey.shade200,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onToggleComplete,
                          child: Center(
                            child: Icon(
                              isCompleted ? Icons.check : Icons.add,
                              color: isCompleted
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Next prayer indicator badge
              if (isNext)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPrayerEmoji(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return '🌙';
      case PrayerType.dhuhr:
        return '☀️';
      case PrayerType.asr:
        return '🌅';
      case PrayerType.maghrib:
        return '🌆';
      case PrayerType.isha:
        return '⭐';
      case PrayerType.sunrise:
        return '🌄';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours h ${minutes}m';
    }
    return '$minutes m';
  }
}
