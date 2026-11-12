import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineProgressService {
  OfflineProgressService._();

  static final OfflineProgressService instance = OfflineProgressService._();

  static const String _queueKey = 'offline_progress_queue';

  final Connectivity _connectivity = Connectivity();

  /// Emits connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Checks whether a network connection type is available.
  /// This does not guarantee that the internet or API is reachable.
  Future<bool> hasNetworkTransport() async {
    final results = await _connectivity.checkConnectivity();

    return results.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  /// Adds a pending action to the local queue.
  Future<void> enqueue({
    required String action,
    required String requestId,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPendingItems();

    final alreadyExists = queue.any(
      (item) => item['request_id'] == requestId,
    );

    if (alreadyExists) {
      return;
    }

    queue.add({
      'request_id': requestId,
      'action': action,
      'payload': payload,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'attempts': 0,
    });

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Returns all pending actions.
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final storedQueue = prefs.getString(_queueKey);

    if (storedQueue == null || storedQueue.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(storedQueue);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Removes an action after successful server synchronization.
  Future<void> removePendingItem(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPendingItems();

    queue.removeWhere(
      (item) => item['request_id'] == requestId,
    );

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Increases retry attempts for a pending action.
  Future<void> incrementAttempts(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getPendingItems();

    for (final item in queue) {
      if (item['request_id'] == requestId) {
        item['attempts'] = (item['attempts'] as int? ?? 0) + 1;
        break;
      }
    }

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Clears the complete queue.
  /// Use only when explicitly required.
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }
}
