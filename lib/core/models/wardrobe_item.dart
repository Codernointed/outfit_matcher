import 'package:vestiq/core/models/clothing_analysis.dart';

/// Enhanced wardrobe item with rich metadata for premium closet experience
class WardrobeItem {
  final String id;
  final ClothingAnalysis analysis;
  final String originalImagePath;
  final String? polishedImagePath;
  final List<String> occasions;
  final List<String> locations;
  final List<String> seasons;
  final List<String> styleHints;
  final String? userNotes;
  final DateTime createdAt;
  final DateTime? lastWorn;
  final List<String> tags;
  final bool isFavorite;
  final int wearCount;

  const WardrobeItem({
    required this.id,
    required this.analysis,
    required this.originalImagePath,
    this.polishedImagePath,
    this.occasions = const [],
    this.locations = const [],
    this.seasons = const [],
    this.styleHints = const [],
    this.userNotes,
    required this.createdAt,
    this.lastWorn,
    this.tags = const [],
    this.isFavorite = false,
    this.wearCount = 0,
  });

  /// Create from ClothingAnalysis with defaults
  factory WardrobeItem.fromAnalysis({
    required String id,
    required ClothingAnalysis analysis,
    required String originalImagePath,
    String? polishedImagePath,
    List<String>? occasions,
    List<String>? locations,
    List<String>? seasons,
    String? userNotes,
    List<String>? tags,
  }) {
    return WardrobeItem(
      id: id,
      analysis: analysis,
      originalImagePath: originalImagePath,
      polishedImagePath: polishedImagePath,
      occasions: occasions ?? _inferOccasions(analysis),
      locations: locations ?? _inferLocations(analysis),
      seasons: seasons ?? analysis.seasons,
      styleHints: analysis.styleHints ?? const [],
      userNotes: userNotes,
      createdAt: DateTime.now(),
      tags: tags ?? [],
    );
  }

  /// Infer occasions from analysis
  static List<String> _inferOccasions(ClothingAnalysis analysis) {
    switch (analysis.formality?.toLowerCase()) {
      case 'formal':
        return ['formal', 'work', 'evening'];
      case 'business':
        return ['work', 'business', 'smart casual'];
      case 'smart casual':
        return ['smart casual', 'date', 'brunch'];
      case 'casual':
      default:
        return ['casual', 'weekend', 'everyday'];
    }
  }

  /// Infer locations from analysis
  static List<String> _inferLocations(ClothingAnalysis analysis) {
    final locations = <String>['indoor'];

    // Add outdoor for casual items
    if (analysis.formality?.toLowerCase() == 'casual') {
      locations.add('outdoor');
    }

    // Add climate-based locations
    if (analysis.seasons.contains('Summer')) {
      locations.addAll(['hot', 'humid', 'beach']);
    }
    if (analysis.seasons.contains('Winter')) {
      locations.addAll(['cold', 'dry']);
    }

    return locations;
  }

  /// Get display image path (polished if available, otherwise original)
  String get displayImagePath => polishedImagePath ?? originalImagePath;

  /// Check if item matches occasion
  bool matchesOccasion(String occasion) {
    return occasions.any(
      (o) => o.toLowerCase().contains(occasion.toLowerCase()),
    );
  }

  /// Check if item matches location/weather
  bool matchesLocation(String location) {
    return locations.any(
      (l) => l.toLowerCase().contains(location.toLowerCase()),
    );
  }

  /// Check if item matches season
  bool matchesSeason(String season) {
    return seasons.any((s) => s.toLowerCase().contains(season.toLowerCase()));
  }

  /// Get compatibility score with another item (0.0 to 1.0)
  double getCompatibilityScore(WardrobeItem other) {
    double score = 0.0;

    // Color harmony (40% weight)
    score += _getColorHarmonyScore(other) * 0.4;

    // Formality match (30% weight)
    score += _getFormalityScore(other) * 0.3;

    // Occasion overlap (20% weight)
    score += _getOccasionScore(other) * 0.2;

    // Season compatibility (10% weight)
    score += _getSeasonScore(other) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  double _getColorHarmonyScore(WardrobeItem other) {
    // Simplified color harmony - complementary colors get high scores
    final colorMap = {
      'red': ['white', 'black', 'blue', 'green'],
      'blue': ['white', 'red', 'yellow', 'orange'],
      'green': ['white', 'red', 'brown', 'beige'],
      'black': ['white', 'red', 'blue', 'green', 'yellow'],
      'white': ['black', 'red', 'blue', 'green', 'brown'],
      'brown': ['white', 'green', 'beige', 'cream'],
      'gray': ['white', 'black', 'red', 'blue'],
    };

    final myColor = analysis.primaryColor.toLowerCase();
    final otherColor = other.analysis.primaryColor.toLowerCase();

    if (myColor == otherColor) return 0.6; // Same color is okay
    if (colorMap[myColor]?.contains(otherColor) == true) return 1.0;
    return 0.3; // Default compatibility
  }

  double _getFormalityScore(WardrobeItem other) {
    final formalityLevels = {
      'formal': 4,
      'business': 3,
      'smart casual': 2,
      'casual': 1,
    };

    final myLevel = formalityLevels[analysis.formality?.toLowerCase()] ?? 1;
    final otherLevel =
        formalityLevels[other.analysis.formality?.toLowerCase()] ?? 1;

    final difference = (myLevel - otherLevel).abs();
    return difference <= 1 ? 1.0 : 0.5; // Adjacent levels are compatible
  }

  double _getOccasionScore(WardrobeItem other) {
    final overlap = occasions.toSet().intersection(other.occasions.toSet());
    return overlap.isEmpty ? 0.0 : 1.0;
  }

  double _getSeasonScore(WardrobeItem other) {
    final overlap = seasons.toSet().intersection(other.seasons.toSet());
    return overlap.isEmpty ? 0.5 : 1.0; // Some items work across seasons
  }

  /// Copy with modifications
  WardrobeItem copyWith({
    String? id,
    ClothingAnalysis? analysis,
    String? originalImagePath,
    String? polishedImagePath,
    List<String>? occasions,
    List<String>? locations,
    List<String>? seasons,
    String? userNotes,
    DateTime? createdAt,
    DateTime? lastWorn,
    List<String>? tags,
    bool? isFavorite,
    int? wearCount,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      analysis: analysis ?? this.analysis,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      polishedImagePath: polishedImagePath ?? this.polishedImagePath,
      occasions: occasions ?? this.occasions,
      locations: locations ?? this.locations,
      seasons: seasons ?? this.seasons,
      styleHints: styleHints ?? this.styleHints,
      userNotes: userNotes ?? this.userNotes,
      createdAt: createdAt ?? this.createdAt,
      lastWorn: lastWorn ?? this.lastWorn,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      wearCount: wearCount ?? this.wearCount,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'analysis': analysis.toJson(),
      'originalImagePath': originalImagePath,
      'polishedImagePath': polishedImagePath,
      'occasions': occasions,
      'locations': locations,
      'seasons': seasons,
      'styleHints': styleHints,
      'userNotes': userNotes,
      'createdAt': createdAt.toIso8601String(),
      'lastWorn': lastWorn?.toIso8601String(),
      'tags': tags,
      'isFavorite': isFavorite,
      'wearCount': wearCount,
    };
  }

  /// Create from JSON
  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as String,
      analysis: ClothingAnalysis.fromJson(
        json['analysis'] as Map<String, dynamic>,
      ),
      originalImagePath: json['originalImagePath'] as String,
      polishedImagePath: json['polishedImagePath'] as String?,
      occasions: List<String>.from(json['occasions'] ?? []),
      locations: List<String>.from(json['locations'] ?? []),
      seasons: List<String>.from(json['seasons'] ?? []),
      styleHints: List<String>.from(json['styleHints'] ?? []),
      userNotes: json['userNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastWorn:
          json['lastWorn'] != null
              ? DateTime.parse(json['lastWorn'] as String)
              : null,
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      wearCount: json['wearCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'WardrobeItem(id: $id, type: ${analysis.itemType}, color: ${analysis.primaryColor})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WardrobeItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Saved outfit look combining multiple wardrobe items
class WardrobeLook {
  final String id;
  final String title;
  final List<String> itemIds;
  final String? imageUrl; // Generated mannequin image
  final String generationMode; // 'pair', 'surprise', 'location'
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isFavorite;

  const WardrobeLook({
    required this.id,
    required this.title,
    required this.itemIds,
    this.imageUrl,
    required this.generationMode,
    this.metadata = const {},
    required this.createdAt,
    this.isFavorite = false,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'itemIds': itemIds,
      'imageUrl': imageUrl,
      'generationMode': generationMode,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// Create from JSON
  factory WardrobeLook.fromJson(Map<String, dynamic> json) {
    return WardrobeLook(
      id: json['id'] as String,
      title: json['title'] as String,
      itemIds: List<String>.from(json['itemIds']),
      imageUrl: json['imageUrl'] as String?,
      generationMode: json['generationMode'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  WardrobeLook copyWith({
    String? id,
    String? title,
    List<String>? itemIds,
    String? imageUrl,
    String? generationMode,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return WardrobeLook(
      id: id ?? this.id,
      title: title ?? this.title,
      itemIds: itemIds ?? this.itemIds,
      imageUrl: imageUrl ?? this.imageUrl,
      generationMode: generationMode ?? this.generationMode,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WardrobeLook && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
