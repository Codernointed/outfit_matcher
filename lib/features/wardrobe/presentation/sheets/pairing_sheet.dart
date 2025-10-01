import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/logger.dart';

Future<void> showWardrobePairingSheet({
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
    builder: (_) => WardrobePairingSheet(heroItem: heroItem, mode: mode),
  );
}

class WardrobePairingSheet extends StatefulWidget {
  const WardrobePairingSheet({
    super.key,
    required this.heroItem,
    required this.mode,
  });

  final WardrobeItem heroItem;
  final PairingMode mode;

  @override
  State<WardrobePairingSheet> createState() => _WardrobePairingSheetState();
}

class _WardrobePairingSheetState extends State<WardrobePairingSheet> {
  late final EnhancedWardrobeStorageService _storage;
  late final WardrobePairingService _pairingService;

  List<OutfitPairing> _pairings = const [];
  int _selectedIndex = 0;
  bool _loading = true;
  bool _saving = false;
  bool _previewLoading = false;
  bool _refreshing = false;
  String? _statusMessage;

  OutfitPairing get _selectedPairing => _pairings[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _storage = getIt<EnhancedWardrobeStorageService>();
    _pairingService = getIt<WardrobePairingService>();
    _loadPairings();
  }

  Future<void> _loadPairings({bool shuffle = false}) async {
    setState(() {
      _loading = !shuffle;
      _refreshing = shuffle;
      _statusMessage =
          shuffle ? 'Refreshing looks...' : 'Analyzing your wardrobe...';
    });

    try {
      List<WardrobeItem> items = await _storage.getWardrobeItems();
      if (!items.any((item) => item.id == widget.heroItem.id)) {
        items = [widget.heroItem, ...items];
      }

      // Check if only one item exists (just the hero item)
      if (items.length == 1) {
        if (!mounted) return;
        setState(() {
          _pairings = [];
          _loading = false;
          _refreshing = false;
          _statusMessage = null;
        });
        return;
      }

      final pairings = await _pairingService.generatePairings(
        heroItem: widget.heroItem,
        wardrobeItems: items,
        mode: widget.mode,
        onProgress: (status) {
          if (!mounted) return;
          setState(() => _statusMessage = status);
        },
      );

      if (!mounted) return;
      setState(() {
        _pairings = pairings.isNotEmpty ? pairings : const [];
        _selectedIndex = pairings.isNotEmpty ? 0 : 0;
        _loading = false;
        _refreshing = false;
        _statusMessage =
            pairings.isEmpty
                ? 'Add one more piece to your closet to unlock ready-to-wear looks.'
                : null;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Unable to generate wardrobe pairings',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _statusMessage =
            'We ran into an issue creating looks. Please try again in a moment.';
      });
    }
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
                if (_statusMessage != null)
                  _buildStatusBanner(theme, controller),
                Expanded(
                  child:
                      _loading
                          ? _buildLoading(theme)
                          : _pairings.isEmpty
                          ? _buildSingleItemSuggestions(theme, controller)
                          : _buildContent(theme, controller),
                ),
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

  Widget _buildStatusBanner(ThemeData theme, ScrollController controller) {
    if (_statusMessage == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(64),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child:
                _loading || _refreshing
                    ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    )
                    : Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Styling your wardrobe...', style: theme.textTheme.titleMedium),
          if (_statusMessage != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleItemSuggestions(ThemeData theme, ScrollController controller) {
    final hero = widget.heroItem;
    final analysis = hero.analysis;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        _buildHeroSummary(theme),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(102),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Styling suggestions for your ${analysis.subcategory ?? analysis.itemType.toLowerCase()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._generateSingleItemSuggestions(hero).map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(128),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add more items to your wardrobe to get complete outfit pairings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _generateSingleItemSuggestions(WardrobeItem item) {
    final suggestions = <String>[];
    final itemType = item.analysis.itemType.toLowerCase();
    final subcategory = item.analysis.subcategory?.toLowerCase() ?? '';
    final color = item.analysis.primaryColor.toLowerCase();
    final formality = item.analysis.formality?.toLowerCase() ?? '';

    // Item-specific pairing suggestions
    if (itemType.contains('top') || subcategory.contains('shirt') || subcategory.contains('blouse')) {
      suggestions.add('Pair with ${formality == 'formal' ? 'tailored trousers or a pencil skirt' : 'jeans or casual pants'} for a balanced look');
      suggestions.add('Add ${color.contains('black') || color.contains('white') ? 'colorful' : 'neutral'} bottoms to complement the $color tone');
      if (subcategory.contains('button')) {
        suggestions.add('Roll sleeves to the elbow and tuck into high-waisted bottoms for effortless style');
      }
    } else if (itemType.contains('bottom') || subcategory.contains('pants') || subcategory.contains('jeans') || subcategory.contains('skirt')) {
      suggestions.add('Match with a ${formality == 'formal' ? 'crisp button-up or structured blouse' : 'casual tee or relaxed top'}');
      suggestions.add('Choose ${color.contains('dark') ? 'lighter tops to create contrast' : 'complementary colors for harmony'}');
      if (subcategory.contains('jeans')) {
        suggestions.add('Cuff the hem and pair with sneakers for casual vibes, or heels for elevated style');
      }
    } else if (itemType.contains('dress')) {
      suggestions.add('Layer with a denim jacket for casual outings or a blazer for formal events');
      suggestions.add('Add a belt at the waist to define your silhouette');
      suggestions.add('Complete with ${formality == 'formal' ? 'heels and minimal jewelry' : 'sneakers or sandals for relaxed elegance'}');
    } else if (itemType.contains('shoe') || subcategory.contains('sneaker') || subcategory.contains('boot')) {
      suggestions.add('Build outfits around these shoes - they set the tone for ${formality == 'formal' ? 'polished, professional looks' : 'casual, comfortable styling'}');
      suggestions.add('Balance the footwear with ${subcategory.contains('sneaker') ? 'streamlined pieces to let them pop' : 'complementary textures and proportions'}');
    }

    // Color-specific suggestions
    if (color.contains('black')) {
      suggestions.add('Black is versatile - pair with any color palette, or go monochrome for sleek sophistication');
    } else if (color.contains('white') || color.contains('cream')) {
      suggestions.add('White brightens any outfit - mix with earth tones or bold colors for visual interest');
    } else if (color.contains('blue')) {
      suggestions.add('Blue pairs beautifully with neutrals, whites, and warm earth tones');
    }

    // General styling tips
    suggestions.add('Consider the occasion - dress it up with structured pieces or down with relaxed fits');
    suggestions.add('Play with proportions - fitted $itemType works well with looser complementary pieces');

    return suggestions.take(5).toList();
  }

  Widget _buildContent(ThemeData theme, ScrollController controller) {
    final pairing = _selectedPairing;
    final tips = _extractStylingTips(pairing);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _buildHeroSummary(theme),
        const SizedBox(height: 12),
        _buildWingmanMoment(theme),
        const SizedBox(height: 12),
        _buildScoreCard(theme, pairing.compatibilityScore),
        const SizedBox(height: 16),
        _buildLookSummary(theme, pairing),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildStylingTips(theme, tips),
        ],
        const SizedBox(height: 20),
        _buildActions(theme),
        if (_pairings.length > 1) ...[
          const SizedBox(height: 28),
          Text(
            'Other ways to wear it',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildAlternatives(theme),
        ],
      ],
    );
  }

  Widget _buildHeroSummary(ThemeData theme) {
    final hero = widget.heroItem;
    final analysis = hero.analysis;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.35 * 255).round()), // Deprecated surfaceVariant and withOpacity
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWardrobeImage(hero, size: 92),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleCase(analysis.subcategory ?? analysis.itemType),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Primary colour • ${_titleCase(analysis.primaryColor)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((0.65 * 255).round()), // Deprecated withOpacity
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (analysis.formality != null)
                      _buildMetadataChip(
                        theme,
                        _titleCase(analysis.formality!),
                        theme.colorScheme.primary,
                      ),
                    if (hero.occasions.isNotEmpty)
                      _buildMetadataChip(
                        theme,
                        _titleCase(hero.occasions.first),
                        theme.colorScheme.secondary,
                      ),
                    if (analysis.fit != null)
                      _buildMetadataChip(
                        theme,
                        _titleCase(analysis.fit!),
                        theme.colorScheme.tertiary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWingmanMoment(ThemeData theme) {
    final lastWorn = widget.heroItem.lastWorn;
    final wearCount = widget.heroItem.wearCount;

    String headline;
    String subtitle;

    if (lastWorn != null) {
      headline = 'Bring it back in style';
      subtitle =
          'You last wore this ${_formatRelativeTime(lastWorn)}. Let’s give it a fresh spin today.';
    } else if (wearCount > 0) {
      headline = 'A trusted favourite';
      subtitle =
          'This piece has served you $wearCount times. Here’s how to keep it feeling new.';
    } else {
      headline = 'First styling session';
      subtitle =
          'You haven’t debuted this yet. Let’s plan a look that feels effortless and premium.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha((0.4 * 255).round()), // Deprecated withOpacity
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.72 * 255).round()), // Deprecated withOpacity
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme, double score) {
    final percentage = (score.clamp(0, 1) * 100).round();
    String verdict;
    if (percentage >= 85) {
      verdict = 'Signature-worthy pairing';
    } else if (percentage >= 70) {
      verdict = 'Confident everyday combo';
    } else {
      verdict = 'Solid base — add a personal twist';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha((0.2 * 255).round())), // Deprecated withOpacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$percentage%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' match',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()), // Deprecated withOpacity
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(verdict, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: score.clamp(0, 1),
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withAlpha((0.12 * 255).round()), // Deprecated withOpacity
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    ); // Closing brace for _buildScoreCard
  }

  Widget _buildLookSummary(ThemeData theme, OutfitPairing pairing) {
    final supporting = pairing.items.where((item) => item.id != widget.heroItem.id).toList();
    final isSuggestion = pairing.metadata['isSuggestion'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSuggestion ? 'Styling suggestions' : 'Today\'s play',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildItemRow(theme, widget.heroItem, label: 'Hero piece'),
          ...supporting.map((item) => _buildItemRow(theme, item, label: _slotLabelForItem(item))),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    ThemeData theme,
    WardrobeItem item, {
    required String label,
  }) {
    final analysis = item.analysis;
    return Row(
      children: [
        _buildWardrobeImage(item, size: 64),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha((0.55 * 255).round()), // Deprecated withOpacity
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _titleCase(analysis.subcategory ?? analysis.itemType),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _titleCase(analysis.primaryColor),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha((0.65 * 255).round()), // Deprecated withOpacity
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStylingTips(ThemeData theme, List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stylist whispers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children:
              tips
                  .map(
                    (tip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(
                          (0.25 * 255).round(),
                        ), // Deprecated withOpacity
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        tip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final pairing = _selectedPairing;
    final bool hasPreview = pairing.mannequinImageUrl != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _handleSave,
            icon:
                _saving
                    ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                    : const Icon(Icons.bookmark_added_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_saving ? 'Saving look...' : 'Save this look'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _previewLoading ? null : _handlePreview,
            icon:
                _previewLoading
                    ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                    : Icon(hasPreview ? Icons.image : Icons.image_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _previewLoading
                    ? 'Rendering mannequin...'
                    : hasPreview
                    ? 'View mannequin preview'
                    : 'Generate mannequin preview',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _refreshing ? null : () => _loadPairings(shuffle: true),
          icon: const Icon(Icons.refresh),
          label: Text(
            _refreshing ? 'Shuffling looks...' : 'Shuffle more ideas',
          ),
        ),
      ],
    );
  }

  Widget _buildAlternatives(ThemeData theme) {
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pairings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pairing = _pairings[index];
          final isSelected = index == _selectedIndex;
          final isTight = pairing.metadata['isTight'] as bool? ?? true;
          
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() => _selectedIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color:
                    isSelected
                        ? theme.colorScheme.primary.withAlpha((0.14 * 255).round()) // Deprecated withOpacity
                        : theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()), // Deprecated surfaceVariant and withOpacity
                border: Border.all(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Look ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Tight/Loose badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isTight 
                              ? theme.colorScheme.primary.withAlpha((0.15 * 255).round()) // Deprecated withOpacity
                              : theme.colorScheme.secondary.withAlpha((0.15 * 255).round()), // Deprecated withOpacity
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isTight ? 'TIGHT' : 'LOOSE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isTight 
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(pairing.compatibilityScore.clamp(0, 1) * 100).round()}% match',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()), // Deprecated withOpacity
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          pairing.items
                              .take(3)
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _buildWardrobeImage(
                                    item,
                                    size: 48,
                                    borderRadius: 12,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pairing.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    final pairing = _selectedPairing;
    final title = _buildLookTitle(pairing);

    try {
      await _storage.saveWardrobeLook(WardrobeLook(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        itemIds: pairing.items.map((item) => item.id).toList(),
        imageUrl: pairing.mannequinImageUrl,
        generationMode: pairing.generationMode.name,
        createdAt: DateTime.now(),
        metadata: pairing.metadata,
      ));

      final now = DateTime.now();
      await Future.wait(
        pairing.items.map(
          (item) => _storage.updateWardrobeItem(
            item.copyWith(lastWorn: now, wearCount: item.wearCount + 1),
          ),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$title" to your looks'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save wardrobe look',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn’t save that look. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handlePreview() async {
    if (_previewLoading) return;
    setState(() => _previewLoading = true);

    try {
      var pairing = _selectedPairing;
      String? imageUrl = pairing.mannequinImageUrl;

      if (imageUrl == null) {
        final outfits = await GeminiApiService.generateEnhancedMannequinOutfits(
          pairing.items.map((item) => item.analysis).toList(),
          userNotes: pairing.metadata['stylingNotes'] as String?,
        );

        if (outfits.isNotEmpty) {
          imageUrl = outfits.first.imageUrl;
          final updated = pairing.copyWith(mannequinImageUrl: imageUrl);
          setState(() {
            _pairings[_selectedIndex] = updated;
          });
          pairing = updated;
        }
      }

      if (!mounted) return;

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We couldn’t render a mannequin for this look just yet.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _buildMannequinImage(imageUrl!),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'A polished preview of your look',
                    style: Theme.of(dialogContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to render mannequin preview',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preview unavailable right now. Try again soon.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  String _buildLookTitle(OutfitPairing pairing) {
    final occasions = widget.heroItem.occasions;
    final focus =
        occasions.isNotEmpty
            ? _titleCase(occasions.first)
            : _titleCase(widget.heroItem.analysis.formality ?? 'styled');
    return 'Look ${_selectedIndex + 1} • $focus moment';
  }

  Widget _buildMannequinImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }

    final data = _decodeDataUrl(imageUrl);
    return Image.memory(data, fit: BoxFit.cover);
  }

  List<String> _extractStylingTips(OutfitPairing pairing) {
    final tips = pairing.metadata['stylingTips'];
    if (tips is List) {
      return tips
          .map((tip) => tip.toString())
          .where((tip) => tip.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  Widget _buildWardrobeImage(
    WardrobeItem item, {
    double size = 72,
    double borderRadius = 18,
  }) {
    final file = File(item.displayImagePath);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.black.withAlpha((0.05 * 255).round()), // Deprecated withOpacity
      ),
      child: Icon(Icons.image_outlined, color: Colors.black.withAlpha((0.3 * 255).round())), // Deprecated withOpacity
    );

    Widget imageWidget;
    if (file.existsSync()) {
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      imageWidget = placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: imageWidget),
    );
  }

  String _slotLabelForItem(WardrobeItem item) {
    final type = item.analysis.itemType.toLowerCase();
    if (type.contains('top') ||
        type.contains('shirt') ||
        type.contains('blouse')) {
      return 'Top pairing';
    }
    if (type.contains('bottom') ||
        type.contains('pants') ||
        type.contains('jeans') ||
        type.contains('skirt')) {
      return 'Bottom';
    }
    if (type.contains('shoe') ||
        type.contains('footwear') ||
        type.contains('boot') ||
        type.contains('sneaker')) {
      return 'Footwear';
    }
    if (type.contains('outer') ||
        type.contains('coat') ||
        type.contains('jacket')) {
      return 'Layer';
    }
    if (type.contains('accessory') ||
        type.contains('belt') ||
        type.contains('bag') ||
        type.contains('jewelry')) {
      return 'Finishing touch';
    }
    return _titleCase(item.analysis.itemType);
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'about a month ago' : '$months months ago';
    }
    if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'last week' : '$weeks weeks ago';
    }
    if (difference.inDays >= 1) {
      return difference.inDays == 1
          ? 'yesterday'
          : '${difference.inDays} days ago';
    }
    if (difference.inHours >= 1) {
      return difference.inHours == 1
          ? 'about an hour ago'
          : '${difference.inHours} hours ago';
    }
    return 'just now';
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    if (!dataUrl.contains(',')) {
      return base64Decode(dataUrl);
    }
    final base64Part = dataUrl.split(',').last;
    return base64Decode(base64Part);
  }

  Widget _buildMetadataChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}