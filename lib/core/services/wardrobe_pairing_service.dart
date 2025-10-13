import 'dart:math';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/compatibility_cache_service.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for generating outfit pairings from wardrobe items
class WardrobePairingService {
  WardrobePairingService({
    this.analytics,
    CompatibilityCacheService? compatibilityCache,
  }) : _compatibilityCache = compatibilityCache;

  final WardrobePairingAnalytics? analytics;
  final CompatibilityCacheService? _compatibilityCache;

  static const int _maxPairingSuggestions = 6;
  static const double _minCompatibilityScore = 0.3;

  /// Pre-compute compatibility matrix for faster pairing generation
  Future<void> precomputeCompatibility(List<WardrobeItem> items) async {
    if (_compatibilityCache != null) {
      await _compatibilityCache.precomputeCompatibilityMatrix(items);
    }
  }

  /// Get compatibility score with caching
  double _getCompatibilityScore(WardrobeItem item1, WardrobeItem item2) {
    final score = _compatibilityCache != null
        ? _compatibilityCache.getCompatibilityScore(item1, item2)
        : item1.getCompatibilityScore(item2);

    // Log enhanced AI usage
    if (item1.analysis.complementaryColors != null ||
        item1.analysis.visualWeight != null ||
        item1.analysis.stylePersonality != null) {
      AppLogger.debug(
        '🎨 Enhanced AI pairing: ${item1.analysis.itemType} + ${item2.analysis.itemType} = ${(score * 100).toStringAsFixed(0)}%',
        data: {
          'color_harmony': item1.analysis.complementaryColors != null,
          'visual_balance': item1.analysis.visualWeight != null,
          'style_match': item1.analysis.stylePersonality != null,
        },
      );
    }

    return score;
  }

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
      final availableItems = wardrobeItems
          .where((item) => item.id != heroItem.id)
          .toList();
      
      if (availableItems.isEmpty) {
        AppLogger.warning(
          '⚠️ No other items available - generating styling suggestions',
        );
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
        AppLogger.warning(
          '⚠️ No pairings generated - creating fallback suggestions',
        );
        onProgress?.call('Creating styling suggestions...');
        return _generateFallbackPairings(heroItem, availableItems, mode: mode);
      }

      AppLogger.info(
        '✅ Pairing generation complete (no auto mannequins)',
        data: {'totalPairings': pairings.length, 'mode': mode.toString()},
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

    // Group items by category with smart exclusion
    // For tops: Only allow layering pieces (jackets, blazers) as additional tops
    final tops = availableItems
        .where((item) => _isTop(item) && !_isLayeringPiece(item))
        .toList();
    final layering = availableItems
        .where((item) => _isLayeringPiece(item))
        .toList();
    final bottoms = availableItems.where((item) => _isBottom(item)).toList();
    final shoes = availableItems.where((item) => _isShoes(item)).toList();
    final accessories = availableItems
        .where((item) => _isAccessory(item))
        .toList();

    final pairings = <OutfitPairing>[];

    // Track used items to ensure diversity
    final usedItemIds = <Set<String>>[];

    // Generate combinations based on hero item type with category exclusion
    if (_isDress(heroItem)) {
      // Dress + shoes + accessories + layering pieces (jackets/coats) - EXCLUDE other dresses
      for (
        int i = 0;
        i < shoes.length && pairings.length < _maxPairingSuggestions;
        i++
      ) {
        final items = [heroItem, shoes[i]];

        // Can add layering pieces over dresses, plus accessories
        if (accessories.length > i) items.add(accessories[i]);
        if (layering.length > i && i % 2 == 0) items.add(layering[i]);

        final itemIds = items.map((item) => item.id).toSet();
        if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
          usedItemIds.add(itemIds);
          pairings.add(
            _createPairing(
              items,
              i == 0
                  ? 'Polished dress look'
                  : i == 1
                  ? 'Casual dress style'
                  : 'Elegant dress ensemble',
              PairingMode.pairThisItem,
              stylingTips: _buildStylingTips(items, heroItem: heroItem),
            ),
          );
        }
      }
    } else if (_isTop(heroItem) && !_isLayeringPiece(heroItem)) {
      // Regular top + bottoms + shoes + accessories - EXCLUDE other regular tops
      // Can add layering pieces (jackets/blazers)
      for (
        int i = 0;
        i < bottoms.length && pairings.length < _maxPairingSuggestions;
        i++
      ) {
        final compatibilityScore = _getCompatibilityScore(heroItem, bottoms[i]);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, bottoms[i]];

          // Vary shoes, accessories, and layering
          if (shoes.length > i) items.add(shoes[i]);
          if (accessories.length > i && i % 2 == 0) items.add(accessories[i]);
          if (layering.length > i && i % 3 == 0) items.add(layering[i]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
            items,
                i == 0
                    ? 'Classic ${heroItem.analysis.primaryColor} combo'
                    : 'Fresh ${heroItem.analysis.primaryColor} pairing',
            PairingMode.pairThisItem,
            score: compatibilityScore,
                stylingTips: _buildStylingTips(items, heroItem: heroItem),
              ),
            );
          }
        }
      }
    } else if (_isLayeringPiece(heroItem)) {
      // Layering piece (jacket/blazer) + top + bottom + shoes - pair with tops AND bottoms
      for (
        int i = 0;
        i < tops.length && pairings.length < _maxPairingSuggestions;
        i++
      ) {
        final compatibilityScore = _getCompatibilityScore(heroItem, tops[i]);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, tops[i]];

          // Add bottoms, shoes, accessories
          if (bottoms.length > i) items.add(bottoms[i]);
          if (shoes.length > i) items.add(shoes[i]);
          if (accessories.length > i && i % 2 == 0) items.add(accessories[i]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
                items,
                i == 0 ? 'Layered sophistication' : 'Polished layering',
                PairingMode.pairThisItem,
                score: compatibilityScore,
                stylingTips: _buildStylingTips(items, heroItem: heroItem),
              ),
            );
          }
        }
      }
    } else if (_isBottom(heroItem)) {
      // Bottom + tops + shoes + accessories - EXCLUDE other bottoms
      for (
        int i = 0;
        i < tops.length && pairings.length < _maxPairingSuggestions;
        i++
      ) {
        final compatibilityScore = _getCompatibilityScore(heroItem, tops[i]);
        if (compatibilityScore >= _minCompatibilityScore) {
          final items = [heroItem, tops[i]];

          // Vary shoes, accessories, and layering
          if (shoes.length > i) items.add(shoes[i]);
          if (accessories.length > i && i % 2 == 0) items.add(accessories[i]);
          if (layering.length > i && i % 3 == 0) items.add(layering[i]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
            items,
                i == 0
                    ? 'Polished ${heroItem.analysis.primaryColor} look'
                    : 'Stylish ${heroItem.analysis.primaryColor} outfit',
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
      for (
        int i = 0;
        i < tops.length && pairings.length < _maxPairingSuggestions;
        i++
      ) {
        for (
          int j = 0;
          j < bottoms.length && pairings.length < _maxPairingSuggestions;
          j++
        ) {
          final items = [heroItem, tops[i], bottoms[j]];
          if (accessories.length > lookIndex) items.add(accessories[lookIndex]);

          final itemIds = items.map((item) => item.id).toSet();
          if (!usedItemIds.any((set) => set.containsAll(itemIds))) {
            usedItemIds.add(itemIds);
            pairings.add(
              _createPairing(
            items,
                lookIndex == 0
                    ? 'Outfit showcasing your ${heroItem.analysis.subcategory ?? 'shoes'}'
                    : 'Alternative look with your ${heroItem.analysis.primaryColor} shoes',
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

    final finalPairings = pairings.take(_maxPairingSuggestions).toList();

    // Log enhanced AI usage summary
    _logEnhancedAIUsage(finalPairings, 'Pair This Item');

    return finalPairings;
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
    final accessories = availableItems
        .where((item) => _isAccessory(item))
        .toList();
    final outerwear = availableItems
        .where((item) => _isOuterwear(item))
        .toList();

    // Build a diverse set of hero candidates (not just the first match)
    final heroCandidates = _selectHeroCandidates(heroItem, availableItems);
    final Set<String> seenCombos = <String>{};

    // Generate exactly 5 outfits with tight/loose ranking
    for (int i = 0; i < 5; i++) {
      final items = <WardrobeItem>[];
      final isTight = i < 3; // First 3 are tight, last 2 are loose

      // Rotate hero among strong candidates for variety
      final currentHero = heroCandidates[i % heroCandidates.length];
      items.add(currentHero);

      if (_isDress(currentHero)) {
        // Dress + shoes + accessories + outerwear
        if (shoes.isNotEmpty) {
          final shoe = isTight
              ? _getBestCompatibleItem(currentHero, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }

        if (accessories.isNotEmpty && (isTight ? true : random.nextBool())) {
          final accessory = isTight
              ? _getBestCompatibleItem(currentHero, accessories)
              : accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }

        if (outerwear.isNotEmpty && (!isTight || random.nextBool())) {
          final outer = isTight
              ? _getBestCompatibleItem(currentHero, outerwear)
              : outerwear[random.nextInt(outerwear.length)];
          items.add(outer);
        }
      } else if (_isTop(currentHero)) {
        // Top + bottom + shoes + accessories
        if (bottoms.isNotEmpty) {
          final bottom = isTight
              ? _getBestCompatibleItem(currentHero, bottoms)
              : bottoms[random.nextInt(bottoms.length)];
          items.add(bottom);
        }

        if (shoes.isNotEmpty) {
          final shoe = isTight
              ? _getBestCompatibleItem(currentHero, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }

        if (accessories.isNotEmpty && (isTight ? random.nextBool() : true)) {
          final accessory = accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }
      } else if (_isBottom(currentHero)) {
        // Bottom + top + shoes + accessories
        if (tops.isNotEmpty) {
          final top = isTight
              ? _getBestCompatibleItem(currentHero, tops)
              : tops[random.nextInt(tops.length)];
          items.add(top);
        }

        if (shoes.isNotEmpty) {
          final shoe = isTight
              ? _getBestCompatibleItem(currentHero, shoes)
              : shoes[random.nextInt(shoes.length)];
          items.add(shoe);
        }

        if (accessories.isNotEmpty && (isTight ? random.nextBool() : true)) {
          final accessory = accessories[random.nextInt(accessories.length)];
          items.add(accessory);
        }
      }

      // Skip duplicate sets to avoid repetition
      final key = items.map((w) => w.id).toList()..sort();
      final signature = key.join('_');
      if (seenCombos.contains(signature)) {
        continue;
      }
      seenCombos.add(signature);

      // Only create pairing if we have at least 2 items (hero + at least one other)
      if (items.length >= 2) {
        // Calculate REAL compatibility score between items
        double totalScore = 0.0;
        int comparisons = 0;
        for (int i = 0; i < items.length; i++) {
          for (int j = i + 1; j < items.length; j++) {
            totalScore += _getCompatibilityScore(items[i], items[j]);
            comparisons++;
          }
        }
        final avgScore = comparisons > 0 ? totalScore / comparisons : 0.5;

        // For tight pairings, use real score; for loose, add some variation
        final finalScore = isTight
            ? avgScore
            : (avgScore * 0.85 + random.nextDouble() * 0.15);

        pairings.add(
          _createPairing(
          items,
            isTight
                ? 'Polished ${heroItem.analysis.primaryColor} ${heroItem.analysis.itemType.toLowerCase()} look'
                : 'Creative surprise combination ${i - 2}',
          PairingMode.surpriseMe,
            score: finalScore.clamp(0.0, 1.0),
            stylingTips: _buildStylingTips(
              items,
              heroItem: heroItem,
              playful: !isTight,
            ),
          ).copyWith(
            metadata: {
              'isTight': isTight,
              'rank': i + 1,
              'stylingTips': _buildStylingTips(
                items,
                heroItem: heroItem,
                playful: !isTight,
              ),
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

    // Log enhanced AI usage summary
    _logEnhancedAIUsage(pairings, 'Surprise Me');

    return pairings;
  }

  /// Log enhanced AI feature usage in pairings
  void _logEnhancedAIUsage(List<OutfitPairing> pairings, String feature) {
    int itemsWithColorIntel = 0;
    int itemsWithVisualWeight = 0;
    int itemsWithStylePersonality = 0;
    int itemsWithPairingHints = 0;
    int itemsWithDesignElements = 0;

    for (final pairing in pairings) {
      for (final item in pairing.items) {
        if (item.analysis.complementaryColors != null) itemsWithColorIntel++;
        if (item.analysis.visualWeight != null) itemsWithVisualWeight++;
        if (item.analysis.stylePersonality != null) itemsWithStylePersonality++;
        if (item.analysis.pairingHints != null) itemsWithPairingHints++;
        if (item.analysis.designElements != null) itemsWithDesignElements++;
      }
    }

    AppLogger.info(
      '🎨 [$feature] Enhanced AI Usage Summary',
      data: {
        'total_pairings': pairings.length,
        'items_with_color_intel': itemsWithColorIntel,
        'items_with_visual_weight': itemsWithVisualWeight,
        'items_with_style_personality': itemsWithStylePersonality,
        'items_with_pairing_hints': itemsWithPairingHints,
        'items_with_design_elements': itemsWithDesignElements,
        'avg_compatibility_score': pairings.isEmpty
            ? 0.0
            : pairings
                      .map((p) => p.compatibilityScore)
                      .reduce((a, b) => a + b) /
                  pairings.length,
      },
    );
  }

  /// Get the best compatible item from a list based on compatibility score
  WardrobeItem _getBestCompatibleItem(
    WardrobeItem heroItem,
    List<WardrobeItem> candidates,
  ) {
    if (candidates.isEmpty) return heroItem;

    candidates.sort(
      (a, b) => _getCompatibilityScore(
        heroItem,
        b,
      ).compareTo(_getCompatibilityScore(heroItem, a)),
    );

    return candidates.first;
  }

  /// Pick diverse hero candidates prioritizing occasion relevance and rotation
  List<WardrobeItem> _selectHeroCandidates(
    WardrobeItem initialHero,
    List<WardrobeItem> availableItems,
  ) {
    final initialType = initialHero.analysis.itemType.toLowerCase();

    // Occasion-aligned same-type items
    List<WardrobeItem> sameTypeOccasionAligned = availableItems.where((w) {
      final typeMatch = w.analysis.itemType.toLowerCase() == initialType;
      final occasions = w.analysis.occasions ?? const <String>[];
      final initialOcc = initialHero.analysis.occasions ?? const <String>[];
      final aligned = occasions.any((o) => initialOcc.contains(o));
      return typeMatch && aligned;
    }).toList();

    if (sameTypeOccasionAligned.isEmpty) {
      sameTypeOccasionAligned = availableItems
          .where((w) => w.analysis.itemType.toLowerCase() == initialType)
          .toList();
    }

    // Add a few different-type candidates for exploration
    final differentType = availableItems
        .where((w) => w.analysis.itemType.toLowerCase() != initialType)
        .take(3)
        .toList();

    // Prefer less-worn items first
    sameTypeOccasionAligned.sort((a, b) => a.wearCount.compareTo(b.wearCount));

    final result = <WardrobeItem>{}
      ..add(initialHero)
      ..addAll(sameTypeOccasionAligned.take(4))
      ..addAll(differentType);

    return result.toList(growable: false);
  }

  /// Get a varied hero item for different outfit combinations
  WardrobeItem _getVariedHeroItem(
    WardrobeItem originalHero,
    List<WardrobeItem> availableItems,
    int index,
  ) {
    // For variety, alternate between different item types
    final sameTypeItems = availableItems.where((item) {
      return item.analysis.itemType.toLowerCase() ==
          originalHero.analysis.itemType.toLowerCase();
    }).toList();

    if (sameTypeItems.length > index && index < sameTypeItems.length) {
      return sameTypeItems[index % sameTypeItems.length];
    }

    // Fallback to original hero
    return originalHero;
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
        
        // Get current gender preference
        final profileService = getIt<ProfileService>();
        final profile = await profileService.getProfile();
        final gender = profile.preferredGender.apiValue;

        final mannequinOutfits =
            await GeminiApiService.generateEnhancedMannequinOutfits(
          analyses,
              userNotes:
                  pairing.metadata['stylingNotes'] as String? ??
                  'Create a polished wardrobe pairing showcasing these items together.',
              gender: gender,
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
          'tips': [
            'Add a bold necklace',
            'Choose heels that complement the color',
            'Keep makeup sophisticated',
          ],
        },
        {
          'description': 'Casual day outfit',
          'items': ['Sneakers', 'Denim jacket', 'Crossbody bag'],
          'tips': [
            'Layer with a light jacket',
            'Comfortable shoes for walking',
            'Add a casual bag',
          ],
        },
        {
          'description': 'Work-appropriate styling',
          'items': ['Blazer', 'Closed-toe shoes', 'Professional bag'],
          'tips': [
            'Add a structured blazer',
            'Choose conservative accessories',
            'Opt for neutral colors',
          ],
        },
      ]);
    } else if (_isTop(heroItem)) {
      suggestions.addAll([
        {
          'description': 'Smart casual combination',
          'items': ['Dark jeans', 'Loafers', 'Watch'],
          'tips': [
            'Pair with well-fitted jeans',
            'Add a classic watch',
            'Choose leather shoes',
          ],
        },
        {
          'description': 'Office-ready look',
          'items': ['Dress pants', 'Blazer', 'Oxford shoes'],
          'tips': [
            'Tuck into tailored pants',
            'Layer with a blazer',
            'Add professional footwear',
          ],
        },
        {
          'description': 'Weekend casual style',
          'items': ['Shorts', 'Sneakers', 'Baseball cap'],
          'tips': [
            'Keep it relaxed with shorts',
            'Comfortable sneakers',
            'Add a casual hat',
          ],
        },
      ]);
    } else if (_isBottom(heroItem)) {
      suggestions.addAll([
        {
          'description': 'Versatile everyday look',
          'items': ['Basic tee', 'Sneakers', 'Light jacket'],
          'tips': [
            'Pair with a simple top',
            'Add comfortable shoes',
            'Layer for weather',
          ],
        },
        {
          'description': 'Elevated casual style',
          'items': ['Blouse', 'Heels', 'Statement bag'],
          'tips': [
            'Choose a flattering top',
            'Add height with heels',
            'Carry a stylish bag',
          ],
        },
        {
          'description': 'Sporty active look',
          'items': ['Athletic top', 'Running shoes', 'Sports bag'],
          'tips': [
            'Match with activewear',
            'Choose performance shoes',
            'Add a gym bag',
          ],
        },
      ]);
    } else {
      // Generic suggestions for other items
      suggestions.addAll([
        {
          'description': 'Complete the look',
          'items': [
            'Complementary pieces',
            'Matching accessories',
            'Suitable footwear',
          ],
          'tips': [
            'Choose  DONT ',
            'Consider the occasion',
            'Balance colors and textures',
          ],
        },
        {
          'description': 'Style it your way',
          'items': ['Personal favorites', 'Seasonal pieces', 'Statement items'],
          'tips': [
            'Add your personal touch',
            'Consider the weather',
            'Mix textures and patterns',
          ],
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

  /// Check if item is a layering piece (can be worn with other tops)
  static bool _isLayeringPiece(WardrobeItem item) {
    final type = item.analysis.itemType.toLowerCase();
    final sub = item.analysis.subcategory?.toLowerCase() ?? '';
    return type.contains('jacket') ||
        type.contains('blazer') ||
        type.contains('vest') ||
        type.contains('coat') ||
        type.contains('cardigan') ||
        sub.contains('jacket') ||
        sub.contains('blazer') ||
        sub.contains('vest') ||
        sub.contains('coat') ||
        sub.contains('cardigan');
  }

  /// Build styling tips for a pairing - ACTUALLY USEFUL and contextual
  List<String> _buildStylingTips(
    List<WardrobeItem> items, {
    WardrobeItem? heroItem,
    bool playful = false,
  }) {
    final tips = <String>[];
    if (items.length < 2) return tips; // Need at least 2 items for useful tips

    final hero = heroItem ?? items.first;
    final heroColor = hero.analysis.primaryColor.toLowerCase();
    final heroSubcategory = hero.analysis.subcategory?.toLowerCase() ?? '';

    // Add AI-generated pairing hints if available
    if (hero.analysis.pairingHints != null &&
        hero.analysis.pairingHints!.isNotEmpty) {
      tips.addAll(hero.analysis.pairingHints!.take(2)); // Add top 2 AI hints
      AppLogger.debug('✨ Using AI pairing hints for ${hero.analysis.itemType}');
    }

    // Add design element tips if available
    if (hero.analysis.designElements != null &&
        hero.analysis.designElements!.isNotEmpty) {
      final elements = hero.analysis.designElements!.take(2).join(', ');
      tips.add('Features $elements - let these details shine');
      AppLogger.debug('🎨 Using AI design elements for styling tips');
    }

    // Find what items are actually in the outfit
    final top = items.firstWhere((item) => _isTop(item), orElse: () => hero);
    final bottom = items.firstWhere(
      (item) => _isBottom(item),
      orElse: () => hero,
    );
    final shoes = items.firstWhere(
      (item) => _isShoes(item),
      orElse: () => hero,
    );
    final hasAccessories = items.any((item) => _isAccessory(item));

    // Get colors and details from ACTUAL outfit items
    final topColor = top != hero
        ? top.analysis.primaryColor.toLowerCase()
        : heroColor;
    final bottomColor = bottom != hero
        ? bottom.analysis.primaryColor.toLowerCase()
        : '';
    final shoesType = shoes != hero
        ? shoes.analysis.subcategory?.toLowerCase() ?? ''
        : '';

    // ACTUAL OUTFIT-BASED TIPS - referencing the real items
    if (_isDress(hero)) {
      // Dress outfit tips
      if (shoes != hero) {
        final shoesColor = shoes.analysis.primaryColor.toLowerCase();
        if (_colorsMatchFamily(heroColor, shoesColor)) {
          tips.add(
            'Your $shoesColor shoes complement this $heroColor dress beautifully',
          );
        } else {
          tips.add(
            'The $shoesColor shoes create nice contrast with the $heroColor dress',
          );
        }
      }
      if (!hasAccessories) {
        tips.add('Consider adding a necklace or earrings to complete the look');
      }
    } else if (_isTop(hero) && bottom != hero) {
      // Top + bottom outfit
      if (bottomColor.isNotEmpty) {
        if (_colorsMatchFamily(topColor, bottomColor)) {
          tips.add(
            'Monochrome $topColor look - add a colorful accessory for pop',
          );
        } else {
          tips.add('The $topColor top pairs well with $bottomColor');
        }
      }

      // Specific fit advice
      if (heroSubcategory.contains('button') ||
          heroSubcategory.contains('shirt')) {
        tips.add('Roll sleeves to the elbow for a relaxed look');
      } else if (heroSubcategory.contains('t-shirt')) {
        tips.add('Half-tuck for a polished yet casual vibe');
      }

      // Shoes advice
      if (shoes != hero && shoesType.contains('sneaker')) {
        tips.add('Sneakers keep this casual and comfortable');
      } else if (shoes != hero && shoesType.contains('heel')) {
        tips.add('Heels dress up the outfit beautifully');
      }
    } else if (_isBottom(hero) && top != hero) {
      // Bottom outfit tips
      if (heroSubcategory.contains('jean') ||
          heroSubcategory.contains('denim')) {
        if (shoes != hero) {
          tips.add('Cuff the jeans once to show off your shoes');
        }
      }

      if (shoes != hero) {
        final shoesColor = shoes.analysis.primaryColor.toLowerCase();
        if (_colorsMatchFamily(heroColor, shoesColor)) {
          tips.add('Shoes and bottoms match - creates a sleek look');
        }
      }
    } else if (_isShoes(hero)) {
      // Shoe-focused outfit
      if (heroSubcategory.contains('sneaker')) {
        tips.add('Let the sneakers be the statement piece');
        if (bottom != hero) {
          tips.add('Roll or cuff pants to showcase the sneakers');
        }
      } else if (heroSubcategory.contains('heel')) {
        tips.add('Heels elevate any outfit instantly');
      }
    }

    // Universal polish tip
    if (!hasAccessories && tips.length < 2) {
      tips.add('Consider adding accessories to personalize the look');
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

  /// Check if two colors are in the same family or match
  bool _colorsMatchFamily(String color1, String color2) {
    // Same color
    if (color1 == color2) return true;

    // Neutral family
    final neutrals = [
      'black',
      'white',
      'gray',
      'grey',
      'beige',
      'cream',
      'ivory',
      'tan',
      'brown',
    ];
    final isColor1Neutral = neutrals.any((n) => color1.contains(n));
    final isColor2Neutral = neutrals.any((n) => color2.contains(n));
    if (isColor1Neutral && isColor2Neutral) return true;

    // Blue family
    final blues = ['blue', 'navy', 'denim', 'indigo', 'teal', 'turquoise'];
    if (blues.any((c) => color1.contains(c)) &&
        blues.any((c) => color2.contains(c))) {
      return true;
    }

    // Red family
    final reds = ['red', 'burgundy', 'maroon', 'wine', 'crimson'];
    if (reds.any((c) => color1.contains(c)) &&
        reds.any((c) => color2.contains(c))) {
      return true;
    }

    // Green family
    final greens = ['green', 'olive', 'emerald', 'forest'];
    if (greens.any((c) => color1.contains(c)) &&
        greens.any((c) => color2.contains(c))) {
      return true;
    }

    return false;
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
