import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../features/home/data/sankalp_progress_repository.dart';
import '../../features/jap/data/jap_session_repository.dart';
import 'app_services.dart';
import 'offline_progress_service.dart';
import 'notification_navigation_service.dart';

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
  bool _isShowingCompletionScreen = false;

  /// Initialize automatic offline synchronization.
  /// Call once after AppServices.init().
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

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
          late final Map<String, dynamic> response;

          switch (action) {
            case writingProgressAction:
              response = await _syncWritingProgress(
                payload: payload,
                requestId: requestId,
              );
              break;

            case japSessionAction:
              response = await _syncJapSession(
                payload: payload,
                requestId: requestId,
              );
              break;

            default:
              // Keep unknown actions in the queue.
              continue;
          }

          // Remove only after successful API synchronization.
          await _offlineService.removePendingItem(requestId);

          syncedCount++;

          debugPrint('Offline item synced: $requestId');

          // Check whether this sync completed the Sankalp.
          await _handleSankalpCompletion(response);
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
  Future<Map<String, dynamic>> _syncWritingProgress({
    required Map<String, dynamic> payload,
    required String requestId,
  }) async {
    return await SankalpProgressRepository.saveWritingProgress(
      sankalpId: _requiredInt(payload, 'sankalp_id'),
      count: _requiredInt(payload, 'count'),
      progressDate: _requiredString(payload, 'progress_date'),
      requestId: requestId,
      metadata: _optionalMap(payload['metadata']),
    );
  }

  /// Sync Jap Counter session.
  Future<Map<String, dynamic>> _syncJapSession({
    required Map<String, dynamic> payload,
    required String requestId,
  }) async {
    final result = await JapSessionRepository.saveSession(
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

    return {
      'sankalp_summary': result.sankalpSummary,
      'sankalp_completed': result.sankalpCompleted,
    };
  }

  /// Open Sankalp completion screen after successful offline sync.
  Future<void> _handleSankalpCompletion(
    Map<String, dynamic> response,
  ) async {
    final rawSummary = response['sankalp_summary'];

    final isCompleted = response['sankalp_completed'] == true ||
        (rawSummary is Map &&
            rawSummary['status']?.toString().toLowerCase() == 'completed');

    if (!isCompleted || _isShowingCompletionScreen) {
      return;
    }

    // Wait for the first app frame if sync starts before runApp().
    if (NotificationNavigationService.navigatorKey.currentState == null) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final navigator = NotificationNavigationService.navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('Completion navigation unavailable.');
      return;
    }

    final summary = rawSummary is Map
        ? Map<String, dynamic>.from(rawSummary)
        : <String, dynamic>{};

    _isShowingCompletionScreen = true;

    try {
      await navigator.pushNamed(
        '/sankalp-complete',
        arguments: summary,
      );
    } finally {
      _isShowingCompletionScreen = false;
    }
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
