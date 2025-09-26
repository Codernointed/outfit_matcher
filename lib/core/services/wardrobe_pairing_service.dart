import 'dart:math';
import 'package:outfit_matcher/core/models/wardrobe_item.dart';
import 'package:outfit_matcher/core/utils/gemini_api_service_new.dart';
import 'package:outfit_matcher/core/utils/logger.dart';

/// Service for generating outfit pairings from wardrobe items
class WardrobePairingService {
  static const int _maxPairingSuggestions = 6;
  static const double _minCompatibilityScore = 0.3;

  /// Generate outfit pairings for a hero item using different modes
  static Future<List<OutfitPairing>> generatePairings({
    required WardrobeItem heroItem,
    required List<WardrobeItem> wardrobeItems,
    required PairingMode mode,
    String? occasion,
    String? location,
    String? weather,
    void Function(String)? onProgress,
  }) async {
    AppLogger.info('👔 Generating outfit pairings', data: {
      'heroItem': heroItem.toString(),
      'wardrobeSize': wardrobeItems.length,
      'mode': mode.toString(),
      'occasion': occasion,
      'location': location,
      'weather': weather,
    });

    onProgress?.call('Analyzing your wardrobe...');

    try {
      // Filter out the hero item from available items
      final availableItems = wardrobeItems.where((item) => item.id != heroItem.id).toList();
      
      if (availableItems.isEmpty) {
        AppLogger.warning('⚠️ No other items available for pairing');
        return [];
      }

      onProgress?.call('Finding perfect matches...');

      // Generate combinations based on mode
      List<OutfitPairing> pairings;
      switch (mode) {
        case PairingMode.pairThisItem:
          pairings = await _generatePerfectPairings(heroItem, availableItems);
          break;
        case PairingMode.surpriseMe:
          pairings = await _generateSurprisePairings(heroItem, availableItems);
          break;
        case PairingMode.styleByLocation:
          pairings = await _generateLocationBasedPairings(
            heroItem,
            availableItems,
            location: location,
            weather: weather,
            occasion: occasion,
          );
          break;
      }

      onProgress?.call('Creating visual previews...');

      // Enhance top pairings with mannequin images
      final enhancedPairings = await _enhancePairingsWithImages(pairings.take(3).toList());

      // Combine enhanced and regular pairings
      final finalPairings = [
        ...enhancedPairings,
        ...pairings.skip(3).take(_maxPairingSuggestions - enhancedPairings.length),
      ];

      AppLogger.info('✅ Pairing generation complete', data: {
        'totalPairings': finalPairings.length,
        'enhancedPairings': enhancedPairings.length,
        'mode': mode.toString(),
      });

      return finalPairings;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Pairing generation failed', error: e, stackTrace: stackTrace);
      
      // Return fallback pairings
      onProgress?.call('Creating fallback suggestions...');
      return _generateFallbackPairings(heroItem, wardrobeItems.where((item) => item.id != heroItem.id).toList());
    }
  }

  /// Generate perfect pairings using compatibility scoring
  static Future<List<OutfitPairing>> _generatePerfectPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems,
  ) async {
    AppLogger.info('🎯 Generating perfect pairings');

    // Group items by category
    final tops = availableItems.where((item) => _isTop(item)).toList();
    final bottoms = availableItems.where((item) => _isBottom(item)).toList();
    final shoes = availableItems.where((item) => _isShoes(item)).toList();
    final accessories = availableItems.where((item) => _isAccessory(item)).toList();
    final outerwear = availableItems.where((item) => _isOuterwear(item)).toList();

    final pairings = <OutfitPairing>[];

    // Generate combinations based on hero item type
    if (_isDress(heroItem)) {
      // Dress + shoes + accessories + outerwear
      for (final shoe in shoes.take(3)) {
        final items = [heroItem, shoe];
        if (accessories.isNotEmpty) items.add(accessories.first);
        if (outerwear.isNotEmpty) items.add(outerwear.first);
        
        pairings.add(_createPairing(items, 'Elegant dress ensemble', PairingMode.pairThisItem));
      }
    } else if (_isTop(heroItem)) {
      // Top + bottom + shoes + accessories
      for (final bottom in bottoms.take(2)) {
        final compatibilityScore = heroItem.getCompatibilityScore(bottom);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, bottom];
          if (shoes.isNotEmpty) items.add(shoes.first);
          if (accessories.isNotEmpty) items.add(accessories.first);
          
          pairings.add(_createPairing(
            items,
            'Perfect ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()} pairing',
            PairingMode.pairThisItem,
            score: compatibilityScore,
          ));
        }
      }
    } else if (_isBottom(heroItem)) {
      // Bottom + top + shoes + accessories
      for (final top in tops.take(2)) {
        final compatibilityScore = heroItem.getCompatibilityScore(top);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, top];
          if (shoes.isNotEmpty) items.add(shoes.first);
          if (accessories.isNotEmpty) items.add(accessories.first);
          
          pairings.add(_createPairing(
            items,
            'Stylish ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()} look',
            PairingMode.pairThisItem,
            score: compatibilityScore,
          ));
        }
      }
    } else if (_isShoes(heroItem)) {
      // Shoes + top + bottom + accessories
      for (final top in tops.take(2)) {
        for (final bottom in bottoms.take(1)) {
          final items = [heroItem, top, bottom];
          if (accessories.isNotEmpty) items.add(accessories.first);
          
          pairings.add(_createPairing(
            items,
            'Outfit showcasing your ${heroItem.analysis.primaryColor} ${heroItem.analysis.subcategory ?? 'shoes'}',
            PairingMode.pairThisItem,
          ));
        }
      }
    }

    // Sort by compatibility score
    pairings.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    
    return pairings.take(_maxPairingSuggestions).toList();
  }

  /// Generate surprise pairings with more creative combinations
  static Future<List<OutfitPairing>> _generateSurprisePairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems,
  ) async {
    AppLogger.info('🎲 Generating surprise pairings');

    final pairings = <OutfitPairing>[];
    final random = Random();

    // Group items
    final tops = availableItems.where((item) => _isTop(item)).toList();
    final bottoms = availableItems.where((item) => _isBottom(item)).toList();
    final shoes = availableItems.where((item) => _isShoes(item)).toList();
    final accessories = availableItems.where((item) => _isAccessory(item)).toList();
    final outerwear = availableItems.where((item) => _isOuterwear(item)).toList();

    // Generate more adventurous combinations
    for (int i = 0; i < _maxPairingSuggestions; i++) {
      final items = <WardrobeItem>[heroItem];
      
      if (_isDress(heroItem)) {
        // Dress + unexpected accessories/outerwear
        if (shoes.isNotEmpty) items.add(shoes[random.nextInt(shoes.length)]);
        if (accessories.isNotEmpty && random.nextBool()) {
          items.add(accessories[random.nextInt(accessories.length)]);
        }
        if (outerwear.isNotEmpty && random.nextBool()) {
          items.add(outerwear[random.nextInt(outerwear.length)]);
        }
      } else if (_isTop(heroItem)) {
        // Top + random bottom + accessories
        if (bottoms.isNotEmpty) items.add(bottoms[random.nextInt(bottoms.length)]);
        if (shoes.isNotEmpty) items.add(shoes[random.nextInt(shoes.length)]);
        if (accessories.isNotEmpty && random.nextBool()) {
          items.add(accessories[random.nextInt(accessories.length)]);
        }
      } else if (_isBottom(heroItem)) {
        // Bottom + random top + accessories
        if (tops.isNotEmpty) items.add(tops[random.nextInt(tops.length)]);
        if (shoes.isNotEmpty) items.add(shoes[random.nextInt(shoes.length)]);
        if (accessories.isNotEmpty && random.nextBool()) {
          items.add(accessories[random.nextInt(accessories.length)]);
        }
      }

      if (items.length > 1) {
        pairings.add(_createPairing(
          items,
          'Surprise combination ${i + 1}',
          PairingMode.surpriseMe,
          score: 0.7 + (random.nextDouble() * 0.3), // Random score between 0.7-1.0
        ));
      }
    }

    return pairings;
  }

  /// Generate location/weather-based pairings
  static Future<List<OutfitPairing>> _generateLocationBasedPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems, {
    String? location,
    String? weather,
    String? occasion,
  }) async {
    AppLogger.info('🌍 Generating location-based pairings', data: {
      'location': location,
      'weather': weather,
      'occasion': occasion,
    });

    // Filter items based on location/weather/occasion
    final suitableItems = availableItems.where((item) {
      bool suitable = true;
      
      if (location != null) {
        suitable &= item.matchesLocation(location);
      }
      
      if (occasion != null) {
        suitable &= item.matchesOccasion(occasion);
      }
      
      // Weather-based filtering
      if (weather != null) {
        switch (weather.toLowerCase()) {
          case 'hot':
          case 'warm':
            suitable &= item.matchesSeason('Summer') || 
                       item.analysis.material?.toLowerCase() == 'cotton' ||
                       item.analysis.material?.toLowerCase() == 'linen';
            break;
          case 'cold':
          case 'cool':
            suitable &= item.matchesSeason('Winter') || 
                       item.analysis.material?.toLowerCase() == 'wool' ||
                       _isOuterwear(item);
            break;
          case 'rainy':
            suitable &= _isOuterwear(item) || item.analysis.material?.toLowerCase() == 'polyester';
            break;
        }
      }
      
      return suitable;
    }).toList();

    if (suitableItems.isEmpty) {
      AppLogger.warning('⚠️ No suitable items found for location/weather constraints');
      return _generatePerfectPairings(heroItem, availableItems);
    }

    // Generate pairings using suitable items
    return _generatePerfectPairings(heroItem, suitableItems);
  }

  /// Enhance pairings with AI-generated mannequin images
  static Future<List<OutfitPairing>> _enhancePairingsWithImages(
    List<OutfitPairing> pairings,
  ) async {
    AppLogger.info('🎨 Enhancing pairings with mannequin images');

    final enhancedPairings = <OutfitPairing>[];

    for (final pairing in pairings) {
      try {
        // Convert WardrobeItems to ClothingAnalysis for Gemini API
        final analyses = pairing.items.map((item) => item.analysis).toList();
        
        final mannequinOutfits = await GeminiApiService.generateEnhancedMannequinOutfits(
          analyses,
          userNotes: 'Create a polished wardrobe pairing showcasing these items together.',
        );

        if (mannequinOutfits.isNotEmpty) {
          final enhanced = pairing.copyWith(
            mannequinImageUrl: mannequinOutfits.first.imageUrl,
          );
          enhancedPairings.add(enhanced);
        } else {
          enhancedPairings.add(pairing);
        }
      } catch (e) {
        AppLogger.warning('⚠️ Failed to generate mannequin for pairing', error: e);
        enhancedPairings.add(pairing);
      }
    }

    return enhancedPairings;
  }

  /// Generate fallback pairings when main generation fails
  static List<OutfitPairing> _generateFallbackPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems,
  ) {
    AppLogger.info('🔄 Generating fallback pairings');

    if (availableItems.isEmpty) return [];

    final pairings = <OutfitPairing>[];
    
    // Simple fallback: pair with first compatible item of each category
    final tops = availableItems.where((item) => _isTop(item)).take(1);
    final bottoms = availableItems.where((item) => _isBottom(item)).take(1);
    final shoes = availableItems.where((item) => _isShoes(item)).take(1);
    
    final items = [heroItem, ...tops, ...bottoms, ...shoes].take(4).toList();
    
    if (items.length > 1) {
      pairings.add(_createPairing(
        items,
        'Quick pairing with your ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()}',
        PairingMode.pairThisItem,
        score: 0.6,
      ));
    }

    return pairings;
  }

  /// Create an outfit pairing
  static OutfitPairing _createPairing(
    List<WardrobeItem> items,
    String description,
    PairingMode mode, {
    double? score,
  }) {
    final id = 'pairing_${DateTime.now().millisecondsSinceEpoch}_${items.map((i) => i.id).join('_')}';
    
    return OutfitPairing(
      id: id,
      items: items,
      description: description,
      compatibilityScore: score ?? _calculateAverageCompatibility(items),
      generationMode: mode,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate average compatibility score for a group of items
  static double _calculateAverageCompatibility(List<WardrobeItem> items) {
    if (items.length < 2) return 1.0;
    
    double totalScore = 0.0;
    int comparisons = 0;
    
    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        totalScore += items[i].getCompatibilityScore(items[j]);
        comparisons++;
      }
    }
    
    return comparisons > 0 ? totalScore / comparisons : 0.5;
  }

  // Category detection helpers
  static bool _isDress(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('dress');
  
  static bool _isTop(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('top') ||
      item.analysis.itemType.toLowerCase().contains('shirt') ||
      item.analysis.itemType.toLowerCase().contains('blouse');
  
  static bool _isBottom(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('bottom') ||
      item.analysis.itemType.toLowerCase().contains('pants') ||
      item.analysis.itemType.toLowerCase().contains('jeans') ||
      item.analysis.itemType.toLowerCase().contains('skirt');
  
  static bool _isShoes(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('shoe') ||
      item.analysis.itemType.toLowerCase().contains('footwear') ||
      item.analysis.itemType.toLowerCase().contains('boot') ||
      item.analysis.itemType.toLowerCase().contains('sneaker');
  
  static bool _isAccessory(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('accessory') ||
      item.analysis.itemType.toLowerCase().contains('jewelry') ||
      item.analysis.itemType.toLowerCase().contains('belt') ||
      item.analysis.itemType.toLowerCase().contains('bag');
  
  static bool _isOuterwear(WardrobeItem item) => 
      item.analysis.itemType.toLowerCase().contains('outer') ||
      item.analysis.itemType.toLowerCase().contains('jacket') ||
      item.analysis.itemType.toLowerCase().contains('coat') ||
      item.analysis.itemType.toLowerCase().contains('blazer');
}

/// Pairing generation modes
enum PairingMode {
  pairThisItem,
  surpriseMe,
  styleByLocation,
}

/// Represents an outfit pairing suggestion
class OutfitPairing {
  final String id;
  final List<WardrobeItem> items;
  final String description;
  final double compatibilityScore;
  final PairingMode generationMode;
  final String? mannequinImageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const OutfitPairing({
    required this.id,
    required this.items,
    required this.description,
    required this.compatibilityScore,
    required this.generationMode,
    this.mannequinImageUrl,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Get hero item (first item in the pairing)
  WardrobeItem get heroItem => items.first;

  /// Get supporting items (all except the first)
  List<WardrobeItem> get supportingItems => items.skip(1).toList();

  /// Convert to WardrobeLook for saving
  WardrobeLook toWardrobeLook({String? title}) {
    return WardrobeLook(
      id: id,
      title: title ?? description,
      itemIds: items.map((item) => item.id).toList(),
      imageUrl: mannequinImageUrl,
      generationMode: generationMode.toString(),
      metadata: {
        'compatibilityScore': compatibilityScore,
        'description': description,
        ...metadata,
      },
      createdAt: createdAt,
    );
  }

  OutfitPairing copyWith({
    String? id,
    List<WardrobeItem>? items,
    String? description,
    double? compatibilityScore,
    PairingMode? generationMode,
    String? mannequinImageUrl,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return OutfitPairing(
      id: id ?? this.id,
      items: items ?? this.items,
      description: description ?? this.description,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      generationMode: generationMode ?? this.generationMode,
      mannequinImageUrl: mannequinImageUrl ?? this.mannequinImageUrl,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'OutfitPairing(id: $id, items: ${items.length}, score: $compatibilityScore)';
  }
}
