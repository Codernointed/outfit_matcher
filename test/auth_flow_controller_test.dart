import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/features/auth/domain/models/auth_flow_state.dart';
import 'package:vestiq/features/auth/domain/services/auth_service.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_flow_controller.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([
  AuthService,
  UserProfileService,
  SharedPreferences,
])
import 'auth_flow_controller_test.mocks.dart';

void main() {
  group('AuthFlowController Tests', () {
    late MockAuthService mockAuthService;
    late MockUserProfileService mockProfileService;
    late MockSharedPreferences mockPrefs;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthService();
      mockProfileService = MockUserProfileService();
      mockPrefs = MockSharedPreferences();

      // Setup default mock behaviors
      when(mockAuthService.authStateChanges).thenAnswer((_) => Stream.value(null));
      when(mockAuthService.currentFirebaseUser).thenReturn(null);
      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(false);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state should be AuthFlowInitial', () {
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      expect(controller.state, isA<AuthFlowInitial>());
    });

    test('First-time user should transition to NeedsOnboarding', () async {
      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(false);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      // Wait for async evaluation
      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state, isA<AuthFlowNeedsOnboarding>());
    });

    test('Returning user without auth should show Unauthenticated', () async {
      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      when(mockAuthService.currentFirebaseUser).thenReturn(null);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state, isA<AuthFlowUnauthenticated>());
    });

    test('Authenticated user with incomplete profile should show NeedsProfile', () async {
      final mockUser = MockFirebaseUser();
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');

      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      when(mockAuthService.currentFirebaseUser).thenReturn(mockUser);
      
      // Profile exists but gender is null
      final incompleteProfile = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'Test User',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        gender: null, // Incomplete!
      );
      when(mockProfileService.getUserProfile('test-uid')).thenAnswer((_) async => incompleteProfile);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state, isA<AuthFlowNeedsProfile>());
      final state = controller.state as AuthFlowNeedsProfile;
      expect(state.userId, equals('test-uid'));
      expect(state.email, equals('test@example.com'));
    });

    test('Authenticated user with complete profile should show Authenticated', () async {
      final mockUser = MockFirebaseUser();
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');

      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      when(mockAuthService.currentFirebaseUser).thenReturn(mockUser);
      
      // Complete profile with gender
      final completeProfile = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'Test User',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        gender: 'male', // Complete!
      );
      when(mockProfileService.getUserProfile('test-uid')).thenAnswer((_) async => completeProfile);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(controller.state, isA<AuthFlowAuthenticated>());
      final state = controller.state as AuthFlowAuthenticated;
      expect(state.userId, equals('test-uid'));
    });

    test('completeOnboarding() should save flag and re-evaluate', () async {
      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(false);
      when(mockPrefs.setBool(AppConstants.onboardingCompletedKey, true)).thenAnswer((_) async => true);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowNeedsOnboarding>());

      // Complete onboarding
      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      await controller.completeOnboarding();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowUnauthenticated>());
      verify(mockPrefs.setBool(AppConstants.onboardingCompletedKey, true)).called(1);
    });

    test('refresh() should re-evaluate auth state', () async {
      final mockUser = MockFirebaseUser();
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');

      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      when(mockAuthService.currentFirebaseUser).thenReturn(null);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowUnauthenticated>());

      // Simulate login
      when(mockAuthService.currentFirebaseUser).thenReturn(mockUser);
      final completeProfile = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'Test User',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        gender: 'female',
      );
      when(mockProfileService.getUserProfile('test-uid')).thenAnswer((_) async => completeProfile);

      await controller.refresh();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowAuthenticated>());
    });

    test('onProfileUpdated() should re-evaluate and transition to Authenticated', () async {
      final mockUser = MockFirebaseUser();
      when(mockUser.uid).thenReturn('test-uid');
      when(mockUser.email).thenReturn('test@example.com');

      when(mockPrefs.getBool(AppConstants.onboardingCompletedKey)).thenReturn(true);
      when(mockAuthService.currentFirebaseUser).thenReturn(mockUser);
      
      // Start with incomplete profile
      final incompleteProfile = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'Test User',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        gender: null,
      );
      when(mockProfileService.getUserProfile('test-uid')).thenAnswer((_) async => incompleteProfile);

      final controller = AuthFlowController(
        mockAuthService,
        mockProfileService,
        mockPrefs,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowNeedsProfile>());

      // Update profile
      final completeProfile = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        username: 'Test User',
        authProvider: AuthProvider.email,
        createdAt: DateTime.now(),
        gender: 'male',
      );
      when(mockProfileService.getUserProfile('test-uid')).thenAnswer((_) async => completeProfile);

      await controller.onProfileUpdated();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(controller.state, isA<AuthFlowAuthenticated>());
    });
  });
}

// Mock Firebase User
class MockFirebaseUser extends Mock implements firebase_auth.User {
  @override
  String get uid => super.noSuchMethod(Invocation.getter(#uid), returnValue: 'mock-uid');
  
  @override
  String? get email => super.noSuchMethod(Invocation.getter(#email), returnValue: null);
}
