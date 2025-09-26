import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outfit_matcher/core/models/wardrobe_item.dart';
import 'package:outfit_matcher/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:outfit_matcher/core/services/outfit_storage_service.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';
import 'package:outfit_matcher/core/services/app_settings_service.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/widgets/wardrobe_quick_actions.dart';

// Providers for wardrobe state management
final wardrobeStorageProvider = Provider<EnhancedWardrobeStorageService>((ref) {
  final prefs = getIt<SharedPreferences>();
  final legacyStorage = getIt<OutfitStorageService>();
  return EnhancedWardrobeStorageService(prefs, legacyStorage);
});

final wardrobeItemsProvider = FutureProvider<List<WardrobeItem>>((ref) async {
  final storage = ref.watch(wardrobeStorageProvider);
  return storage.getWardrobeItems();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.dateAdded);
final showFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

final filteredWardrobeItemsProvider = FutureProvider<List<WardrobeItem>>((ref) async {
  final storage = ref.watch(wardrobeStorageProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final sortMode = ref.watch(sortModeProvider);
  final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);

  List<WardrobeItem> items;

  // Apply search first
  if (searchQuery.isNotEmpty) {
    items = await storage.searchWardrobeItems(searchQuery);
  } else {
    items = await storage.getWardrobeItemsByCategory(selectedCategory);
  }

  // Apply favorites filter
  if (showFavoritesOnly) {
    items = items.where((item) => item.isFavorite).toList();
  }

  // Apply sorting
  switch (sortMode) {
    case SortMode.dateAdded:
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case SortMode.color:
      items.sort((a, b) => a.analysis.primaryColor.compareTo(b.analysis.primaryColor));
      break;
    case SortMode.type:
      items.sort((a, b) => a.analysis.itemType.compareTo(b.analysis.itemType));
      break;
    case SortMode.wearCount:
      items.sort((a, b) => b.wearCount.compareTo(a.wearCount));
      break;
  }

  return items;
});

enum SortMode { dateAdded, color, type, wearCount }

class EnhancedClosetScreen extends ConsumerStatefulWidget {
  const EnhancedClosetScreen({super.key});

  @override
  ConsumerState<EnhancedClosetScreen> createState() => _EnhancedClosetScreenState();
}

class _EnhancedClosetScreenState extends ConsumerState<EnhancedClosetScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredItemsAsync = ref.watch(filteredWardrobeItemsProvider);
    final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search wardrobe...',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.titleLarge,
              )
            : const Text('My Closet'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _isSearching = false);
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              ref.read(showFavoritesOnlyProvider.notifier).state = !showFavoritesOnly;
            },
          ),
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) {
              ref.read(sortModeProvider.notifier).state = mode;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortMode.dateAdded,
                child: Text('Date Added'),
              ),
              const PopupMenuItem(
                value: SortMode.color,
                child: Text('Color'),
              ),
              const PopupMenuItem(
                value: SortMode.type,
                child: Text('Type'),
              ),
              const PopupMenuItem(
                value: SortMode.wearCount,
                child: Text('Wear Count'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              if (value == 'premium_toggle') {
                _togglePremiumPolishing();
              }
            },
            itemBuilder: (context) {
              final settings = getIt<AppSettingsService>();
              final isPremiumEnabled = settings.isPremiumPolishingEnabled;
              
              return [
                PopupMenuItem(
                  value: 'premium_toggle',
                  child: Row(
                    children: [
                      Icon(
                        isPremiumEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                        color: isPremiumEnabled ? Colors.amber : null,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Premium Polishing'),
                      const Spacer(),
                      Switch(
                        value: isPremiumEnabled,
                        onChanged: null, // Handled by menu selection
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          _buildCategoryTabs(theme, selectedCategory),
          
          // Items grid
          Expanded(
            child: filteredItemsAsync.when(
              data: (items) => _buildItemsGrid(context, items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SimpleWardrobeUploadScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme, String selectedCategory) {
    final categories = [
      {'name': 'All', 'icon': Icons.apps},
      {'name': 'Tops', 'icon': Icons.checkroom},
      {'name': 'Bottoms', 'icon': Icons.content_cut},
      {'name': 'Dresses', 'icon': Icons.woman},
      {'name': 'Shoes', 'icon': Icons.directions_walk},
      {'name': 'Accessories', 'icon': Icons.watch},
      {'name': 'Outerwear', 'icon': Icons.ac_unit},
    ];
    
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'] as String;
          final categoryIcon = category['icon'] as IconData;
          final isSelected = categoryName == selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = categoryName;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected 
                        ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        categoryIcon,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(BuildContext context, List<WardrobeItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(context, items[index]);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, WardrobeItem item) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () => _showItemPreview(context, item),
        onLongPress: () => _showQuickActions(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'closet_item_${item.id}',
                    child: _buildItemImage(item),
                  ),
                  
                  // Favorite indicator
                  if (item.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  
                  // Wear count badge
                  if (item.wearCount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.wearCount}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  // Occasions chips
                  if (item.occasions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: item.occasions.take(2).map((occasion) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            occasion,
                            style: theme.textTheme.labelSmall,
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
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        ),
      );
    }
    
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    final theme = Theme.of(context);
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 50,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);
    
    String title;
    String message;
    
    if (searchQuery.isNotEmpty) {
      title = 'No items found';
      message = 'Try a different search term or check your spelling.';
    } else if (showFavoritesOnly) {
      title = 'No favorites yet';
      message = 'Tap the heart icon on items to add them to your favorites.';
    } else {
      title = 'Your closet is empty';
      message = 'Start building your digital wardrobe by adding your first item.';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (searchQuery.isEmpty && !showFavoritesOnly) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Item'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SimpleWardrobeUploadScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load your wardrobe items',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(filteredWardrobeItemsProvider);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showItemPreview(BuildContext context, WardrobeItem item) {
    showWardrobeItemPreview(
      context,
      item,
      heroTag: 'closet_item_${item.id}',
    );
  }

  void _showQuickActions(BuildContext context, WardrobeItem item) {
    // Use a safer approach to get position
    final RenderObject? renderObject = context.findRenderObject();
    Offset position = Offset.zero;
    
    if (renderObject is RenderBox) {
      try {
        position = renderObject.localToGlobal(Offset.zero);
        position = Offset(
          position.dx + renderObject.size.width / 2, 
          position.dy + renderObject.size.height / 2,
        );
      } catch (e) {
        // Fallback to center of screen
        position = Offset(200, 300);
      }
    } else {
      // Fallback position
      position = Offset(200, 300);
    }
    
    showWardrobeQuickActions(context, item, position);
  }

  void _togglePremiumPolishing() async {
    final settings = getIt<AppSettingsService>();
    final currentValue = settings.isPremiumPolishingEnabled;
    await settings.setPremiumPolishing(!currentValue);
    
    setState(() {}); // Refresh UI
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !currentValue 
              ? '✨ Premium polishing enabled - new uploads will be enhanced!'
              : '💾 Premium polishing disabled - faster uploads, less storage',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: !currentValue ? Colors.amber : Colors.grey[700],
      ),
    );
  }
}
