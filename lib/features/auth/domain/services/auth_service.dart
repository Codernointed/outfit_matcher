import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/core/services/walkthrough_service.dart';
import 'package:vestiq/core/di/service_locator.dart';

/// Service for handling Firebase authentication operations
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    UserProfileService? userProfileService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _userProfileService = userProfileService ?? UserProfileService();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserProfileService _userProfileService;
  bool _googleSignInInitialized = false;

  /// Get current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  // ==================== EMAIL/PASSWORD AUTHENTICATION ====================

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      AppLogger.info('📝 Signing up with email: $email');

      // Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await user.updateDisplayName(username);

      // Send email verification
      await user.sendEmailVerification();
      AppLogger.info('📧 Verification email sent to: $email');

      // Create user profile in Firestore
      final appUser = await _userProfileService.createUserProfile(
        uid: user.uid,
        email: email,
        username: username,
        displayName: username,
        authProvider: AuthProvider.email,
      );

      AppLogger.info('✅ User signed up successfully: ${user.uid}');
      return appUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Sign up error', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('❌ Unexpected sign up error', error: e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔐 Signing in with email: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Check if profile exists, create if not
      AppUser? appUser = await _userProfileService.getUserProfile(user.uid);

      if (appUser == null) {
        // Profile doesn't exist - create it
        AppLogger.warning(
          '⚠️ Profile not found, creating new profile for: ${user.uid}',
        );
        appUser = await _userProfileService.createUserProfile(
          uid: user.uid,
          email: user.email ?? email,
          username: user.displayName ?? email.split('@')[0],
          displayName: user.displayName,
          photoUrl: user.photoURL,
          authProvider: AuthProvider.email,
        );
      } else {
        // Profile exists - just update last login
        appUser = await _userProfileService.updateLastLogin(user.uid);
      }

      AppLogger.info('✅ User signed in successfully: ${user.uid}');

      // Mark walkthroughs as seen for returning users
      try {
        if (getIt.isRegistered<WalkthroughService>()) {
          final walkthroughService = getIt<WalkthroughService>();
          await walkthroughService.completeHomeWalkthrough();
          await walkthroughService.completeClosetWalkthrough();
          AppLogger.info('✅ Marked walkthroughs as seen for returning user');
        }
      } catch (e) {
        AppLogger.warning('⚠️ Failed to mark walkthroughs as seen: $e');
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Sign in error', error: e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('❌ Unexpected sign in error', error: e);
      rethrow;
    }
  }

  // ==================== GOOGLE SIGN-IN ====================

  /// Initialize Google Sign-In (call once)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      try {
        await _googleSignIn.initialize();
        _googleSignInInitialized = true;
        AppLogger.info('✅ Google Sign-In initialized');
      } catch (e) {
        AppLogger.error('❌ Google Sign-In initialization error', error: e);
        // Continue anyway, it might be already initialized
        _googleSignInInitialized = true;
      }
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      AppLogger.info('🔍 Starting Google sign-in flow (v7)');

      // 1. Ensure initialized
      await _ensureGoogleSignInInitialized();

      // 2. Trigger authentication
      AppLogger.info('⏳ Awaiting Google Sign In...');

      // In v7, authenticate() returns the account directly
      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate();

      AppLogger.info('✅ Google User selected: ${googleUser.email}');
      AppLogger.info('⏳ Retrieving tokens...');

      // 3. Obtain authentication details (idToken)
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create credential
      // Note: We deliberately omit accessToken if we can't get it easily.
      // Firebase usually accepts idToken alone for identity.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken:
            null, // Access token is for API access, idToken is for identity
      );

      AppLogger.info('⏳ Signing in to Firebase with credential...');

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception(
          'Failed to sign in with Google - Firebase user is null',
        );
      }

      AppLogger.info('✅ Firebase Sign In successful: ${user.uid}');
      AppLogger.info('⏳ Fetching/Creating user profile...');

      // Check if profile exists in Firestore (more reliable than isNewUser)
      AppUser? appUser = await _userProfileService.getUserProfile(user.uid);

      if (appUser == null) {
        // Profile doesn't exist - create it
        AppLogger.info('🆕 Creating new Google user profile: ${user.uid}');
        appUser = await _userProfileService.createUserProfile(
          uid: user.uid,
          email: user.email ?? googleUser.email,
          username:
              user.displayName ??
              googleUser.displayName ??
              user.email?.split('@')[0] ??
              'user',
          displayName: user.displayName ?? googleUser.displayName,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
          authProvider: AuthProvider.google,
        );
        AppLogger.info('✅ New profile created');
      } else {
        // Profile exists - just update last login
        AppLogger.info(
          '👋 Existing Google user, updating last login: ${user.uid}',
        );
        appUser = await _userProfileService.updateLastLogin(user.uid);
        AppLogger.info('✅ Last login updated');

        // Mark walkthroughs as seen for returning users
        try {
          if (getIt.isRegistered<WalkthroughService>()) {
            final walkthroughService = getIt<WalkthroughService>();
            await walkthroughService.completeHomeWalkthrough();
            await walkthroughService.completeClosetWalkthrough();
            AppLogger.info(
              '✅ Marked walkthroughs as seen for returning Google user',
            );
          }
        } catch (e) {
          AppLogger.warning('⚠️ Failed to mark walkthroughs as seen: $e');
        }
      }

      return appUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Google sign-in error [Firebase]', error: e);
      throw _handleAuthException(e);
    } catch (e, stack) {
      AppLogger.error(
        '❌ Unexpected Google sign-in error',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.info('📧 Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.info('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Password reset error', error: e);
      throw _handleAuthException(e);
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔑 Confirming password reset');
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
      AppLogger.info('✅ Password reset successful');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Password reset confirmation error', error: e);
      throw _handleAuthException(e);
    }
  }

  // ==================== EMAIL VERIFICATION ====================

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (user.emailVerified) {
        AppLogger.info('✅ Email already verified');
        return;
      }

      await user.sendEmailVerification();
      AppLogger.info('📧 Verification email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Email verification error', error: e);
      throw _handleAuthException(e);
    }
  }

  /// Reload user to check email verification status
  Future<bool> checkEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;
      return updatedUser?.emailVerified ?? false;
    } catch (e) {
      AppLogger.error('❌ Error checking email verification', error: e);
      return false;
    }
  }

  // ==================== ACCOUNT MANAGEMENT ====================

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      AppLogger.info('✅ Profile updated successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Profile update error', error: e);
      throw _handleAuthException(e);
    }
  }

  /// Update email address
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.verifyBeforeUpdateEmail(newEmail);
      await user.sendEmailVerification();
      AppLogger.info('✅ Email update verification sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Email update error', error: e);
      throw _handleAuthException(e);
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.updatePassword(newPassword);
      AppLogger.info('✅ Password updated successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Password update error', error: e);
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Delete user profile from Firestore
      await _userProfileService.deleteUserProfile(user.uid);

      // Delete Firebase Auth user
      await user.delete();

      AppLogger.info('✅ Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Account deletion error', error: e);
      throw _handleAuthException(e);
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.info('🚪 Signing out from all services...');

      // Attempt to sign out from Google unconditionally (no state check available)
      try {
        AppLogger.info('🚪 Disconnecting Google Sign-In...');
        // In v7, disconnect/signOut should handle not-signed-in states gracefully or throw
        await _googleSignIn.disconnect();
        await _googleSignIn.signOut();
      } catch (e) {
        AppLogger.warning('⚠️ Google sign out warning (ignoring): $e');
      }

      // Sign out from Firebase
      AppLogger.info('🚪 Signing out from Firebase...');
      await _firebaseAuth.signOut();

      AppLogger.info('✅ Signed out successfully');
    } catch (e) {
      AppLogger.error('❌ Sign out error', error: e);
      rethrow;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    AppLogger.error('🚨 Auth exception: ${e.code}', error: e);

    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'The credentials are malformed or expired.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
