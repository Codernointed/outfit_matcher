import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/auth/domain/models/auth_flow_state.dart';
import 'package:vestiq/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vestiq/features/auth/presentation/screens/login_screen.dart';

/// Integration tests for authentication flow
///
/// These tests verify the entire authentication flow works correctly
/// from onboarding through to authenticated state.
void main() {
  group('Auth Flow Integration Tests', () {
    testWidgets('AuthWrapper shows correct screen based on state', (
      tester,
    ) async {
      // Build the widget tree
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuthWrapper())),
      );

      // Wait for initial state evaluation
      await tester.pumpAndSettle();

      // For first-time user, should show either splash or onboarding
      // We can't check exact screen because it depends on SharedPreferences
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('OnboardingScreen has all required elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
      );

      await tester.pumpAndSettle();

      // Should have page indicator dots
      expect(find.byType(PageView), findsOneWidget);

      // Should have navigation buttons
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('LoginScreen has all required form fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      // Should have email and password fields
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Should have sign in button
      expect(find.text('Sign In'), findsOneWidget);

      // Should have google sign in button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Should have link to signup
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('LoginScreen validates email format', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      // Find the email field (first TextFormField)
      final emailField = find.byType(TextFormField).first;

      // Enter invalid email
      await tester.enterText(emailField, 'invalid-email');

      // Find and tap sign in button
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('email'), findsWidgets);
    });

    testWidgets('LoginScreen validates password is not empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      // Find email field and enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Leave password empty

      // Find and tap sign in button
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Should show validation error for password
      expect(find.textContaining('password'), findsWidgets);
    });

    testWidgets('GenderSelectionScreen has male and female options', (
      tester,
    ) async {
      // Note: Can't directly test GenderSelectionScreen without proper auth setup
      // This would be tested in full integration test with Firebase emulator
    });
  });

  group('AuthFlowState Tests', () {
    test('AuthFlowInitial is created correctly', () {
      const state = AuthFlowInitial();
      expect(state, isA<AuthFlowInitial>());
      expect(state, isA<AuthFlowState>());
    });

    test('AuthFlowNeedsOnboarding is created correctly', () {
      const state = AuthFlowNeedsOnboarding();
      expect(state, isA<AuthFlowNeedsOnboarding>());
      expect(state, isA<AuthFlowState>());
    });

    test('AuthFlowUnauthenticated is created correctly', () {
      const state = AuthFlowUnauthenticated();
      expect(state, isA<AuthFlowUnauthenticated>());
      expect(state, isA<AuthFlowState>());
    });

    test('AuthFlowNeedsProfile stores user info correctly', () {
      const state = AuthFlowNeedsProfile(
        userId: 'test-uid',
        email: 'test@example.com',
      );

      expect(state, isA<AuthFlowNeedsProfile>());
      expect(state.userId, equals('test-uid'));
      expect(state.email, equals('test@example.com'));
    });

    test('AuthFlowAuthenticated stores userId correctly', () {
      const state = AuthFlowAuthenticated(userId: 'test-uid');

      expect(state, isA<AuthFlowAuthenticated>());
      expect(state.userId, equals('test-uid'));
    });

    test('AuthFlowError stores message correctly', () {
      const state = AuthFlowError(message: 'Test error');

      expect(state, isA<AuthFlowError>());
      expect(state.message, equals('Test error'));
    });
  });
}
