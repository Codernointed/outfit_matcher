import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_quick_actions_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';
import 'package:vestiq/core/utils/logger.dart';

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

final filteredWardrobeItemsProvider = FutureProvider<List<WardrobeItem>>((
  ref,
) async {
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
      items.sort(
        (a, b) => a.analysis.primaryColor.compareTo(b.analysis.primaryColor),
      );
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
  ConsumerState<EnhancedClosetScreen> createState() =>
      _EnhancedClosetScreenState();
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
      body: Column(
        children: [
          // Custom header
          _buildCustomHeader(theme, showFavoritesOnly),

          // Category tabs
          _buildCategoryTabs(theme, selectedCategory),

          // Items grid
          Expanded(
            child: filteredItemsAsync.when(
              data: (items) => RefreshIndicator(
                onRefresh: _handleRefresh,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          _buildEmptyState(context),
                        ],
                      )
                    : _buildItemsGrid(context, items),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    _buildErrorState(context, error),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: filteredItemsAsync.maybeWhen(
        data: (items) => items.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SimpleWardrobeUploadScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildCustomHeader(ThemeData theme, bool showFavoritesOnly) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main header row
          Row(
            children: [
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Closet',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your digital wardrobe',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                children: [
                  // Search button
                  Container(
                    decoration: BoxDecoration(
                      color: _isSearching
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: _isSearching
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Favorites button
                  Container(
                    decoration: BoxDecoration(
                      color: showFavoritesOnly
                          ? Colors.red.withOpacity(0.1)
                          : theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        showFavoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: showFavoritesOnly
                            ? Colors.red
                            : theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        ref.read(showFavoritesOnlyProvider.notifier).state =
                            !showFavoritesOnly;
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Settings button
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: _showSettingsSheet,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search bar (when active)
          if (_isSearching) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search your wardrobe...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ],
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
      margin: const EdgeInsets.only(bottom: 8),
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
                  ref.read(selectedCategoryProvider.notifier).state =
                      categoryName;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          )
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
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
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
      physics: const AlwaysScrollableScrollPhysics(),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withOpacity(0.5),
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
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
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
    IconData icon;

    if (searchQuery.isNotEmpty) {
      title = 'No items found';
      message = 'Try a different search term or check your spelling.';
      icon = Icons.search_off;
    } else if (showFavoritesOnly) {
      title = 'No favorites yet';
      message = 'Tap the heart icon on items to add them to your favorites.';
      icon = Icons.favorite_border;
    } else {
      title = 'Your closet is empty';
      message =
          'Start building your digital wardrobe by adding your first item.';
      icon = Icons.checkroom;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Beautiful empty state icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(icon, size: 60, color: theme.colorScheme.primary),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),

          // Action button for empty closet
          if (searchQuery.isEmpty && !showFavoritesOnly) ...[
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text(
                  'Add Your First Item',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SimpleWardrobeUploadScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // // Alternative text
            // Text(
            //   'or',
            //   style: theme.textTheme.bodyMedium?.copyWith(
            //     color: theme.colorScheme.onSurface.withOpacity(0.5),
            //   ),
            // ),

            // const SizedBox(height: 8),

            // TextButton.icon(
            //   icon: const Icon(Icons.camera_alt, size: 18),
            //   label: const Text('Take a photo'),
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => const SimpleWardrobeUploadScreen(),
            //       ),
            //     );
            //   },
            //   style: TextButton.styleFrom(
            //     foregroundColor: theme.colorScheme.primary,
            //     textStyle: const TextStyle(fontWeight: FontWeight.w500),
            //   ),
            // ),
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
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
    showWardrobeItemPreview(context, item, heroTag: 'closet_item_${item.id}');
  }

  void _showQuickActions(BuildContext context, WardrobeItem item) async {
    AppLogger.ui(
      'EnhancedCloset',
      'ShowQuickActions',
      data: {'item_id': item.id},
    );

    await WardrobeQuickActionsSheet.show(
      context,
      item: item,
      onPairThisItem: () => _navigateToPairing(item, PairingMode.pairThisItem),
      onSurpriseMe: () => _navigateToPairing(item, PairingMode.surpriseMe),
      onViewInspiration: () => _navigateToInspiration(item),
      onEdit: () => _editItem(item),
      onDelete: () => _deleteItem(item),
    );
  }

  void _navigateToPairing(WardrobeItem heroItem, PairingMode mode) async {
    if (!mounted) return;

    // Use interactive pairing for "Pair This Item", regular pairing sheet for others
    if (mode == PairingMode.pairThisItem) {
      showInteractivePairingSheet(
        context: context,
        heroItem: heroItem,
        mode: mode,
      );
    } else {
      showWardrobePairingSheet(
        context: context,
        heroItem: heroItem,
        mode: mode,
      );
    }
  }

  void _navigateToInspiration(WardrobeItem item) async {
    // Show dialog to add custom styling notes
    final customNotes = await showDialog<String>(
      context: context,
      builder: (context) => _buildStylingNotesDialog(context, item),
    );

    if (!mounted) return;

    // Combine default notes with custom notes
    final finalNotes = [
      if (item.userNotes != null) item.userNotes!,
      if (customNotes != null && customNotes.isNotEmpty) customNotes,
    ].join('\n\n');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVisualSearchScreen(
          analyses: [item.analysis],
          itemImages: [item.displayImagePath],
          userNotes: finalNotes.isEmpty ? null : finalNotes,
        ),
      ),
    );
  }

  Widget _buildStylingNotesDialog(BuildContext context, WardrobeItem item) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    // Pre-fill with item context
    final defaultNotes =
        'Style this ${item.analysis.primaryColor} ${item.analysis.itemType}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Add Styling Notes')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add custom styling instructions for the AI',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    defaultNotes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g., "Make it edgy", "Add vintage vibes", "Corporate chic"...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, controller.text),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate'),
        ),
      ],
    );
  }

  void _editItem(WardrobeItem item) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.analysis.itemType} from your closet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final storage = ref.read(wardrobeStorageProvider);
        await storage.deleteWardrobeItem(item.id);
        ref.invalidate(wardrobeItemsProvider);
        ref.invalidate(filteredWardrobeItemsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from closet')),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to delete item', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove item')),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final storage = ref.read(wardrobeStorageProvider);
      await storage.refreshCache();
      ref.invalidate(wardrobeItemsProvider);
      ref.invalidate(filteredWardrobeItemsProvider);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to refresh wardrobe cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _showSettingsSheet() async {
    final settings = getIt<AppSettingsService>();
    bool premiumEnabled = settings.isPremiumPolishingEnabled;
    SortMode currentSort = ref.read(sortModeProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: MediaQuery.of(sheetContext).viewInsets,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 360),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        premiumEnabled
                            ? Icons.auto_awesome
                            : Icons.auto_awesome_outlined,
                        color: premiumEnabled
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      title: const Text('Premium image polishing'),
                      subtitle: const Text(
                        'Hyper-detailed editing for uploads (uses more data)',
                      ),
                      trailing: Switch.adaptive(
                        value: premiumEnabled,
                        onChanged: (value) async {
                          setSheetState(() => premiumEnabled = value);
                          await settings.setPremiumPolishing(value);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? '✨ Premium polishing enabled - uploads will look couture-ready.'
                                    : '💾 Premium polishing off - faster uploads, less data.',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: value
                                  ? Colors.amber
                                  : Colors.grey[700],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sort looks by',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ...SortMode.values.map((mode) {
                      final isSelected = mode == currentSort;
                      return ListTile(
                        leading: Icon(
                          mode == SortMode.dateAdded
                              ? Icons.schedule
                              : mode == SortMode.color
                              ? Icons.palette
                              : mode == SortMode.type
                              ? Icons.category
                              : Icons.repeat,
                        ),
                        title: Text(_sortLabelForMode(mode)),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setSheetState(() => currentSort = mode);
                          ref.read(sortModeProvider.notifier).state = mode;
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _sortLabelForMode(SortMode mode) {
    switch (mode) {
      case SortMode.dateAdded:
        return 'Latest added';
      case SortMode.color:
        return 'Colour harmony';
      case SortMode.type:
        return 'Item type';
      case SortMode.wearCount:
        return 'Wear frequency';
    }
  }
}
