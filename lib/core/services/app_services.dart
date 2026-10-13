import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/session_store.dart';
import '../../features/auth/data/token_storage.dart';
import '../network/api_client.dart';

/// One place that builds and holds the app-wide services.
/// Call [AppServices.init] once in main() before runApp().
class AppServices {
  AppServices._();

  static late final TokenStorage tokens;
  static late final ApiClient api;
  static late final AuthRepository auth;
  static late final SessionStore session;

  static Future<void> init() async {
    tokens = TokenStorage();
    api = ApiClient(tokens);
    auth = AuthRepository(apiClient: api, tokenStorage: tokens);
    session = await SessionStore.load();
  }
}
