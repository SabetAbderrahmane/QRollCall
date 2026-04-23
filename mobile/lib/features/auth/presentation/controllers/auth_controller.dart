import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../models/app_user.dart';
import '../../data/auth_api_service.dart';
import '../../data/firebase_auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthApiService apiService,
    required FirebaseAuthService firebaseAuthService,
  })  : _apiService = apiService,
        _firebaseAuthService = firebaseAuthService;

  final AuthApiService _apiService;
  final FirebaseAuthService _firebaseAuthService;

  AppUser? currentUser;
  bool isInitializing = true;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> bootstrapSession() async {
    isInitializing = true;
    notifyListeners();

    try {
      if (_firebaseAuthService.currentUser != null) {
        await _syncBackendUser();
      }
    } catch (e) {
      errorMessage = _friendlyError(e);
      currentUser = null;
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _firebaseAuthService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _syncBackendUser(forceRefresh: true);
    });
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _firebaseAuthService.signUpWithEmailPassword(
        fullName: fullName,
        email: email,
        password: password,
      );
      await _syncBackendUser(forceRefresh: true);
    });
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(() async {
      await _firebaseAuthService.signInWithGoogle();
      await _syncBackendUser(forceRefresh: true);
    });
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Enter your email address first.');
    }

    await _firebaseAuthService.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuthService.signOut();
      currentUser = null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _syncBackendUser({bool forceRefresh = false}) async {
    final idToken = await _firebaseAuthService.getIdToken(
      forceRefresh: forceRefresh,
    );

    await _apiService.syncUser(idToken);
    currentUser = await _apiService.getCurrentUser(idToken);
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      errorMessage = _friendlyError(e);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'No account exists for that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'That email is already in use.';
        case 'weak-password':
          return 'Your password is too weak.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'google-id-token-missing':
          return error.message ?? 'Google sign-in failed.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}