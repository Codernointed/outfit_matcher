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
  
  // Fit information
  final String? length; // short, medium, long
  final String? silhouette; // fitted, loose, A-line, etc.

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
    this.length,
    this.silhouette,
  });

  @override
  String toString() {
    return 'ClothingAnalysis('
        'id: $id, '
        'itemType: $itemType, '
        'primaryColor: $primaryColor, '
        'patternType: $patternType, '
        'style: $style, '
        'seasons: $seasons, '
        'confidence: $confidence)';
  }

  factory ClothingAnalysis.fromJson(Map<String, dynamic> json) {
    print('📦 Creating ClothingAnalysis from JSON: ${json.keys.join(', ')}');
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
    );
    print('✅ ClothingAnalysis created: ${analysis.itemType} (${analysis.primaryColor})');
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
      'length': length,
      'silhouette': silhouette,
    };
    print('📤 Serializing ClothingAnalysis: $itemType');
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
      items: (json['items'] as List?)?.map((e) => ClothingAnalysis.fromJson(e)).toList() ?? [],
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      style: json['style'] ?? '',
      occasion: json['occasion'] ?? '',
      description: json['description'],
      missingItems: json['missingItems'] != null ? List<String>.from(json['missingItems']) : null,
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
      items: (json['items'] as List?)?.map((e) => ClothingAnalysis.fromJson(e)).toList() ?? [],
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
