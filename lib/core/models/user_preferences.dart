import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks user's style preferences learned from behavior
/// This powers smarter outfit generation over time
class UserPreferences {
  final String userId;

  // Color preferences (weighted by frequency)
  final Map<String, int> favoriteColors; // color -> count
  final Map<String, int> avoidedColors; // colors they skip/delete

  // Style preferences
  final Map<String, int> favoriteStyles; // casual, formal, etc -> count
  final Map<String, int> favoriteOccasions; // work, party, etc -> count

  // Category preferences
  final Map<String, int> mostWornCategories; // jeans, t-shirt -> wear count
  final Map<String, int> mostSavedCategories; // categories they save often

  // Pattern preferences
  final Map<String, int> favoritePatterns; // solid, striped, etc -> count

  // Pairing preferences (learns what they like together)
  final Map<String, int> successfulPairings; // "jeans+tshirt" -> count
  final Map<String, int> rejectedPairings; // pairings they skip

  // Brand preferences
  final Map<String, int> favoriteBrands;

  // Timing patterns
  final Map<String, int> occasionsByTimeOfDay; // morning casual, evening formal
  final Map<String, int> occasionsByWeather; // sunny casual, rainy formal

  // Generation preferences
  final String preferredMannequinStyle; // realistic, artistic, minimal
  final bool prefersFullOutfits; // vs individual items
  final double avgMatchScoreAccepted; // min match score they typically save

  // Metadata
  final DateTime lastUpdated;
  final int totalGenerations;
  final int totalSaves;
  final int totalViews;

  const UserPreferences({
    required this.userId,
    this.favoriteColors = const {},
    this.avoidedColors = const {},
    this.favoriteStyles = const {},
    this.favoriteOccasions = const {},
    this.mostWornCategories = const {},
    this.mostSavedCategories = const {},
    this.favoritePatterns = const {},
    this.successfulPairings = const {},
    this.rejectedPairings = const {},
    this.favoriteBrands = const {},
    this.occasionsByTimeOfDay = const {},
    this.occasionsByWeather = const {},
    this.preferredMannequinStyle = 'realistic',
    this.prefersFullOutfits = true,
    this.avgMatchScoreAccepted = 0.7,
    required this.lastUpdated,
    this.totalGenerations = 0,
    this.totalSaves = 0,
    this.totalViews = 0,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'favoriteColors': favoriteColors,
      'avoidedColors': avoidedColors,
      'favoriteStyles': favoriteStyles,
      'favoriteOccasions': favoriteOccasions,
      'mostWornCategories': mostWornCategories,
      'mostSavedCategories': mostSavedCategories,
      'favoritePatterns': favoritePatterns,
      'successfulPairings': successfulPairings,
      'rejectedPairings': rejectedPairings,
      'favoriteBrands': favoriteBrands,
      'occasionsByTimeOfDay': occasionsByTimeOfDay,
      'occasionsByWeather': occasionsByWeather,
      'preferredMannequinStyle': preferredMannequinStyle,
      'prefersFullOutfits': prefersFullOutfits,
      'avgMatchScoreAccepted': avgMatchScoreAccepted,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'totalGenerations': totalGenerations,
      'totalSaves': totalSaves,
      'totalViews': totalViews,
    };
  }

  /// Create from Firestore document
  factory UserPreferences.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserPreferences(
      userId: data['userId'] as String,
      favoriteColors: Map<String, int>.from(data['favoriteColors'] as Map? ?? {}),
      avoidedColors: Map<String, int>.from(data['avoidedColors'] as Map? ?? {}),
      favoriteStyles: Map<String, int>.from(data['favoriteStyles'] as Map? ?? {}),
      favoriteOccasions: Map<String, int>.from(data['favoriteOccasions'] as Map? ?? {}),
      mostWornCategories: Map<String, int>.from(data['mostWornCategories'] as Map? ?? {}),
      mostSavedCategories: Map<String, int>.from(data['mostSavedCategories'] as Map? ?? {}),
      favoritePatterns: Map<String, int>.from(data['favoritePatterns'] as Map? ?? {}),
      successfulPairings: Map<String, int>.from(data['successfulPairings'] as Map? ?? {}),
      rejectedPairings: Map<String, int>.from(data['rejectedPairings'] as Map? ?? {}),
      favoriteBrands: Map<String, int>.from(data['favoriteBrands'] as Map? ?? {}),
      occasionsByTimeOfDay: Map<String, int>.from(data['occasionsByTimeOfDay'] as Map? ?? {}),
      occasionsByWeather: Map<String, int>.from(data['occasionsByWeather'] as Map? ?? {}),
      preferredMannequinStyle: data['preferredMannequinStyle'] as String? ?? 'realistic',
      prefersFullOutfits: data['prefersFullOutfits'] as bool? ?? true,
      avgMatchScoreAccepted: (data['avgMatchScoreAccepted'] as num?)?.toDouble() ?? 0.7,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      totalGenerations: data['totalGenerations'] as int? ?? 0,
      totalSaves: data['totalSaves'] as int? ?? 0,
      totalViews: data['totalViews'] as int? ?? 0,
    );
  }

  /// Create empty preferences for new user
  factory UserPreferences.empty(String userId) {
    return UserPreferences(
      userId: userId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get top N favorite colors sorted by frequency
  List<String> getTopColors(int n) {
    final sorted = favoriteColors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Get top N favorite styles
  List<String> getTopStyles(int n) {
    final sorted = favoriteStyles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Get top N favorite occasions
  List<String> getTopOccasions(int n) {
    final sorted = favoriteOccasions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Get most worn categories
  List<String> getMostWornCategories(int n) {
    final sorted = mostWornCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => e.key).toList();
  }

  /// Check if a pairing is successful (appears in successful pairings)
  bool isPairingSuccessful(String category1, String category2) {
    final key = _createPairingKey(category1, category2);
    return successfulPairings.containsKey(key);
  }

  /// Check if a pairing should be avoided
  bool isPairingRejected(String category1, String category2) {
    final key = _createPairingKey(category1, category2);
    return rejectedPairings.containsKey(key);
  }

  /// Create a consistent key for category pairings
  static String _createPairingKey(String cat1, String cat2) {
    final sorted = [cat1, cat2]..sort();
    return sorted.join('+');
  }

  UserPreferences copyWith({
    Map<String, int>? favoriteColors,
    Map<String, int>? avoidedColors,
    Map<String, int>? favoriteStyles,
    Map<String, int>? favoriteOccasions,
    Map<String, int>? mostWornCategories,
    Map<String, int>? mostSavedCategories,
    Map<String, int>? favoritePatterns,
    Map<String, int>? successfulPairings,
    Map<String, int>? rejectedPairings,
    Map<String, int>? favoriteBrands,
    Map<String, int>? occasionsByTimeOfDay,
    Map<String, int>? occasionsByWeather,
    String? preferredMannequinStyle,
    bool? prefersFullOutfits,
    double? avgMatchScoreAccepted,
    DateTime? lastUpdated,
    int? totalGenerations,
    int? totalSaves,
    int? totalViews,
  }) {
    return UserPreferences(
      userId: userId,
      favoriteColors: favoriteColors ?? this.favoriteColors,
      avoidedColors: avoidedColors ?? this.avoidedColors,
      favoriteStyles: favoriteStyles ?? this.favoriteStyles,
      favoriteOccasions: favoriteOccasions ?? this.favoriteOccasions,
      mostWornCategories: mostWornCategories ?? this.mostWornCategories,
      mostSavedCategories: mostSavedCategories ?? this.mostSavedCategories,
      favoritePatterns: favoritePatterns ?? this.favoritePatterns,
      successfulPairings: successfulPairings ?? this.successfulPairings,
      rejectedPairings: rejectedPairings ?? this.rejectedPairings,
      favoriteBrands: favoriteBrands ?? this.favoriteBrands,
      occasionsByTimeOfDay: occasionsByTimeOfDay ?? this.occasionsByTimeOfDay,
      occasionsByWeather: occasionsByWeather ?? this.occasionsByWeather,
      preferredMannequinStyle: preferredMannequinStyle ?? this.preferredMannequinStyle,
      prefersFullOutfits: prefersFullOutfits ?? this.prefersFullOutfits,
      avgMatchScoreAccepted: avgMatchScoreAccepted ?? this.avgMatchScoreAccepted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalGenerations: totalGenerations ?? this.totalGenerations,
      totalSaves: totalSaves ?? this.totalSaves,
      totalViews: totalViews ?? this.totalViews,
    );
  }
}
