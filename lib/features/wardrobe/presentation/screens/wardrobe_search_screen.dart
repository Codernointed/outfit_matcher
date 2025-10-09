import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Real-time search screen for wardrobe items
class WardrobeSearchScreen extends ConsumerStatefulWidget {
  const WardrobeSearchScreen({super.key});

  @override
  ConsumerState<WardrobeSearchScreen> createState() => _WardrobeSearchScreenState();
}

class _WardrobeSearchScreenState extends ConsumerState<WardrobeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentQuery = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search your wardrobe...',
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SimpleWardrobeUploadScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _currentQuery.isEmpty
          ? _buildEmptySearchState()
          : _buildSearchResults(),
    );
  }

  Widget _buildEmptySearchState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.search,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search Your Wardrobe',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type to search by color, type, brand, or occasion',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSearchChip('Red dress'),
              _buildSearchChip('Black shoes'),
              _buildSearchChip('Work outfits'),
              _buildSearchChip('Summer clothes'),
              _buildSearchChip('Favorite items'),
              _buildSearchChip('Casual wear'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        setState(() {
          _currentQuery = text;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<WardrobeItem>>(
      future: _performSearch(_currentQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return _buildNoResultsState();
        }

        return _buildResultsGrid(results);
      },
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Search Error',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to search wardrobe items',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.search_off,
              size: 60,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different term or check your spelling',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<WardrobeItem> results) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildSearchResultCard(results[index]);
      },
    );
  }

  Widget _buildSearchResultCard(WardrobeItem item) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showItemPreview(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Hero(
                tag: 'search_item_${item.id}',
                child: _buildItemImage(item),
              ),
            ),

            // Item info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.analysis.subcategory ?? item.analysis.itemType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.analysis.primaryColor,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),

                  // Highlight search matches
                  if (_highlightMatches(item).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: _highlightMatches(item).take(2).map((match) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            match,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(WardrobeItem item) {
    final imagePath = item.displayImagePath;

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.checkroom, color: Colors.grey),
          );
        },
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.checkroom, color: Colors.grey),
    );
  }

  List<String> _highlightMatches(WardrobeItem item) {
    final query = _currentQuery.toLowerCase();
    final matches = <String>[];

    // Check various fields for matches
    if (item.analysis.primaryColor.toLowerCase().contains(query)) {
      matches.add(item.analysis.primaryColor);
    }
    if (item.analysis.itemType.toLowerCase().contains(query)) {
      matches.add(item.analysis.itemType);
    }
    if (item.analysis.subcategory?.toLowerCase().contains(query) == true) {
      matches.add(item.analysis.subcategory!);
    }
    if (item.analysis.material?.toLowerCase().contains(query) == true) {
      matches.add(item.analysis.material!);
    }
    if (item.userNotes?.toLowerCase().contains(query) == true) {
      matches.add('Notes');
    }
    if (item.tags.any((tag) => tag.toLowerCase().contains(query))) {
      matches.add('Tags');
    }
    if (item.occasions.any((occasion) => occasion.toLowerCase().contains(query))) {
      matches.add('Occasions');
    }

    return matches;
  }

  void _showItemPreview(BuildContext context, WardrobeItem item) {
    showWardrobeItemPreview(context, item, heroTag: 'search_item_${item.id}');
  }

  Future<List<WardrobeItem>> _performSearch(String query) async {
    if (query.isEmpty) return [];

    try {
      final storage = getIt<EnhancedWardrobeStorageService>();
      final results = await storage.searchWardrobeItems(query);

      AppLogger.debug('🔍 Search completed: "$query" -> ${results.length} results');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Search failed', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
