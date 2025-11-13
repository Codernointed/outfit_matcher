import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart';
import 'package:vestiq/features/auth/domain/models/auth_flow_state.dart';
import 'package:vestiq/features/auth/domain/services/auth_service.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';

// ==================== SHARED PREFERENCES PROVIDER ====================

/// Provider for SharedPreferences instance
/// This is initialized asynchronously during app startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences not initialized. Make sure setupServiceLocator() is called before creating ProviderScope',
  );
});

// ==================== AUTH FLOW CONTROLLER ====================

/// Controller that manages the authentication flow state
///
/// This is the SINGLE source of truth for where the user should be in the app.
/// All navigation decisions flow from this controller's state.
class AuthFlowController extends StateNotifier<AuthFlowState> {
  final AuthService _authService;
  final UserProfileService _profileService;
  final SharedPreferences _prefs;

  AuthFlowController(this._authService, this._profileService, this._prefs)
    : super(const AuthFlowInitial()) {
    // Start evaluating auth state immediately
    _evaluateAuthState();

    // Listen to Firebase auth changes and re-evaluate
    _authService.authStateChanges.listen((_) {
      _evaluateAuthState();
    });
  }

  /// Evaluate complete authentication state and emit appropriate AuthFlowState
  Future<void> _evaluateAuthState() async {
    try {
      AppLogger.info('🔍 [AuthFlow] Evaluating authentication state...');

      // Step 1: Check if user has seen onboarding
      final hasSeenOnboarding =
          _prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

      if (!hasSeenOnboarding) {
        AppLogger.info('📱 [AuthFlow] → NeedsOnboarding (first time user)');
        state = const AuthFlowNeedsOnboarding();
        return;
      }

      // Step 2: Check Firebase auth status
      final currentUser = _authService.currentFirebaseUser;

      if (currentUser == null) {
        AppLogger.info('🔓 [AuthFlow] → Unauthenticated (no Firebase user)');
        state = const AuthFlowUnauthenticated();
        return;
      }

      // Step 3: Check Firestore profile completeness
      final profile = await _profileService.getUserProfile(currentUser.uid);

      if (profile == null) {
        AppLogger.warning(
          '⚠️ [AuthFlow] Auth exists but no profile - creating...',
        );
        // Create profile and re-evaluate
        await _profileService.createUserProfile(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          username: currentUser.displayName ?? 'User',
          authProvider: AuthProvider.email,
        );
        state = AuthFlowNeedsProfile(
          userId: currentUser.uid,
          email: currentUser.email,
        );
        return;
      }

      // Step 4: Check if profile is complete (has required fields)
      final isProfileComplete =
          profile.gender != null && profile.gender!.isNotEmpty;

      if (!isProfileComplete) {
        AppLogger.info('👤 [AuthFlow] → NeedsProfile (gender missing)');
        state = AuthFlowNeedsProfile(
          userId: currentUser.uid,
          email: currentUser.email,
        );
        return;
      }

      // Step 5: Everything complete - user authenticated
      AppLogger.info('✅ [AuthFlow] → Authenticated (ready for app)');
      state = AuthFlowAuthenticated(userId: currentUser.uid);
    } catch (e, stack) {
      AppLogger.error(
        '❌ [AuthFlow] Error evaluating state',
        error: e,
        stackTrace: stack,
      );
      state = AuthFlowError(message: 'Authentication check failed: $e');
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      AppLogger.info('📝 [AuthFlow] Marking onboarding complete');
      await _prefs.setBool(AppConstants.onboardingCompletedKey, true);

      // Re-evaluate (should move to Unauthenticated)
      await _evaluateAuthState();
    } catch (e) {
      AppLogger.error('❌ [AuthFlow] Error completing onboarding', error: e);
    }
  }

  /// Called after successful sign up or login - re-evaluate state
  Future<void> refresh() async {
    AppLogger.info('🔄 [AuthFlow] Refreshing auth state');
    await _evaluateAuthState();
  }

  /// Called after profile update (e.g., gender saved)
  Future<void> onProfileUpdated() async {
    AppLogger.info('👤 [AuthFlow] Profile updated - refreshing');
    await _evaluateAuthState();
  }

  /// Sign out - will trigger auth state change listener
  Future<void> signOut() async {
    try {
      AppLogger.info('🚪 [AuthFlow] Signing out');
      await _authService.signOut();
      // State will update via auth state listener
    } catch (e) {
      AppLogger.error('❌ [AuthFlow] Error signing out', error: e);
    }
  }
}

/// Provider for AuthFlowController - single source of truth
final authFlowControllerProvider =
    StateNotifierProvider<AuthFlowController, AuthFlowState>((ref) {
      final authService = ref.watch(authServiceProvider);
      final profileService = ref.watch(userProfileServiceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      return AuthFlowController(authService, profileService, prefs);
    });
