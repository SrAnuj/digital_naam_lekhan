import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _raw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/sankalp/api/v1',
  );

  /// On the Android emulator "localhost" is the emulator itself.
  /// 10.0.2.2 is the host PC, so swap it automatically for local dev.
  /// On a real phone pass your PC's LAN IP instead:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10/sankalp/api/v1
  static String get baseUrl {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _raw.contains('localhost')) {
      return _raw.replaceFirst('localhost', '10.0.2.2');
    }
    return _raw;
  }
}
