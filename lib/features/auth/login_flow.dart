import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../data.dart';

/// Call after a successful login (phone or Google).
/// Saves the name, then opens Home, or the Name screen if there is no name yet.
Future<void> finishLogin(
  BuildContext context,
  Map<String, dynamic> data,
) async {
  final session = AppServices.session;
  await session.setGuest(false);

  final user = data['user'];
  final raw = (user is Map ? user['name'] : null) ?? data['name'];
  final fromServer = raw is String ? raw.trim() : '';

  // Name from the server, else the one saved earlier on this device.
  final name = fromServer.isNotEmpty ? fromServer : session.userName;
  if (name != null) {
    await session.setUserName(name);
    AppState.name = name;
  }

  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    name == null ? '/profile-setup' : '/home',
    (r) => false,
  );
}
