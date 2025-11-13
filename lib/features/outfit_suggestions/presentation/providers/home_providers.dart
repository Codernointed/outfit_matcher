import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/services/favorites_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';

// ============================================================================
// STATE CLASSES
// ============================================================================

/// Base sealed class for home screen state
sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeReady extends HomeState {
  final QuickIdeasState quickIdeas;
  final RecentLooksState recentLooks;
  final TodaysPicksState todaysPicks;
  final WardrobeSnapshotState wardrobe;
  final bool isDarkMode;

  const HomeReady({
    required this.quickIdeas,
    required this.recentLooks,
    required this.todaysPicks,
    required this.wardrobe,
    this.isDarkMode = false,
  });

  HomeReady copyWith({
    QuickIdeasState? quickIdeas,
    RecentLooksState? recentLooks,
    TodaysPicksState? todaysPicks,
    WardrobeSnapshotState? wardrobe,
    bool? isDarkMode,
  }) {
    return HomeReady(
      quickIdeas: quickIdeas ?? this.quickIdeas,
      recentLooks: recentLooks ?? this.recentLooks,
      todaysPicks: todaysPicks ?? this.todaysPicks,
      wardrobe: wardrobe ?? this.wardrobe,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  final VoidCallback? retry;

  const HomeError(this.message, {this.retry});
}

// ============================================================================
// SUB-STATE CLASSES
// ============================================================================

class QuickIdeasState {
  final List<QuickIdeaCard> ideas;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, bool> hasNewSuggestions; // occasion -> hasNew

  const QuickIdeasState({
    this.ideas = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasNewSuggestions = const {},
  });

  QuickIdeasState copyWith({
    List<QuickIdeaCard>? ideas,
    bool? isLoading,
    String? errorMessage,
    Map<String, bool>? hasNewSuggestions,
  }) {
    return QuickIdeasState(
      ideas: ideas ?? this.ideas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasNewSuggestions: hasNewSuggestions ?? this.hasNewSuggestions,
    );
  }
}

class QuickIdeaCard {
  final String occasion;
  final String icon;
  final String bgColor;
  final String iconColor;
  final bool hasNewSuggestions;

  const QuickIdeaCard({
    required this.occasion,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.hasNewSuggestions = false,
  });
}

class RecentLooksState {
  final List<SavedOutfit> looks;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> favoriteIds;

  const RecentLooksState({
    this.looks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.favoriteIds = const {},
  });

  RecentLooksState copyWith({
    List<SavedOutfit>? looks,
    bool? isLoading,
    String? errorMessage,
    Set<String>? favoriteIds,
  }) {
    return RecentLooksState(
      looks: looks ?? this.looks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

class TodaysPicksState {
  final List<OutfitPairing> todayPicks;
  final List<OutfitPairing> tonightPicks;
  final bool isLoading;
  final String? errorMessage;
  final TodayTab activeTab;

  const TodaysPicksState({
    this.todayPicks = const [],
    this.tonightPicks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeTab = TodayTab.today,
  });

  TodaysPicksState copyWith({
    List<OutfitPairing>? todayPicks,
    List<OutfitPairing>? tonightPicks,
    bool? isLoading,
    String? errorMessage,
    TodayTab? activeTab,
  }) {
    return TodaysPicksState(
      todayPicks: todayPicks ?? this.todayPicks,
      tonightPicks: tonightPicks ?? this.tonightPicks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

enum TodayTab { today, tonight }

class WardrobeSnapshotState {
  final List<WardrobeItem> items;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMoreItems;

  const WardrobeSnapshotState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMoreItems = false,
  });

  WardrobeSnapshotState copyWith({
    List<WardrobeItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool? hasMoreItems,
  }) {
    return WardrobeSnapshotState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for Quick Outfit Ideas state
final quickIdeasProvider =
    StateNotifierProvider<QuickIdeasNotifier, QuickIdeasState>((ref) {
      return QuickIdeasNotifier();
    });

class QuickIdeasNotifier extends StateNotifier<QuickIdeasState> {
  QuickIdeasNotifier() : super(const QuickIdeasState()) {
    _initialize();
  }

  void _initialize() {
    AppLogger.info('🎯 [QUICK IDEAS] Initializing...');

    // Define the 4 quick idea cards
    final ideas = [
      const QuickIdeaCard(
        occasion: 'Casual',
        icon: 'weekend_rounded',
        bgColor: '#E3F2FD',
        iconColor: '#1976D2',
      ),
      const QuickIdeaCard(
        occasion: 'Work',
        icon: 'business_center_rounded',
        bgColor: '#F3E5F5',
        iconColor: '#7B1FA2',
      ),
      const QuickIdeaCard(
        occasion: 'Date',
        icon: 'favorite_rounded',
        bgColor: '#FCE4EC',
        iconColor: '#C2185B',
      ),
      const QuickIdeaCard(
        occasion: 'Party',
        icon: 'celebration_rounded',
        bgColor: '#FFF3E0',
        iconColor: '#F57C00',
      ),
    ];

    state = state.copyWith(ideas: ideas);
    AppLogger.info('✅ [QUICK IDEAS] Initialized with ${ideas.length} cards');
  }

  void markAsViewed(String occasion) {
    AppLogger.info('👁️ [QUICK IDEAS] Marking $occasion as viewed');
    final updated = Map<String, bool>.from(state.hasNewSuggestions);
    updated[occasion] = false;
    state = state.copyWith(hasNewSuggestions: updated);
  }

  void setNewSuggestion(String occasion) {
    AppLogger.info('✨ [QUICK IDEAS] New suggestion available for $occasion');
    final updated = Map<String, bool>.from(state.hasNewSuggestions);
    updated[occasion] = true;
    state = state.copyWith(hasNewSuggestions: updated);
  }
}

/// Provider for Recent Looks state
final recentLooksProvider =
    StateNotifierProvider<RecentLooksNotifier, RecentLooksState>((ref) {
      return RecentLooksNotifier();
    });

class RecentLooksNotifier extends StateNotifier<RecentLooksState> {
  final OutfitStorageService _storage = getIt<OutfitStorageService>();

  RecentLooksNotifier() : super(const RecentLooksState()) {
    loadRecentLooks();
  }

  Future<void> loadRecentLooks() async {
    AppLogger.info('📥 [RECENT LOOKS] Loading...');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final allLooks = await _storage.fetchAll();
      final recentLooks = allLooks.take(6).toList();

      AppLogger.info('✅ [RECENT LOOKS] Loaded ${recentLooks.length} looks');
      state = state.copyWith(looks: recentLooks, isLoading: false);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [RECENT LOOKS] Failed to load',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load recent looks',
      );
    }
  }

  Future<void> toggleFavorite(String outfitId, String uid) async {
    AppLogger.info('⭐ [RECENT LOOKS] Toggling favorite: $outfitId');
    final favorites = Set<String>.from(state.favoriteIds);
    final wasAdded = !favorites.contains(outfitId);

    // Optimistically update UI
    if (favorites.contains(outfitId)) {
      favorites.remove(outfitId);
      AppLogger.info('💔 Removed from favorites');
    } else {
      favorites.add(outfitId);
      AppLogger.info('❤️ Added to favorites');
    }

    state = state.copyWith(favoriteIds: favorites);

    // Persist to Firestore
    try {
      final favoritesService = FavoritesService();
      await favoritesService.toggleFavoriteOutfit(uid, outfitId);
      AppLogger.info('✅ [RECENT LOOKS] Favorite persisted to Firestore');
    } catch (e) {
      AppLogger.error('❌ [RECENT LOOKS] Failed to persist favorite', error: e);
      // Revert on error
      if (wasAdded) {
        favorites.remove(outfitId);
      } else {
        favorites.add(outfitId);
      }
      state = state.copyWith(favoriteIds: favorites);
    }
  }

  Future<void> refresh() async {
    AppLogger.info('🔄 [RECENT LOOKS] Refreshing...');
    await loadRecentLooks();
  }
}

/// Provider for Today's Picks state
final todaysPicksProvider =
    StateNotifierProvider<TodaysPicksNotifier, TodaysPicksState>((ref) {
      return TodaysPicksNotifier();
    });

class TodaysPicksNotifier extends StateNotifier<TodaysPicksState> {
  final EnhancedWardrobeStorageService _wardrobeStorage =
      getIt<EnhancedWardrobeStorageService>();

  TodaysPicksNotifier() : super(const TodaysPicksState()) {
    generatePicks();
  }

  Future<void> generatePicks() async {
    AppLogger.info('🌅 [TODAY PICKS] Generating picks...');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final wardrobeItems = await _wardrobeStorage.getWardrobeItems();

      if (wardrobeItems.isEmpty) {
        AppLogger.warning('⚠️ [TODAY PICKS] No wardrobe items available');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Add items to your wardrobe to get suggestions',
        );
        return;
      }

      // Generate outfit pairings using the pairing service with enhanced AI
      final pairingService = getIt<WardrobePairingService>();

      // Select a hero item for today (prefer recently added or favorites)
      final heroItem = _selectHeroItemForToday(wardrobeItems);

      // Generate daytime outfits (casual, work-appropriate)
      AppLogger.info('☀️ [TODAY PICKS] Generating daytime outfits...');
      final todayOutfits = await pairingService.generatePairings(
        heroItem: heroItem,
        wardrobeItems: wardrobeItems,
        mode: PairingMode.surpriseMe,
        occasion: 'casual',
      );

      // Generate evening outfits (date, party-appropriate)
      AppLogger.info('🌙 [TODAY PICKS] Generating evening outfits...');
      final tonightOutfits = await pairingService.generatePairings(
        heroItem: heroItem,
        wardrobeItems: wardrobeItems,
        mode: PairingMode.surpriseMe,
        occasion: 'party',
      );

      AppLogger.info(
        '✅ [TODAY PICKS] Generated ${todayOutfits.length} day + ${tonightOutfits.length} night picks',
      );
      state = state.copyWith(
        todayPicks: todayOutfits.take(3).toList(),
        tonightPicks: tonightOutfits.take(3).toList(),
        isLoading: false,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [TODAY PICKS] Failed to generate',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate picks',
      );
    }
  }

  /// Select the best hero item for today's picks
  WardrobeItem _selectHeroItemForToday(List<WardrobeItem> items) {
    // Prioritize: favorites > recently added > most worn
    final favorites = items.where((item) => item.isFavorite).toList();
    if (favorites.isNotEmpty) {
      return favorites.first;
    }

    // Sort by creation date (most recent first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.first;
  }

  void setActiveTab(TodayTab tab) {
    AppLogger.info('📑 [TODAY PICKS] Switching to ${tab.name} tab');
    state = state.copyWith(activeTab: tab);
  }

  Future<void> reroll() async {
    AppLogger.info('🎲 [TODAY PICKS] Rerolling suggestions...');
    await generatePicks();
  }
}

/// Provider for Wardrobe Snapshot state
final wardrobeSnapshotProvider =
    StateNotifierProvider.autoDispose<
      WardrobeSnapshotNotifier,
      WardrobeSnapshotState
    >((ref) {
      final notifier = WardrobeSnapshotNotifier();
      notifier.loadSnapshot(); // Ensure it loads on creation
      return notifier;
    });

class WardrobeSnapshotNotifier extends StateNotifier<WardrobeSnapshotState> {
  final EnhancedWardrobeStorageService _storage =
      getIt<EnhancedWardrobeStorageService>();

  WardrobeSnapshotNotifier() : super(const WardrobeSnapshotState()) {
    loadSnapshot();
  }

  Future<void> loadSnapshot() async {
    AppLogger.info('👗 [WARDROBE SNAPSHOT] Loading...');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final allItems = await _storage.getWardrobeItems();
      final snapshotItems = allItems.take(6).toList();

      AppLogger.info(
        '✅ [WARDROBE SNAPSHOT] Loaded ${snapshotItems.length} items',
      );
      state = state.copyWith(
        items: snapshotItems,
        isLoading: false,
        hasMoreItems: allItems.length > 6,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [WARDROBE SNAPSHOT] Failed to load',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load wardrobe',
      );
    }
  }

  Future<void> refresh() async {
    AppLogger.info('🔄 [WARDROBE SNAPSHOT] Refreshing...');
    await loadSnapshot();
  }
}

/// Provider for theme mode
final homeThemeProvider = StateProvider<bool>(
  (ref) => false,
); // false = light, true = dark

/// Provider for search history
final homeSearchHistoryProvider = StateProvider<List<String>>((ref) => []);
