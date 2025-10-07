import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';

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

class CleanItemPreviewSheet extends ConsumerWidget {
  final WardrobeItem item;
  final String heroTag;

  const CleanItemPreviewSheet({
    super.key,
    required this.item,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

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
    return Hero(
      tag: heroTag,
      child: Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _buildImage(theme),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    final imagePath = item.displayImagePath;

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
        ),
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
                item.analysis.subcategory ?? item.analysis.itemType,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.analysis.primaryColor} • ${item.analysis.style}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            item.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: item.isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            // TODO: Toggle favorite
          },
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
          item.analysis.material ?? 'Material',
          Icons.texture,
        ),
        _buildDetailChip(
          theme,
          item.analysis.fit ?? 'Regular fit',
          Icons.checkroom,
        ),
        _buildDetailChip(
          theme,
          item.analysis.formality ?? 'Casual',
          Icons.style,
        ),
        if (item.occasions.isNotEmpty)
          ...item.occasions
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
            heroItem: item,
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
          _buildStatItem(theme, '${item.wearCount}x', 'Worn', Icons.repeat),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withAlpha(51),
          ),
          _buildStatItem(
            theme,
            _formatDate(item.createdAt),
            'Added',
            Icons.calendar_today,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withAlpha(51),
          ),
          _buildStatItem(
            theme,
            '${(item.analysis.confidence * 5).toStringAsFixed(1)}⭐',
            'Rating',
            Icons.star,
          ),
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
      heroItem: item,
      mode: PairingMode.surpriseMe,
    );
  }

  void _navigateToInspiration(BuildContext context) {
    // TODO: Navigate to inspiration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('View Inspiration coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
