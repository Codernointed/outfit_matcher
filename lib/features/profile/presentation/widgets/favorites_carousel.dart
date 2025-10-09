import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';

/// Horizontal carousel showing favorite items and looks
class FavoritesCarousel extends StatelessWidget {
  final List<WardrobeItem> favoriteItems;
  final List<SavedOutfit> favoriteLooks;
  final VoidCallback onViewAll;

  const FavoritesCarousel({
    super.key,
    required this.favoriteItems,
    required this.favoriteLooks,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = favoriteItems.isNotEmpty || favoriteLooks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorites',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (hasItems)
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onViewAll();
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Carousel or empty state
        if (hasItems)
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: (favoriteItems.length + favoriteLooks.length).clamp(
                0,
                6,
              ),
              itemBuilder: (context, index) {
                if (index < favoriteItems.length) {
                  return _buildItemCard(context, favoriteItems[index]);
                } else {
                  final lookIndex = index - favoriteItems.length;
                  if (lookIndex < favoriteLooks.length) {
                    return _buildLookCard(context, favoriteLooks[lookIndex]);
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          )
        else
          _buildEmptyState(context),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, WardrobeItem item) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (item.polishedImagePath != null)
              Image.file(File(item.polishedImagePath!), fit: BoxFit.cover)
            else if (item.originalImagePath != null)
              Image.file(File(item.originalImagePath!), fit: BoxFit.cover)
            else
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.checkroom,
                  size: 40,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),

            // Favorite badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookCard(BuildContext context, SavedOutfit look) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Look preview (mannequin or items grid)
            if (look.mannequinImages.isNotEmpty)
              Image.memory(look.mannequinImages.first as Uint8List, fit: BoxFit.cover)
            else
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.favorite_border,
                  size: 40,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),

            // Favorite badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.favorite_border,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No favorites yet. Start hearting items!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
