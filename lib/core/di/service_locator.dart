import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/services/compatibility_cache_service.dart';
import 'package:vestiq/core/services/enhanced_outfit_storage_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/file_based_storage_service.dart';
import 'package:vestiq/core/services/image_processing_service.dart';
import 'package:vestiq/core/services/mannequin_cache_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/services/voice_search_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/services/analytics_service.dart';
import 'package:vestiq/core/subscriptions/paystack_payment_service.dart';
import 'package:vestiq/core/subscriptions/subscription_config.dart';
import 'package:vestiq/core/subscriptions/subscription_api_client.dart';
import 'package:vestiq/core/subscriptions/usage_guard.dart';
import 'package:vestiq/core/utils/image_cache_manager.dart';
import 'package:vestiq/features/auth/domain/services/user_preferences_service.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/features/outfit_suggestions/data/firestore_outfit_service.dart';
import 'package:vestiq/features/wardrobe/data/firestore_wardrobe_service.dart';
import 'package:vestiq/features/wardrobe/data/firestore_wear_history_service.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Set up the service locator for dependency injection
Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Analytics
  getIt.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Repositories

  // Core Services
  getIt.registerLazySingleton<OutfitStorageService>(
    () => OutfitStorageService(sharedPreferences),
  );

  // Firestore Outfit Service
  getIt.registerLazySingleton<FirestoreOutfitService>(
    () => FirestoreOutfitService(),
  );

  // Enhanced Outfit Storage Service (with Firestore sync)
  getIt.registerLazySingleton<EnhancedOutfitStorageService>(
    () => EnhancedOutfitStorageService(
      localService: getIt<OutfitStorageService>(),
      firestoreService: getIt<FirestoreOutfitService>(),
      userProfileService: getIt<UserProfileService>(),
    ),
  );

  getIt.registerLazySingleton<EnhancedWardrobeStorageService>(
    () => EnhancedWardrobeStorageService(
      sharedPreferences,
      getIt<OutfitStorageService>(),
    ),
  );

  getIt.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(sharedPreferences),
  );

  getIt.registerLazySingleton<SubscriptionConfig>(
    () => SubscriptionConfig.fromEnv(dotenv),
  );

  getIt.registerLazySingleton<SubscriptionApiClient>(
    () => SubscriptionApiClient(
      httpClient: getIt<http.Client>(),
      config: getIt<SubscriptionConfig>(),
    ),
  );

  getIt.registerLazySingleton<PaystackPaymentService>(
    () => PaystackPaymentService(config: getIt<SubscriptionConfig>()),
  );

  getIt.registerLazySingleton<UsageGuard>(
    () => UsageGuard(getIt<AppSettingsService>()),
  );

  // Wardrobe Services
  getIt.registerLazySingleton<ImageProcessingService>(
    () => ImageProcessingService(),
  );

  getIt.registerLazySingleton<CompatibilityCacheService>(
    () => CompatibilityCacheService(),
  );

  getIt.registerLazySingleton<MannequinCacheService>(
    () => MannequinCacheService(sharedPreferences),
  );

  getIt.registerLazySingleton<WardrobePairingService>(
    () => WardrobePairingService(
      compatibilityCache: getIt<CompatibilityCacheService>(),
    ),
  );

  getIt.registerLazySingleton<ImageCacheManager>(
    () => ImageCacheManager.instance,
  );

  getIt.registerLazySingleton<FileBasedStorageService>(
    () => FileBasedStorageService.instance,
  );

  getIt.registerLazySingleton<VoiceSearchService>(() => VoiceSearchService());

  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(sharedPreferences),
  );

  // Auth / User Profile Services
  // Ensure Firebase is initialized before this is called (done in main.dart)
  getIt.registerLazySingleton<UserProfileService>(
    () => UserProfileService(firestore: FirebaseFirestore.instance),
  );

  // Firestore Wardrobe Service
  getIt.registerLazySingleton<FirestoreWardrobeService>(
    () => FirestoreWardrobeService(firestore: FirebaseFirestore.instance),
  );

  // Firestore Wear History Service
  getIt.registerLazySingleton<FirestoreWearHistoryService>(
    () => FirestoreWearHistoryService(),
  );

  // User Preferences Service
  getIt.registerLazySingleton<UserPreferencesService>(
    () => UserPreferencesService(),
  );

  // Controllers

  // Use cases
}
