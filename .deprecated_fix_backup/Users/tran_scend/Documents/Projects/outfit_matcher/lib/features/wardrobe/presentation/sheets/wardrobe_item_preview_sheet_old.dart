import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/sheets/interactive_pairing_sheet.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/item_details_screen.dart';

/// Beautiful preview sheet for wardrobe items with pairing options
class WardrobeItemPreviewSheet extends ConsumerStatefulWidget {
  final WardrobeItem item;
  final String heroTag;

  const WardrobeItemPreviewSheet({
    super.key,
    required this.item,
    required this.heroTag,
  });

  @override
  ConsumerState<WardrobeItemPreviewSheet> createState() =>
      _WardrobeItemPreviewSheetState();
}

class _WardrobeItemPreviewSheetState
    extends ConsumerState<WardrobeItemPreviewSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => _closeSheet(),
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // Background blur effect
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(color: Colors.black54),
              ),

              // Main sheet content
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: screenHeight * 0.85,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSheetHandle(theme),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildItemHeader(theme),
                                const SizedBox(height: 24),
                                _buildItemImage(theme),
                                const SizedBox(height: 24),
                                _buildItemDetails(theme),
                                const SizedBox(height: 32),
                                _buildActionButtons(theme),
                                const SizedBox(height: 24),
                                _buildQuickStats(theme),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildItemHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.analysis.subcategory ??
                    widget.item.analysis.itemType,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.analysis.primaryColor,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Favorite button
        Container(
          decoration: BoxDecoration(
            color: widget.item.isFavorite
                ? Colors.red.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Toggle favorite
            },
            icon: Icon(
              widget.item.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.item.isFavorite
                  ? Colors.red
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(ThemeData theme) {
    return Hero(
      tag: widget.heroTag,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final imagePath = widget.item.displayImagePath;

    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 80,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildItemDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildDetailRow(theme, 'Style', widget.item.analysis.style),
        _buildDetailRow(
          theme,
          'Material',
          widget.item.analysis.material ?? 'Unknown',
        ),
        _buildDetailRow(theme, 'Fit', widget.item.analysis.fit ?? 'Regular'),
        _buildDetailRow(
          theme,
          'Formality',
          widget.item.analysis.formality ?? 'Casual',
        ),

        if (widget.item.occasions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Perfect for',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.occasions.map((occasion) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  occasion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get Outfit Ideas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Compact pill-style action buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPillAction(
              theme: theme,
              icon: Icons.auto_awesome,
              label: 'Pair This Item',
              color: theme.colorScheme.primary,
              onTap: () => _navigateToInteractivePairing(),
              isPrimary: true,
            ),
            _buildPillAction(
              theme: theme,
              icon: Icons.shuffle,
              label: 'Surprise Me',
              color: Colors.purple,
              onTap: () => _navigateToPairing(PairingMode.surpriseMe),
            ),
            _buildPillAction(
              theme: theme,
              icon: Icons.location_on,
              label: 'Style by Location',
              color: Colors.green,
              onTap: () => _navigateToPairing(PairingMode.styleByLocation),
            ),
            _buildPillAction(
              theme: theme,
              icon: Icons.lightbulb_outline,
              label: 'Full Suggestions',
              color: theme.colorScheme.secondary,
              onTap: () => _navigateToSuggestions(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillAction({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: isPrimary
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isPrimary ? Colors.white : color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, 'Worn', '${widget.item.wearCount}x'),
          _buildStatItem(theme, 'Added', _formatDate(widget.item.createdAt)),
          _buildStatItem(
            theme,
            'Rating',
            '${(widget.item.analysis.confidence * 5).toStringAsFixed(1)}⭐',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return '${(difference / 30).floor()}mo ago';
  }

  void _navigateToInteractivePairing() async {
    await _closeSheet();

    if (!mounted) return;

    await showInteractivePairingSheet(context: context, heroItem: widget.item);
  }

  void _navigateToPairing(PairingMode mode) async {
    await _closeSheet();

    if (!mounted) return;

    await showWardrobePairingSheet(
      context: context,
      heroItem: widget.item,
      mode: mode,
    );
  }

  void _navigateToSuggestions() async {
    await _closeSheet();

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ItemDetailsScreen(imagePaths: [widget.item.displayImagePath]),
        ),
      );
    }
  }

  Future<void> _closeSheet() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// Show the wardrobe item preview sheet
Future<void> showWardrobeItemPreview(
  BuildContext context,
  WardrobeItem item, {
  String? heroTag,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return WardrobeItemPreviewSheet(
        item: item,
        heroTag: heroTag ?? 'item_${item.id}',
      );
    },
  );
}
