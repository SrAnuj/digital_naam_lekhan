import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'naamvriddhi_access_token';

  Future<void> save(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> read() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
  }
}
