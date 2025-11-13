import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart';
import 'package:vestiq/features/auth/domain/services/auth_service.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/core/utils/logger.dart';

// ==================== SERVICE PROVIDERS ====================

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

// ==================== AUTH STATE PROVIDERS ====================

/// Provider for Firebase auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current Firebase user
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for current user profile
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      final userProfileService = ref.watch(userProfileServiceProvider);
      return userProfileService.watchUserProfile(firebaseUser.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ==================== AUTH CONTROLLER ====================

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authService) : super(const AsyncValue.data(null));

  final AuthService _authService;

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('❌ Sign up failed', error: e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('❌ Sign in failed', error: e);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('❌ Google sign in failed', error: e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('❌ Sign out failed', error: e);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      AppLogger.error('❌ Password reset failed', error: e);
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      AppLogger.error('❌ Email verification failed', error: e);
      rethrow;
    }
  }
}

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authServiceProvider));
    });
