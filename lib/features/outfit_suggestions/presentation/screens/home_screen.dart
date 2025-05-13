import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/upload_options_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _navigateUploadOptions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UploadOptionsScreen()),
    );
  }

  // State for BottomNavigationBar index (will be managed by a Riverpod provider later)
  // For now, a placeholder state or hardcoded index for active tab.
  // Let's assume a simple int for now, default to 0 (Home)
  // int _currentIndex = 0; // This would require HomeScreen to be StatefulWidget

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Placeholder for managing current index, ideally via Riverpod
    const int currentIndex = 0; // Home selected by default

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.checkroom, color: theme.colorScheme.primary), // App logo
            const SizedBox(width: 8),
            const Text('Outfit Matcher'), // App name
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.wb_sunny_outlined,
            ), // Optional Weather Indicator
            onPressed: () {
              /* TODO: Implement weather functionality */
            },
          ),
          IconButton(
            icon: const Icon(Icons.search), // Search Icon
            onPressed: () {
              /* TODO: Implement global search */
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
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
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Removed
      // floatingActionButton: FloatingActionButton凶( // Removed
      //   onPressed: () {
      //     _navigateUploadOptions(context);
      //   },
      //   shape: const CircleBorder(),
      //   elevation: 2.0,
      //   child: const Icon(Icons.add, size: 30),
      // ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ), // Horizontal and bottom padding
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            20,
          ), // Rounded corners for the bar
          child: BottomNavigationBar(
            currentIndex: currentIndex, // Use the state variable
            onTap: (index) {
              // TODO: Update currentIndex state via Riverpod provider
              if (index == 2) {
                // Assuming 'Add' is at index 2
                _navigateUploadOptions(context);
              }
              print('Tapped on index $index');
            },
            type:
                BottomNavigationBarType
                    .fixed, // Reinstated for consistent behavior
            backgroundColor: const Color(
              0xFFF4C2C2,
            ).withOpacity(0.85), // Rose-pink background, slightly transparent
            selectedItemColor:
                theme.colorScheme.primary, // Color for selected icon and label
            unselectedItemColor: Colors.black.withOpacity(
              0.6,
            ), // Color for unselected items
            elevation:
                0, // Elevation is handled by the container/padding if needed, or set to low like 2-4
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
                // Reinstated Add item
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

  Widget _buildAddNewItemButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.camera_alt_outlined, size: 28),
      label: const Text(
        'Add New Item',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        _navigateUploadOptions(context);
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

  // _buildBottomAppBar and _buildBottomNavItem are no longer needed
}
