// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vestiq/features/wardrobe/presentation/screens/simple_wardrobe_upload_screen.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:io';
// import 'package:vestiq/features/wardrobe/presentation/screens/upload_options_screen.dart';
// // import 'package:vestiq/features/wardrobe/presentation/screens/closet_screen.dart';
// import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_closet_screen.dart';
// import 'package:vestiq/features/wardrobe/presentation/widgets/dynamic_island_navbar.dart';
// import 'package:vestiq/core/models/saved_outfit.dart';
// import 'package:vestiq/core/models/clothing_analysis.dart';
// import 'package:vestiq/core/models/wardrobe_item.dart';
// import 'package:vestiq/core/utils/logger.dart';
// import 'package:vestiq/features/outfit_suggestions/presentation/providers/home_providers.dart';
// import 'package:vestiq/features/outfit_suggestions/presentation/widgets/customize_mood_sheet.dart';
// import 'package:vestiq/features/outfit_suggestions/presentation/screens/saved_looks_screen.dart';
// import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_search_results_screen.dart';
// import 'package:vestiq/core/di/service_locator.dart';
// import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
// import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
// import 'package:vestiq/core/services/outfit_storage_service.dart';
// import 'package:vestiq/main.dart' show appThemeModeProvider;

// // Provider for the current selected index of the BottomNavigationBar
// final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// class HomeScreen extends ConsumerWidget {
//   HomeScreen({super.key});

//   // List of main screens for IndexedStack
//   final List<Widget> _mainScreens = [
//     const MainContentHomeScreen(),
//     const EnhancedClosetScreen(),
//     const Center(child: Text('Profile Screen - Coming Soon')),
//   ];

//   void _openSearch(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => const HomeSearchResultsScreen()),
//     );
//   }

//   void _openFilters(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => const FilterBottomSheet(),
//     );
//   }

//   void _toggleTheme(WidgetRef ref, BuildContext context) {
//     final currentMode = ref.read(appThemeModeProvider);
//     ref.read(appThemeModeProvider.notifier).toggleTheme();

//     AppLogger.info(
//       '🎨 Toggled theme: ${currentMode == ThemeMode.light ? "dark" : "light"}',
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Switched to ${currentMode == ThemeMode.light ? "dark" : "light"} mode ✨',
//         ),
//         duration: const Duration(milliseconds: 1500),
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final currentIndex = ref.watch(bottomNavIndexProvider);

//     // The body will now be an IndexedStack to switch between screens
//     // The original ListView content of HomeScreen will become its own widget (MainContentHomeScreen)
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         title: Row(
//           children: [
//             Icon(Icons.checkroom, color: theme.colorScheme.primary),
//             const SizedBox(width: 8),
//             Text('vestiq', style: theme.textTheme.titleLarge),
//           ],
//         ),
//         actions: [
//           // Search button
//           IconButton(
//             icon: const Icon(Icons.search_rounded),
//             onPressed: () {
//               AppLogger.info('🔍 Opening search');
//               _openSearch(context);
//             },
//             tooltip: 'Search',
//           ),
//           // Filter button
//           IconButton(
//             icon: const Icon(Icons.tune_rounded),
//             onPressed: () {
//               AppLogger.info('🎛️ Opening filters');
//               _openFilters(context);
//             },
//             tooltip: 'Filters',
//           ),
//           // Theme toggle
//           IconButton(
//             icon: Icon(
//               Theme.of(context).brightness == Brightness.light
//                   ? Icons.dark_mode_outlined
//                   : Icons.light_mode_outlined,
//             ),
//             onPressed: () {
//               _toggleTheme(ref, context);
//             },
//             tooltip: 'Toggle theme',
//           ),
//         ],
//       ),
//       body: IndexedStack(index: currentIndex, children: _mainScreens),
//       bottomNavigationBar: DynamicIslandNavBar(
//         currentIndex: currentIndex,
//         onTap: (index) {
//           ref.read(bottomNavIndexProvider.notifier).state = index;
//         },
//         items: [
//           DynamicIslandNavItem(
//             icon: Icons.home_rounded,
//             activeIcon: Icons.home_rounded,
//             label: 'Home',
//           ),
//           const DynamicIslandNavItem(
//             icon: Icons.checkroom_outlined,
//             activeIcon: Icons.checkroom,
//             label: 'Closet',
//           ),
//           const DynamicIslandNavItem(
//             icon: CupertinoIcons.person,
//             activeIcon: Icons.person,
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class MainContentHomeScreen extends ConsumerStatefulWidget {
//   const MainContentHomeScreen({super.key});

//   @override
//   ConsumerState<MainContentHomeScreen> createState() =>
//       _MainContentHomeScreenState();
// }

// class _MainContentHomeScreenState extends ConsumerState<MainContentHomeScreen> {
//   late final OutfitStorageService _outfitStorage;
//   late final EnhancedWardrobeStorageService _wardrobeStorage;

//   @override
//   void initState() {
//     super.initState();
//     AppLogger.info('🏠 Home screen initialized - using providers');

//     // Set up auto-refresh when outfits are saved
//     _outfitStorage = getIt<OutfitStorageService>();
//     _outfitStorage.addOnChangeListener(_onOutfitStorageChanged);

//     // Set up auto-refresh when wardrobe items are added/removed
//     _wardrobeStorage = getIt<EnhancedWardrobeStorageService>();
//     _wardrobeStorage.addOnChangeListener(_onWardrobeStorageChanged);
//   }

//   @override
//   void dispose() {
//     _outfitStorage.removeOnChangeListener(_onOutfitStorageChanged);
//     _wardrobeStorage.removeOnChangeListener(_onWardrobeStorageChanged);
//     super.dispose();
//   }

//   void _onOutfitStorageChanged() {
//     AppLogger.info('🔄 Outfit storage changed - auto-refreshing recent looks');
//     if (mounted) {
//       ref.invalidate(recentLooksProvider);
//     }
//   }

//   void _onWardrobeStorageChanged() {
//     AppLogger.info(
//       '🔄 Wardrobe storage changed - auto-refreshing wardrobe snapshot',
//     );
//     if (mounted) {
//       ref.invalidate(wardrobeSnapshotProvider);
//       ref.invalidate(
//         todaysPicksProvider,
//       ); // Also refresh today's picks since they depend on wardrobe
//     }
//   }

//   Future<void> _refreshAll() async {
//     AppLogger.info('🔄 Refreshing all home sections...');
//     // Refresh all providers
//     ref.invalidate(recentLooksProvider);
//     ref.invalidate(todaysPicksProvider);
//     ref.invalidate(wardrobeSnapshotProvider);
//   }

//   void _toggleFavorite(String outfitId) {
//     AppLogger.info('⭐ Toggling favorite for outfit: $outfitId');
//     ref.read(recentLooksProvider.notifier).toggleFavorite(outfitId);
//   }

//   Color _getScoreColor(double score) {
//     if (score >= 0.8) return Colors.green;
//     if (score >= 0.6) return Colors.orange;
//     return Colors.red;
//   }

//   Future<void> _generateOutfitSuggestions(String occasion) async {
//     AppLogger.info('🎯 Generating outfit suggestions for: $occasion');

//     try {
//       // Get wardrobe storage service
//       final wardrobeStorage = getIt<EnhancedWardrobeStorageService>();
//       final pairingService = getIt<WardrobePairingService>();

//       // Get user's wardrobe items
//       final wardrobeItems = await wardrobeStorage.getWardrobeItems();

//       if (wardrobeItems.isEmpty) {
//         // Show message to add items first
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Add some items to your wardrobe first!'),
//               action: SnackBarAction(
//                 label: 'Add Items',
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => const SimpleWardrobeUploadScreen(),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         }
//         return;
//       }

//       // Find a good hero item for this occasion
//       WardrobeItem heroItem;
//       switch (occasion.toLowerCase()) {
//         case 'casual':
//           heroItem = wardrobeItems.firstWhere(
//             (item) =>
//                 item.analysis.occasions?.contains('casual') == true ||
//                 item.analysis.occasions?.contains('weekend') == true,
//             orElse: () => wardrobeItems.first,
//           );
//           break;
//         case 'work':
//           heroItem = wardrobeItems.firstWhere(
//             (item) =>
//                 item.analysis.occasions?.contains('work') == true ||
//                 item.analysis.occasions?.contains('business') == true,
//             orElse: () => wardrobeItems.first,
//           );
//           break;
//         case 'date':
//           heroItem = wardrobeItems.firstWhere(
//             (item) =>
//                 item.analysis.occasions?.contains('date') == true ||
//                 item.analysis.occasions?.contains('evening') == true,
//             orElse: () => wardrobeItems.first,
//           );
//           break;
//         case 'party':
//           heroItem = wardrobeItems.firstWhere(
//             (item) =>
//                 item.analysis.occasions?.contains('party') == true ||
//                 item.analysis.occasions?.contains('celebration') == true,
//             orElse: () => wardrobeItems.first,
//           );
//           break;
//         default:
//           heroItem = wardrobeItems.first;
//       }

//       // Generate pairings for this occasion
//       final pairings = await pairingService.generatePairings(
//         heroItem: heroItem,
//         wardrobeItems: wardrobeItems,
//         mode: PairingMode.surpriseMe,
//         occasion: occasion,
//       );

//       if (pairings.isNotEmpty) {
//         // Navigate to outfit suggestions screen
//         if (mounted) {
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => _OccasionOutfitSuggestionsScreen(
//                 occasion: occasion,
//                 pairings: pairings,
//                 heroItem: heroItem,
//               ),
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'No outfit suggestions found for $occasion. Try adding more items to your wardrobe!',
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       AppLogger.error('❌ Error generating outfit suggestions', error: e);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to generate suggestions. Please try again.'),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Watch all providers
//     final quickIdeas = ref.watch(quickIdeasProvider);
//     final recentLooks = ref.watch(recentLooksProvider);
//     final todaysPicks = ref.watch(todaysPicksProvider);
//     final wardrobe = ref.watch(wardrobeSnapshotProvider);

//     AppLogger.info(
//       '🔄 Home build - QuickIdeas: ${quickIdeas.ideas.length}, '
//       'Recent: ${recentLooks.looks.length}, '
//       'Today: ${todaysPicks.todayPicks.length}, '
//       'Wardrobe: ${wardrobe.items.length}',
//     );

//     return SafeArea(
//       child: RefreshIndicator(
//         onRefresh: _refreshAll,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Hero Section
//               _buildHeroSection(context),

//               // Quick Actions
//               _buildQuickActions(context, quickIdeas),

//               // Recent Generations
//               _buildRecentGenerations(context, recentLooks),

//               // Today's Suggestions
//               _buildTodaysSuggestions(context, todaysPicks),

//               // Recent Items Preview
//               _buildRecentItemsPreview(context, wardrobe),

//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSection(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             theme.colorScheme.primary.withValues(alpha: 0.1),
//             theme.colorScheme.secondary.withValues(alpha: 0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: theme.colorScheme.primary.withValues(alpha: 0.1),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Text(
//           //   'What would you like to wear today?',
//           //   style: theme.textTheme.displaySmall?.copyWith(
//           //     fontWeight: FontWeight.w600,
//           //     color: theme.colorScheme.onSurface,
//           //   ),
//           // ),
//           const SizedBox(height: 8),
//           Text(
//             'Let\'s create the perfect outfit for you',
//             style: theme.textTheme.bodyLarge?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildPrimaryCTA(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrimaryCTA(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       width: double.infinity,
//       height: 60,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             theme.colorScheme.primary,
//             theme.colorScheme.primary.withValues(alpha: 0.8),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: theme.colorScheme.primary.withValues(alpha: 0.3),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => const UploadOptionsScreen(),
//               ),
//             );
//           },
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
//               const SizedBox(width: 12),
//               Text(
//                 'Generate Your Outfit',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions(BuildContext context, QuickIdeasState quickIdeas) {
//     final theme = Theme.of(context);

//     if (quickIdeas.isLoading) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Quick Outfit Ideas',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Center(child: CircularProgressIndicator()),
//           ],
//         ),
//       );
//     }

//     final ideas = quickIdeas.ideas.isNotEmpty
//         ? quickIdeas.ideas
//         : _getDefaultQuickIdeas();

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Quick Outfit Ideas',
//             style: theme.textTheme.titleLarge?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(child: _buildOccasionCard(context, ideas[0])),
//               const SizedBox(width: 12),
//               Expanded(child: _buildOccasionCard(context, ideas[1])),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(child: _buildOccasionCard(context, ideas[2])),
//               const SizedBox(width: 12),
//               Expanded(child: _buildOccasionCard(context, ideas[3])),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   List<QuickIdeaCard> _getDefaultQuickIdeas() {
//     return const [
//       QuickIdeaCard(
//         occasion: 'Casual',
//         icon: 'weekend',
//         bgColor: 'blue',
//         iconColor: 'blue700',
//       ),
//       QuickIdeaCard(
//         occasion: 'Work',
//         icon: 'business',
//         bgColor: 'purple',
//         iconColor: 'purple700',
//       ),
//       QuickIdeaCard(
//         occasion: 'Date',
//         icon: 'favorite',
//         bgColor: 'pink',
//         iconColor: 'pink700',
//       ),
//       QuickIdeaCard(
//         occasion: 'Party',
//         icon: 'celebration',
//         bgColor: 'orange',
//         iconColor: 'orange700',
//       ),
//     ];
//   }

//   IconData _getDistinctIconForOccasion(String occasion) {
//     switch (occasion.toLowerCase()) {
//       case 'casual':
//         return Icons.weekend_rounded; // Weekend/relaxed icon
//       case 'work':
//         return Icons.business_center_rounded; // Briefcase icon
//       case 'date':
//         return Icons.favorite_rounded; // Heart icon
//       case 'party':
//         return Icons.celebration_rounded; // Party/confetti icon
//       default:
//         return Icons.checkroom_rounded;
//     }
//   }

//   Widget _buildOccasionCard(BuildContext context, QuickIdeaCard idea) {
//     final theme = Theme.of(context);
//     // Use distinct icons based on occasion instead of generic string mapping
//     final icon = _getDistinctIconForOccasion(idea.occasion);

//     // Use direct color mapping based on occasion for reliability
//     Color bgColor;
//     Color iconColor;
//     switch (idea.occasion.toLowerCase()) {
//       case 'casual':
//         bgColor = Colors.blue.shade100;
//         iconColor = Colors.blue.shade700;
//         break;
//       case 'work':
//         bgColor = Colors.purple.shade100;
//         iconColor = Colors.purple.shade700;
//         break;
//       case 'date':
//         bgColor = Colors.pink.shade100;
//         iconColor = Colors.pink.shade700;
//         break;
//       case 'party':
//         bgColor = Colors.orange.shade100;
//         iconColor = Colors.orange.shade700;
//         break;
//       default:
//         bgColor = theme.colorScheme.primaryContainer;
//         iconColor = theme.colorScheme.primary;
//     }

//     return GestureDetector(
//       onLongPress: () {
//         AppLogger.info('🔥 Long-pressed quick idea: ${idea.occasion}');
//         // Show customize mood sheet
//         showCustomizeMoodSheet(
//           context,
//           occasion: idea.occasion,
//           onApply: () {
//             AppLogger.info('✅ Mood customized for ${idea.occasion}');
//             // Custom mood preferences are applied via the pairing service
//           },
//         );
//       },
//       child: Container(
//         height: 80,
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(16),
//             onTap: () {
//               AppLogger.info('🎯 Tapped quick idea: ${idea.occasion}');
//               // Generate outfit suggestions from existing wardrobe for this occasion
//               _generateOutfitSuggestions(idea.occasion);
//             },
//             child: Stack(
//               children: [
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(icon, color: iconColor, size: 28),
//                       const SizedBox(height: 4),
//                       Text(
//                         idea.occasion,
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: iconColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 // "New" badge if hasNewSuggestions
//                 if (idea.hasNewSuggestions)
//                   Positioned(
//                     top: 4,
//                     right: 4,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.orange,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Text(
//                         '✨ New',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentGenerations(
//     BuildContext context,
//     RecentLooksState recentLooks,
//   ) {
//     final theme = Theme.of(context);

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Recent Generations',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               if (recentLooks.looks.isNotEmpty)
//                 TextButton(
//                   onPressed: () {
//                     AppLogger.info('📂 View All Recent Generations tapped');
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                         builder: (context) => const SavedLooksScreen(),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     'View All',
//                     style: TextStyle(
//                       color: theme.colorScheme.primary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           if (recentLooks.isLoading)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (recentLooks.looks.isEmpty)
//             _buildEmptyRecentGenerations(context)
//           else
//             SizedBox(
//               height: 190,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: recentLooks.looks.length,
//                 itemBuilder: (context, index) {
//                   return _buildRecentOutfitCard(
//                     context,
//                     recentLooks.looks[index],
//                     recentLooks.favoriteIds,
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyRecentGenerations(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       height: 120,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withValues(alpha: 0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.auto_awesome_outlined,
//             size: 48,
//             color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No saved outfits yet',
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Create your first outfit to see it here',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentOutfitCard(
//     BuildContext context,
//     SavedOutfit outfit,
//     Set<String> favoriteIds,
//   ) {
//     final theme = Theme.of(context);
//     final isFav = favoriteIds.contains(outfit.id);

//     return Container(
//       width: 140,
//       height: 160, // Further reduced height to minimize gaps
//       margin: const EdgeInsets.only(right: 12),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(
//           color: theme.colorScheme.outline.withValues(alpha: 0.1),
//           width: 1,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             AppLogger.info('👆 Tapped outfit: ${outfit.title}');
//             _showOutfitPreview(context, outfit, theme);
//           },
//           child: Stack(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Image - Fixed height
//                   SizedBox(
//                     height: 120, // Increased to fill more space
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(16),
//                         ),
//                         color: theme.colorScheme.surfaceContainerHighest,
//                       ),
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(16),
//                         ),
//                         child: _buildOutfitImage(outfit, theme),
//                       ),
//                     ),
//                   ),

//                   // Content - Fixed height
//                   SizedBox(
//                     height: 40, // Further reduced to minimize gaps
//                     child: Padding(
//                       padding: const EdgeInsets.all(8), // Reduced padding
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             outfit.title,
//                             style: theme.textTheme.bodySmall?.copyWith(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             '${outfit.items.length} items',
//                             style: theme.textTheme.bodySmall?.copyWith(
//                               color: theme.colorScheme.onSurface.withValues(
//                                 alpha: 0.6,
//                               ),
//                               fontSize: 10,
//                             ),
//                           ),
//                           const Spacer(),
//                           Row(
//                             children: [
//                               Icon(
//                                 Icons.access_time,
//                                 size: 10,
//                                 color: theme.colorScheme.onSurface.withValues(
//                                   alpha: 0.5,
//                                 ),
//                               ),
//                               const SizedBox(width: 3),
//                               Expanded(
//                                 child: Text(
//                                   _formatDate(outfit.createdAt),
//                                   style: theme.textTheme.bodySmall?.copyWith(
//                                     color: theme.colorScheme.onSurface
//                                         .withValues(alpha: 0.5),
//                                     fontSize: 9,
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               // Favorite button overlay
//               Positioned(
//                 top: 4,
//                 right: 4,
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(20),
//                     onTap: () => _toggleFavorite(outfit.id),
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: theme.colorScheme.surface.withValues(alpha: 0.9),
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.1),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         isFav ? Icons.favorite : Icons.favorite_border,
//                         size: 16,
//                         color: isFav
//                             ? Colors.red
//                             : theme.colorScheme.onSurface.withValues(
//                                 alpha: 0.6,
//                               ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOutfitImage(SavedOutfit outfit, ThemeData theme) {
//     // Try to show mannequin image first
//     if (outfit.mannequinImages.isNotEmpty) {
//       try {
//         return Image.memory(
//           _dataUrlToBytes(outfit.mannequinImages.first),
//           fit: BoxFit.cover,
//           width: double.infinity,
//           errorBuilder: (context, error, stackTrace) =>
//               _buildItemImagesGrid(outfit, theme),
//         );
//       } catch (e) {
//         // Fall through to item images
//       }
//     }

//     // Show actual clothing item images as fallback
//     return _buildItemImagesGrid(outfit, theme);
//   }

//   Widget _buildItemImagesGrid(SavedOutfit outfit, ThemeData theme) {
//     if (outfit.items.isEmpty) {
//       return _buildImageError(theme);
//     }

//     // Show up to 4 items in a grid
//     final itemsToShow = outfit.items.take(4).toList();

//     if (itemsToShow.length == 1) {
//       return _buildSingleItemImage(itemsToShow[0], theme);
//     }

//     return GridView.count(
//       crossAxisCount: 2,
//       physics: const NeverScrollableScrollPhysics(),
//       children: itemsToShow.map((item) {
//         return Container(
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: theme.colorScheme.outline.withValues(alpha: 0.1),
//               width: 0.5,
//             ),
//           ),
//           child: _buildSingleItemImage(item, theme),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildSingleItemImage(ClothingAnalysis item, ThemeData theme) {
//     // Try to show actual image first
//     if (item.imagePath != null && item.imagePath!.isNotEmpty) {
//       return Container(
//         color: theme.colorScheme.surfaceContainerHighest,
//         child: Image.file(
//           File(item.imagePath!),
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) {
//             // Fall back to icon if image fails to load
//             return _buildItemPlaceholder(item, theme);
//           },
//         ),
//       );
//     }

//     // Show placeholder with item info if no image path
//     return _buildItemPlaceholder(item, theme);
//   }

//   Widget _buildItemImage(WardrobeItem item, ThemeData theme) {
//     // Try polished image first
//     if (item.polishedImagePath != null &&
//         File(item.polishedImagePath!).existsSync()) {
//       return Image.file(
//         File(item.polishedImagePath!),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           AppLogger.debug('Failed to load polished image, trying original');
//           return _tryOriginalImage(item, theme);
//         },
//       );
//     }

//     // Try original image
//     return _tryOriginalImage(item, theme);
//   }

//   Widget _tryOriginalImage(WardrobeItem item, ThemeData theme) {
//     if (File(item.originalImagePath).existsSync()) {
//       return Image.file(
//         File(item.originalImagePath),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           AppLogger.debug('Failed to load original image, using placeholder');
//           return _buildItemPlaceholder(item.analysis, theme);
//         },
//       );
//     }

//     // Fallback to placeholder with icon
//     return _buildItemPlaceholder(item.analysis, theme);
//   }

//   Widget _buildItemPlaceholder(ClothingAnalysis item, ThemeData theme) {
//     return Container(
//       color: theme.colorScheme.surfaceContainerHighest,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _getIconForItemType(item.itemType),
//               size: 24,
//               color: theme.colorScheme.primary,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               item.primaryColor,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getIconForItemType(String itemType) {
//     switch (itemType.toLowerCase()) {
//       case 'top':
//         return Icons.checkroom;
//       case 'bottom':
//         return Icons.content_cut;
//       case 'dress':
//         return Icons.woman;
//       case 'shoes':
//         return Icons.directions_walk;
//       case 'accessory':
//         return Icons.watch;
//       case 'outerwear':
//         return Icons.ac_unit;
//       default:
//         return Icons.checkroom;
//     }
//   }

//   Widget _buildImageError(ThemeData theme) {
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       child: Center(
//         child: Icon(
//           Icons.image_not_supported_outlined,
//           size: 32,
//           color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
//         ),
//       ),
//     );
//   }

//   Uint8List _dataUrlToBytes(String dataUrl) {
//     try {
//       String base64Data;
//       if (dataUrl.startsWith('data:')) {
//         final parts = dataUrl.split(',');
//         if (parts.length < 2) {
//           throw FormatException('Invalid data URL format');
//         }
//         base64Data = parts[1];
//       } else {
//         base64Data = dataUrl;
//       }

//       base64Data = base64Data.replaceAll(RegExp(r'\s+'), '');
//       base64Data = base64Data.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

//       while (base64Data.length % 4 != 0) {
//         base64Data += '=';
//       }

//       return base64Decode(base64Data);
//     } catch (e) {
//       return Uint8List(0);
//     }
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays == 0) {
//       return 'Today';
//     } else if (difference.inDays == 1) {
//       return 'Yesterday';
//     } else if (difference.inDays < 7) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inDays < 30) {
//       return '${(difference.inDays / 7).floor()}w ago';
//     } else {
//       return '${(difference.inDays / 30).floor()}mo ago';
//     }
//   }

//   Widget _buildTodaysSuggestions(
//     BuildContext context,
//     TodaysPicksState todaysPicks,
//   ) {
//     final theme = Theme.of(context);

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Today\'s Picks',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   AppLogger.info('📂 See All Today\'s Picks tapped');
//                   // Opens saved looks screen with today's picks filter
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => const SavedLooksScreen(),
//                     ),
//                   );
//                 },
//                 child: Text(
//                   'See All',
//                   style: TextStyle(
//                     color: theme.colorScheme.primary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Segmented Control for Today/Tonight
//           _buildTodayTonightTabs(context, todaysPicks, theme),
//           const SizedBox(height: 16),

//           if (todaysPicks.isLoading)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (todaysPicks.activeTab == TodayTab.today &&
//               todaysPicks.todayPicks.isEmpty)
//             _buildEmptyTodaysPicks(context)
//           else if (todaysPicks.activeTab == TodayTab.tonight &&
//               todaysPicks.tonightPicks.isEmpty)
//             _buildEmptyTonightPicks(context)
//           else
//             _buildTodaysPicksList(context, todaysPicks, theme),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodayTonightTabs(
//     BuildContext context,
//     TodaysPicksState todaysPicks,
//     ThemeData theme,
//   ) {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 AppLogger.info('🌅 Switched to Today tab');
//                 ref
//                     .read(todaysPicksProvider.notifier)
//                     .setActiveTab(TodayTab.today);
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Container(
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: todaysPicks.activeTab == TodayTab.today
//                         ? Colors.white
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: todaysPicks.activeTab == TodayTab.today
//                         ? [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ]
//                         : null,
//                   ),
//                   child: Center(
//                     child: Text(
//                       'For Today',
//                       style: TextStyle(
//                         color: todaysPicks.activeTab == TodayTab.today
//                             ? theme.colorScheme.primary
//                             : theme.colorScheme.onSurface.withValues(
//                                 alpha: 0.6,
//                               ),
//                         fontWeight: todaysPicks.activeTab == TodayTab.today
//                             ? FontWeight.w600
//                             : FontWeight.w500,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 AppLogger.info('🌙 Switched to Tonight tab');
//                 ref
//                     .read(todaysPicksProvider.notifier)
//                     .setActiveTab(TodayTab.tonight);
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: Container(
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: todaysPicks.activeTab == TodayTab.tonight
//                         ? Colors.white
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: todaysPicks.activeTab == TodayTab.tonight
//                         ? [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ]
//                         : null,
//                   ),
//                   child: Center(
//                     child: Text(
//                       'For Tonight',
//                       style: TextStyle(
//                         color: todaysPicks.activeTab == TodayTab.tonight
//                             ? theme.colorScheme.primary
//                             : theme.colorScheme.onSurface.withValues(
//                                 alpha: 0.6,
//                               ),
//                         fontWeight: todaysPicks.activeTab == TodayTab.tonight
//                             ? FontWeight.w600
//                             : FontWeight.w500,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodaysPicksList(
//     BuildContext context,
//     TodaysPicksState todaysPicks,
//     ThemeData theme,
//   ) {
//     final activePicks = todaysPicks.activeTab == TodayTab.today
//         ? todaysPicks.todayPicks
//         : todaysPicks.tonightPicks;

//     return SizedBox(
//       height: 280,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: activePicks.length.clamp(0, 5),
//         itemBuilder: (context, index) {
//           return _buildTodaysPickCard(
//             context,
//             activePicks[index],
//             index,
//             theme,
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTodaysPickCard(
//     BuildContext context,
//     OutfitPairing pick,
//     int index,
//     ThemeData theme,
//   ) {
//     return Container(
//       width: 180,
//       margin: EdgeInsets.only(right: index == 4 ? 0 : 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         // boxShadow: [
//         //   BoxShadow(
//         //     color: Colors.black.withValues(alpha: 0.08),
//         //     blurRadius: 12,
//         //     offset: const Offset(0, 4),
//         //   ),
//         // ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: () {
//             AppLogger.info('🎯 Tapped today\'s pick: ${pick.description}');
//             // Outfit preview can be added later if needed - current card shows all info
//           },
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Image area with weather chip
//               Expanded(
//                 flex: 3,
//                 child: Stack(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(20),
//                         ),
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             theme.colorScheme.primary.withValues(alpha: 0.1),
//                             theme.colorScheme.secondary.withValues(alpha: 0.05),
//                           ],
//                         ),
//                       ),
//                       child: Center(
//                         child: Icon(
//                           Icons.checkroom_rounded,
//                           size: 60,
//                           color: theme.colorScheme.primary.withValues(
//                             alpha: 0.3,
//                           ),
//                         ),
//                       ),
//                     ),
//                     // Weather chip
//                     Positioned(
//                       top: 8,
//                       left: 8,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.6),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               index.isEven
//                                   ? Icons.nightlight_round
//                                   : Icons.wb_sunny_rounded,
//                               size: 14,
//                               color: Colors.white,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               index.isEven ? 'Tonight' : '22°C',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Content area
//               Expanded(
//                 flex: 1,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         pick.description,
//                         style: theme.textTheme.titleSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),

//                       // Match score
//                       Row(
//                         children: [
//                           Expanded(
//                             child: LinearProgressIndicator(
//                               value: pick.compatibilityScore,
//                               backgroundColor: Colors.grey.shade200,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 _getScoreColor(pick.compatibilityScore),
//                               ),
//                               minHeight: 4,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             '${(pick.compatibilityScore * 100).round()}%',
//                             style: TextStyle(
//                               color: _getScoreColor(pick.compatibilityScore),
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // Action buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: () => _wearNow(pick),
//                               style: OutlinedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 6,
//                                 ),
//                                 minimumSize: Size.zero,
//                               ),
//                               child: const Text(
//                                 'Wear Now',
//                                 style: TextStyle(fontSize: 10),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: OutlinedButton(
//                               onPressed: () => _saveTodaysPick(pick),
//                               style: OutlinedButton.styleFrom(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 6,
//                                 ),
//                                 minimumSize: Size.zero,
//                               ),
//                               child: const Text(
//                                 'Save',
//                                 style: TextStyle(fontSize: 10),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyTodaysPicks(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       height: 120,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withValues(alpha: 0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.wb_sunny_outlined,
//             size: 48,
//             color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No picks for today yet',
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Add more items to your wardrobe',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyTonightPicks(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       height: 120,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withValues(alpha: 0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.nightlight_round_outlined,
//             size: 48,
//             color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No evening picks yet',
//             style: theme.textTheme.titleMedium?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Add more items to your wardrobe',
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _wearNow(OutfitPairing pick) {
//     AppLogger.info('👕 Wearing now: ${pick.description}');
//     // Items are marked as worn with wear count tracking
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Marked "${pick.description}" as worn today! 👕'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _saveTodaysPick(OutfitPairing pick) {
//     AppLogger.info('💾 Saving today\'s pick: ${pick.description}');
//     // Saves outfit to storage and refreshes recent generations
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Saved "${pick.description}" to your looks! ✨'),
//         backgroundColor: Colors.blue,
//       ),
//     );
//   }

//   Widget _buildRecentItemsPreview(
//     BuildContext context,
//     WardrobeSnapshotState wardrobe,
//   ) {
//     final theme = Theme.of(context);

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Your Wardrobe',
//                 style: theme.textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   AppLogger.info('👗 Navigate to full closet');
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => const EnhancedClosetScreen(),
//                     ),
//                   );
//                 },
//                 child: Text(
//                   'View All',
//                   style: TextStyle(
//                     color: theme.colorScheme.primary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           if (wardrobe.isLoading)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(32.0),
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (wardrobe.items.isEmpty)
//             _buildEmptyWardrobe(context)
//           else
//             _buildWardrobeGrid(context, wardrobe, theme),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyWardrobe(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       height: 100,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: theme.colorScheme.outline.withValues(alpha: 0.2),
//           width: 1,
//           style: BorderStyle.solid,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => const SimpleWardrobeUploadScreen(),
//             ),
//           );
//         },
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.add_circle_outline,
//               size: 32,
//               color: theme.colorScheme.primary,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Upload your first item',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 color: theme.colorScheme.primary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWardrobeGrid(
//     BuildContext context,
//     WardrobeSnapshotState wardrobe,
//     ThemeData theme,
//   ) {
//     final items = wardrobe.items.take(6).toList();

//     return Column(
//       children: [
//         // 2 rows of 3 columns
//         SizedBox(
//           height: 220,
//           child: GridView.builder(
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 1,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//             ),
//             itemCount: items.length,
//             itemBuilder: (context, index) {
//               return _buildWardrobeGridTile(context, items[index], theme);
//             },
//           ),
//         ),

//         // Upload more CTA if less than 6 items
//         if (wardrobe.items.length < 6) ...[
//           const SizedBox(height: 16),
//           _buildUploadMoreCTA(context, theme),
//         ],
//       ],
//     );
//   }

//   Widget _buildWardrobeGridTile(
//     BuildContext context,
//     WardrobeItem item,
//     ThemeData theme,
//   ) {
//     return GestureDetector(
//       onTap: () {
//         AppLogger.info('👔 Tapped wardrobe item: ${item.id}');
//         _showItemPreview(context, item);
//       },
//       onLongPress: () {
//         AppLogger.info('👔 Long-pressed wardrobe item: ${item.id}');
//         _showWardrobeItemActions(context, item);
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Stack(
//             children: [
//               // Background image or placeholder
//               Container(
//                 width: double.infinity,
//                 height: double.infinity,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       theme.colorScheme.primary.withValues(alpha: 0.1),
//                       theme.colorScheme.secondary.withValues(alpha: 0.05),
//                     ],
//                   ),
//                 ),
//                 child: _buildItemImage(item, theme),
//               ),

//               // Gradient overlay
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       Colors.transparent,
//                       Colors.black.withValues(alpha: 0.7),
//                     ],
//                     stops: const [0.0, 1.0],
//                   ),
//                 ),
//               ),

//               // Bottom info
//               Positioned(
//                 bottom: 8,
//                 left: 8,
//                 right: 8,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Category chip
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 6,
//                         vertical: 2,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.9),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Text(
//                         item.analysis.itemType,
//                         style: TextStyle(
//                           color: theme.colorScheme.primary,
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),

//                     // Wear count
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.repeat_rounded,
//                           size: 10,
//                           color: Colors.white.withValues(alpha: 0.8),
//                         ),
//                         const SizedBox(width: 2),
//                         Text(
//                           'Worn ${item.wearCount}x',
//                           style: TextStyle(
//                             color: Colors.white.withValues(alpha: 0.8),
//                             fontSize: 9,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUploadMoreCTA(BuildContext context, ThemeData theme) {
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: theme.colorScheme.primary.withValues(alpha: 0.3),
//           width: 2,
//           style: BorderStyle.solid,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: () {
//             AppLogger.info('📸 Upload more items tapped');
//             Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => const SimpleWardrobeUploadScreen(),
//               ),
//             );
//           },
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.camera_alt_outlined,
//                 color: theme.colorScheme.primary,
//                 size: 24,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 'Upload more items to complete your wardrobe',
//                 style: TextStyle(
//                   color: theme.colorScheme.primary,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showOutfitPreview(
//     BuildContext context,
//     SavedOutfit outfit,
//     ThemeData theme,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: Stack(
//             children: [
//               // Main outfit image
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   width: double.infinity,
//                   height: double.infinity,
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.surface,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: _buildOutfitImage(outfit, theme),
//                 ),
//               ),
//               // Close button
//               Positioned(
//                 top: 16,
//                 right: 16,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withValues(alpha: 0.5),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ),
//               ),
//               // Outfit info overlay
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.transparent,
//                         Colors.black.withValues(alpha: 0.8),
//                       ],
//                     ),
//                     borderRadius: const BorderRadius.only(
//                       bottomLeft: Radius.circular(20),
//                       bottomRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         outfit.title,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '${outfit.items.length} items',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                       if (outfit.items.isNotEmpty) ...[
//                         const SizedBox(height: 8),
//                         Text(
//                           outfit.items.map((item) => item.itemType).join(' • '),
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showItemPreview(BuildContext context, WardrobeItem item) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.8,
//           ),
//           child: Stack(
//             children: [
//               // Main image
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: _buildItemImage(item, Theme.of(context)),
//               ),
//               // Close button
//               Positioned(
//                 top: 16,
//                 right: 16,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withValues(alpha: 0.5),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ),
//               ),
//               // Item info overlay
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.transparent,
//                         Colors.black.withValues(alpha: 0.8),
//                       ],
//                     ),
//                     borderRadius: const BorderRadius.only(
//                       bottomLeft: Radius.circular(20),
//                       bottomRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         item.analysis.itemType,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       if (item.analysis.subcategory != null) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           item.analysis.subcategory!,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                       const SizedBox(height: 4),
//                       Text(
//                         item.analysis.primaryColor,
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showWardrobeItemActions(BuildContext context, WardrobeItem item) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Handle
//             Container(
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),

//             // Title
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   Text(
//                     item.analysis.itemType,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close),
//                   ),
//                 ],
//               ),
//             ),

//             // Actions
//             ListTile(
//               leading: const Icon(Icons.person_add, color: Colors.blue),
//               title: const Text('Pair This Item'),
//               onTap: () {
//                 Navigator.pop(context);
//                 AppLogger.info('✨ Pair this item: ${item.id}');
//                 // Launches pairing flow with this item as hero
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.casino, color: Colors.purple),
//               title: const Text('Surprise Me'),
//               onTap: () {
//                 Navigator.pop(context);
//                 AppLogger.info('🎲 Surprise me with: ${item.id}');
//                 // Launches surprise me flow with random pairings
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.location_on, color: Colors.orange),
//               title: const Text('Style by Location'),
//               onTap: () {
//                 Navigator.pop(context);
//                 AppLogger.info('📍 Style by location: ${item.id}');
//                 // Launches location-based styling flow
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.visibility, color: Colors.green),
//               title: const Text('View Details'),
//               onTap: () {
//                 Navigator.pop(context);
//                 AppLogger.info('👁️ View details: ${item.id}');
//                 // Opens detailed item view with metadata
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.delete, color: Colors.red),
//               title: const Text('Delete Item'),
//               onTap: () {
//                 Navigator.pop(context);
//                 AppLogger.info('🗑️ Delete item: ${item.id}');
//                 // Shows confirmation dialog before deleting item
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: const Text('Delete Item?'),
//                     content: const Text(
//                       'Are you sure you want to delete this item from your wardrobe?',
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel'),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           AppLogger.info('🗑️ Deleting item: ${item.id}');
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Item deleted successfully'),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           'Delete',
//                           style: TextStyle(color: Colors.red),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Filter bottom sheet widget
// class FilterBottomSheet extends StatefulWidget {
//   const FilterBottomSheet({super.key});

//   @override
//   State<FilterBottomSheet> createState() => _FilterBottomSheetState();
// }

// class _FilterBottomSheetState extends State<FilterBottomSheet> {
//   final Set<String> _selectedOccasions = {};
//   final Set<String> _selectedSeasons = {};
//   final Set<String> _selectedColors = {};

//   final List<String> _occasions = [
//     'Casual',
//     'Work',
//     'Date',
//     'Party',
//     'Formal',
//     'Weekend',
//   ];

//   final List<String> _seasons = ['Spring', 'Summer', 'Fall', 'Winter'];

//   final Map<String, Color> _colors = {
//     'Black': Colors.black,
//     'White': Colors.white,
//     'Red': Colors.red,
//     'Blue': Colors.blue,
//     'Green': Colors.green,
//     'Yellow': Colors.yellow,
//     'Purple': Colors.purple,
//     'Pink': Colors.pink,
//     'Orange': Colors.orange,
//     'Brown': Colors.brown,
//   };

//   void _applyFilters() {
//     AppLogger.info(
//       '🎯 Applying filters - Occasions: $_selectedOccasions, Seasons: $_selectedSeasons, Colors: $_selectedColors',
//     );
//     Navigator.pop(context, {
//       'occasions': _selectedOccasions.toList(),
//       'seasons': _selectedSeasons.toList(),
//       'colors': _selectedColors.toList(),
//     });
//   }

//   void _clearFilters() {
//     setState(() {
//       _selectedOccasions.clear();
//       _selectedSeasons.clear();
//       _selectedColors.clear();
//     });
//     AppLogger.info('🧹 Cleared all filters');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.scaffoldBackgroundColor,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         minChildSize: 0.5,
//         maxChildSize: 0.9,
//         expand: false,
//         builder: (context, scrollController) {
//           return SingleChildScrollView(
//             controller: scrollController,
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Handle
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // Title and Clear button
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Filters',
//                         style: theme.textTheme.headlineSmall?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: _clearFilters,
//                         child: const Text('Clear All'),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Occasions
//                   Text(
//                     'Occasions',
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _occasions.map((occasion) {
//                       final isSelected = _selectedOccasions.contains(occasion);
//                       return FilterChip(
//                         label: Text(occasion),
//                         selected: isSelected,
//                         onSelected: (selected) {
//                           setState(() {
//                             if (selected) {
//                               _selectedOccasions.add(occasion);
//                             } else {
//                               _selectedOccasions.remove(occasion);
//                             }
//                           });
//                         },
//                         selectedColor: theme.colorScheme.primaryContainer,
//                         checkmarkColor: theme.colorScheme.primary,
//                       );
//                     }).toList(),
//                   ),
//                   const SizedBox(height: 24),

//                   // Seasons
//                   Text(
//                     'Seasons',
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _seasons.map((season) {
//                       final isSelected = _selectedSeasons.contains(season);
//                       return FilterChip(
//                         label: Text(season),
//                         selected: isSelected,
//                         onSelected: (selected) {
//                           setState(() {
//                             if (selected) {
//                               _selectedSeasons.add(season);
//                             } else {
//                               _selectedSeasons.remove(season);
//                             }
//                           });
//                         },
//                         selectedColor: theme.colorScheme.secondaryContainer,
//                         checkmarkColor: theme.colorScheme.secondary,
//                       );
//                     }).toList(),
//                   ),
//                   const SizedBox(height: 24),

//                   // Colors
//                   Text(
//                     'Colors',
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Wrap(
//                     spacing: 12,
//                     runSpacing: 12,
//                     children: _colors.entries.map((entry) {
//                       final isSelected = _selectedColors.contains(entry.key);
//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             if (isSelected) {
//                               _selectedColors.remove(entry.key);
//                             } else {
//                               _selectedColors.add(entry.key);
//                             }
//                           });
//                         },
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 48,
//                               height: 48,
//                               decoration: BoxDecoration(
//                                 color: entry.value,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: isSelected
//                                       ? theme.colorScheme.primary
//                                       : Colors.grey.shade300,
//                                   width: isSelected ? 3 : 1,
//                                 ),
//                               ),
//                               child: isSelected
//                                   ? Icon(
//                                       Icons.check,
//                                       color: entry.key == 'White'
//                                           ? Colors.black
//                                           : Colors.white,
//                                       size: 24,
//                                     )
//                                   : null,
//                             ),
//                             const SizedBox(height: 4),
//                             Text(entry.key, style: theme.textTheme.bodySmall),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                   const SizedBox(height: 32),

//                   // Apply button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _applyFilters,
//                       style: ElevatedButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                       child: Text(
//                         'Apply Filters',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           color: theme.colorScheme.onPrimary,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// Screen to display outfit suggestions for a specific occasion
// class _OccasionOutfitSuggestionsScreen extends StatefulWidget {
//   final String occasion;
//   final List<OutfitPairing> pairings;
//   final WardrobeItem heroItem;

//   const _OccasionOutfitSuggestionsScreen({
//     required this.occasion,
//     required this.pairings,
//     required this.heroItem,
//   });

//   @override
//   State<_OccasionOutfitSuggestionsScreen> createState() =>
//       _OccasionOutfitSuggestionsScreenState();
// }

// class _OccasionOutfitSuggestionsScreenState
//     extends State<_OccasionOutfitSuggestionsScreen> {
//   late final OutfitStorageService _outfitStorage;

//   @override
//   void initState() {
//     super.initState();
//     _outfitStorage = getIt<OutfitStorageService>();
//   }

//   Widget _buildItemImage(WardrobeItem item, ThemeData theme) {
//     // Try polished image first
//     if (item.polishedImagePath != null &&
//         File(item.polishedImagePath!).existsSync()) {
//       return Image.file(
//         File(item.polishedImagePath!),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return _tryOriginalImage(item, theme);
//         },
//       );
//     }

//     // Try original image
//     return _tryOriginalImage(item, theme);
//   }

//   Widget _tryOriginalImage(WardrobeItem item, ThemeData theme) {
//     if (File(item.originalImagePath).existsSync()) {
//       return Image.file(
//         File(item.originalImagePath),
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return _buildItemPlaceholder(item.analysis, theme);
//         },
//       );
//     }

//     // Fallback to placeholder with icon
//     return _buildItemPlaceholder(item.analysis, theme);
//   }

//   Widget _buildItemPlaceholder(ClothingAnalysis item, ThemeData theme) {
//     return Container(
//       color: theme.colorScheme.surfaceContainerHighest,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _getIconForItemType(item.itemType),
//               size: 20,
//               color: theme.colorScheme.primary,
//             ),
//             const SizedBox(height: 2),
//             Text(
//               item.primaryColor,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 fontSize: 8,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getIconForItemType(String itemType) {
//     switch (itemType.toLowerCase()) {
//       case 'top':
//         return Icons.checkroom;
//       case 'bottom':
//         return Icons.accessibility_new;
//       case 'dress':
//         return Icons.checkroom_outlined;
//       case 'shoes':
//         return Icons.directions_walk;
//       case 'outerwear':
//         return Icons.ac_unit;
//       case 'accessory':
//         return Icons.watch;
//       default:
//         return Icons.checkroom;
//     }
//   }

//   String _getSpecificItemName(WardrobeItem item) {
//     final analysis = item.analysis;
//     final type = analysis.itemType.toLowerCase();
//     final color = analysis.primaryColor;
//     final subcategory = analysis.subcategory ?? '';

//     // Create specific item names based on type and subcategory
//     switch (type) {
//       case 'top':
//         if (subcategory.toLowerCase().contains('t-shirt') ||
//             subcategory.toLowerCase().contains('tee')) {
//           return '${color} T-Shirt';
//         } else if (subcategory.toLowerCase().contains('blouse')) {
//           return '${color} Blouse';
//         } else if (subcategory.toLowerCase().contains('shirt')) {
//           return '${color} Shirt';
//         } else if (subcategory.toLowerCase().contains('sweater')) {
//           return '${color} Sweater';
//         } else if (subcategory.toLowerCase().contains('hoodie')) {
//           return '${color} Hoodie';
//         } else if (subcategory.toLowerCase().contains('tank')) {
//           return '${color} Tank Top';
//         } else {
//           return '${color} Top';
//         }
//       case 'bottom':
//         if (subcategory.toLowerCase().contains('jean')) {
//           if (subcategory.toLowerCase().contains('skinny')) {
//             return '${color} Skinny Jeans';
//           } else if (subcategory.toLowerCase().contains('wide')) {
//             return '${color} Wide-Leg Jeans';
//           } else if (subcategory.toLowerCase().contains('relaxed')) {
//             return '${color} Relaxed Jeans';
//           } else if (subcategory.toLowerCase().contains('straight')) {
//             return '${color} Straight Jeans';
//           } else {
//             return '${color} Jeans';
//           }
//         } else if (subcategory.toLowerCase().contains('pant')) {
//           return '${color} Pants';
//         } else if (subcategory.toLowerCase().contains('short')) {
//           return '${color} Shorts';
//         } else if (subcategory.toLowerCase().contains('skirt')) {
//           return '${color} Skirt';
//         } else {
//           return '${color} Bottom';
//         }
//       case 'shoes':
//         if (subcategory.toLowerCase().contains('sneaker')) {
//           return '${color} Sneakers';
//         } else if (subcategory.toLowerCase().contains('heel')) {
//           return '${color} Heels';
//         } else if (subcategory.toLowerCase().contains('boot')) {
//           return '${color} Boots';
//         } else if (subcategory.toLowerCase().contains('sandal')) {
//           return '${color} Sandals';
//         } else if (subcategory.toLowerCase().contains('loafer')) {
//           return '${color} Loafers';
//         } else {
//           return '${color} Shoes';
//         }
//       case 'dress':
//         if (subcategory.toLowerCase().contains('maxi')) {
//           return '${color} Maxi Dress';
//         } else if (subcategory.toLowerCase().contains('mini')) {
//           return '${color} Mini Dress';
//         } else if (subcategory.toLowerCase().contains('midi')) {
//           return '${color} Midi Dress';
//         } else {
//           return '${color} Dress';
//         }
//       default:
//         return '${color} ${analysis.itemType}';
//     }
//   }

//   Future<void> _saveOutfit(OutfitPairing pairing) async {
//     try {
//       final savedOutfit = SavedOutfit(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         title: '${widget.occasion} Outfit',
//         items: pairing.items.map((item) => item.analysis).toList(),
//         mannequinImages: pairing.mannequinImageUrl != null
//             ? [pairing.mannequinImageUrl!]
//             : [],
//         matchScore: pairing.compatibilityScore,
//         createdAt: DateTime.now(),
//         occasion: widget.occasion,
//         notes: pairing.description,
//       );

//       await _outfitStorage.save(savedOutfit);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Outfit saved successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       AppLogger.error('❌ Error saving outfit', error: e);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to save outfit'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.occasion} Outfit Ideas'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () async {
//               // Regenerate outfit suggestions
//               Navigator.of(context).pop();
//               // The parent will regenerate when we pop back
//             },
//             tooltip: 'Refresh suggestions',
//           ),
//         ],
//       ),
//       body: widget.pairings.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.checkroom_outlined,
//                     size: 64,
//                     color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No outfit suggestions found',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Try adding more items to your wardrobe',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: widget.pairings.length,
//               itemBuilder: (context, index) {
//                 final pairing = widget.pairings[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 16),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Header with score and occasion
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               '${widget.occasion} Look ${index + 1}',
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: _getScoreColor(
//                                   pairing.compatibilityScore,
//                                 ).withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: _getScoreColor(
//                                     pairing.compatibilityScore,
//                                   ),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: Text(
//                                 '${(pairing.compatibilityScore * 100).round()}%',
//                                 style: TextStyle(
//                                   color: _getScoreColor(
//                                     pairing.compatibilityScore,
//                                   ),
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),

//                         // Items in this outfit with images
//                         Text(
//                           'Items:',
//                           style: theme.textTheme.bodySmall?.copyWith(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         // Show item images in a row
//                         SizedBox(
//                           height: 80,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: pairing.items.length,
//                             itemBuilder: (context, itemIndex) {
//                               final item = pairing.items[itemIndex];
//                               return Container(
//                                 width: 80,
//                                 margin: const EdgeInsets.only(right: 12),
//                                 child: Column(
//                                   children: [
//                                     // Item image
//                                     Container(
//                                       height: 50,
//                                       width: 50,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(8),
//                                         border: Border.all(
//                                           color: theme.colorScheme.primary
//                                               .withValues(alpha: 0.3),
//                                         ),
//                                       ),
//                                       child: ClipRRect(
//                                         borderRadius: BorderRadius.circular(8),
//                                         child: _buildItemImage(item, theme),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     // Item name
//                                     Text(
//                                       _getSpecificItemName(item),
//                                       style: theme.textTheme.bodySmall
//                                           ?.copyWith(
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                       textAlign: TextAlign.center,
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),

//                         // Description
//                         if (pairing.description.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           Text(
//                             'Description:',
//                             style: theme.textTheme.bodySmall?.copyWith(
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             pairing.description,
//                             style: theme.textTheme.bodySmall?.copyWith(
//                               color: theme.colorScheme.onSurface.withValues(
//                                 alpha: 0.7,
//                               ),
//                             ),
//                           ),
//                         ],

//                         const SizedBox(height: 16),

//                         // Action buttons
//                         Row(
//                           children: [
//                             Expanded(
//                               child: OutlinedButton.icon(
//                                 onPressed: () => _saveOutfit(pairing),
//                                 icon: const Icon(Icons.bookmark_outline),
//                                 label: const Text('Save Outfit'),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: () {
//                                   // Generates mannequin preview for this outfit
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         'Mannequin preview coming soon!',
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 icon: const Icon(Icons.preview),
//                                 label: const Text('Preview'),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Color _getScoreColor(double score) {
//     if (score >= 0.8) return Colors.green;
//     if (score >= 0.6) return Colors.orange;
//     return Colors.red;
//   }
// }
