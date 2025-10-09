import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart';

/// Screen for displaying search results across items, looks, and inspiration
class HomeSearchResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;

  const HomeSearchResultsScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<HomeSearchResultsScreen> createState() =>
      _HomeSearchResultsScreenState();
}

class _HomeSearchResultsScreenState
    extends ConsumerState<HomeSearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;

  final EnhancedWardrobeStorageService _wardrobeStorage =
      getIt<EnhancedWardrobeStorageService>();
  final OutfitStorageService _outfitStorage = getIt<OutfitStorageService>();

  List<WardrobeItem> _itemResults = [];
  List<SavedOutfit> _lookResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController(text: widget.initialQuery);

    AppLogger.info(
      '🔍 [SEARCH] Screen initialized with query: "${widget.initialQuery}"',
    );

    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _itemResults = [];
        _lookResults = [];
        _isSearching = false;
      });
      return;
    }

    AppLogger.info('🔍 [SEARCH] Performing search for: "$query"');
    setState(() {
      _isSearching = true;
    });

    try {
      // Search wardrobe items
      final items = await _wardrobeStorage.searchWardrobeItems(query);

      // Search saved outfits
      final allOutfits = await _outfitStorage.fetchAll();
      final outfits = allOutfits.where((outfit) {
        return outfit.title.toLowerCase().contains(query.toLowerCase()) ||
            outfit.items.any(
              (item) =>
                  item.primaryColor.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  item.itemType.toLowerCase().contains(query.toLowerCase()),
            );
      }).toList();

      AppLogger.info(
        '✅ [SEARCH] Found ${items.length} items, ${outfits.length} outfits',
      );

      setState(() {
        _itemResults = items;
        _lookResults = outfits;
        _isSearching = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [SEARCH] Search failed',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search wardrobe, outfits...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Items (${_itemResults.length})'),
            Tab(text: 'Looks (${_lookResults.length})'),
            const Tab(text: 'Inspiration'),
          ],
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildItemsTab(theme),
                _buildLooksTab(theme),
                _buildInspirationTab(theme),
              ],
            ),
    );
  }

  Widget _buildItemsTab(ThemeData theme) {
    if (_itemResults.isEmpty) {
      return _buildEmptyState(
        theme,
        'No items found',
        'Try searching for colors, types, or styles',
        Icons.checkroom_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itemResults.length,
      itemBuilder: (context, index) {
        final item = _itemResults[index];
        return _buildItemCard(item, theme);
      },
    );
  }

  Widget _buildItemCard(WardrobeItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: theme.colorScheme.surfaceContainerHighest,
            child: item.displayImagePath.isNotEmpty
                ? Image.file(
                    File(item.displayImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.checkroom,
                        color: theme.colorScheme.primary,
                      );
                    },
                  )
                : Icon(Icons.checkroom, color: theme.colorScheme.primary),
          ),
        ),
        title: Text(
          '${item.analysis.primaryColor} ${item.analysis.itemType}',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          item.analysis.subcategory ?? item.analysis.style,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: () {
          AppLogger.info('👆 [SEARCH] Tapped item: ${item.id}');
          showWardrobeItemPreview(
            context,
            item,
            heroTag: 'search_item_${item.id}',
          );
        },
      ),
    );
  }

  Widget _buildLooksTab(ThemeData theme) {
    if (_lookResults.isEmpty) {
      return _buildEmptyState(
        theme,
        'No looks found',
        'Try searching for outfit names or occasions',
        Icons.auto_awesome_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _lookResults.length,
      itemBuilder: (context, index) {
        final look = _lookResults[index];
        return _buildLookCard(look, theme);
      },
    );
  }

  Widget _buildLookCard(SavedOutfit look, ThemeData theme) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppLogger.info('👆 [SEARCH] Tapped look: ${look.title}');
          // TODO: Navigate to look detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    look.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${look.items.length} items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspirationTab(ThemeData theme) {
    return _buildEmptyState(
      theme,
      'Inspiration coming soon',
      'Browse visual search for outfit inspiration',
      Icons.lightbulb_outline,
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
