import 'package:vestiq/core/utils/logger.dart';

class ClothingAnalysis {
  final String id;
  final String itemType; // e.g., "blouse", "jeans"
  final String primaryColor;
  final String patternType;
  final String style; // e.g., "casual", "formal"
  final List<String> seasons;
  final double confidence;
  final List<String> tags;

  // Additional metadata
  final String? brand;
  final String? material;
  final String? neckline; // For tops/dresses
  final String? sleeveLength;
  final String? fit; // e.g., "slim", "oversized"
  final bool isPatterned;
  final String? imagePath;

  // Style attributes
  final String? formality; // casual, business, formal, party
  final String? subcategory; // blouse, t-shirt, dress shirt, etc.
  final List<String>? colors; // secondary colors
  final String? texture; // smooth, textured, knit, etc.

  // Enhanced color intelligence
  final String? colorFamily; // normalized family (e.g., brown, blue)
  final String? exactPrimaryColor; // precise name like "warm beige"
  final String? colorHex; // hex code if available
  final List<String>?
  colorKeywords; // adjectives for the color (soft, muted, etc.)

  // Pattern insights
  final String? patternDetails; // natural language description of pattern
  final List<String>? patternKeywords; // additional descriptors

  // Contextual metadata from AI analysis
  final List<String>?
  occasions; // suggested occasions (date night, brunch, work)
  final List<String>? locations; // indoor, outdoor, beach, cold_weather, etc.
  final List<String>? styleHints; // quick styling tips from AI
  final List<String>? styleDescriptors; // mood/attitude notes

  // Fit information
  final String? length; // short, medium, long
  final String? silhouette; // fitted, loose, A-line, etc.

  // Enhanced fashion intelligence for perfect pairing
  final String? colorUndertone; // warm, cool, neutral
  final List<String>? complementaryColors; // colors that pair well
  final String? colorTemperature; // warm, cool, neutral
  final List<String>?
  designElements; // embellishments, hardware, unique features
  final String? visualWeight; // light, medium, heavy - for visual balance
  final List<String>? pairingHints; // AI suggestions for what pairs well
  final String? stylePersonality; // edgy, classic, romantic, minimalist, etc.
  final String?
  detailLevel; // minimal, moderate, detailed - for pairing complexity
  final List<String>? garmentKeywords; // hero descriptors e.g. retro, sporty
  final Map<String, dynamic>?
  rawAttributes; // additional AI metadata for future use

  const ClothingAnalysis({
    required this.id,
    required this.itemType,
    required this.primaryColor,
    required this.patternType,
    required this.style,
    required this.seasons,
    required this.confidence,
    required this.tags,
    this.brand,
    this.material,
    this.neckline,
    this.sleeveLength,
    this.fit,
    this.isPatterned = false,
    this.imagePath,
    this.formality,
    this.subcategory,
    this.colors,
    this.texture,
    this.colorFamily,
    this.exactPrimaryColor,
    this.colorHex,
    this.colorKeywords,
    this.patternDetails,
    this.patternKeywords,
    this.length,
    this.silhouette,
    this.occasions,
    this.locations,
    this.styleHints,
    this.styleDescriptors,
    this.colorUndertone,
    this.complementaryColors,
    this.colorTemperature,
    this.designElements,
    this.visualWeight,
    this.pairingHints,
    this.stylePersonality,
    this.detailLevel,
    this.garmentKeywords,
    this.rawAttributes,
  });

  ClothingAnalysis copyWith({
    String? id,
    String? itemType,
    String? primaryColor,
    String? patternType,
    String? style,
    List<String>? seasons,
    double? confidence,
    List<String>? tags,
    String? brand,
    String? material,
    String? neckline,
    String? sleeveLength,
    String? fit,
    bool? isPatterned,
    String? imagePath,
    String? formality,
    String? subcategory,
    List<String>? colors,
    String? texture,
    String? colorFamily,
    String? exactPrimaryColor,
    String? colorHex,
    List<String>? colorKeywords,
    String? patternDetails,
    List<String>? patternKeywords,
    String? length,
    String? silhouette,
    List<String>? occasions,
    List<String>? locations,
    List<String>? styleHints,
    List<String>? styleDescriptors,
    String? colorUndertone,
    List<String>? complementaryColors,
    String? colorTemperature,
    List<String>? designElements,
    String? visualWeight,
    List<String>? pairingHints,
    String? stylePersonality,
    String? detailLevel,
    List<String>? garmentKeywords,
    Map<String, dynamic>? rawAttributes,
  }) {
    return ClothingAnalysis(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      primaryColor: primaryColor ?? this.primaryColor,
      patternType: patternType ?? this.patternType,
      style: style ?? this.style,
      seasons: seasons ?? this.seasons,
      confidence: confidence ?? this.confidence,
      tags: tags ?? this.tags,
      brand: brand ?? this.brand,
      material: material ?? this.material,
      neckline: neckline ?? this.neckline,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      fit: fit ?? this.fit,
      isPatterned: isPatterned ?? this.isPatterned,
      imagePath: imagePath ?? this.imagePath,
      formality: formality ?? this.formality,
      subcategory: subcategory ?? this.subcategory,
      colors: colors ?? this.colors,
      texture: texture ?? this.texture,
      colorFamily: colorFamily ?? this.colorFamily,
      exactPrimaryColor: exactPrimaryColor ?? this.exactPrimaryColor,
      colorHex: colorHex ?? this.colorHex,
      colorKeywords: colorKeywords ?? this.colorKeywords,
      patternDetails: patternDetails ?? this.patternDetails,
      patternKeywords: patternKeywords ?? this.patternKeywords,
      length: length ?? this.length,
      silhouette: silhouette ?? this.silhouette,
      occasions: occasions ?? this.occasions,
      locations: locations ?? this.locations,
      styleHints: styleHints ?? this.styleHints,
      styleDescriptors: styleDescriptors ?? this.styleDescriptors,
      colorUndertone: colorUndertone ?? this.colorUndertone,
      complementaryColors: complementaryColors ?? this.complementaryColors,
      colorTemperature: colorTemperature ?? this.colorTemperature,
      designElements: designElements ?? this.designElements,
      visualWeight: visualWeight ?? this.visualWeight,
      pairingHints: pairingHints ?? this.pairingHints,
      stylePersonality: stylePersonality ?? this.stylePersonality,
      detailLevel: detailLevel ?? this.detailLevel,
      garmentKeywords: garmentKeywords ?? this.garmentKeywords,
      rawAttributes: rawAttributes ?? this.rawAttributes,
    );
  }

  @override
  String toString() {
    return 'ClothingAnalysis('
        'id: $id, '
        'itemType: $itemType, '
        'primaryColor: $primaryColor, '
        'style: $style, '
        'seasons: $seasons, '
        'confidence: $confidence)';
  }

  factory ClothingAnalysis.fromJson(Map<String, dynamic> json) {
    AppLogger.debug('📦 Creating ClothingAnalysis from JSON');
    final analysis = ClothingAnalysis(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      itemType: json['itemType'] ?? '',
      primaryColor: json['primaryColor'] ?? '',
      patternType: json['patternType'] ?? '',
      style: json['style'] ?? 'casual',
      seasons: List<String>.from(json['seasons'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      tags: List<String>.from(json['tags'] ?? []),
      fit: json['fit'],
      material: json['material'],
      formality: json['formality'],
      subcategory: json['subcategory'],
      imagePath: json['imagePath'],
      colorFamily: json['colorFamily'],
      exactPrimaryColor: json['exactPrimaryColor'],
      colorHex: json['colorHex'],
      colorKeywords: json['colorKeywords'] != null
          ? List<String>.from(json['colorKeywords'] as List<dynamic>)
          : null,
      patternDetails: json['patternDetails'],
      patternKeywords: json['patternKeywords'] != null
          ? List<String>.from(json['patternKeywords'] as List<dynamic>)
          : null,
      occasions: json['occasions'] != null
          ? List<String>.from(json['occasions'] as List<dynamic>)
          : null,
      locations: json['locations'] != null
          ? List<String>.from(json['locations'] as List<dynamic>)
          : null,
      styleHints: json['styleHints'] != null
          ? List<String>.from(json['styleHints'] as List<dynamic>)
          : null,
      styleDescriptors: json['styleDescriptors'] != null
          ? List<String>.from(json['styleDescriptors'] as List<dynamic>)
          : null,
      colorUndertone: json['colorUndertone'],
      complementaryColors: json['complementaryColors'] != null
          ? List<String>.from(json['complementaryColors'] as List<dynamic>)
          : null,
      colorTemperature: json['colorTemperature'],
      designElements: json['designElements'] != null
          ? List<String>.from(json['designElements'] as List<dynamic>)
          : null,
      visualWeight: json['visualWeight'],
      pairingHints: json['pairingHints'] != null
          ? List<String>.from(json['pairingHints'] as List<dynamic>)
          : null,
      stylePersonality: json['stylePersonality'],
      detailLevel: json['detailLevel'],
      garmentKeywords: json['garmentKeywords'] != null
          ? List<String>.from(json['garmentKeywords'] as List<dynamic>)
          : null,
      rawAttributes: json['rawAttributes'] as Map<String, dynamic>?,
    );
    AppLogger.debug(
      '✅ ClothingAnalysis created: ${analysis.itemType} (${analysis.primaryColor})',
    );
    return analysis;
  }

  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'itemType': itemType,
      'primaryColor': primaryColor,
      'patternType': patternType,
      'style': style,
      'seasons': seasons,
      'confidence': confidence,
      'tags': tags,
      'brand': brand,
      'material': material,
      'neckline': neckline,
      'sleeveLength': sleeveLength,
      'fit': fit,
      'isPatterned': isPatterned,
      'imagePath': imagePath,
      'formality': formality,
      'subcategory': subcategory,
      'colors': colors,
      'texture': texture,
      'colorFamily': colorFamily,
      'exactPrimaryColor': exactPrimaryColor,
      'colorHex': colorHex,
      'colorKeywords': colorKeywords,
      'patternDetails': patternDetails,
      'patternKeywords': patternKeywords,
      'length': length,
      'silhouette': silhouette,
      'occasions': occasions,
      'locations': locations,
      'styleHints': styleHints,
      'styleDescriptors': styleDescriptors,
      'colorUndertone': colorUndertone,
      'complementaryColors': complementaryColors,
      'colorTemperature': colorTemperature,
      'designElements': designElements,
      'visualWeight': visualWeight,
      'pairingHints': pairingHints,
      'stylePersonality': stylePersonality,
      'detailLevel': detailLevel,
      'garmentKeywords': garmentKeywords,
      'rawAttributes': rawAttributes,
    };
    AppLogger.debug('📤 Serializing ClothingAnalysis: $itemType');
    return data;
  }
}

class OutfitSuggestion {
  final String id;
  final List<ClothingAnalysis> items;
  final double matchScore;
  final String style; // e.g., "casual", "business"
  final String occasion;
  final String? description;
  final List<String>? missingItems; // Items needed to complete the outfit
  final String? season;
  final List<String>? tags;

  const OutfitSuggestion({
    required this.id,
    required this.items,
    required this.matchScore,
    required this.style,
    required this.occasion,
    this.description,
    this.missingItems,
    this.season,
    this.tags,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestion(
      id: json['id'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => ClothingAnalysis.fromJson(e))
              .toList() ??
          [],
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      style: json['style'] ?? '',
      occasion: json['occasion'] ?? '',
      description: json['description'],
      missingItems: json['missingItems'] != null
          ? List<String>.from(json['missingItems'])
          : null,
      season: json['season'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'matchScore': matchScore,
      'style': style,
      'occasion': occasion,
      'description': description,
      'missingItems': missingItems,
      'season': season,
      'tags': tags,
    };
  }
}

class OnlineInspiration {
  final String id;
  final String imageUrl;
  final String source; // e.g., "Unsplash", "Pexels"
  final String? sourceUrl;
  final double confidence;
  final Map<String, dynamic>? metadata;
  final String? title;
  final String? description;
  final List<String>? tags;
  final String? photographer;
  final int? width;
  final int? height;

  const OnlineInspiration({
    required this.id,
    required this.imageUrl,
    required this.source,
    this.sourceUrl,
    required this.confidence,
    this.metadata,
    this.title,
    this.description,
    this.tags,
    this.photographer,
    this.width,
    this.height,
  });

  factory OnlineInspiration.fromJson(Map<String, dynamic> json) {
    return OnlineInspiration(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      source: json['source'] ?? '',
      sourceUrl: json['sourceUrl'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'],
      title: json['title'],
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      photographer: json['photographer'],
      width: json['width'],
      height: json['height'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'source': source,
      'sourceUrl': sourceUrl,
      'confidence': confidence,
      'metadata': metadata,
      'title': title,
      'description': description,
      'tags': tags,
      'photographer': photographer,
      'width': width,
      'height': height,
    };
  }
}

class PositionedItem {
  final String itemId;
  final double x;
  final double y;
  final double rotation;
  final double scale;
  final int zIndex;

  const PositionedItem({
    required this.itemId,
    required this.x,
    required this.y,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.zIndex = 0,
  });

  factory PositionedItem.fromJson(Map<String, dynamic> json) {
    return PositionedItem(
      itemId: json['itemId'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'x': x,
      'y': y,
      'rotation': rotation,
      'scale': scale,
      'zIndex': zIndex,
    };
  }
}

class MannequinOutfit {
  final String id;
  final List<ClothingAnalysis> items;
  final String imageUrl; // Generated mannequin image
  final String? pose; // front, side, back
  final String? style;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  const MannequinOutfit({
    required this.id,
    required this.items,
    required this.imageUrl,
    this.pose,
    this.style,
    this.confidence,
    this.metadata,
  });

  factory MannequinOutfit.fromJson(Map<String, dynamic> json) {
    return MannequinOutfit(
      id: json['id'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((e) => ClothingAnalysis.fromJson(e))
              .toList() ??
          [],
      imageUrl: json['imageUrl'] ?? '',
      pose: json['pose'],
      style: json['style'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'imageUrl': imageUrl,
      'pose': pose,
      'style': style,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}
