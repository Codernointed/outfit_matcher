import 'package:flutter/material.dart';
import 'package:vestiq/features/profile/presentation/screens/profile_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/home_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/upload_options_screen.dart';
import 'package:vestiq/features/wardrobe/presentation/widgets/dynamic_island_navbar.dart';

/// Main screen with premium dynamic island bottom navigation
class MainScreen extends StatefulWidget {
  /// Default constructor
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens to show in the tab view
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const Center(child: Text('Closet Screen - Coming Soon')),
      const UploadOptionsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: DynamicIslandNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          DynamicIslandNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          DynamicIslandNavItem(
            icon: Icons.checkroom_outlined,
            activeIcon: Icons.checkroom,
            label: 'Closet',
          ),
          DynamicIslandNavItem(
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle,
            label: 'Add',
          ),
          DynamicIslandNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
