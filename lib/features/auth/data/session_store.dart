import 'package:shared_preferences/shared_preferences.dart';

/// Small local flags: has the user seen onboarding, chosen language, etc.
/// (The API access token lives in [TokenStorage], not here.)
class SessionStore {
  SessionStore._(this._p);
  final SharedPreferences _p;

  static Future<SessionStore> load() async =>
      SessionStore._(await SharedPreferences.getInstance());

  static const _kOnboarded = 'onboarding_done';
  static const _kLanguage = 'language_code';
  static const _kName = 'user_name';
  static const _kGuest = 'is_guest';

  bool get onboardingDone => _p.getBool(_kOnboarded) ?? false;
  Future<void> setOnboardingDone() => _p.setBool(_kOnboarded, true);

  String get language => _p.getString(_kLanguage) ?? 'hi';
  Future<void> setLanguage(String code) => _p.setString(_kLanguage, code);

  String? get userName => _p.getString(_kName);
  Future<void> setUserName(String name) => _p.setString(_kName, name);

  bool get isGuest => _p.getBool(_kGuest) ?? false;
  Future<void> setGuest(bool v) => _p.setBool(_kGuest, v);

  /// Called on logout. Keeps onboarding + language so the user does not
  /// have to see the intro again.
  Future<void> clearUser() async {
    await _p.remove(_kName);
    await _p.remove(_kGuest);
  }
}
