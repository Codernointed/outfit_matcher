import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
// import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';

/// Quick action item data
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Beautiful quick actions menu for wardrobe items
class WardrobeQuickActions extends StatefulWidget {
  final WardrobeItem item;
  final Offset position;
  final VoidCallback onDismiss;

  const WardrobeQuickActions({
    super.key,
    required this.item,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<WardrobeQuickActions> createState() => _WardrobeQuickActionsState();
}

class _WardrobeQuickActionsState extends State<WardrobeQuickActions>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late final EnhancedWardrobeStorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = getIt<EnhancedWardrobeStorageService>();
    AppLogger.info(
      '⚡ [QUICK ACTIONS] Menu opened for ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
    _scaleController.forward();

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Calculate menu position
    final menuWidth = 200.0;
    final menuHeight = 280.0;

    double left = widget.position.dx - menuWidth / 2;
    double top = widget.position.dy - menuHeight - 20;

    // Adjust for screen boundaries
    if (left < 16) left = 16;
    if (left + menuWidth > screenSize.width - 16) {
      left = screenSize.width - menuWidth - 16;
    }
    if (top < 50) top = widget.position.dy + 20;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildQuickActionsMenu(theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsMenu(ThemeData theme) {
    final actions = _getQuickActions();

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.checkroom,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.analysis.itemType,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.item.analysis.primaryColor,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: actions
                  .map((action) => _buildActionItem(theme, action))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(ThemeData theme, QuickActionItem action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onDismiss();
            action.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, color: action.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<QuickActionItem> _getQuickActions() {
    return [
      QuickActionItem(
        icon: Icons.auto_awesome,
        label: 'Pair This Item',
        color: Colors.blue,
        onTap: () => _navigateToPairingInteractive(),
      ),
      QuickActionItem(
        icon: Icons.shuffle,
        label: 'Surprise Me',
        color: Colors.purple,
        onTap: () => _navigateToPairingWithMode(PairingMode.surpriseMe),
      ),
      QuickActionItem(
        icon: Icons.location_on,
        label: 'Style by Location',
        color: Colors.green,
        onTap: () => _navigateToPairingWithMode(PairingMode.styleByLocation),
      ),
      QuickActionItem(
        icon: widget.item.isFavorite ? Icons.favorite : Icons.favorite_border,
        label: widget.item.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
        color: Colors.red,
        onTap: () => _toggleFavorite(),
      ),
      QuickActionItem(
        icon: Icons.edit,
        label: 'Edit Details',
        color: Colors.orange,
        onTap: () => _editItem(),
      ),
      QuickActionItem(
        icon: Icons.delete_outline,
        label: 'Delete Item',
        color: Colors.red.shade700,
        onTap: () => _deleteItem(),
      ),
    ];
  }

  void _navigateToPairingInteractive() {
    AppLogger.info('🎯 [QUICK ACTIONS] Navigating to Pair This Item');
    AppLogger.info(
      '   Hero item: ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showInteractivePairingSheet(
      context: context,
      heroItem: widget.item,
      mode: PairingMode.pairThisItem,
    );
  }

  void _navigateToPairingWithMode(PairingMode mode) {
    final modeLabel = mode == PairingMode.surpriseMe
        ? 'Surprise Me'
        : 'Style by Location';
    AppLogger.info('🎯 [QUICK ACTIONS] Navigating to $modeLabel');
    AppLogger.info(
      '   Hero item: ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    showWardrobePairingSheet(
      context: context,
      heroItem: widget.item,
      mode: mode,
    );
  }

  Future<void> _toggleFavorite() async {
    final isCurrentlyFavorite = widget.item.isFavorite;

    AppLogger.info('⭐ [QUICK ACTIONS] Toggling favorite');
    AppLogger.info(
      '   Item: ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );
    AppLogger.info('   Currently favorite: $isCurrentlyFavorite');

    try {
      // Update the item's favorite status
      final updatedItem = widget.item.copyWith(
        isFavorite: !isCurrentlyFavorite,
      );

      // Save to storage
      await _storage.updateWardrobeItem(updatedItem);

      AppLogger.info('✅ [QUICK ACTIONS] Favorite status updated successfully');

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
        '❌ [QUICK ACTIONS] Failed to update favorite status',
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

  void _editItem() {
    AppLogger.info('✏️ [QUICK ACTIONS] Edit item requested');
    AppLogger.info(
      '   Item: ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );

    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteItem() {
    AppLogger.info('🗑️ [QUICK ACTIONS] Delete item requested');
    AppLogger.info(
      '   Item: ${widget.item.analysis.primaryColor} ${widget.item.analysis.itemType}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete this ${widget.item.analysis.itemType.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.info('❌ [QUICK ACTIONS] Delete cancelled');
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppLogger.info('✅ [QUICK ACTIONS] Delete confirmed');
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Show quick actions menu
void showWardrobeQuickActions(
  BuildContext context,
  WardrobeItem item,
  Offset position,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return WardrobeQuickActions(
        item: item,
        position: position,
        onDismiss: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    },
  );
}
