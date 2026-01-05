import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/providers/home_providers.dart';
import 'package:vestiq/core/utils/gallery_service.dart';
import 'package:vestiq/features/outfit_suggestions/data/firestore_generation_history_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shows a detail sheet for a saved look
void showLookDetailSheet(BuildContext context, SavedOutfit look) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LookDetailSheet(look: look),
  );
}

class LookDetailSheet extends ConsumerStatefulWidget {
  final SavedOutfit look;
  final bool isHistoryItem;

  const LookDetailSheet({
    super.key,
    required this.look,
    this.isHistoryItem = false,
  });

  @override
  ConsumerState<LookDetailSheet> createState() => _LookDetailSheetState();
}

class _LookDetailSheetState extends ConsumerState<LookDetailSheet> {
  late SavedOutfit _currentLook;
  final OutfitStorageService _outfitStorage = getIt<OutfitStorageService>();

  @override
  void initState() {
    super.initState();
    _currentLook = widget.look;
    AppLogger.info(
      '👗 [LOOK DETAIL] Opening detail for: ${_currentLook.title}',
    );
  }

  Future<void> _shareLook() async {
    final text =
        'Check out this outfit: ${_currentLook.title}\n\n'
        'Match Score: ${(_currentLook.matchScore * 100).toInt()}%\n'
        'Items: ${_currentLook.items.map((e) => "${e.primaryColor} ${e.itemType}").join(", ")}\n\n'
        'Created with Vestiq!';

    // Check if we have a generated image (mannequin)
    if (_currentLook.mannequinImages.isNotEmpty) {
      await Share.share(text);
    } else {
      await Share.share(text);
    }
  }

  Future<void> _downloadLook() async {
    if (_currentLook.mannequinImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image to download')));
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saving image...')));
      }

      final success = await GalleryService.saveDataUrlImageToGallery(
        _currentLook.mannequinImages.first,
        'vestiq_look_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Image saved to gallery!' : 'Failed to save image',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Failed to download look image', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image. Check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Look'),
        content: Text(
          'Are you sure you want to delete "${_currentLook.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (widget.isHistoryItem) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await getIt<FirestoreGenerationHistoryService>().deleteFromHistory(
              user.uid,
              _currentLook.id,
            );
            if (mounted) {
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from history')),
              );
            }
          }
        } else {
          await _outfitStorage.delete(_currentLook.id);
          ref.invalidate(recentLooksProvider);
          if (mounted) {
            Navigator.pop(context); // Close sheet
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Look deleted')));
          }
        }
      } catch (e) {
        AppLogger.error('❌ Failed to delete look', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete look')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(0),
                  children: [
                    // Header Image Area
                    _buildLookHeader(context, theme),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Actions
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentLook.title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_currentLook.mannequinImages.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.download_outlined),
                                  tooltip: 'Download',
                                  onPressed: _downloadLook,
                                ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                tooltip: 'Share',
                                onPressed: _shareLook,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                                onPressed: _deleteLook,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Score Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(
                                _currentLook.matchScore,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: _getScoreColor(
                                    _currentLook.matchScore,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(_currentLook.matchScore * 100).toInt()}% Match Score',
                                  style: TextStyle(
                                    color: _getScoreColor(
                                      _currentLook.matchScore,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Items in this look',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildItemsGrid(theme),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLookHeader(BuildContext context, ThemeData theme) {
    // If we have a mannequin image, show it big
    if (_currentLook.mannequinImages.isNotEmpty) {
      try {
        return SizedBox(
          height: 350,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _dataUrlToBytes(_currentLook.mannequinImages.first),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: theme.colorScheme.surfaceContainerHighest),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  style: IconButton.styleFrom(backgroundColor: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        // Fallback
      }
    }

    // No mannequin image, show pattern background
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            child: Center(
              child: Icon(
                Icons.checkroom,
                size: 64,
                color: theme.colorScheme.onSecondaryContainer.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.7,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(ThemeData theme) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _currentLook.items.length,
      itemBuilder: (context, index) {
        final item = _currentLook.items[index];
        return _buildItemCard(item, theme);
      },
    );
  }

  Widget _buildItemCard(ClothingAnalysis item, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: item.imagePath != null
                ? Image.file(
                    File(item.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade200),
                  )
                : Container(color: Colors.grey.shade200),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.itemType,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.primaryColor,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.70) return Colors.lightGreen;
    if (score >= 0.50) return Colors.amber;
    return Colors.red;
  }

  Uint8List _dataUrlToBytes(String dataUrl) {
    try {
      String base64Data;
      if (dataUrl.startsWith('data:')) {
        final parts = dataUrl.split(',');
        base64Data = parts.length > 1 ? parts[1] : parts[0];
      } else {
        base64Data = dataUrl;
      }
      base64Data = base64Data.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(base64Data);
    } catch (e) {
      return Uint8List(0);
    }
  }
}
