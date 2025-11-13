import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';

// ==================== FILTER CRITERIA MODEL ====================

/// Filter criteria for wardrobe search
class WardrobeFilterCriteria {
  final List<String> categories;
  final List<String> colors;
  final List<String> seasons;
  final List<String> occasions;
  final bool favoritesOnly;

  const WardrobeFilterCriteria({
    this.categories = const [],
    this.colors = const [],
    this.seasons = const [],
    this.occasions = const [],
    this.favoritesOnly = false,
  });

  WardrobeFilterCriteria copyWith({
    List<String>? categories,
    List<String>? colors,
    List<String>? seasons,
    List<String>? occasions,
    bool? favoritesOnly,
  }) {
    return WardrobeFilterCriteria(
      categories: categories ?? this.categories,
      colors: colors ?? this.colors,
      seasons: seasons ?? this.seasons,
      occasions: occasions ?? this.occasions,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  bool get hasActiveFilters =>
      categories.isNotEmpty ||
      colors.isNotEmpty ||
      seasons.isNotEmpty ||
      occasions.isNotEmpty ||
      favoritesOnly;

  /// Check if item matches all active filters
  bool matchesItem(WardrobeItem item) {
    // Check category filter
    if (categories.isNotEmpty && !categories.contains(item.analysis.itemType)) {
      return false;
    }

    // Check color filter
    if (colors.isNotEmpty && !colors.contains(item.analysis.primaryColor)) {
      return false;
    }

    // Check season filter
    if (seasons.isNotEmpty) {
      final itemSeasons = item.seasons;
      if (!seasons.any((season) => itemSeasons.contains(season))) {
        return false;
      }
    }

    // Check occasion filter
    if (occasions.isNotEmpty) {
      final itemOccasions = item.occasions;
      if (!occasions.any((occasion) => itemOccasions.contains(occasion))) {
        return false;
      }
    }

    // Check favorites filter
    if (favoritesOnly && item.isFavorite != true) {
      return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'WardrobeFilterCriteria('
        'categories: $categories, '
        'colors: $colors, '
        'seasons: $seasons, '
        'occasions: $occasions, '
        'favoritesOnly: $favoritesOnly)';
  }
}

// ==================== STATE PROVIDERS ====================

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filter criteria
final filterCriteriaProvider = StateProvider<WardrobeFilterCriteria>((ref) {
  return const WardrobeFilterCriteria();
});

// ==================== SEARCH RESULTS PROVIDER ====================

/// Provider for wardrobe search results with filters
final wardrobeSearchResultsProvider = StreamProvider.autoDispose<List<WardrobeItem>>((
  ref,
) async* {
  try {
    // Get current user
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      AppLogger.info('🔍 No user logged in, returning empty search results');
      yield [];
      return;
    }

    // Watch search query and filter criteria
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(filterCriteriaProvider);

    AppLogger.info('🔍 Search query: "$query", filters: $filters');

    // Get all wardrobe items
    final wardrobeService = getIt<EnhancedWardrobeStorageService>();
    final allItems = await wardrobeService.getWardrobeItems();

    // Apply search query
    List<WardrobeItem> results = allItems;

    if (query.trim().isNotEmpty) {
      final queryLower = query.toLowerCase();
      results = results.where((item) {
        return item.analysis.itemType.toLowerCase().contains(queryLower) ||
            item.analysis.primaryColor.toLowerCase().contains(queryLower) ||
            (item.analysis.brand?.toLowerCase().contains(queryLower) ?? false) ||
            item.seasons.any((tag) => tag.toLowerCase().contains(queryLower)) ||
            item.occasions.any((tag) => tag.toLowerCase().contains(queryLower)) ||
            item.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      }).toList();
    }

    // Apply filters
    if (filters.hasActiveFilters) {
      results = results.where(filters.matchesItem).toList();
    }

    AppLogger.info('🔍 Found ${results.length} items matching search/filters');
    yield results;
  } catch (e) {
    AppLogger.error('❌ Error performing wardrobe search', error: e);
    yield [];
  }
});

/// Provider for quick filter presets
final quickFiltersProvider = Provider<List<QuickFilter>>((ref) {
  return [
    const QuickFilter(
      label: 'Favorites',
      icon: '⭐',
      criteria: WardrobeFilterCriteria(favoritesOnly: true),
    ),
    const QuickFilter(
      label: 'Tops',
      icon: '👕',
      criteria: WardrobeFilterCriteria(categories: ['T-Shirt', 'Shirt', 'Blouse', 'Sweater']),
    ),
    const QuickFilter(
      label: 'Bottoms',
      icon: '👖',
      criteria: WardrobeFilterCriteria(categories: ['Jeans', 'Pants', 'Shorts', 'Skirt']),
    ),
    const QuickFilter(
      label: 'Outerwear',
      icon: '🧥',
      criteria: WardrobeFilterCriteria(categories: ['Jacket', 'Coat', 'Blazer']),
    ),
    const QuickFilter(
      label: 'Shoes',
      icon: '👟',
      criteria: WardrobeFilterCriteria(categories: ['Sneakers', 'Boots', 'Heels', 'Sandals']),
    ),
    const QuickFilter(
      label: 'Summer',
      icon: '☀️',
      criteria: WardrobeFilterCriteria(seasons: ['Summer']),
    ),
    const QuickFilter(
      label: 'Winter',
      icon: '❄️',
      criteria: WardrobeFilterCriteria(seasons: ['Winter']),
    ),
  ];
});

/// Quick filter model
class QuickFilter {
  final String label;
  final String icon;
  final WardrobeFilterCriteria criteria;

  const QuickFilter({
    required this.label,
    required this.icon,
    required this.criteria,
  });
}

// ==================== FILTER OPTIONS PROVIDERS ====================

/// Provider for available category options (extracted from wardrobe)
final availableCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final wardrobeService = getIt<EnhancedWardrobeStorageService>();
  final items = await wardrobeService.getWardrobeItems();
  
  final categories = items.map((item) => item.analysis.itemType).toSet().toList();
  categories.sort();
  
  return categories;
});

/// Provider for available color options
final availableColorsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final wardrobeService = getIt<EnhancedWardrobeStorageService>();
  final items = await wardrobeService.getWardrobeItems();
  
  final colors = items.map((item) => item.analysis.primaryColor).toSet().toList();
  colors.sort();
  
  return colors;
});

/// Provider for available season options
final availableSeasonsProvider = Provider<List<String>>((ref) {
  return ['Spring', 'Summer', 'Fall', 'Winter'];
});

/// Provider for available occasion options
final availableOccasionsProvider = Provider<List<String>>((ref) {
  return ['Casual', 'Formal', 'Work', 'Party', 'Athletic', 'Beach', 'Date Night'];
});
