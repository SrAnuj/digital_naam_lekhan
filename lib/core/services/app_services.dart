import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/session_store.dart';
import '../../features/auth/data/token_storage.dart';
import '../network/api_client.dart';
import 'fcm_service.dart';

/// One place that builds and holds the app-wide services.
class AppServices {
  AppServices._();

  static late final TokenStorage tokens;
  static late final ApiClient api;
  static late final AuthRepository auth;
  static late final SessionStore session;
  static late final FcmService fcm;

  /// Initializes all application-wide services.
  static Future<void> init() async {
    // 1. Secure storage for Laravel API token.
    tokens = TokenStorage();

    // 2. API client with automatic Bearer token handling.
    api = ApiClient(tokens);

    // 3. Firebase Cloud Messaging service.
    fcm = FcmService(api);

    // 4. Authentication repository with FCM integration.
    auth = AuthRepository(
      apiClient: api,
      tokenStorage: tokens,
      fcmService: fcm,
    );

    // 5. Load locally saved app session and preferences.
    session = await SessionStore.load();
  }
}
