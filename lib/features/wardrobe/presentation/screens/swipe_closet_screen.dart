import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/swipe_closet_request.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/features/wardrobe/presentation/providers/swipe_planner_providers.dart'
    as swipe_planner_providers;
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current selection preview
          if (selections.top != null ||
              selections.bottom != null ||
              selections.footwear != null ||
              selections.accessory != null)
            _buildSelectionPreview(theme, selections),

          const SizedBox(height: 24),

          // Tops section
          if (pools.tops.isNotEmpty) ...[
            Text(
              'Tops',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
            Text(
              'Bottoms',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
            Text(
              'Shoes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
            Text(
              'Accessories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

  Widget _buildSwipeRow(
    ThemeData theme,
    List<WardrobeItem> items,
    PageController controller,
    Function(WardrobeItem) onItemSelected,
  ) {
    return SizedBox(
      height: 170,
      width: 200,
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        onPageChanged: (index) {
          onItemSelected(items[index]);
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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

    final request = ref.read(swipe_planner_providers.swipeRequestProvider);

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please plan an outfit first')),
      );
      return;
    }

    // Use existing wardrobe pairing service to generate a surprise combination
    try {
      final storage = getIt<EnhancedWardrobeStorageService>();
      final wardrobeItems = await storage.getWardrobeItems();

      if (wardrobeItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add some items to your closet first')),
        );
        return;
      }

      // Filter items based on the request
      final filteredItems = await storage.getFilteredWardrobeItems(
        occasion: request.occasion,
        mood: request.mood,
        weather: request.weather,
        colorPreference: request.colorPreference,
        gender: request.gender,
      );

      if (filteredItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No items match your occasion. Try adjusting your preferences.',
            ),
          ),
        );
        return;
      }

      // Create a temporary hero item from the first available item
      final heroItem = filteredItems.first;

      // Generate surprise pairings using the existing service
      final pairingService = getIt<WardrobePairingService>();
      final pairings = await pairingService.generatePairings(
        heroItem: heroItem,
        wardrobeItems: filteredItems,
        mode: PairingMode.surpriseMe,
      );

      if (pairings.isNotEmpty) {
        final surprisePairing = pairings.first;

        // Update the selections with the surprise outfit
        ref
            .read(
              swipe_planner_providers.swipeClosetSelectionsProvider.notifier,
            )
            .state = swipe_planner_providers.SwipeClosetSelections(
          top: surprisePairing.items
              .where(
                (item) => item.analysis.itemType.toLowerCase().contains('top'),
              )
              .firstOrNull,
          bottom: surprisePairing.items
              .where(
                (item) =>
                    item.analysis.itemType.toLowerCase().contains('bottom'),
              )
              .firstOrNull,
          footwear: surprisePairing.items
              .where(
                (item) =>
                    item.analysis.itemType.toLowerCase().contains('shoe') ||
                    item.analysis.itemType.toLowerCase().contains('footwear'),
              )
              .firstOrNull,
          accessory: surprisePairing.items
              .where(
                (item) =>
                    item.analysis.itemType.toLowerCase().contains('accessory'),
              )
              .firstOrNull,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Surprise outfit generated!')),
        );
      }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save outfit')));
    }
  }
}
