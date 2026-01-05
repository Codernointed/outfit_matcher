import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/outfit_suggestions/data/firestore_generation_history_service.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/sheets/look_detail_sheet.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';

/// Provider for the user's generation history
final generationHistoryProvider = StreamProvider.autoDispose<List<SavedOutfit>>(
  (ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return Stream.value([]);

    final historyService = getIt<FirestoreGenerationHistoryService>();
    return historyService.watchHistory(user.uid);
  },
);

class GenerationHistoryScreen extends ConsumerWidget {
  const GenerationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(generationHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generation History'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: historyAsync.when(
        data: (outfits) {
          if (outfits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate outfits to see them here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultSpacing),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfit = outfits[index];
              final isLast = index == outfits.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: _buildHistoryCard(context, outfit),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error(
            'Error loading history',
            error: error,
            stackTrace: stack,
          );
          return Center(
            child: Text('Error loading history: ${error.toString()}'),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, SavedOutfit outfit) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat.yMMMd().add_jm().format(outfit.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          _showDetails(context, outfit);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Hero(
                tag: 'history_thumb_${outfit.id}',
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                    image: outfit.mannequinImages.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              outfit.mannequinImages.first,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: outfit.mannequinImages.isEmpty
                      ? Icon(
                          Icons.checkroom,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfit.title.isNotEmpty
                          ? outfit.title
                          : 'Generated Outfit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (outfit.style.isNotEmpty)
                          _buildChip(theme, outfit.style, Colors.blue),
                        _buildChip(
                          theme,
                          '${outfit.items.length} items',
                          Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, SavedOutfit outfit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LookDetailSheet(
        look: outfit,
        isHistoryItem: true, // We will add this flag to LookDetailSheet
      ),
    );
  }
}
