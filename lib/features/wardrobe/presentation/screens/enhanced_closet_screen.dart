import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/walkthrough_step.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/walkthrough_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/widgets/walkthrough_overlay.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/swipe_closet_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/swipe_planner_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/wardrobe_quick_actions_sheet.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/providers/home_providers.dart';
import 'package:vestiq/core/services/analytics_service.dart'; // Import Analytics

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

final filteredWardrobeItemsProvider =
    FutureProvider.autoDispose<List<WardrobeItem>>((ref) async {
      final storage = ref.watch(wardrobeStorageProvider);
      final selectedCategory = ref.watch(selectedCategoryProvider);
      final searchQuery = ref.watch(searchQueryProvider);
      final sortMode = ref.watch(sortModeProvider);
      final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);

      AppLogger.debug('🔄 Fetching filtered wardrobe items (fresh data)');

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
            (a, b) =>
                a.analysis.primaryColor.compareTo(b.analysis.primaryColor),
          );
          break;
        case SortMode.type:
          items.sort(
            (a, b) => a.analysis.itemType.compareTo(b.analysis.itemType),
          );
          break;
        case SortMode.wearCount:
          items.sort((a, b) => b.wearCount.compareTo(a.wearCount));
          break;
      }

      AppLogger.debug('✅ Filtered wardrobe items: ${items.length} items');
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
  final GlobalKey _categoryTabsKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _firstItemKey = GlobalKey();
  final GlobalKey _plannerKey = GlobalKey();

  WalkthroughService? _walkthroughService;
  bool _showClosetWalkthrough = false;
  List<WalkthroughStep> _closetSteps = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWalkthrough());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initWalkthrough() async {
    final prefs = getIt<SharedPreferences>();
    _walkthroughService = WalkthroughService(prefs);
    if (!mounted) return;
    if (!(_walkthroughService?.shouldShowClosetWalkthrough() ?? false)) return;

    setState(() {
      _closetSteps = [
        WalkthroughStep(
          targetKey: _categoryTabsKey,
          title: 'Filter by vibe',
          description: 'Switch categories to narrow your closet.',
          position: TooltipPosition.below,
        ),
        WalkthroughStep(
          targetKey: _searchKey,
          title: 'Find it fast',
          description: 'Search by color or item name.',
          position: TooltipPosition.below,
        ),
        WalkthroughStep(
          targetKey: _firstItemKey,
          title: 'Tap or press',
          description: 'Tap to preview. Long-press for quick actions.',
          position: TooltipPosition.above,
        ),
        WalkthroughStep(
          targetKey: _plannerKey,
          title: 'Plan an outfit',
          description: 'Let the assistant build a look.',
          position: TooltipPosition.above,
        ),
      ];
      _showClosetWalkthrough = true;
    });
  }

  void _endClosetWalkthrough() {
    _walkthroughService?.completeClosetWalkthrough();
    setState(() => _showClosetWalkthrough = false);
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

    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
              _buildCustomHeader(theme, showFavoritesOnly),
              _buildCategoryTabs(theme, selectedCategory),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                          builder: (context) =>
                              const SimpleWardrobeUploadScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  )
                : null,
            orElse: () => null,
          ),
        ),
        if (_showClosetWalkthrough && _closetSteps.isNotEmpty)
          WalkthroughOverlay(
            steps: _closetSteps,
            onFinish: _endClosetWalkthrough,
            onSkip: _endClosetWalkthrough,
          ),
      ],
    );
  }

  // Minimal header implementation for enhanced_closet_screen.dart
  // Replace the _buildCustomHeader method with this

  // Minimal header implementation for enhanced_closet_screen.dart
  Widget _buildCustomHeader(ThemeData theme, bool showFavoritesOnly) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Unified Compact Header Row
          Row(
            children: [
              Text(
                'My Closet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),

              // Compact Plan Button
              SizedBox(
                height: 32,
                child: FilledButton.icon(
                  key: _plannerKey,
                  onPressed: _showSwipePlanner,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text(
                    'Plan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search Toggle
              IconButton(
                key: _searchKey,
                icon: Icon(_isSearching ? Icons.close : Icons.search, size: 20),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  });
                },
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: _isSearching
                      ? theme.colorScheme.secondaryContainer
                      : null,
                ),
              ),

              // Favorites Toggle
              IconButton(
                icon: Icon(
                  showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: showFavoritesOnly ? Colors.red : null,
                ),
                onPressed: () {
                  ref.read(showFavoritesOnlyProvider.notifier).state =
                      !showFavoritesOnly;
                },
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
              ),

              // More/Settings
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                onPressed: _showSettingsSheet,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
              ),
            ],
          ),

          // Search bar (when active) - Expands below
          if (_isSearching) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
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
      {'name': 'Access.', 'icon': Icons.watch}, // Shortened text
      {'name': 'Outer.', 'icon': Icons.ac_unit}, // Shortened text
    ];

    return Container(
      key: _categoryTabsKey,
      height: 36, // Reduced height
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryName = category['name'] as String;
          final categoryIcon = category['icon'] as IconData;

          // Map display aliases back to actual category names for selection check
          final realCategoryName = categoryName == 'Access.'
              ? 'Accessories'
              : categoryName == 'Outer.'
              ? 'Outerwear'
              : categoryName;

          final isSelected = realCategoryName == selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  final newCategory = (category['name'] == 'Access.'
                      ? 'Accessories'
                      : category['name'] == 'Outer.'
                      ? 'Outerwear'
                      : categoryName);

                  ref.read(selectedCategoryProvider.notifier).state =
                      newCategory;

                  // Log Filter Event
                  getIt<AnalyticsService>().logEvent(
                    name: 'wardrobe_filter',
                    parameters: {'category': newCategory},
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors
                              .transparent, // Minimal: no background for unselected
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          categoryIcon,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        categoryName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
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
        final isFirst = index == 0;
        return _buildItemCard(context, items[index], isFirst);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, WardrobeItem item, bool isFirst) {
    final theme = Theme.of(context);

    return Card(
      key: isFirst ? _firstItemKey : null,
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                                .withValues(alpha: 0.5),
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
      color: Colors.grey.shade200,
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
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.smallSpacing,
        horizontal: AppConstants.largeSpacing,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Beautiful empty state icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(icon, size: 60, color: theme.colorScheme.primary),
          ),

          const SizedBox(height: AppConstants.smallSpacing),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
            //     color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
              color: Colors.grey.shade600,
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
    // Log Item View
    getIt<AnalyticsService>().logItemViewed(item: item);

    showWardrobeItemPreview(
      context,
      item,
      heroTag: 'closet_item_${item.id}',
      onInspirationTap: () => _navigateToInspiration(item),
    );
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

    // If dialog was dismissed (null), don't navigate
    if (customNotes == null) {
      AppLogger.info('👤 User cancelled inspiration dialog');
      return;
    }

    if (!mounted) return;

    // Combine default notes with custom notes
    final finalNotes = [
      if (item.userNotes != null) item.userNotes!,
      if (customNotes.isNotEmpty) customNotes,
    ].join('\n\n');

    AppLogger.info('🎨 Navigating to inspiration with notes: $finalNotes');

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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Skip'),
        ),
        FilledButton.icon(
          onPressed: () {
            final notes = controller.text.trim();
            Navigator.pop(context, notes);
          },
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

        // Force complete refresh of ALL providers across the app
        AppLogger.info('🔄 [DELETE] Refreshing all app states...');

        // 1. Closet Screen Providers
        ref.invalidate(wardrobeStorageProvider);
        ref.invalidate(wardrobeItemsProvider);
        ref.invalidate(filteredWardrobeItemsProvider);

        // 2. Home Screen Providers (Crucial for removing from Today's Picks/Snapshot)
        ref.invalidate(todaysPicksProvider);
        ref.invalidate(wardrobeSnapshotProvider);
        ref.invalidate(recentLooksProvider);

        // Force immediate rebuild
        setState(() {});

        // Log Deletion
        final daysOwned = DateTime.now().difference(item.createdAt).inDays;
        getIt<AnalyticsService>().logItemDeleted(
          itemType: item.analysis.itemType,
          daysSinceCreation: daysOwned,
        );

        AppLogger.info('✅ Item deleted and UI refreshed globally');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item removed from closet'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to delete item', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove item'),
              backgroundColor: Colors.red,
            ),
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.15,
                        ),
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
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
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
                                  : Colors.grey.shade700,
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

  Future<void> _showSwipePlanner() async {
    AppLogger.info('🎯 Opening swipe planner sheet');

    final request = await showSwipePlannerSheet(context);

    if (request != null && mounted) {
      AppLogger.info(
        '🚀 Swipe planner completed with request',
        data: {
          'occasion': request.occasion,
          'mood': request.mood,
          'weather': request.weather,
          'colorPreference': request.colorPreference,
        },
      );

      // Navigate to swipe closet screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SwipeClosetScreen()),
      );
    }
  }
}
