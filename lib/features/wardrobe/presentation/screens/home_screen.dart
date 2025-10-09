import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_closet_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/wardrobe_search_screen.dart';

/// Home screen showing recent items and outfit suggestions
class HomeScreen extends StatelessWidget {
  /// Default constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WardrobeSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add new item button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to upload options screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SimpleWardrobeUploadScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Item'),
              ),
            ),
            const SizedBox(height: AppConstants.largeSpacing),

            // Recent items section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to closet screen with favorites filter
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EnhancedClosetScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),

            // Recent items grid
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding / 2,
                ),
                children: [
                  // Recent item placeholders
                  _buildRecentItemCard(
                    context,
                    'Blue Top',
                    'assets/images/blue_dress.jpeg',
                  ),
                  _buildRecentItemCard(
                    context,
                    'Black Pants',
                    'assets/images/black_dress.jpeg',
                  ),
                  _buildRecentItemCard(
                    context,
                    'Red Dress',
                    'assets/images/red_dress.jpeg',
                  ),
                  _buildAddItemCard(context),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.largeSpacing),

            // Outfit ideas section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outfit Ideas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to outfit ideas screen
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallSpacing),

            // Outfit ideas list
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
              ),
              itemBuilder: (context, index) {
                final outfitNames = [
                  'Casual Friday',
                  'Night Out',
                  'Office Ready',
                ];

                return _buildOutfitCard(
                  context,
                  outfitNames[index],
                  '3 items',
                  'assets/images/casual_outfit.jpeg',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build a card for a recent item
  Widget _buildRecentItemCard(
    BuildContext context,
    String name,
    String imagePath,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding / 2,
      ),
      child: Column(
        children: [
          // Item image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Item name
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a card for adding a new item
  Widget _buildAddItemCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding / 2,
      ),
      child: Column(
        children: [
          // Add item button
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: Icon(Icons.add, color: Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 8),

          // Label
          Text(
            'Add',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a card for an outfit suggestion
  Widget _buildOutfitCard(
    BuildContext context,
    String name,
    String itemCount,
    String imagePath,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to outfit details
        },
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultSpacing),
          child: Row(
            children: [
              // Outfit thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(
                    AppConstants.smallBorderRadius,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppConstants.smallBorderRadius,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.defaultSpacing),

              // Outfit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      itemCount,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Favorite button
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // TODO: Toggle favorite status
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
