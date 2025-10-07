import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/utils/logger.dart';

import 'package:vestiq/core/services/wardrobe_pairing_service.dart';

/// Interactive pairing sheet where user manually selects items and gets AI coaching
Future<void> showInteractivePairingSheet({
  required BuildContext context,
  required WardrobeItem heroItem,
  PairingMode mode = PairingMode.pairThisItem,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => InteractivePairingSheet(heroItem: heroItem, mode: mode),
  );
}

class InteractivePairingSheet extends StatefulWidget {
  const InteractivePairingSheet({
    super.key,
    required this.heroItem,
    this.mode = PairingMode.pairThisItem,
  });

  final WardrobeItem heroItem;
  final PairingMode mode;

  @override
  State<InteractivePairingSheet> createState() =>
      _InteractivePairingSheetState();
}

class _InteractivePairingSheetState extends State<InteractivePairingSheet> {
  late final EnhancedWardrobeStorageService _storage;

  List<WardrobeItem> _wardrobeItems = [];
  List<WardrobeItem> _selectedItems = [];
  bool _loading = true;
  String _coachingMessage = '';
  double _currentScore = 0.0;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _storage = getIt<EnhancedWardrobeStorageService>();
    _selectedItems = [widget.heroItem]; // Hero item is always first
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    try {
      final items = await _storage.getWardrobeItems();
      setState(() {
        _wardrobeItems = items
            .where((item) => item.id != widget.heroItem.id)
            .toList();
        _loading = false;
        _coachingMessage = 'Pick items from your wardrobe to build your look';
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load wardrobe',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _loading = false;
        _coachingMessage = 'Unable to load wardrobe. Please try again.';
      });
    }
  }

  void _onItemSelected(WardrobeItem item) {
    setState(() {
      if (_selectedItems.any((i) => i.id == item.id)) {
        // Deselect
        _selectedItems.removeWhere((i) => i.id == item.id);
        _updateCoaching();
      } else {
        // Select
        _selectedItems.add(item);
        _updateCoaching();
      }
    });
  }

  void _updateCoaching() {
    if (_selectedItems.length == 1) {
      _coachingMessage =
          'Great start! Now pick items to pair with your ${widget.heroItem.analysis.itemType.toLowerCase()}';
      _currentScore = 0.0;
      _suggestions = [];
      return;
    }

    // Calculate compatibility
    double totalScore = 0.0;
    int comparisons = 0;

    for (int i = 0; i < _selectedItems.length; i++) {
      for (int j = i + 1; j < _selectedItems.length; j++) {
        totalScore += _selectedItems[i].getCompatibilityScore(
          _selectedItems[j],
        );
        comparisons++;
      }
    }

    _currentScore = comparisons > 0 ? totalScore / comparisons : 0.0;
    final percentage = (_currentScore * 100).round();

    // Generate coaching message
    if (percentage >= 85) {
      _coachingMessage = '✨ Signature-worthy! This combo is fire.';
      _suggestions = [
        'This look is polished and ready to wear',
        'The colors create perfect harmony',
      ];
    } else if (percentage >= 70) {
      _coachingMessage = '👍 Solid match! This works beautifully.';
      _suggestions = _generateImprovementSuggestions();
    } else if (percentage >= 50) {
      _coachingMessage = '🤔 Interesting choice. Want to try something bolder?';
      _suggestions = _generateImprovementSuggestions();
    } else {
      _coachingMessage = '💡 Let\'s refine this. Try swapping one piece.';
      _suggestions = _generateImprovementSuggestions();
    }
  }

  List<String> _generateImprovementSuggestions() {
    final suggestions = <String>[];
    final hero = widget.heroItem;

    // Check what's missing
    final hasTop = _selectedItems.any((item) => _isTop(item));
    final hasBottom = _selectedItems.any((item) => _isBottom(item));
    final hasShoes = _selectedItems.any((item) => _isShoes(item));

    if (!hasTop && !_isTop(hero)) {
      suggestions.add('Add a top to complete the look');
    }
    if (!hasBottom && !_isBottom(hero)) {
      suggestions.add('Try adding bottoms for balance');
    }
    if (!hasShoes && !_isShoes(hero)) {
      suggestions.add('Pick shoes to ground the outfit');
    }

    // Color suggestions
    if (hero.analysis.primaryColor.toLowerCase().contains('black')) {
      suggestions.add('Add a pop of color to brighten it up');
    } else if (hero.analysis.primaryColor.toLowerCase().contains('white')) {
      suggestions.add('Layer textures for visual interest');
    }

    return suggestions.take(3).toList();
  }

  bool _isTop(WardrobeItem item) {
    final type = item.analysis.itemType.toLowerCase();
    return type.contains('top') ||
        type.contains('shirt') ||
        type.contains('blouse') ||
        type.contains('sweater') ||
        type.contains('t-shirt') ||
        type.contains('tee');
  }

  bool _isBottom(WardrobeItem item) {
    final type = item.analysis.itemType.toLowerCase();
    return type.contains('bottom') ||
        type.contains('pants') ||
        type.contains('jeans') ||
        type.contains('skirt') ||
        type.contains('shorts') ||
        type.contains('trousers');
  }

  bool _isShoes(WardrobeItem item) {
    final type = item.analysis.itemType.toLowerCase();
    return type.contains('shoe') ||
        type.contains('sneaker') ||
        type.contains('boot') ||
        type.contains('sandal') ||
        type.contains('heel');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.75,
      maxChildSize: 0.98,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHandle(theme),
                _buildHeader(theme),
                if (_selectedItems.length > 1) _buildCoachingCard(theme),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(theme, controller),
                ),
                _buildBottomBar(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pair This Item',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _coachingMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingCard(ThemeData theme) {
    final percentage = (_currentScore * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(102),
            theme.colorScheme.primaryContainer.withAlpha(51),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(51),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage% Match',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                percentage >= 85 ? Icons.auto_awesome : Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ],
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._suggestions.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(204),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Selected items section
        Text(
          'Your Look (${_selectedItems.length} ${_selectedItems.length == 1 ? 'item' : 'items'})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _selectedItems
              .map((item) => _buildSelectedItemChip(theme, item))
              .toList(),
        ),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),

        // Wardrobe items
        Text(
          'Pick from Your Wardrobe',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: _wardrobeItems.length,
          itemBuilder: (context, index) {
            final item = _wardrobeItems[index];
            final isSelected = _selectedItems.any((i) => i.id == item.id);
            return _buildWardrobeItemCard(theme, item, isSelected);
          },
        ),
        const SizedBox(height: 100), // Space for bottom bar
      ],
    );
  }

  Widget _buildSelectedItemChip(ThemeData theme, WardrobeItem item) {
    final isHero = item.id == widget.heroItem.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHero
            ? theme.colorScheme.primary.withAlpha(26)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isHero
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHero)
            Icon(Icons.star, size: 16, color: theme.colorScheme.primary),
          if (isHero) const SizedBox(width: 4),
          Text(
            item.analysis.subcategory ?? item.analysis.itemType,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHero ? FontWeight.w700 : FontWeight.w500,
              color: isHero ? theme.colorScheme.primary : null,
            ),
          ),
          if (!isHero) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _onItemSelected(item),
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWardrobeItemCard(
    ThemeData theme,
    WardrobeItem item,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _onItemSelected(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withAlpha(51),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child:
                  (item.polishedImagePath?.isNotEmpty ?? false) &&
                      File(item.polishedImagePath!).existsSync()
                  ? Image.file(
                      File(item.polishedImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : item.originalImagePath.isNotEmpty &&
                        File(item.originalImagePath).existsSync()
                  ? Image.file(
                      File(item.originalImagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.checkroom,
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _selectedItems.length > 1
              ? () {
                  // Save outfit logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Outfit saved with ${_selectedItems.length} items!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _selectedItems.length > 1
                ? 'Save This Look'
                : 'Select items to continue',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
