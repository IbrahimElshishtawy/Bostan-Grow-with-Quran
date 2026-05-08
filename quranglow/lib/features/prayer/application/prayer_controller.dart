/// Prayer and Qibla state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/models/prayer_models.dart';
import 'package:quranglow/core/models/qibla_models.dart';
import 'package:quranglow/features/prayer/services/prayer_times_service.dart';

class PrayerState {
  const PrayerState({
    required this.schedule,
    required this.stats,
    required this.tracker,
    required this.isLoading,
    this.error,
  });

  final PrayerSchedule? schedule;
  final PrayerStats stats;
  final PrayerTracker tracker;
  final bool isLoading;
  final String? error;

  PrayerState copyWith({
    PrayerSchedule? schedule,
    PrayerStats? stats,
    PrayerTracker? tracker,
    bool? isLoading,
    String? error,
  }) {
    return PrayerState(
      schedule: schedule ?? this.schedule,
      stats: stats ?? this.stats,
      tracker: tracker ?? this.tracker,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PrayerController extends StateNotifier<PrayerState> {
  PrayerController()
      : super(
          PrayerState(
            schedule: null,
            stats: const PrayerStats(
              totalPrayersCompleted: 0,
              currentStreak: 0,
              longestStreak: 0,
              completionRate: 0.0,
              lastPrayerDate: null,
            ),
            tracker: PrayerTracker(
              stats: const PrayerStats(
                totalPrayersCompleted: 0,
                currentStreak: 0,
                longestStreak: 0,
                completionRate: 0.0,
                lastPrayerDate: null,
              ),
              achievements: PrayerTracker.getDefaultAchievements(),
            ),
            isLoading: false,
          ),
        );

  /// Load prayer times for location
  Future<void> loadPrayerTimes({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = PrayerTimesService.calculatePrayerTimes(
        date: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        location: location,
      );

      state = state.copyWith(
        schedule: schedule,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Mark prayer as completed
  void completePrayer(PrayerTime prayer) {
    if (state.schedule == null) return;

    final updatedPrayers = state.schedule!.prayers.map((p) {
      return p.type == prayer.type
          ? p.copyWith(isCompleted: true, completedAt: DateTime.now())
          : p;
    }).toList();

    final updatedSchedule = state.schedule!.copyWith(prayers: updatedPrayers);
    state.tracker.completePrayer(prayer);

    state = state.copyWith(
      schedule: updatedSchedule,
      stats: state.tracker.stats,
      tracker: state.tracker,
    );
  }

  /// Update completion rate
  void updateCompletionRate() {
    if (state.schedule == null) return;

    final rate = state.schedule!.completionPercentage;
    state = state.copyWith(
      stats: state.stats.copyWith(completionRate: rate),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class QiblaState {
  const QiblaState({
    required this.compassState,
    required this.calibration,
    required this.isLoading,
    this.error,
  });

  final QiblaCompassState compassState;
  final QiblaCalibration calibration;
  final bool isLoading;
  final String? error;

  QiblaState copyWith({
    QiblaCompassState? compassState,
    QiblaCalibration? calibration,
    bool? isLoading,
    String? error,
  }) {
    return QiblaState(
      compassState: compassState ?? this.compassState,
      calibration: calibration ?? this.calibration,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QiblaController extends StateNotifier<QiblaState> {
  QiblaController()
      : super(
          QiblaState(
            compassState: QiblaCompassState(
              qiblaDirection: const QiblaDirection(
                angle: 0,
                direction: 'N',
                distance: 0,
              ),
              compassReading: CompassReading(
                heading: 0,
                accuracy: 0,
                timestamp: DateTime.now(),
              ),
              relativeAngle: 0,
              isCalibrated: false,
              isLoading: false,
            ),
            calibration: const QiblaCalibration(
              isRequired: true,
              instruction: 'Move your device in a figure-8 pattern',
              progress: 0,
            ),
            isLoading: false,
          ),
        );

  /// Initialize Qibla compass
  Future<void> initialize({
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final qiblaDirection = QiblaDirection.calculate(
        userLatitude: latitude,
        userLongitude: longitude,
      );

      final compassState = state.compassState.copyWith(
        qiblaDirection: qiblaDirection,
      );

      state = state.copyWith(
        compassState: compassState,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update compass heading
  void updateCompassHeading(double heading, double accuracy) {
    final compassReading = CompassReading(
      heading: heading,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );

    final relativeAngle = _calculateRelativeAngle(
      heading,
      state.compassState.qiblaDirection.angle,
    );

    final compassState = state.compassState.copyWith(
      compassReading: compassReading,
      relativeAngle: relativeAngle,
      isCalibrated: accuracy < 15,
    );

    state = state.copyWith(compassState: compassState);
  }

  /// Start calibration
  void startCalibration() {
    state = state.copyWith(
      calibration: state.calibration.copyWith(
        isRequired: true,
        progress: 0,
      ),
    );
  }

  /// Update calibration progress
  void updateCalibrationProgress(double progress) {
    state = state.copyWith(
      calibration: state.calibration.copyWith(progress: progress),
    );

    if (progress >= 1.0) {
      completeCalibration();
    }
  }

  /// Complete calibration
  void completeCalibration() {
    state = state.copyWith(
      calibration: state.calibration.copyWith(
        isRequired: false,
        progress: 1.0,
      ),
      compassState: state.compassState.copyWith(isCalibrated: true),
    );
  }

  double _calculateRelativeAngle(double heading, double qiblaAngle) {
    var angle = qiblaAngle - heading;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    return angle;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
