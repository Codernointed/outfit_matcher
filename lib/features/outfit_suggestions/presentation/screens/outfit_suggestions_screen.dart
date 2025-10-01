import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/features/wardrobe/domain/entities/clothing_item.dart';

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

  @override
  void initState() {
    super.initState();
    // Generate dummy outfits based on the item
    _outfits = _generateOutfits();
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
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Save this outfit as favorite
            },
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
                  onPressed:
                      _currentOutfit > 0
                          ? () {
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
                  onPressed:
                      _currentOutfit < _outfits.length - 1
                          ? () {
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
    return Column(
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
          'name':
              widget.item.type == ClothingType.top ? 'Blue Top' : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'Black Bottom', 'color': Colors.black87},
        {'name': 'White Shoes', 'color': Colors.white},
      ],
      'explanation':
          'This outfit combines complementary colors that work well together. The ${_getItemDescription(widget.item)} pairs perfectly with black bottoms, creating a balanced look that\'s suitable for casual day out occasions.',
    });

    // Outfit 2: Weekend Brunch
    outfits.add({
      'name': 'Weekend Brunch',
      'items': [
        {
          'name':
              widget.item.type == ClothingType.top ? 'Blue Top' : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'Beige Bottom', 'color': const Color(0xFFE3D0B9)},
        {'name': 'Brown Shoes', 'color': Colors.brown},
      ],
      'explanation':
          'This color palette creates a warm, inviting look perfect for weekend brunches. The ${_getItemDescription(widget.item)} brings a nice pop of color to the neutral tones of the other pieces.',
    });

    // Outfit 3: Shopping Day
    outfits.add({
      'name': 'Shopping Day',
      'items': [
        {
          'name':
              widget.item.type == ClothingType.top ? 'Blue Top' : 'Your Item',
          'color': Colors.blue[200]!,
        },
        {'name': 'White Bottom', 'color': Colors.white},
        {'name': 'Sneakers', 'color': Colors.grey[300]!},
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
}
