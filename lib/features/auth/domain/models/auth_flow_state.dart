/// Authentication flow states - single source of truth for app navigation
///
/// This sealed class defines ALL possible states in the authentication flow.
/// Each state knows exactly where the user should be routed.
sealed class AuthFlowState {
  const AuthFlowState();
}

/// Initial state - checking stored preferences and auth status
class AuthFlowInitial extends AuthFlowState {
  const AuthFlowInitial();
}

/// User needs to see onboarding (first time)
class AuthFlowNeedsOnboarding extends AuthFlowState {
  const AuthFlowNeedsOnboarding();
}

/// User needs to authenticate (not signed in)
class AuthFlowUnauthenticated extends AuthFlowState {
  const AuthFlowUnauthenticated();
}

/// User is authenticated but profile incomplete (missing required fields)
class AuthFlowNeedsProfile extends AuthFlowState {
  final String userId;
  final String? email;
  
  const AuthFlowNeedsProfile({
    required this.userId,
    this.email,
  });
}

/// User is fully authenticated with complete profile - ready for app
class AuthFlowAuthenticated extends AuthFlowState {
  final String userId;
  
  const AuthFlowAuthenticated({
    required this.userId,
  });
}

/// Error state - authentication check failed
class AuthFlowError extends AuthFlowState {
  final String message;
  
  const AuthFlowError({required this.message});
}
