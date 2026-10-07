import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_database.dart';
import 'sync_conflict_resolver.dart';
import 'sync_metadata.dart';
import 'sync_operation.dart';

class SyncManager extends ChangeNotifier {
  final LocalDatabase _localDb;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final SyncConflictResolver _conflictResolver;

  SyncMetadata _metadata = const SyncMetadata();
  SyncMetadata get metadata => _metadata;

  bool _isProcessing = false;

  SyncManager({
    LocalDatabase? localDb,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SyncConflictResolver conflictResolver = const SyncConflictResolver(),
  })  : _localDb = localDb ?? LocalDatabase.instance,
        _firestore = firestore ?? _safeFirestore(),
        _auth = auth ?? _safeAuth(),
        _conflictResolver = conflictResolver {
    _refreshPendingCount();
  }

  static FirebaseFirestore? _safeFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? _safeAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  void _refreshPendingCount() {
    final pending = _localDb.getPendingSyncOperations();
    _metadata = _metadata.copyWith(pendingOperationsCount: pending.length);
    notifyListeners();
  }

  /// Enqueues an offline-first sync operation
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperationType type,
    required Map<String, dynamic> payload,
  }) async {
    final op = SyncOperation(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );

    await _localDb.enqueueSyncOperation(op.toMap());
    _refreshPendingCount();

    // Trigger background sync attempt without blocking caller
    unawaited(processQueue());
  }

  /// Process queue with exponential backoff & offline resilience
  Future<void> processQueue() async {
    if (_isProcessing) return;

    final user = _auth?.currentUser;
    final firestore = _firestore;

    // If not authenticated or Firestore unavailable, retain queue offline
    if (user == null || firestore == null) {
      _refreshPendingCount();
      return;
    }

    _isProcessing = true;
    _metadata = _metadata.copyWith(isSyncing: true, lastError: null);
    notifyListeners();

    try {
      final rawOps = _localDb.getPendingSyncOperations();
      for (final raw in rawOps) {
        final op = SyncOperation.fromMap(raw);
        if (op.retryCount >= 5) {
          // Max retries reached, skip or discard to prevent infinite loop
          await _localDb.removeSyncOperation(op.id);
          continue;
        }

        try {
          await _executeOperation(user.uid, firestore, op);
          await _localDb.removeSyncOperation(op.id);
        } catch (e) {
          // Increment retry with exponential backoff
          final updatedOp = op.copyWith(
            retryCount: op.retryCount + 1,
            lastError: e.toString(),
          );
          await _localDb.enqueueSyncOperation(updatedOp.toMap());
          // Wait briefly before attempting next operation
          await Future.delayed(Duration(milliseconds: 200 * (1 << op.retryCount)));
        }
      }

      _metadata = _metadata.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastError: null,
      );
    } catch (e) {
      _metadata = _metadata.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    } finally {
      _isProcessing = false;
      _refreshPendingCount();
    }
  }

  Future<void> _executeOperation(
    String userId,
    FirebaseFirestore firestore,
    SyncOperation op,
  ) async {
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection(op.entityType)
        .doc(op.payload['id']?.toString() ?? op.id);

    switch (op.type) {
      case SyncOperationType.create:
      case SyncOperationType.update:
        await docRef.set(op.payload, SetOptions(merge: true));
        break;
      case SyncOperationType.delete:
        await docRef.delete();
        break;
    }
  }

  /// Conflict resolution helper for bi-directional syncing
  Map<String, dynamic> resolveConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) {
    return _conflictResolver.resolve(
      localData: localData,
      remoteData: remoteData,
    );
  }
}
