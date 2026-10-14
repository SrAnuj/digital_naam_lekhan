import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'token_storage.dart';

/// An error whose [message] is safe to show to the user.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// True when the user closed the Google / Apple popup on purpose.
bool isSignInCancelled(Object e) =>
    e is FirebaseAuthException &&
    const {
      'popup-closed-by-user',
      'cancelled-popup-request',
      'web-context-canceled',
      'canceled',
    }.contains(e.code);

/// Turns any login error (Firebase / Dio / our own) into a short message.
String authErrorMessage(Object e) {
  // Full details in the terminal / browser console while we debug.
  debugPrint('AUTH ERROR -> ${e.runtimeType}: $e');

  if (e is AuthFailure) return e.message;

  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid mobile number.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please check and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'OTP expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again after some time.';
      case 'quota-exceeded':
        return 'SMS limit reached. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check and retry.';
      case 'popup-blocked':
        return 'The sign-in popup was blocked. Allow popups and try again.';
      case 'account-exists-with-different-credential':
        return 'This email is already used with another sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      case 'unauthorized-domain':
        return 'This domain is not allowed in Firebase (Authorized domains).';
      default:
        return '${e.message ?? 'Login failed'} (${e.code})';
    }
  }

  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Please try again.';
      default:
        return 'Server error (${e.response?.statusCode ?? '-'}). '
            'Please try again.';
    }
  }

  final s = e.toString();
  final text = s.startsWith('Exception: ') ? s.substring(11) : s;
  return '$text [${e.runtimeType}]';
}

/// Phone, Google and Apple login:
///   Firebase sign-in -> Firebase ID token -> Laravel -> Passport token
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiClient,
        _tokens = tokenStorage,
        _firebase = firebaseAuth ?? FirebaseAuth.instance;

  final ApiClient _api;
  final TokenStorage _tokens;
  final FirebaseAuth _firebase;

  String? _verificationId;
  int? _resendToken;
  PhoneAuthCredential? _autoCredential;

  final _autoVerified = StreamController<void>.broadcast();

  /// Fires when Android reads the SMS (or Firebase instantly verifies) AFTER
  /// the OTP screen is already open, so the UI can continue by itself.
  Stream<void> get autoVerified => _autoVerified.stream;

  /// True when Firebase already verified the phone without a typed code.
  bool get hasAutoCredential => _autoCredential != null;

  /// Is an API token saved on this device?
  Future<bool> hasSession() async {
    final t = await _tokens.read();
    return t != null && t.isNotEmpty;
  }

  // ───────────────────────── phone ─────────────────────────

  /// [phoneNumber] must be E.164, e.g. +919876543210.
  Future<void> sendOtp(String phoneNumber, {bool resend = false}) async {
    final completer = Completer<void>();
    if (!resend) _resendToken = null;
    _autoCredential = null;

    await _firebase.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (credential) {
        _autoCredential = credential;
        if (!completer.isCompleted) {
          completer.complete();
        } else {
          _autoVerified.add(null);
        }
      },
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.completeError(
            AuthFailure('OTP request timed out. Please try again.'),
          );
        }
      },
    );

    await completer.future;
  }

  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    final PhoneAuthCredential credential;

    if (_autoCredential != null) {
      credential = _autoCredential!;
      _autoCredential = null;
    } else {
      final verificationId = _verificationId;
      if (verificationId == null) {
        throw AuthFailure('Please request an OTP first.');
      }
      credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );
    }

    final result = await _firebase.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw AuthFailure('Firebase could not verify your phone.');
    }

    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw AuthFailure('Could not obtain Firebase ID token.');
    }

    return _exchange('/auth/login', idToken);
  }

  // ───────────────────────── google / apple ─────────────────────────

  /// Web: popup. Android / iOS: browser sheet.
  /// Returns the same data map as [verifyOtp].
  Future<Map<String, dynamic>> signInWithGoogle() => _socialLogin(
        GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile'),
        '/auth/google',
      );

  Future<Map<String, dynamic>> signInWithApple() => _socialLogin(
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
        '/auth/apple',
      );

  Future<Map<String, dynamic>> _socialLogin(
    AuthProvider provider,
    String path,
  ) async {
    final UserCredential result = kIsWeb
        ? await _firebase.signInWithPopup(provider)
        : await _firebase.signInWithProvider(provider);

    final firebaseUser = result.user;
    if (firebaseUser == null) {
      throw AuthFailure('Sign-in failed. Please try again.');
    }

    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw AuthFailure('Could not obtain Firebase ID token.');
    }

    return _exchange(path, idToken);
  }

  // ───────────────────────── shared ─────────────────────────

  /// Sends the Firebase ID token to Laravel and stores the access token.
  Future<Map<String, dynamic>> _exchange(String path, String idToken) async {
    try {
      final response = await _api.dio.post(
        path,
        data: {'id_token': idToken},
      );

      final body = Map<String, dynamic>.from(response.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final accessToken = data['access_token'] as String?;

      if (body['success'] != true ||
          accessToken == null ||
          accessToken.isEmpty) {
        throw AuthFailure('Server did not return an access token.');
      }

      await _tokens.save(accessToken);
      return data;
    } catch (_) {
      // Do not leave a Firebase session active if Laravel login fails.
      await _firebase.signOut();
      rethrow;
    }
  }

  /// Saves the user's name on the server (PATCH /profile).
  Future<void> updateName(String name) async {
    await _api.dio.patch('/profile', data: {'name': name});
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } finally {
      await _tokens.clear();
      await _firebase.signOut();
    }
  }
}
