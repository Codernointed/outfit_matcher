import 'package:flutter_test/flutter_test.dart';
import 'package:vestiq/features/auth/domain/models/auth_flow_state.dart';

/// Simple unit tests for auth flow states without external dependencies
void main() {
  group('AuthFlowState', () {
    test('Initial state should be initial', () {
      const state = AuthFlowInitial();
      expect(state, isA<AuthFlowInitial>());
    });

    test('NeedsOnboarding state should be identifiable', () {
      const state = AuthFlowNeedsOnboarding();
      expect(state, isA<AuthFlowNeedsOnboarding>());
    });

    test('Unauthenticated state should be identifiable', () {
      const state = AuthFlowUnauthenticated();
      expect(state, isA<AuthFlowUnauthenticated>());
    });

    test('NeedsProfile state should be identifiable and contain userId', () {
      const state = AuthFlowNeedsProfile(
        userId: 'test-uid',
        email: 'test@example.com',
      );
      expect(state, isA<AuthFlowNeedsProfile>());
      expect(state.userId, equals('test-uid'));
      expect(state.email, equals('test@example.com'));
    });

    test('Authenticated state should be identifiable and contain userId', () {
      const state = AuthFlowAuthenticated(userId: 'test-uid');
      expect(state, isA<AuthFlowAuthenticated>());
      expect(state.userId, equals('test-uid'));
    });

    test('Error state should contain error message', () {
      const errorMessage = 'Test error';
      const state = AuthFlowError(message: errorMessage);

      expect(state, isA<AuthFlowError>());
      expect(state.message, equals(errorMessage));
    });
  });

  group('Auth Flow Transitions', () {
    test('Should identify first-time user needing onboarding', () {
      const state = AuthFlowNeedsOnboarding();
      expect(state, isA<AuthFlowNeedsOnboarding>());
    });

    test('Should identify unauthenticated user after onboarding', () {
      const state = AuthFlowUnauthenticated();
      expect(state, isA<AuthFlowUnauthenticated>());
    });

    test('Should identify authenticated user needing profile completion', () {
      const state = AuthFlowNeedsProfile(userId: 'test-uid');
      expect(state, isA<AuthFlowNeedsProfile>());
      expect(state.userId, equals('test-uid'));
    });

    test('Should identify fully authenticated user', () {
      const state = AuthFlowAuthenticated(userId: 'test-uid');
      expect(state, isA<AuthFlowAuthenticated>());
      expect(state.userId, equals('test-uid'));
    });
  });

  group('Error Handling', () {
    test('Should create error state with message', () {
      const errorMessage = 'Authentication failed';
      const errorState = AuthFlowError(message: errorMessage);

      expect(errorState.message, equals(errorMessage));
    });

    test('Should handle network errors', () {
      const errorMessage = 'Network error occurred';
      const errorState = AuthFlowError(message: errorMessage);

      expect(errorState.message, contains('Network'));
    });

    test('Should handle Firebase errors', () {
      const errorMessage = 'Firebase authentication failed';
      const errorState = AuthFlowError(message: errorMessage);

      expect(errorState.message, contains('Firebase'));
    });
  });
}
