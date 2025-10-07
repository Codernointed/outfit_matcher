import 'package:flutter/material.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Quick actions bottom sheet for wardrobe items to reduce navigation friction
class WardrobeQuickActionsSheet extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback onPairThisItem;
  final VoidCallback onSurpriseMe;
  final VoidCallback onViewInspiration;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WardrobeQuickActionsSheet({
    super.key,
    required this.item,
    required this.onPairThisItem,
    required this.onSurpriseMe,
    required this.onViewInspiration,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Item preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.displayImagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.analysis.itemType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.analysis.primaryColor} • ${item.analysis.style}',
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

            const Divider(height: 1),

            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildActionTile(
                    context,
                    icon: Icons.auto_awesome,
                    iconColor: theme.colorScheme.primary,
                    title: 'Pair This Item',
                    subtitle: 'Find perfect matches from your closet',
                    onTap: () {
                      AppLogger.ui(
                        'QuickActions',
                        'PairThisItem',
                        data: {'item_id': item.id},
                      );
                      Navigator.pop(context);
                      onPairThisItem();
                    },
                  ),
                  _buildActionTile(
                    context,
                    icon: Icons.shuffle,
                    iconColor: Colors.purple,
                    title: 'Surprise Me',
                    subtitle: 'Get creative outfit suggestions',
                    onTap: () {
                      AppLogger.ui(
                        'QuickActions',
                        'SurpriseMe',
                        data: {'item_id': item.id},
                      );
                      Navigator.pop(context);
                      onSurpriseMe();
                    },
                  ),
                  _buildActionTile(
                    context,
                    icon: Icons.explore,
                    iconColor: Colors.orange,
                    title: 'View Inspiration',
                    subtitle: 'See styling ideas and mannequin looks',
                    onTap: () {
                      AppLogger.ui(
                        'QuickActions',
                        'ViewInspiration',
                        data: {'item_id': item.id},
                      );
                      Navigator.pop(context);
                      onViewInspiration();
                    },
                  ),

                  if (onEdit != null || onDelete != null) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                  ],

                  if (onEdit != null)
                    _buildActionTile(
                      context,
                      icon: Icons.edit_outlined,
                      iconColor: theme.colorScheme.secondary,
                      title: 'Edit Details',
                      subtitle: 'Update tags, notes, and occasions',
                      onTap: () {
                        AppLogger.ui(
                          'QuickActions',
                          'Edit',
                          data: {'item_id': item.id},
                        );
                        Navigator.pop(context);
                        onEdit!();
                      },
                    ),

                  if (onDelete != null)
                    _buildActionTile(
                      context,
                      icon: Icons.delete_outline,
                      iconColor: Colors.red,
                      title: 'Remove from Closet',
                      subtitle: 'Delete this item permanently',
                      onTap: () {
                        AppLogger.ui(
                          'QuickActions',
                          'Delete',
                          data: {'item_id': item.id},
                        );
                        Navigator.pop(context);
                        onDelete!();
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the quick actions sheet
  static Future<void> show(
    BuildContext context, {
    required WardrobeItem item,
    required VoidCallback onPairThisItem,
    required VoidCallback onSurpriseMe,
    required VoidCallback onViewInspiration,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WardrobeQuickActionsSheet(
        item: item,
        onPairThisItem: onPairThisItem,
        onSurpriseMe: onSurpriseMe,
        onViewInspiration: onViewInspiration,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}
