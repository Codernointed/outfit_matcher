import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/swipe_closet_request.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/features/wardrobe/presentation/providers/swipe_planner_providers.dart'
    as swipe_planner_providers;
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';

class SwipeClosetScreen extends ConsumerStatefulWidget {
  const SwipeClosetScreen({super.key});

  @override
  ConsumerState<SwipeClosetScreen> createState() => _SwipeClosetScreenState();
}

class _SwipeClosetScreenState extends ConsumerState<SwipeClosetScreen> {
  final PageController _topController = PageController();
  final PageController _bottomController = PageController();
  final PageController _footwearController = PageController();
  final PageController _accessoryController = PageController();

  late final OutfitStorageService _outfitStorage;

  @override
  void initState() {
    super.initState();
    _outfitStorage = getIt<OutfitStorageService>();
  }

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    _footwearController.dispose();
    _accessoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = ref.watch(swipe_planner_providers.swipeRequestProvider);
    final poolsAsync = ref.watch(
      swipe_planner_providers.swipeClosetPoolsProvider,
    );
    final selections = ref.watch(
      swipe_planner_providers.swipeClosetSelectionsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          request?.occasion ?? 'Find your look',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Surprise me',
            onPressed: _shuffleOutfit,
          ),
        ],
      ),
      body: poolsAsync.when(
        data: (pools) => _buildSwipeContent(theme, pools, selections, request),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Failed to load items: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(
                  swipe_planner_providers.swipeClosetPoolsProvider,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme, selections),
    );
  }

  Widget _buildSwipeContent(
    ThemeData theme,
    swipe_planner_providers.SwipeClosetPools pools,
    swipe_planner_providers.SwipeClosetSelections selections,
    SwipeClosetRequest? request,
  ) {
    // Count total items
    final totalItems =
        pools.tops.length +
        pools.bottoms.length +
        pools.footwear.length +
        pools.accessories.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Occasion info banner
          if (request != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      totalItems > 0
                          ? 'Showing $totalItems items for "${request.occasion}"'
                          : 'No exact matches for "${request.occasion}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Current selection preview
          if (selections.top != null ||
              selections.bottom != null ||
              selections.footwear != null ||
              selections.accessory != null)
            _buildSelectionPreview(theme, selections),

          const SizedBox(height: 24),

          // Tops section
          if (pools.tops.isNotEmpty) ...[
            _buildCategoryHeader(theme, 'Tops', pools.tops.length),
            const SizedBox(height: 12),
            _buildSwipeRow(
              theme,
              pools.tops,
              _topController,
              (item) => _updateSelection(top: item),
            ),
            const SizedBox(height: 24),
          ],

          // Bottoms section
          if (pools.bottoms.isNotEmpty) ...[
            _buildCategoryHeader(theme, 'Bottoms', pools.bottoms.length),
            const SizedBox(height: 12),
            _buildSwipeRow(
              theme,
              pools.bottoms,
              _bottomController,
              (item) => _updateSelection(bottom: item),
            ),
            const SizedBox(height: 24),
          ],

          // Footwear section
          if (pools.footwear.isNotEmpty) ...[
            _buildCategoryHeader(theme, 'Shoes', pools.footwear.length),
            const SizedBox(height: 12),
            _buildSwipeRow(
              theme,
              pools.footwear,
              _footwearController,
              (item) => _updateSelection(footwear: item),
            ),
            const SizedBox(height: 24),
          ],

          // Accessories section
          if (pools.accessories.isNotEmpty) ...[
            _buildCategoryHeader(
              theme,
              'Accessories',
              pools.accessories.length,
            ),
            const SizedBox(height: 12),
            _buildSwipeRow(
              theme,
              pools.accessories,
              _accessoryController,
              (item) => _updateSelection(accessory: item),
            ),
            const SizedBox(height: 24),
          ],

          // Empty state
          if (pools.tops.isEmpty &&
              pools.bottoms.isEmpty &&
              pools.footwear.isEmpty &&
              pools.accessories.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No items found for "${request?.occasion ?? 'your occasion'}"',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some items to your closet that match this occasion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Browse My Closet'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.swipe,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildSwipeRow(
    ThemeData theme,
    List<WardrobeItem> items,
    PageController controller,
    Function(WardrobeItem) onItemSelected,
  ) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        onPageChanged: (index) {
          HapticFeedback.lightImpact();
          onItemSelected(items[index]);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildItemImage(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemImage(WardrobeItem item) {
    if (item.displayImagePath.isNotEmpty) {
      return Image.file(
        File(item.displayImagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(item),
      );
    }
    return _buildPlaceholder(item);
  }

  Widget _buildPlaceholder(WardrobeItem item) {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            '${item.analysis.primaryColor}\n${item.analysis.itemType}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPreview(
    ThemeData theme,
    swipe_planner_providers.SwipeClosetSelections selections,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your current look',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (selections.top != null)
                Expanded(child: _buildMiniItem(selections.top!)),
              if (selections.bottom != null)
                Expanded(child: _buildMiniItem(selections.bottom!)),
              if (selections.footwear != null)
                Expanded(child: _buildMiniItem(selections.footwear!)),
              if (selections.accessory != null)
                Expanded(child: _buildMiniItem(selections.accessory!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniItem(WardrobeItem item) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildItemImage(item),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.analysis.itemType,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    ThemeData theme,
    swipe_planner_providers.SwipeClosetSelections selections,
  ) {
    final hasSelection =
        selections.top != null ||
        selections.bottom != null ||
        selections.footwear != null ||
        selections.accessory != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shuffleOutfit,
                icon: const Icon(Icons.shuffle),
                label: const Text('Surprise Me'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasSelection ? _saveOutfit : null,
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Save Look'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelection({
    WardrobeItem? top,
    WardrobeItem? bottom,
    WardrobeItem? footwear,
    WardrobeItem? accessory,
  }) {
    final current = ref.read(
      swipe_planner_providers.swipeClosetSelectionsProvider,
    );
    ref
        .read(swipe_planner_providers.swipeClosetSelectionsProvider.notifier)
        .state = current.copyWith(
      top: top,
      bottom: bottom,
      footwear: footwear,
      accessory: accessory,
    );
  }

  Future<void> _shuffleOutfit() async {
    AppLogger.info('🔀 Surprise me tapped');

    final poolsAsync = ref.read(
      swipe_planner_providers.swipeClosetPoolsProvider,
    );

    // Get pools from the provider (already filtered)
    final pools = poolsAsync.when(
      data: (data) => data,
      loading: () => const swipe_planner_providers.SwipeClosetPools(),
      error: (_, __) => const swipe_planner_providers.SwipeClosetPools(),
    );

    // Collect all available items from pools
    final allPoolItems = [
      ...pools.tops,
      ...pools.bottoms,
      ...pools.footwear,
      ...pools.accessories,
    ];

    if (allPoolItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some items to your closet first')),
      );
      return;
    }

    AppLogger.info('🎲 Shuffling from ${allPoolItems.length} available items');

    try {
      // Pick random items from each category
      final randomTop = pools.tops.isNotEmpty
          ? pools.tops[DateTime.now().millisecond % pools.tops.length]
          : null;
      final randomBottom = pools.bottoms.isNotEmpty
          ? pools.bottoms[DateTime.now().millisecond % pools.bottoms.length]
          : null;
      final randomFootwear = pools.footwear.isNotEmpty
          ? pools.footwear[DateTime.now().millisecond % pools.footwear.length]
          : null;
      final randomAccessory = pools.accessories.isNotEmpty
          ? pools.accessories[DateTime.now().millisecond %
                pools.accessories.length]
          : null;

      // Update selections
      ref
          .read(swipe_planner_providers.swipeClosetSelectionsProvider.notifier)
          .state = swipe_planner_providers.SwipeClosetSelections(
        top: randomTop,
        bottom: randomBottom,
        footwear: randomFootwear,
        accessory: randomAccessory,
      );

      // Scroll to show the selected items
      if (randomTop != null && pools.tops.isNotEmpty) {
        final index = pools.tops.indexOf(randomTop);
        _topController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      if (randomBottom != null && pools.bottoms.isNotEmpty) {
        final index = pools.bottoms.indexOf(randomBottom);
        _bottomController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      if (randomFootwear != null && pools.footwear.isNotEmpty) {
        final index = pools.footwear.indexOf(randomFootwear);
        _footwearController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      if (randomAccessory != null && pools.accessories.isNotEmpty) {
        final index = pools.accessories.indexOf(randomAccessory);
        _accessoryController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Surprise outfit generated!')),
      );
    } catch (e) {
      AppLogger.error('❌ Failed to generate surprise outfit', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate surprise outfit')),
      );
    }
  }

  Future<void> _saveOutfit() async {
    AppLogger.info('💾 Save outfit tapped');

    final selections = ref.read(
      swipe_planner_providers.swipeClosetSelectionsProvider,
    );
    final request = ref.read(swipe_planner_providers.swipeRequestProvider);

    if (selections.top == null &&
        selections.bottom == null &&
        selections.footwear == null &&
        selections.accessory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to save')),
      );
      return;
    }

    final itemsToSave = <WardrobeItem>[];
    if (selections.top != null) itemsToSave.add(selections.top!);
    if (selections.bottom != null) itemsToSave.add(selections.bottom!);
    if (selections.footwear != null) itemsToSave.add(selections.footwear!);
    if (selections.accessory != null) itemsToSave.add(selections.accessory!);

    try {
      final outfit = SavedOutfit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: request?.occasion ?? 'Custom Outfit',
        items: itemsToSave.map((item) => item.analysis).toList(),
        notes: request?.notes ?? 'Saved from Swipe Closet',
        occasion: request?.occasion ?? '',
        createdAt: DateTime.now(),
      );

      await _outfitStorage.save(outfit);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Outfit saved to your looks!')),
      );

      // Reset selections after saving
      ref
              .read(
                swipe_planner_providers.swipeClosetSelectionsProvider.notifier,
              )
              .state =
          const swipe_planner_providers.SwipeClosetSelections();
    } catch (e) {
      AppLogger.error('❌ Failed to save outfit', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save outfit')));
    }
  }
}
