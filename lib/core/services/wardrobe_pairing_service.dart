import 'dart:math';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for generating outfit pairings from wardrobe items
class WardrobePairingService {
  WardrobePairingService({this.analytics});

  final WardrobePairingAnalytics? analytics;

  static const int _maxPairingSuggestions = 6;
  static const double _minCompatibilityScore = 0.3;

  /// Generate outfit pairings for a hero item using different modes
  Future<List<OutfitPairing>> generatePairings({
    required WardrobeItem heroItem,
    required List<WardrobeItem> wardrobeItems,
    required PairingMode mode,
    String? occasion,
    String? location,
    String? weather,
    void Function(String)? onProgress,
  }) async {
    AppLogger.info(
      '👔 Generating outfit pairings',
      data: {
        'heroItem': heroItem.toString(),
        'wardrobeSize': wardrobeItems.length,
        'mode': mode.toString(),
        'occasion': occasion,
        'location': location,
        'weather': weather,
      },
    );

    onProgress?.call('Analyzing your wardrobe...');
    analytics?.trackPairingStart(
      mode: mode,
      heroItem: heroItem,
      wardrobeSize: wardrobeItems.length,
    );

    try {
      // Filter out the hero item from available items
      final availableItems =
          wardrobeItems.where((item) => item.id != heroItem.id).toList();

      if (availableItems.isEmpty) {
        AppLogger.warning('⚠️ No other items available - generating styling suggestions');
        analytics?.trackPairingEmpty(mode: mode, reason: 'no_available_items');
        onProgress?.call('Creating styling suggestions...');
        return _generateFallbackPairings(heroItem, [], mode: mode);
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

      // No automatic mannequin generation - only generate when user requests preview
      // This ensures fast initial loading and only generates expensive API calls on demand

      // If no pairings were generated, create fallback suggestions
      if (pairings.isEmpty) {
        AppLogger.warning('⚠️ No pairings generated - creating fallback suggestions');
        onProgress?.call('Creating styling suggestions...');
        return _generateFallbackPairings(heroItem, availableItems, mode: mode);
      }

      AppLogger.info(
        '✅ Pairing generation complete (no auto mannequins)',
        data: {
          'totalPairings': pairings.length,
          'mode': mode.toString(),
        },
      );
      analytics?.trackPairingSuccess(
        mode: mode,
        heroItem: heroItem,
        totalPairings: pairings.length,
        enhancedPairings: 0, // No auto-enhancement
      );

      return pairings;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Pairing generation failed',
        error: e,
        stackTrace: stackTrace,
      );
      analytics?.trackPairingFailure(mode: mode, heroItem: heroItem, error: e);

      // Return fallback pairings
      onProgress?.call('Creating fallback suggestions...');
      return _generateFallbackPairings(
        heroItem,
        wardrobeItems.where((item) => item.id != heroItem.id).toList(),
        mode: mode,
      );
    }
  }

  /// Generate perfect pairings using compatibility scoring
  Future<List<OutfitPairing>> _generatePerfectPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems,
  ) async {
    AppLogger.info('🎯 Generating perfect pairings');

    // Group items by category
    final tops = availableItems.where((item) => _isTop(item)).toList();
    final bottoms = availableItems.where((item) => _isBottom(item)).toList();
    final shoes = availableItems.where((item) => _isShoes(item)).toList();
    final accessories =
        availableItems.where((item) => _isAccessory(item)).toList();
    final outerwear =
        availableItems.where((item) => _isOuterwear(item)).toList();

    final pairings = <OutfitPairing>[];

    // Track used items to ensure diversity
    final usedItemIds = <Set<String>>[];
    
    // Generate combinations based on hero item type
    if (_isDress(heroItem)) {
      // Dress + shoes + accessories + outerwear - vary each look
      for (int i = 0; i < shoes.length && pairings.length < _maxPairingSuggestions; i++) {
        final items = [heroItem, shoes[i]];
        
        // Vary accessories and outerwear for each look
        if (accessories.length > i) items.add(accessories[i]);
        if (outerwear.length > i && i % 2 == 0) items.add(outerwear[i]);

        final itemIds = items.map((item) => item.id).toSet();
        if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
          usedItemIds.add(itemIds);
          pairings.add(
            _createPairing(
              items,
              i == 0 ? 'Polished dress look' : i == 1 ? 'Casual dress style' : 'Elegant dress ensemble',
              PairingMode.pairThisItem,
              stylingTips: _buildStylingTips(items, heroItem: heroItem),
            ),
          );
        }
      }
    } else if (_isTop(heroItem)) {
      // Top + bottom + shoes + accessories - create diverse combinations
      for (int i = 0; i < bottoms.length && pairings.length < _maxPairingSuggestions; i++) {
        final compatibilityScore = heroItem.getCompatibilityScore(bottoms[i]);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, bottoms[i]];
          
          // Vary shoes and accessories
          if (shoes.length > i) items.add(shoes[i]);
          if (accessories.length > i && i % 2 == 0) items.add(accessories[i]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
                items,
                i == 0 ? 'Classic ${heroItem.analysis.primaryColor} combo' : 'Fresh ${heroItem.analysis.primaryColor} pairing',
                PairingMode.pairThisItem,
                score: compatibilityScore,
                stylingTips: _buildStylingTips(items, heroItem: heroItem),
              ),
            );
          }
        }
      }
    } else if (_isBottom(heroItem)) {
      // Bottom + top + shoes + accessories - ensure variety
      for (int i = 0; i < tops.length && pairings.length < _maxPairingSuggestions; i++) {
        final compatibilityScore = heroItem.getCompatibilityScore(tops[i]);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, tops[i]];
          
          // Vary shoes and accessories
          if (shoes.length > i) items.add(shoes[i]);
          if (accessories.length > i && i % 2 == 0) items.add(accessories[i]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
                items,
                i == 0 ? 'Polished ${heroItem.analysis.primaryColor} look' : 'Stylish ${heroItem.analysis.primaryColor} outfit',
                PairingMode.pairThisItem,
                score: compatibilityScore,
                stylingTips: _buildStylingTips(items, heroItem: heroItem),
              ),
            );
          }
        }
      }
    } else if (_isShoes(heroItem)) {
      // Shoes + top + bottom + accessories - create distinct looks
      int lookIndex = 0;
      for (int i = 0; i < tops.length && pairings.length < _maxPairingSuggestions; i++) {
        for (int j = 0; j < bottoms.length && pairings.length < _maxPairingSuggestions; j++) {
          final items = [heroItem, tops[i], bottoms[j]];
          if (accessories.length > lookIndex) items.add(accessories[lookIndex]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
                items,
                lookIndex == 0 ? 'Outfit showcasing your ${heroItem.analysis.subcategory ?? 'shoes'}' : 'Alternative look with your ${heroItem.analysis.primaryColor} shoes',
                PairingMode.pairThisItem,
                stylingTips: _buildStylingTips(items, heroItem: heroItem),
              ),
            );
            lookIndex++;
          }
        }
      }
    }

    // Sort by compatibility score
    pairings.sort(
      (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
    );

    return pairings.take(_maxPairingSuggestions).toList();
  }

  /// Generate surprise pairings with more creative combinations
  Future<List<OutfitPairing>> _generateSurprisePairings(
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
    final accessories =
        availableItems.where((item) => _isAccessory(item)).toList();
    final outerwear =
        availableItems.where((item) => _isOuterwear(item)).toList();

    // Generate exactly 5 outfits with tight/loose ranking
    for (int i = 0; i < 5; i++) {
      final items = <WardrobeItem>[heroItem];
      final isTight = i < 3; // First 3 are tight, last 2 are loose
      
      if (_isDress(heroItem)) {
        // Dress + shoes + accessories + outerwear
        if (shoes.isNotEmpty) {
          final shoe = isTight 
              ? _getBestCompatibleItem(heroItem, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }
        
        if (accessories.isNotEmpty && (isTight ? true : random.nextBool())) {
          final accessory = isTight
              ? _getBestCompatibleItem(heroItem, accessories)
              : accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }
        
        if (outerwear.isNotEmpty && (!isTight || random.nextBool())) {
          final outer = isTight
              ? _getBestCompatibleItem(heroItem, outerwear)
              : outerwear[random.nextInt(outerwear.length)];
          items.add(outer);
        }
      } else if (_isTop(heroItem)) {
        // Top + bottom + shoes + accessories
        if (bottoms.isNotEmpty) {
          final bottom = isTight
              ? _getBestCompatibleItem(heroItem, bottoms)
              : bottoms[random.nextInt(bottoms.length)];
          items.add(bottom);
        }
        
        if (shoes.isNotEmpty) {
          final shoe = isTight
              ? _getBestCompatibleItem(heroItem, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }
        
        if (accessories.isNotEmpty && (isTight ? random.nextBool() : true)) {
          final accessory = accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }
      } else if (_isBottom(heroItem)) {
        // Bottom + top + shoes + accessories
        if (tops.isNotEmpty) {
          final top = isTight
              ? _getBestCompatibleItem(heroItem, tops)
              : tops[random.nextInt(tops.length)];
          items.add(top);
        }
        
        if (shoes.isNotEmpty) {
          final shoe = isTight
              ? _getBestCompatibleItem(heroItem, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }
        
        if (accessories.isNotEmpty && (isTight ? random.nextBool() : true)) {
          final accessory = accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }
      }

      if (items.length > 1) {
        final baseScore = isTight ? 0.8 : 0.6;
        final randomVariation = random.nextDouble() * 0.2;
        final finalScore = (baseScore + randomVariation).clamp(0.0, 1.0);
        
        pairings.add(
          _createPairing(
            items,
            isTight 
                ? 'Polished ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()} look'
                : 'Creative surprise combination ${i - 2}',
            PairingMode.surpriseMe,
            score: finalScore,
            stylingTips: _buildStylingTips(
              items,
              heroItem: heroItem,
              playful: !isTight,
            ),
          ).copyWith(
            metadata: {
              'isTight': isTight,
              'rank': i + 1,
              'stylingTips': _buildStylingTips(items, heroItem: heroItem, playful: !isTight),
            },
          ),
        );
      }
    }

    // Sort to ensure tight pairings come first
    pairings.sort((a, b) {
      final aTight = a.metadata['isTight'] as bool? ?? false;
      final bTight = b.metadata['isTight'] as bool? ?? false;
      
      if (aTight && !bTight) return -1;
      if (!aTight && bTight) return 1;
      
      // Within same category, sort by score
      return b.compatibilityScore.compareTo(a.compatibilityScore);
    });

    return pairings;
  }
  
  /// Get the best compatible item from a list based on compatibility score
  WardrobeItem _getBestCompatibleItem(WardrobeItem heroItem, List<WardrobeItem> candidates) {
    if (candidates.isEmpty) return candidates.first;
    
    candidates.sort((a, b) => 
        heroItem.getCompatibilityScore(b).compareTo(heroItem.getCompatibilityScore(a)));
    
    return candidates.first;
  }

  /// Generate location/weather-based pairings
  Future<List<OutfitPairing>> _generateLocationBasedPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems, {
    String? location,
    String? weather,
    String? occasion,
  }) async {
    AppLogger.info(
      '🌍 Generating location-based pairings',
      data: {'location': location, 'weather': weather, 'occasion': occasion},
    );

    // Filter items based on location/weather/occasion
    final suitableItems =
        availableItems.where((item) {
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
                suitable &=
                    item.matchesSeason('Summer') ||
                    item.analysis.material?.toLowerCase() == 'cotton' ||
                    item.analysis.material?.toLowerCase() == 'linen';
                break;
              case 'cold':
              case 'cool':
                suitable &=
                    item.matchesSeason('Winter') ||
                    item.analysis.material?.toLowerCase() == 'wool' ||
                    _isOuterwear(item);
                break;
              case 'rainy':
                suitable &=
                    _isOuterwear(item) ||
                    item.analysis.material?.toLowerCase() == 'polyester';
                break;
            }
          }

          return suitable;
        }).toList();

    if (suitableItems.isEmpty) {
      AppLogger.warning(
        '⚠️ No suitable items found for location/weather constraints',
      );
      return _generatePerfectPairings(heroItem, availableItems);
    }

    // Generate pairings using suitable items
    return _generatePerfectPairings(heroItem, suitableItems);
  }

  /// Enhance pairings with AI-generated mannequin images
  Future<List<OutfitPairing>> _enhancePairingsWithImages(
    List<OutfitPairing> pairings, {
    required PairingMode mode,
  }) async {
    AppLogger.info('🎨 Enhancing pairings with mannequin images');

    final enhancedPairings = <OutfitPairing>[];

    for (final pairing in pairings) {
      try {
        // Convert WardrobeItems to ClothingAnalysis for Gemini API
        final analyses = pairing.items.map((item) => item.analysis).toList();

        final mannequinOutfits =
            await GeminiApiService.generateEnhancedMannequinOutfits(
              analyses,
              userNotes:
                  pairing.metadata['stylingNotes'] as String? ??
                  'Create a polished wardrobe pairing showcasing these items together.',
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
        AppLogger.warning(
          '⚠️ Failed to generate mannequin for pairing',
          error: e,
        );
        enhancedPairings.add(pairing);
      }
    }

    return enhancedPairings;
  }

  /// Generate fallback pairings when main generation fails
  List<OutfitPairing> _generateFallbackPairings(
    WardrobeItem heroItem,
    List<WardrobeItem> availableItems, {
    required PairingMode mode,
  }) {
    AppLogger.info('🔄 Generating fallback pairings');

    final pairings = <OutfitPairing>[];
    
    // Even with no other items, suggest what would complete the outfit
    final suggestions = _getSingleItemSuggestions(heroItem);
    
    for (int i = 0; i < suggestions.length; i++) {
      pairings.add(
        OutfitPairing(
          id: 'fallback_${DateTime.now().millisecondsSinceEpoch}_$i',
          items: [heroItem], // Just the hero item for now
          description: suggestions[i]['description'] as String,
          compatibilityScore: 0.8,
          generationMode: mode,
          createdAt: DateTime.now(),
          metadata: {
            'isSuggestion': true,
            'suggestedItems': suggestions[i]['items'] as List<String>,
            'stylingTips': suggestions[i]['tips'] as List<String>,
          },
        ),
      );
    }

    // If we have some available items, create basic combinations
    if (availableItems.isNotEmpty) {
      final items = [heroItem, ...availableItems.take(3)];
      pairings.add(
        _createPairing(
          items,
          'Quick pairing with your ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()}',
          mode,
          score: 0.6,
          stylingTips: _buildStylingTips(items, heroItem: heroItem),
        ),
      );
    }

    return pairings;
  }
  
  /// Get styling suggestions for a single item
  List<Map<String, dynamic>> _getSingleItemSuggestions(WardrobeItem heroItem) {
    final suggestions = <Map<String, dynamic>>[];
    
    if (_isDress(heroItem)) {
      suggestions.addAll([
        {
          'description': 'Elegant evening look',
          'items': ['Heels', 'Statement jewelry', 'Clutch bag'],
          'tips': ['Add a bold necklace', 'Choose heels that complement the color', 'Keep makeup sophisticated'],
        },
        {
          'description': 'Casual day outfit',
          'items': ['Sneakers', 'Denim jacket', 'Crossbody bag'],
          'tips': ['Layer with a light jacket', 'Comfortable shoes for walking', 'Add a casual bag'],
        },
        {
          'description': 'Work-appropriate styling',
          'items': ['Blazer', 'Closed-toe shoes', 'Professional bag'],
          'tips': ['Add a structured blazer', 'Choose conservative accessories', 'Opt for neutral colors'],
        },
      ]);
    } else if (_isTop(heroItem)) {
      suggestions.addAll([
        {
          'description': 'Smart casual combination',
          'items': ['Dark jeans', 'Loafers', 'Watch'],
          'tips': ['Pair with well-fitted jeans', 'Add a classic watch', 'Choose leather shoes'],
        },
        {
          'description': 'Office-ready look',
          'items': ['Dress pants', 'Blazer', 'Oxford shoes'],
          'tips': ['Tuck into tailored pants', 'Layer with a blazer', 'Add professional footwear'],
        },
        {
          'description': 'Weekend casual style',
          'items': ['Shorts', 'Sneakers', 'Baseball cap'],
          'tips': ['Keep it relaxed with shorts', 'Comfortable sneakers', 'Add a casual hat'],
        },
      ]);
    } else if (_isBottom(heroItem)) {
      suggestions.addAll([
        {
          'description': 'Versatile everyday look',
          'items': ['Basic tee', 'Sneakers', 'Light jacket'],
          'tips': ['Pair with a simple top', 'Add comfortable shoes', 'Layer for weather'],
        },
        {
          'description': 'Elevated casual style',
          'items': ['Blouse', 'Heels', 'Statement bag'],
          'tips': ['Choose a flattering top', 'Add height with heels', 'Carry a stylish bag'],
        },
        {
          'description': 'Sporty active look',
          'items': ['Athletic top', 'Running shoes', 'Sports bag'],
          'tips': ['Match with activewear', 'Choose performance shoes', 'Add a gym bag'],
        },
      ]);
    } else {
      // Generic suggestions for other items
      suggestions.addAll([
        {
          'description': 'Complete the look',
          'items': ['Complementary pieces', 'Matching accessories', 'Suitable footwear'],
          'tips': ['Choose items that match the style', 'Consider the occasion', 'Balance colors and textures'],
        },
        {
          'description': 'Style it your way',
          'items': ['Personal favorites', 'Seasonal pieces', 'Statement items'],
          'tips': ['Add your personal touch', 'Consider the weather', 'Mix textures and patterns'],
        },
      ]);
    }
    
    return suggestions.take(3).toList();
  }

  /// Create an outfit pairing
  OutfitPairing _createPairing(
    List<WardrobeItem> items,
    String description,
    PairingMode mode, {
    double? score,
    List<String>? stylingTips,
  }) {
    final id =
        'pairing_${DateTime.now().millisecondsSinceEpoch}_${items.map((i) => i.id).join('_')}';

    return OutfitPairing(
      id: id,
      items: items,
      description: description,
      compatibilityScore: score ?? _calculateAverageCompatibility(items),
      generationMode: mode,
      createdAt: DateTime.now(),
      metadata: {
        if (stylingTips != null && stylingTips.isNotEmpty)
          'stylingTips': stylingTips,
        'stylingNotes': stylingTips?.join('; '),
      },
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

  /// Build styling tips for a pairing - item-specific and contextual
  List<String> _buildStylingTips(
    List<WardrobeItem> items, {
    WardrobeItem? heroItem,
    bool playful = false,
  }) {
    final tips = <String>[];
    final hero = heroItem ?? items.first;
    final heroType = hero.analysis.itemType.toLowerCase();
    final heroColor = hero.analysis.primaryColor.toLowerCase();
    final heroSubcategory = hero.analysis.subcategory?.toLowerCase() ?? '';
    
    // Analyze the complete outfit for contextual tips
    final hasTop = items.any((item) => _isTop(item));
    final hasBottom = items.any((item) => _isBottom(item));
    final hasShoes = items.any((item) => _isShoes(item));
    final hasAccessories = items.any((item) => _isAccessory(item));
    
    // Item-specific styling tips based on actual item type
    if (_isTop(hero)) {
      if (heroSubcategory.contains('button') || heroSubcategory.contains('shirt')) {
        tips.add('Roll sleeves to the elbow for a relaxed, confident look');
        tips.add('Try half-tucking into your ${hasBottom ? items.firstWhere((item) => _isBottom(item)).analysis.subcategory?.toLowerCase() ?? "bottoms" : "bottoms"} for casual elegance');
      } else if (heroSubcategory.contains('t-shirt') || heroSubcategory.contains('tee')) {
        tips.add('Layer with an open shirt or jacket for dimension');
        tips.add('Tuck fully for a polished look, or leave untucked for casual vibes');
      } else if (heroSubcategory.contains('sweater') || heroSubcategory.contains('knit')) {
        tips.add('Layer over a collared shirt for preppy sophistication');
        tips.add('Push sleeves up slightly to show watch or bracelets');
      } else if (heroSubcategory.contains('blouse')) {
        tips.add('French tuck for effortless chic');
        tips.add('Add a statement necklace to draw attention upward');
      }
    } else if (_isBottom(hero)) {
      if (heroSubcategory.contains('jeans') || heroSubcategory.contains('denim')) {
        tips.add('Cuff the hem once to show off your ${hasShoes ? items.firstWhere((item) => _isShoes(item)).analysis.subcategory?.toLowerCase() ?? "shoes" : "shoes"}');
        tips.add('Balance loose jeans with a fitted top, or vice versa');
      } else if (heroSubcategory.contains('trousers') || heroSubcategory.contains('pants')) {
        tips.add('Ensure a clean break at the shoe for polished proportions');
        tips.add('Add a belt that complements your ${hasShoes ? "shoes" : "overall look"}');
      } else if (heroSubcategory.contains('skirt')) {
        tips.add('Balance skirt length with top fit - short skirt = modest top');
        tips.add('Add tights or bare legs depending on formality');
      } else if (heroSubcategory.contains('shorts')) {
        tips.add('Keep proportions balanced - fitted shorts with relaxed top');
        tips.add('Roll the hem for a casual, summery vibe');
      }
    } else if (_isDress(hero)) {
      tips.add('Cinch with a belt at the natural waist for definition');
      tips.add('Layer with a denim jacket or blazer for versatility');
      if (heroSubcategory.contains('maxi')) {
        tips.add('Add heels to elongate your silhouette');
      } else if (heroSubcategory.contains('mini')) {
        tips.add('Balance with a modest top layer or accessories');
      }
    } else if (_isShoes(hero)) {
      if (heroSubcategory.contains('sneaker')) {
        tips.add('Keep the rest of the outfit streamlined to let sneakers pop');
        tips.add('Roll or cuff pants to showcase the sneaker design');
      } else if (heroSubcategory.contains('boot')) {
        tips.add('Tuck pants into boots or let them stack naturally');
        tips.add('Match boot formality to outfit - dress boots with tailored pieces');
      } else if (heroSubcategory.contains('heel')) {
        tips.add('Ensure hem length works with heel height');
        tips.add('Keep accessories minimal to let heels be the statement');
      }
    }
    
    // Color harmony tips based on actual colors in outfit
    if (heroColor.contains('black')) {
      if (items.any((item) => item.analysis.primaryColor.toLowerCase().contains('white'))) {
        tips.add('Classic black & white - add a third color for visual interest');
      } else {
        tips.add('Black anchors bold colors beautifully');
      }
    } else if (heroColor.contains('white') || heroColor.contains('cream')) {
      tips.add('White brightens any palette - add texture to avoid flatness');
    } else if (heroColor.contains('blue')) {
      tips.add('Blue pairs well with neutrals and earth tones');
    } else if (heroColor.contains('red')) {
      tips.add('Red makes a statement - keep other pieces neutral');
    }
    
    // Formality-specific tips
    if (hero.analysis.formality?.toLowerCase() == 'formal') {
      tips.add('Maintain clean lines and tailored fit throughout');
      if (!hasAccessories) {
        tips.add('Add a watch or subtle jewelry for polish');
      }
    } else if (hero.analysis.formality?.toLowerCase() == 'casual') {
      tips.add('Mix textures (denim, cotton, knit) for depth');
      tips.add('Don\'t be afraid to roll, cuff, or layer casually');
    }
    
    // Playful tips for Surprise Me mode
    if (playful) {
      final playfulTips = [
        'Break the rules - try unexpected combinations',
        'Mix high and low - dress shoes with casual pieces',
        'Add a bold accessory as your signature piece',
        'Layer different patterns for creative flair',
        'Play with proportions - oversized with fitted',
      ];
      tips.add(playfulTips[Random().nextInt(playfulTips.length)]);
    }
    
    // Seasonal contextual tips
    final now = DateTime.now();
    final season = _getCurrentSeason(now);
    switch (season) {
      case 'Summer':
        tips.add('Light, breathable fabrics keep you comfortable');
        break;
      case 'Winter':
        tips.add('Layer strategically - base, mid, outer');
        break;
      case 'Spring':
        tips.add('Perfect for transitional layering pieces');
        break;
      case 'Fall':
        tips.add('Rich, warm tones complement the season');
        break;
    }
    
    // Return top 3-4 most relevant tips
    return tips.take(4).toList();
  }
  
  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }
}

/// Analytics callbacks for pairing flows
abstract class WardrobePairingAnalytics {
  void trackPairingStart({
    required PairingMode mode,
    required WardrobeItem heroItem,
    required int wardrobeSize,
  });

  void trackPairingSuccess({
    required PairingMode mode,
    required WardrobeItem heroItem,
    required int totalPairings,
    required int enhancedPairings,
  });

  void trackPairingFailure({
    required PairingMode mode,
    required WardrobeItem heroItem,
    required Object error,
  });

  void trackPairingEmpty({required PairingMode mode, required String reason});
}

/// Pairing generation modes
enum PairingMode { pairThisItem, surpriseMe, styleByLocation }

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
