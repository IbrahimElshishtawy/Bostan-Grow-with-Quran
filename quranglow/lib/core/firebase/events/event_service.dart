import 'dart:developer' as dev;
import '../analytics/analytics_service.dart';
import '../../sync/sync_manager.dart';
import '../../sync/sync_operation.dart';

class EventService {
  final AnalyticsService _analyticsService;
  final SyncManager _syncManager;

  EventService({
    AnalyticsService? analyticsService,
    required SyncManager syncManager,
  })  : _analyticsService = analyticsService ?? AnalyticsService(),
        _syncManager = syncManager;

  /// Routes an event based on its importance (Section 29)
  Future<void> logProductEvent({
    required String type,
    Map<String, dynamic>? metadata,
    bool syncToFirestore = false,
  }) async {
    try {
      // 1. Log to Firebase Analytics for aggregated product telemetry
      final safeAnalyticsParams = <String, Object>{};
      if (metadata != null) {
        metadata.forEach((key, value) {
          if (value is num || value is String || value is bool) {
            safeAnalyticsParams[key] = value as Object;
          }
        });
      }
      await _analyticsService.logEvent(
        name: type,
        parameters: safeAnalyticsParams.isEmpty ? null : safeAnalyticsParams,
      );

      // 2. If it's an important user milestone event, queue it for Firestore sync
      if (syncToFirestore) {
        final eventId = 'ev_${DateTime.now().millisecondsSinceEpoch}_${type.hashCode}';
        final payload = {
          'id': eventId,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        };

        await _syncManager.enqueue(
          entityType: 'events',
          entityId: eventId,
          type: SyncOperationType.create,
          payload: payload,
        );
      }
    } catch (e) {
      dev.log('Error routing product event: $e', name: 'EventService');
    }
  }
}
