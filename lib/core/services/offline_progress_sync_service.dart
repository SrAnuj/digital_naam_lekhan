import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../features/home/data/sankalp_progress_repository.dart';
import '../../features/jap/data/jap_session_repository.dart';
import 'app_services.dart';
import 'offline_progress_service.dart';

class OfflineProgressSyncService with WidgetsBindingObserver {
  OfflineProgressSyncService._();

  static final OfflineProgressSyncService instance =
      OfflineProgressSyncService._();

  static const String writingProgressAction = 'writing_progress';
  static const String japSessionAction = 'jap_session';

  final OfflineProgressService _offlineService =
      OfflineProgressService.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize automatic offline synchronization.
  /// Call once after AppServices.init().
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Listen for internet connectivity changes.
    // Do not wrap listen() in unawaited().
    _connectivitySubscription = _offlineService.onConnectivityChanged.listen(
      (results) {
        final hasNetwork = results.any(
          (result) => result != ConnectivityResult.none,
        );

        if (hasNetwork) {
          unawaited(syncPendingItems());
        }
      },
      onError: (Object error) {
        debugPrint('Connectivity listener error: $error');
      },
    );

    // Sync previously queued items when the app starts.
    unawaited(syncPendingItems());
  }

  /// Retry pending items when app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncPendingItems());
    }
  }

  /// Cancel connectivity listener when service is disposed.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    _isInitialized = false;
  }

  /// Process pending offline items one by one.
  Future<int> syncPendingItems() async {
    if (_isSyncing) return 0;

    _isSyncing = true;

    var syncedCount = 0;

    try {
      // Avoid protected API calls when user is logged out.
      final token = await AppServices.tokens.read();

      if (token == null || token.trim().isEmpty) {
        return 0;
      }

      final hasNetwork = await _offlineService.hasNetworkTransport();

      if (!hasNetwork) return 0;

      final pendingItems = await _offlineService.getPendingItems();

      for (final item in pendingItems) {
        final requestId = item['request_id']?.toString();
        final action = item['action']?.toString();
        final rawPayload = item['payload'];

        if (requestId == null ||
            requestId.isEmpty ||
            action == null ||
            rawPayload is! Map) {
          continue;
        }

        final payload = Map<String, dynamic>.from(rawPayload);

        try {
          switch (action) {
            case writingProgressAction:
              await _syncWritingProgress(
                payload: payload,
                requestId: requestId,
              );
              break;

            case japSessionAction:
              await _syncJapSession(
                payload: payload,
                requestId: requestId,
              );
              break;

            default:
              // Keep unknown actions in the queue.
              continue;
          }

          await _offlineService.removePendingItem(requestId);

          syncedCount++;

          debugPrint('Offline item synced: $requestId');
        } catch (error, stackTrace) {
          await _offlineService.incrementAttempts(requestId);

          debugPrint(
            'Offline sync failed for $requestId: $error',
          );

          debugPrintStack(stackTrace: stackTrace);

          // Keep failed items for the next retry.
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Offline queue processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isSyncing = false;
    }

    debugPrint(
      'Offline sync completed. Synced: $syncedCount',
    );

    return syncedCount;
  }

  /// Sync Naam Writing progress.
  Future<void> _syncWritingProgress({
    required Map<String, dynamic> payload,
    required String requestId,
  }) async {
    await SankalpProgressRepository.saveWritingProgress(
      sankalpId: _requiredInt(payload, 'sankalp_id'),
      count: _requiredInt(payload, 'count'),
      progressDate: _requiredString(payload, 'progress_date'),
      requestId: requestId,
      metadata: _optionalMap(payload['metadata']),
    );
  }

  /// Sync Jap Counter session.
  Future<void> _syncJapSession({
    required Map<String, dynamic> payload,
    required String requestId,
  }) async {
    await JapSessionRepository.saveSession(
      sankalpId: _requiredInt(payload, 'sankalp_id'),
      count: _requiredInt(payload, 'count'),
      requestId: requestId,
      activityDate: _requiredString(payload, 'activity_date'),
      malaSize: _optionalInt(payload['mala_size']) ?? 108,
      startedAt: _optionalDateTime(payload['started_at']),
      completedAt: _optionalDateTime(payload['completed_at']),
      durationSeconds: _optionalInt(payload['duration_seconds']) ?? 0,
      metadata: _optionalMap(payload['metadata']),
    );
  }

  int _requiredInt(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];

    if (value is int && value > 0) {
      return value;
    }

    throw FormatException(
      'Invalid or missing $key in offline queue.',
    );
  }

  String _requiredString(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException(
      'Invalid or missing $key in offline queue.',
    );
  }

  int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  DateTime? _optionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Map<String, dynamic>? _optionalMap(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException(
      'Invalid metadata in offline queue.',
    );
  }
}
