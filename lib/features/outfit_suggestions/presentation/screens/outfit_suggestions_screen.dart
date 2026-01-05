import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/features/wardrobe/domain/entities/clothing_item.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Screen for showing outfit suggestions based on a clothing item
class OutfitSuggestionsScreen extends StatefulWidget {
  /// The clothing item to generate suggestions for
  final ClothingItem item;

  /// Default constructor
  const OutfitSuggestionsScreen({required this.item, super.key});

  @override
  State<OutfitSuggestionsScreen> createState() =>
      _OutfitSuggestionsScreenState();
}

class _OutfitSuggestionsScreenState extends State<OutfitSuggestionsScreen> {
  /// Current outfit index
  int _currentOutfit = 0;

  /// Dummy outfit data
  late final List<Map<String, dynamic>> _outfits;

  /// Favorite status for each outfit
  final Set<int> _favoriteOutfits = {};

  /// Storage service for saving outfits
  late final OutfitStorageService _outfitStorage;

  @override
  void initState() {
    super.initState();
    _outfitStorage = getIt<OutfitStorageService>();
    // Generate dummy outfits based on the item
    _outfits = _generateOutfits();
    AppLogger.info('🎨 [OUTFIT SUGGESTIONS] Screen initialized');
    AppLogger.info('   Hero item: ${widget.item.color} ${widget.item.type}');
    AppLogger.info('   Generated ${_outfits.length} outfit suggestions');
  }

  @override
  Widget build(BuildContext context) {
    final currentOutfit = _outfits[_currentOutfit];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Suggestions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCurrentOutfitFavorite()
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _isCurrentOutfitFavorite() ? Colors.red : null,
            ),
            onPressed: _toggleCurrentOutfitFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outfit title
            Text(
              currentOutfit['name'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.smallSpacing),

            // Subtitle with item reference
            Text(
              'Based on your ${_capitalizeEnum(widget.item.color.toString().split('.').last)} ${_capitalizeEnum(widget.item.type.toString().split('.').last)}, we\'ve created these outfit combinations for you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.largeSpacing),

            // Outfit items grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: AppConstants.smallSpacing,
                crossAxisSpacing: AppConstants.smallSpacing,
                children: [
                  for (final item in currentOutfit['items'])
                    _buildItemCard(item['name'], item['color']),
                ],
              ),
            ),

            // Navigation between outfits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentOutfit > 0
                      ? () {
                          AppLogger.info(
                            '👈 [OUTFIT SUGGESTIONS] Navigating to previous outfit',
                          );
                          AppLogger.info(
                            '   From: $_currentOutfit to ${_currentOutfit - 1}',
                          );
                          setState(() {
                            _currentOutfit--;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultSpacing,
                    ),
                  ),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentOutfit < _outfits.length - 1
                      ? () {
                          AppLogger.info(
                            '👉 [OUTFIT SUGGESTIONS] Navigating to next outfit',
                          );
                          AppLogger.info(
                            '   From: $_currentOutfit to ${_currentOutfit + 1}',
                          );
                          setState(() {
                            _currentOutfit++;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultSpacing,
                    ),
                  ),
                  child: const Text('Next Outfit'),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultSpacing),

            // Why this works explanation
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why This Works',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallSpacing),
                    Text(
                      currentOutfit['explanation'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a card for a clothing item
  Widget _buildItemCard(String name, Color color) {
    return Stack(
      children: [
        Column(
          children: [
            // Item image/color
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    AppConstants.smallBorderRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Item name
            Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),

        // Favorite button overlay for each item
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggleItemFavorite(name),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  _isItemFavorite(name)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 12,
                  color: _isItemFavorite(name) ? Colors.red : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Generate dummy outfits based on the item
  List<Map<String, dynamic>> _generateOutfits() {
    // For demo purposes, create some dummy outfits
    final outfits = <Map<String, dynamic>>[];

    // Outfit 1: Casual Day Out
    outfits.add({
      'name': 'Casual Day Out',
      'items': [
        {
          'name': widget.item.type == ClothingType.top
              ? '${widget.item.color} Relaxed Tee'
              : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'Black Denim Jeans', 'color': Colors.black87},
        {'name': 'White Canvas Sneakers', 'color': Colors.white},
      ],
      'explanation':
          'This outfit combines complementary colors that work well together. The ${_getItemDescription(widget.item)} pairs perfectly with black denim, creating a balanced look that\'s suitable for casual day out occasions.',
    });

    // Outfit 2: Weekend Brunch
    outfits.add({
      'name': 'Weekend Brunch',
      'items': [
        {
          'name': widget.item.type == ClothingType.top
              ? '${widget.item.color} Flowy Blouse'
              : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'Beige Wide-Leg Pants', 'color': const Color(0xFFE3D0B9)},
        {'name': 'Brown Leather Loafers', 'color': Colors.brown},
      ],
      'explanation':
          'This color palette creates a warm, inviting look perfect for weekend brunches. The ${_getItemDescription(widget.item)} brings a nice pop of color to the neutral tones of the other pieces.',
    });

    // Outfit 3: Shopping Day
    outfits.add({
      'name': 'Shopping Day',
      'items': [
        {
          'name': widget.item.type == ClothingType.top
              ? '${widget.item.color} Comfortable Sweatshirt'
              : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'White High-Waist Jeans', 'color': Colors.white},
        {'name': 'Gray Running Sneakers', 'color': Colors.grey[300]!},
      ],
      'explanation':
          'A fresh, light combination that\'s comfortable for a day of shopping. The ${_getItemDescription(widget.item)} works beautifully with white to create a clean, crisp look that\'s easy to accessorize.',
    });

    return outfits;
  }

  /// Get a description of the item based on color and type
  String _getItemDescription(ClothingItem item) {
    return '${_capitalizeEnum(item.color.toString().split('.').last)} ${_capitalizeEnum(item.type.toString().split('.').last.toLowerCase())}';
  }

  /// Capitalize the first letter of a string
  String _capitalizeEnum(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Check if current outfit is favorited
  bool _isCurrentOutfitFavorite() {
    return _favoriteOutfits.contains(_currentOutfit);
  }

  /// Check if specific item is favorited
  bool _isItemFavorite(String itemName) {
    // For demo purposes, we'll track favorites by item name
    // In a real app, you'd use unique IDs
    return _favoriteOutfits.contains(itemName.hashCode);
  }

  /// Toggle favorite status for current outfit
  Future<void> _toggleCurrentOutfitFavorite() async {
    final outfit = _outfits[_currentOutfit];
    final isCurrentlyFavorite = _isCurrentOutfitFavorite();

    AppLogger.info('⭐ [OUTFIT SUGGESTIONS] Toggling outfit favorite');
    AppLogger.info('   Outfit: "${outfit['name']}"');
    AppLogger.info('   Currently favorite: $isCurrentlyFavorite');

    if (isCurrentlyFavorite) {
      // Remove from favorites
      setState(() {
        _favoriteOutfits.remove(_currentOutfit);
      });
      AppLogger.info('💔 Removed outfit from favorites');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${outfit['name']}" from favorites'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Add to favorites and save to storage
      setState(() {
        _favoriteOutfits.add(_currentOutfit);
      });

      await _saveOutfitToStorage(outfit);

      AppLogger.info('❤️ Added outfit to favorites and saved');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${outfit['name']}" to your looks! ✨'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Toggle favorite status for specific item
  void _toggleItemFavorite(String itemName) {
    final isCurrentlyFavorite = _isItemFavorite(itemName);

    AppLogger.info('⭐ [OUTFIT SUGGESTIONS] Toggling item favorite');
    AppLogger.info('   Item: "$itemName"');
    AppLogger.info('   Currently favorite: $isCurrentlyFavorite');

    setState(() {
      if (isCurrentlyFavorite) {
        _favoriteOutfits.remove(itemName.hashCode);
        AppLogger.info('💔 Removed item from favorites');
      } else {
        _favoriteOutfits.add(itemName.hashCode);
        AppLogger.info('❤️ Added item to favorites');
      }
    });
  }

  /// Save outfit to storage service
  Future<void> _saveOutfitToStorage(Map<String, dynamic> outfitData) async {
    try {
      AppLogger.info('💾 [OUTFIT SUGGESTIONS] Saving outfit to storage...');

      // Convert outfit data to SavedOutfit
      final savedOutfit = SavedOutfit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: outfitData['name'],
        items: _convertOutfitToClothingAnalyses(outfitData),
        mannequinImages: [], // No mannequin for dummy outfits
        createdAt: DateTime.now(),
        notes: outfitData['explanation'] ?? '',
        matchScore: 0.85, // Default high score for suggestions
      );

      await _outfitStorage.save(savedOutfit);

      AppLogger.info('✅ [OUTFIT SUGGESTIONS] Outfit saved successfully!');
      AppLogger.info('   Outfit ID: ${savedOutfit.id}');
      AppLogger.info('   Title: "${savedOutfit.title}"');
      AppLogger.info('   Items: ${savedOutfit.items.length}');
    } catch (e) {
      AppLogger.error('❌ [OUTFIT SUGGESTIONS] Failed to save outfit', error: e);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save outfit. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Convert outfit data to ClothingAnalysis objects
  List<ClothingAnalysis> _convertOutfitToClothingAnalyses(
    Map<String, dynamic> outfitData,
  ) {
    final items = <ClothingAnalysis>[];

    for (final itemData in outfitData['items']) {
      final item = ClothingAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString() + itemData['name'],
        itemType: _getItemTypeFromName(itemData['name']),
        primaryColor: _getColorNameFromColor(itemData['color']),
        patternType: 'solid',
        style: _getStyleFromOutfitName(outfitData['name']),
        seasons: ['spring', 'summer', 'fall', 'winter'],
        confidence: 0.9,
        tags: ['suggested', 'outfit'],
      );
      items.add(item);
    }

    return items;
  }

  /// Get item type from item name
  String _getItemTypeFromName(String name) {
    if (name.toLowerCase().contains('top') ||
        name.toLowerCase().contains('shirt')) {
      return 'Top';
    } else if (name.toLowerCase().contains('bottom') ||
        name.toLowerCase().contains('pant') ||
        name.toLowerCase().contains('jean')) {
      return 'Bottom';
    } else if (name.toLowerCase().contains('shoe') ||
        name.toLowerCase().contains('sneaker')) {
      return 'Shoes';
    } else {
      return 'Accessory';
    }
  }

  /// Get color name from Color object
  String _getColorNameFromColor(Color color) {
    if (color == Colors.blue[200]) return 'blue';
    if (color == Colors.black87) return 'black';
    if (color == Colors.white) return 'white';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.grey[300]) return 'grey';
    if (color.toARGB32() == const Color(0xFFE3D0B9).toARGB32()) return 'beige';
    return 'unknown';
  }

  /// Get style from outfit name
  String _getStyleFromOutfitName(String outfitName) {
    if (outfitName.toLowerCase().contains('casual')) return 'casual';
    if (outfitName.toLowerCase().contains('brunch')) return 'smart casual';
    if (outfitName.toLowerCase().contains('shopping')) return 'casual';
    return 'casual';
  }
}
