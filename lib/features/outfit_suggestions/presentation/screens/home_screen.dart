import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/upload_options_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/closet_screen.dart'; // Import ClosetScreen
// TODO: Import ProfileScreen when created
// import 'package:outfit_matcher/features/profile/presentation/screens/profile_screen.dart';

// Provider for the current selected index of the BottomNavigationBar
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  void _navigateUploadOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UploadOptionsScreen()),
    );
  }

  // List of main screens for IndexedStack
  final List<Widget> _mainScreens = [
    const MainContentHomeScreen(), // Placeholder for actual home content screen
    const ClosetScreen(),
    // UploadOptionsScreen is navigated to, not a persistent tab view
    const Center(
      child: Text('Profile Screen - Coming Soon'),
    ), // Placeholder for ProfileScreen
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // The body will now be an IndexedStack to switch between screens
    // The original ListView content of HomeScreen will become its own widget (MainContentHomeScreen)
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.checkroom, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Outfit Matcher'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            onPressed: () {
              /* TODO: Implement weather functionality */
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              /* TODO: Implement global search */
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: IndexedStack(
        index:
            currentIndex == 2
                ? 0
                : currentIndex, // If 'Add' is tapped, stay on current view (or Home)
        children: _mainScreens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == 2) {
                // 'Add' button index
                _navigateUploadOptions(context);
              } else {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFF4C2C2).withOpacity(0.85),
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.black.withOpacity(0.6),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.checkroom_outlined),
                activeIcon: Icon(Icons.checkroom),
                label: 'Closet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This widget now holds the original content of the HomeScreen's body
class MainContentHomeScreen extends StatelessWidget {
  const MainContentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAddNewItemButton(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Recent Items'),
          _buildRecentItemsList(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Outfit Ideas'),
          _buildOutfitIdeasList(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Style Tips'),
          _buildStyleTipsPlaceholder(context),
        ],
      ),
    );
  }

  // Methods copied from the original HomeScreen, they need access to context
  // or need to be passed context if they remain static or top-level functions.
  // For simplicity, they are instance methods here needing access to context.

  Widget _buildAddNewItemButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.camera_alt_outlined, size: 28),
      label: const Text(
        'Add New Item',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UploadOptionsScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentItemsList(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(right: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text('Item ${index + 1}')),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutfitIdeasList(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Outfit Idea ${index + 1}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStyleTipsPlaceholder(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Style tips coming soon!',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.teal[700]),
          ),
        ),
      ),
    );
  }
}
