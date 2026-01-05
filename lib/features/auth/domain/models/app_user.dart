import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive user model with all profile data
class AppUser {
  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;

  // Authentication metadata
  final AuthProvider authProvider;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;

  // Profile information
  final String? gender;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? location;
  final String? country;

  // App usage statistics
  final int totalGenerations;
  final int todayGenerations;
  final DateTime? lastGenerationDate;
  final int wardrobeItemCount;
  final int savedOutfitCount;
  final int favoriteCount;
  final int totalWears;

  // Subscription & limits
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiryDate;
  final int generationsLimit;
  final int wardrobeItemLimit;

  // User preferences
  final UserPreferences preferences;

  // Style profile
  final List<String> preferredStyles;
  final List<String> preferredColors;
  final List<String> preferredOccasions;
  final String? bodyType;
  final String? stylePersonality;

  // App settings
  final bool notificationsEnabled;
  final bool emailNotificationsEnabled;
  final String themeMode; // 'light', 'dark', 'system'
  final String language;

  // Social features (for future)
  final List<String> followingIds;
  final List<String> followerIds;
  final bool isPublicProfile;

  // Analytics & tracking
  final Map<String, int> featureUsageCount;
  final DateTime? lastActiveDate;
  final int totalAppOpenCount;
  final int totalSessionDuration; // in minutes

  const AppUser({
    required this.uid,
    required this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.authProvider,
    required this.createdAt,
    required this.lastLoginAt,
    this.isEmailVerified = false,
    this.gender,
    this.bio,
    this.dateOfBirth,
    this.location,
    this.country,
    this.totalGenerations = 0,
    this.todayGenerations = 0,
    this.lastGenerationDate,
    this.wardrobeItemCount = 0,
    this.savedOutfitCount = 0,
    this.favoriteCount = 0,
    this.totalWears = 0,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiryDate,
    this.generationsLimit = 5,
    this.wardrobeItemLimit = 30,
    required this.preferences,
    this.preferredStyles = const [],
    this.preferredColors = const [],
    this.preferredOccasions = const [],
    this.bodyType,
    this.stylePersonality,
    this.notificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.themeMode = 'system',
    this.language = 'en',
    this.followingIds = const [],
    this.followerIds = const [],
    this.isPublicProfile = false,
    this.featureUsageCount = const {},
    this.lastActiveDate,
    this.totalAppOpenCount = 0,
    this.totalSessionDuration = 0,
  });

  /// Check if user can generate more outfits today
  bool canGenerateOutfit() {
    if (subscriptionTier != SubscriptionTier.free) return true;

    final now = DateTime.now();
    final lastGen = lastGenerationDate;

    // Reset daily count if it's a new day
    if (lastGen == null ||
        lastGen.year != now.year ||
        lastGen.month != now.month ||
        lastGen.day != now.day) {
      return true;
    }

    return todayGenerations < generationsLimit;
  }

  /// Check if user can add more wardrobe items
  bool canAddWardrobeItem() {
    if (subscriptionTier != SubscriptionTier.free) return true;
    return wardrobeItemCount < wardrobeItemLimit;
  }

  /// Get remaining generations for today
  int getRemainingGenerations() {
    if (subscriptionTier != SubscriptionTier.free) return -1; // Unlimited

    final now = DateTime.now();
    final lastGen = lastGenerationDate;

    // Reset count if new day
    if (lastGen == null ||
        lastGen.year != now.year ||
        lastGen.month != now.month ||
        lastGen.day != now.day) {
      return generationsLimit;
    }

    return (generationsLimit - todayGenerations).clamp(0, generationsLimit);
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? authProvider,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? gender,
    String? bio,
    DateTime? dateOfBirth,
    String? location,
    String? country,
    int? totalGenerations,
    int? todayGenerations,
    DateTime? lastGenerationDate,
    int? wardrobeItemCount,
    int? savedOutfitCount,
    int? favoriteCount,
    int? totalWears,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiryDate,
    int? generationsLimit,
    int? wardrobeItemLimit,
    UserPreferences? preferences,
    List<String>? preferredStyles,
    List<String>? preferredColors,
    List<String>? preferredOccasions,
    String? bodyType,
    String? stylePersonality,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    String? themeMode,
    String? language,
    List<String>? followingIds,
    List<String>? followerIds,
    bool? isPublicProfile,
    Map<String, int>? featureUsageCount,
    DateTime? lastActiveDate,
    int? totalAppOpenCount,
    int? totalSessionDuration,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      country: country ?? this.country,
      totalGenerations: totalGenerations ?? this.totalGenerations,
      todayGenerations: todayGenerations ?? this.todayGenerations,
      lastGenerationDate: lastGenerationDate ?? this.lastGenerationDate,
      wardrobeItemCount: wardrobeItemCount ?? this.wardrobeItemCount,
      savedOutfitCount: savedOutfitCount ?? this.savedOutfitCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      totalWears: totalWears ?? this.totalWears,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiryDate:
          subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      generationsLimit: generationsLimit ?? this.generationsLimit,
      wardrobeItemLimit: wardrobeItemLimit ?? this.wardrobeItemLimit,
      preferences: preferences ?? this.preferences,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      preferredColors: preferredColors ?? this.preferredColors,
      preferredOccasions: preferredOccasions ?? this.preferredOccasions,
      bodyType: bodyType ?? this.bodyType,
      stylePersonality: stylePersonality ?? this.stylePersonality,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      followingIds: followingIds ?? this.followingIds,
      followerIds: followerIds ?? this.followerIds,
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
      featureUsageCount: featureUsageCount ?? this.featureUsageCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalAppOpenCount: totalAppOpenCount ?? this.totalAppOpenCount,
      totalSessionDuration: totalSessionDuration ?? this.totalSessionDuration,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isEmailVerified': isEmailVerified,
      'gender': gender,
      'bio': bio,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'location': location,
      'country': country,
      'totalGenerations': totalGenerations,
      'todayGenerations': todayGenerations,
      'lastGenerationDate': lastGenerationDate != null
          ? Timestamp.fromDate(lastGenerationDate!)
          : null,
      'wardrobeItemCount': wardrobeItemCount,
      'savedOutfitCount': savedOutfitCount,
      'favoriteCount': favoriteCount,
      'totalWears': totalWears,
      'subscriptionTier': subscriptionTier.name,
      'subscriptionExpiryDate': subscriptionExpiryDate != null
          ? Timestamp.fromDate(subscriptionExpiryDate!)
          : null,
      'generationsLimit': generationsLimit,
      'wardrobeItemLimit': wardrobeItemLimit,
      'preferences': preferences.toMap(),
      'preferredStyles': preferredStyles,
      'preferredColors': preferredColors,
      'preferredOccasions': preferredOccasions,
      'bodyType': bodyType,
      'stylePersonality': stylePersonality,
      'notificationsEnabled': notificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'themeMode': themeMode,
      'language': language,
      'followingIds': followingIds,
      'followerIds': followerIds,
      'isPublicProfile': isPublicProfile,
      'featureUsageCount': featureUsageCount,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'totalAppOpenCount': totalAppOpenCount,
      'totalSessionDuration': totalSessionDuration,
    };
  }

  /// Create from Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] as String,
      email: data['email'] as String,
      username: data['username'] as String?,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      authProvider: AuthProvider.values.firstWhere(
        (e) => e.name == data['authProvider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      gender: data['gender'] as String?,
      bio: data['bio'] as String?,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      location: data['location'] as String?,
      country: data['country'] as String?,
      totalGenerations: data['totalGenerations'] as int? ?? 0,
      todayGenerations: data['todayGenerations'] as int? ?? 0,
      lastGenerationDate: data['lastGenerationDate'] != null
          ? (data['lastGenerationDate'] as Timestamp).toDate()
          : null,
      wardrobeItemCount: data['wardrobeItemCount'] as int? ?? 0,
      savedOutfitCount: data['savedOutfitCount'] as int? ?? 0,
      favoriteCount: data['favoriteCount'] as int? ?? 0,
      totalWears: data['totalWears'] as int? ?? 0,
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == data['subscriptionTier'],
        orElse: () => SubscriptionTier.free,
      ),
      subscriptionExpiryDate: data['subscriptionExpiryDate'] != null
          ? (data['subscriptionExpiryDate'] as Timestamp).toDate()
          : null,
      generationsLimit: data['generationsLimit'] as int? ?? 5,
      wardrobeItemLimit: data['wardrobeItemLimit'] as int? ?? 30,
      preferences: UserPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>? ?? {},
      ),
      preferredStyles: List<String>.from(data['preferredStyles'] ?? []),
      preferredColors: List<String>.from(data['preferredColors'] ?? []),
      preferredOccasions: List<String>.from(data['preferredOccasions'] ?? []),
      bodyType: data['bodyType'] as String?,
      stylePersonality: data['stylePersonality'] as String?,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled:
          data['emailNotificationsEnabled'] as bool? ?? true,
      themeMode: data['themeMode'] as String? ?? 'system',
      language: data['language'] as String? ?? 'en',
      followingIds: List<String>.from(data['followingIds'] ?? []),
      followerIds: List<String>.from(data['followerIds'] ?? []),
      isPublicProfile: data['isPublicProfile'] as bool? ?? false,
      featureUsageCount: Map<String, int>.from(data['featureUsageCount'] ?? {}),
      lastActiveDate: data['lastActiveDate'] != null
          ? (data['lastActiveDate'] as Timestamp).toDate()
          : null,
      totalAppOpenCount: data['totalAppOpenCount'] as int? ?? 0,
      totalSessionDuration: data['totalSessionDuration'] as int? ?? 0,
    );
  }
}

/// Authentication provider enum
enum AuthProvider { email, google, apple, phone }

/// Subscription tier enum
enum SubscriptionTier { free, plus, pro }

/// User preferences model
class UserPreferences {
  final bool showWelcomeTips;
  final bool autoSavePairings;
  final bool highQualityImages;
  final bool analyticsEnabled;
  final String defaultPairingMode; // 'pairThisItem', 'surpriseMe', 'weather'
  final bool enableMannequinGeneration;
  final bool enableFlatLayGeneration;
  final bool enableVisualSearch;

  const UserPreferences({
    this.showWelcomeTips = true,
    this.autoSavePairings = true,
    this.highQualityImages = true,
    this.analyticsEnabled = true,
    this.defaultPairingMode = 'surpriseMe',
    this.enableMannequinGeneration = true,
    this.enableFlatLayGeneration = true,
    this.enableVisualSearch = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'showWelcomeTips': showWelcomeTips,
      'autoSavePairings': autoSavePairings,
      'highQualityImages': highQualityImages,
      'analyticsEnabled': analyticsEnabled,
      'defaultPairingMode': defaultPairingMode,
      'enableMannequinGeneration': enableMannequinGeneration,
      'enableFlatLayGeneration': enableFlatLayGeneration,
      'enableVisualSearch': enableVisualSearch,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      showWelcomeTips: map['showWelcomeTips'] as bool? ?? true,
      autoSavePairings: map['autoSavePairings'] as bool? ?? true,
      highQualityImages: map['highQualityImages'] as bool? ?? true,
      analyticsEnabled: map['analyticsEnabled'] as bool? ?? true,
      defaultPairingMode: map['defaultPairingMode'] as String? ?? 'surpriseMe',
      enableMannequinGeneration:
          map['enableMannequinGeneration'] as bool? ?? true,
      enableFlatLayGeneration: map['enableFlatLayGeneration'] as bool? ?? true,
      enableVisualSearch: map['enableVisualSearch'] as bool? ?? true,
    );
  }

  UserPreferences copyWith({
    bool? showWelcomeTips,
    bool? autoSavePairings,
    bool? highQualityImages,
    bool? analyticsEnabled,
    String? defaultPairingMode,
    bool? enableMannequinGeneration,
    bool? enableFlatLayGeneration,
    bool? enableVisualSearch,
  }) {
    return UserPreferences(
      showWelcomeTips: showWelcomeTips ?? this.showWelcomeTips,
      autoSavePairings: autoSavePairings ?? this.autoSavePairings,
      highQualityImages: highQualityImages ?? this.highQualityImages,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      defaultPairingMode: defaultPairingMode ?? this.defaultPairingMode,
      enableMannequinGeneration:
          enableMannequinGeneration ?? this.enableMannequinGeneration,
      enableFlatLayGeneration:
          enableFlatLayGeneration ?? this.enableFlatLayGeneration,
      enableVisualSearch: enableVisualSearch ?? this.enableVisualSearch,
    );
  }
}
