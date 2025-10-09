import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/providers/home_providers.dart';

/// Full-screen view of all saved outfit looks with filtering and sorting
class SavedLooksScreen extends ConsumerStatefulWidget {
  final String initialFilter;

  const SavedLooksScreen({super.key, this.initialFilter = 'All'});

  @override
  ConsumerState<SavedLooksScreen> createState() => _SavedLooksScreenState();
}

class _SavedLooksScreenState extends ConsumerState<SavedLooksScreen> {
  late String _selectedFilter;
  String _selectedSort = 'Recent'; // Recent, Score, Name
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    AppLogger.info(
      '📂 Saved Looks Screen opened with filter: $_selectedFilter',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedOutfit> _filterAndSortLooks(
    List<SavedOutfit> looks,
    Set<String> favoriteIds,
  ) {
    var filtered = looks.where((look) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            look.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            look.items.any(
              (item) =>
                  item.primaryColor.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  item.itemType.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            );
        if (!matchesSearch) return false;
      }

      // Filter by category
      switch (_selectedFilter) {
        case 'Tight':
          return look.matchScore >= 0.75;
        case 'Loose':
          return look.matchScore < 0.75;
        case 'Favorites':
          return favoriteIds.contains(look.id);
        default:
          return true;
      }
    }).toList();

    // Sort
    switch (_selectedSort) {
      case 'Score':
        filtered.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case 'Name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentLooks = ref.watch(recentLooksProvider);

    final filteredLooks = _filterAndSortLooks(
      recentLooks.looks,
      recentLooks.favoriteIds,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Looks (${recentLooks.looks.length})'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                AppLogger.info('🔍 Search query: $value');
              },
              decoration: InputDecoration(
                hintText: 'Search looks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(theme, 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Tight'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Loose'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Favorites'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: const Icon(Icons.sort, size: 16),
                    items: ['Recent', 'Score', 'Name'].map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSort = value;
                        });
                        AppLogger.info('📊 Sort changed to: $value');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid View
          Expanded(
            child: recentLooks.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredLooks.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(recentLooksProvider);
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: filteredLooks.length,
                      itemBuilder: (context, index) {
                        return _buildLookCard(
                          theme,
                          filteredLooks[index],
                          recentLooks.favoriteIds,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
        AppLogger.info('🏷️ Filter changed to: $label');
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildLookCard(
    ThemeData theme,
    SavedOutfit look,
    Set<String> favoriteIds,
  ) {
    final isFavorite = favoriteIds.contains(look.id);
    final isTight = look.matchScore >= 0.75;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppLogger.info('👆 Tapped look: ${look.title}');
          // TODO: Navigate to LookDetailScreen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      width: double.infinity,
                      child: _buildLookImage(look, theme),
                    ),
                  ),

                  // Tight/Loose badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isTight ? Colors.green : Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isTight ? 'Tight' : 'Loose',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          ref
                              .read(recentLooksProvider.notifier)
                              .toggleFavorite(look.id);
                          AppLogger.info('⭐ Toggled favorite: ${look.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? Colors.red
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    look.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.checkroom,
                        size: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${look.items.length} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(
                            look.matchScore,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(look.matchScore * 100).toInt()}%',
                          style: TextStyle(
                            color: _getScoreColor(look.matchScore),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookImage(SavedOutfit look, ThemeData theme) {
    // Try mannequin image first
    if (look.mannequinImages.isNotEmpty) {
      try {
        return Image.memory(
          _dataUrlToBytes(look.mannequinImages.first),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildItemsGrid(look, theme),
        );
      } catch (e) {
        // Fall through
      }
    }

    return _buildItemsGrid(look, theme);
  }

  Widget _buildItemsGrid(SavedOutfit look, ThemeData theme) {
    if (look.items.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }

    final itemsToShow = look.items.take(4).toList();

    if (itemsToShow.length == 1) {
      return _buildSingleItemImage(itemsToShow[0], theme);
    }

    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: itemsToShow
          .map((item) => _buildSingleItemImage(item, theme))
          .toList(),
    );
  }

  Widget _buildSingleItemImage(ClothingAnalysis item, ThemeData theme) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return Image.file(
        File(item.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildItemPlaceholder(item, theme),
      );
    }

    return _buildItemPlaceholder(item, theme);
  }

  Widget _buildItemPlaceholder(ClothingAnalysis item, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForItemType(item.itemType),
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              item.primaryColor,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No looks match your search'
                : 'No saved looks yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Start creating outfits to see them here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForItemType(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'top':
        return Icons.checkroom;
      case 'bottom':
        return Icons.content_cut;
      case 'dress':
        return Icons.woman;
      case 'shoes':
        return Icons.directions_walk;
      case 'accessory':
        return Icons.watch;
      case 'outerwear':
        return Icons.ac_unit;
      default:
        return Icons.checkroom;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.70) return Colors.lightGreen;
    if (score >= 0.50) return Colors.orange;
    return Colors.red;
  }

  Uint8List _dataUrlToBytes(String dataUrl) {
    try {
      String base64Data;
      if (dataUrl.startsWith('data:')) {
        final parts = dataUrl.split(',');
        if (parts.length < 2) {
          throw FormatException('Invalid data URL format');
        }
        base64Data = parts[1];
      } else {
        base64Data = dataUrl;
      }

      base64Data = base64Data.replaceAll(RegExp(r'\s+'), '');
      base64Data = base64Data.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

      while (base64Data.length % 4 != 0) {
        base64Data += '=';
      }

      return base64Decode(base64Data);
    } catch (e) {
      return Uint8List(0);
    }
  }
}
