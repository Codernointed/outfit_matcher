import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Clean, modern preview sheet for wardrobe items
void showWardrobeItemPreview(
  BuildContext context,
  WardrobeItem item, {
  String heroTag = 'wardrobe_item',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CleanItemPreviewSheet(item: item, heroTag: heroTag),
  );
}

class CleanItemPreviewSheet extends ConsumerStatefulWidget {
  final WardrobeItem item;
  final String heroTag;

  const CleanItemPreviewSheet({
    super.key,
    required this.item,
    required this.heroTag,
  });

  @override
  ConsumerState<CleanItemPreviewSheet> createState() =>
      _CleanItemPreviewSheetState();
}

class _CleanItemPreviewSheetState extends ConsumerState<CleanItemPreviewSheet> {
  late WardrobeItem _currentItem;
  late final EnhancedWardrobeStorageService _storage;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _storage = getIt<EnhancedWardrobeStorageService>();
    AppLogger.info(
      '👕 [WARDROBE PREVIEW] Sheet opened for ${_currentItem.analysis.primaryColor} ${_currentItem.analysis.itemType}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(0),
                  children: [
                    // Hero Image
                    _buildHeroImage(context, theme),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Favorite
                          _buildHeader(context, theme),

                          const SizedBox(height: 24),

                          // Quick Details
                          _buildQuickDetails(theme),

                          const SizedBox(height: 32),

                          // Primary Action - Pair This Item
                          _buildPrimaryAction(context, theme),

                          const SizedBox(height: 12),

                          // Secondary Actions
                          Row(
                            children: [
                              Expanded(
                                child: _buildSecondaryAction(
                                  context,
                                  theme,
                                  'Surprise Me',
                                  Icons.shuffle,
                                  Colors.purple,
                                  () => _navigateToSurpriseMe(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSecondaryAction(
                                  context,
                                  theme,
                                  'Inspiration',
                                  Icons.explore,
                                  Colors.orange,
                                  () => _navigateToInspiration(context),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Stats
                          _buildStats(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Hero(
        tag: widget.heroTag,
        child: Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildImage(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    final imagePath = _currentItem.displayImagePath;

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.checkroom,
        size: 80,
        color: theme.colorScheme.onSurface.withAlpha(77),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentItem.analysis.subcategory ??
                    _currentItem.analysis.itemType,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_currentItem.analysis.primaryColor} • ${_currentItem.analysis.style}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _currentItem.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _currentItem.isFavorite ? Colors.red : null,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildQuickDetails(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildDetailChip(
          theme,
          _currentItem.analysis.material ?? 'Material',
          Icons.texture,
        ),
        _buildDetailChip(
          theme,
          _currentItem.analysis.fit ?? 'Regular fit',
          Icons.checkroom,
        ),
        _buildDetailChip(
          theme,
          _currentItem.analysis.formality ?? 'Casual',
          Icons.style,
        ),
        if (_currentItem.occasions.isNotEmpty)
          ..._currentItem.occasions
              .take(2)
              .map(
                (occasion) => _buildDetailChip(
                  theme,
                  occasion,
                  Icons.event,
                  isPrimary: true,
                ),
              ),
      ],
    );
  }

  Widget _buildDetailChip(
    ThemeData theme,
    String label,
    IconData icon, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary
            ? theme.colorScheme.primaryContainer.withAlpha(128)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(153),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isPrimary
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withAlpha(204),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          showInteractivePairingSheet(
            context: context,
            heroItem: _currentItem,
            mode: PairingMode.pairThisItem,
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Pair This Item'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        onTap();
      },
      icon: Icon(icon, size: 20, color: color),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: TextStyle(color: color)),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withAlpha(77)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            '${_currentItem.wearCount}x',
            'Worn',
            Icons.repeat,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withAlpha(51),
          ),
          _buildStatItem(
            theme,
            _formatDate(_currentItem.createdAt),
            'Added',
            Icons.calendar_today,
          ),
          // Container(
          //   width: 1,
          //   height: 40,
          //   color: theme.colorScheme.outline.withAlpha(51),
          // ),
          // _buildStatItem(
          //   theme,
          //   '${(item.analysis.confidence * 5).toStringAsFixed(1)}⭐',
          //   'Rating',
          //   Icons.star,
          // ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()}y ago';
  }

  void _navigateToSurpriseMe(BuildContext context) {
    showWardrobePairingSheet(
      context: context,
      heroItem: _currentItem,
      mode: PairingMode.surpriseMe,
    );
  }

  void _navigateToInspiration(BuildContext context) async {
    AppLogger.info(
      '🎨 [PREVIEW SHEET] Inspiration button tapped for ${_currentItem.analysis.primaryColor} ${_currentItem.analysis.itemType}',
    );

    // Show dialog to add custom styling notes
    final customNotes = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _buildStylingNotesDialog(dialogContext),
    );

    AppLogger.info(
      '📝 [PREVIEW SHEET] Dialog returned: ${customNotes == null ? "null (cancelled)" : "\"$customNotes\""}',
    );

    // If dialog was dismissed (null), don't navigate
    if (customNotes == null) {
      AppLogger.info('👤 [PREVIEW SHEET] User cancelled inspiration dialog');
      return;
    }

    // Check if widget is still mounted before navigation
    if (!mounted) {
      AppLogger.warning('⚠️ [PREVIEW SHEET] Widget unmounted, cannot navigate');
      return;
    }

    // Close the preview sheet first
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Wait a frame to ensure sheet is closed
    await Future.delayed(const Duration(milliseconds: 100));

    // Check context is still valid
    if (!context.mounted) {
      AppLogger.warning(
        '⚠️ [PREVIEW SHEET] Context unmounted after sheet close',
      );
      return;
    }

    // Combine default notes with custom notes
    final finalNotes = [
      if (_currentItem.userNotes != null) _currentItem.userNotes!,
      if (customNotes.isNotEmpty) customNotes,
    ].join('\n\n');

    AppLogger.info(
      '🚀 [PREVIEW SHEET] Navigating to inspiration with notes: "$finalNotes"',
    );

    // Navigate to inspiration screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVisualSearchScreen(
          analyses: [_currentItem.analysis],
          itemImages: [_currentItem.displayImagePath],
          userNotes: finalNotes.isEmpty ? null : finalNotes,
        ),
      ),
    );
  }

  Widget _buildStylingNotesDialog(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    // Pre-fill with item context
    final defaultNotes =
        'Style this ${_currentItem.analysis.primaryColor} ${_currentItem.analysis.itemType}';

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
          onPressed: () {
            AppLogger.info('🔙 [PREVIEW SHEET] Skip button tapped');
            Navigator.pop(context, '');
          },
          child: const Text('Skip'),
        ),
        FilledButton.icon(
          onPressed: () {
            final notes = controller.text.trim();
            AppLogger.info(
              '✅ [PREVIEW SHEET] Generate button tapped with notes: "$notes"',
            );
            Navigator.pop(context, notes);
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate'),
        ),
      ],
    );
  }

  /// Toggle favorite status for the item
  Future<void> _toggleFavorite() async {
    final isCurrentlyFavorite = _currentItem.isFavorite;

    AppLogger.info('⭐ [WARDROBE PREVIEW] Toggling favorite');
    AppLogger.info(
      '   Item: ${_currentItem.analysis.primaryColor} ${_currentItem.analysis.itemType}',
    );
    AppLogger.info('   Currently favorite: $isCurrentlyFavorite');

    try {
      // Update the item's favorite status
      final updatedItem = _currentItem.copyWith(
        isFavorite: !isCurrentlyFavorite,
      );

      // Save to storage
      await _storage.updateWardrobeItem(updatedItem);

      // Update local state
      setState(() {
        _currentItem = updatedItem;
      });

      AppLogger.info(
        '✅ [WARDROBE PREVIEW] Favorite status updated successfully',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorite
                ? 'Removed from favorites'
                : 'Added to favorites ❤️',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isCurrentlyFavorite ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error(
        '❌ [WARDROBE PREVIEW] Failed to update favorite status',
        error: e,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update favorite status. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
