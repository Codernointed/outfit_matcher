import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/core/theme/app_theme.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';

/// The onboarding screen widget showing the app features to new users
class OnboardingScreen extends StatefulWidget {
  /// Default constructor
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Current page index
  int _currentPage = 0;

  /// Page controller for the onboarding pages
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to the main screen and mark onboarding as completed
  void _completeOnboarding() async {
    // Save that onboarding has been completed
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);

    if (!mounted) return;

    // Navigate to main screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: AppConstants.verticalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallSpacing / 2,
                    ),
                    width: index == _currentPage ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color:
                          index == _currentPage
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),

            // Page view for onboarding
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  _OnboardingPage(
                    icon: Icons.camera_alt,
                    title: 'Capture Your Clothes',
                    imagePath: 'assets/images/create_wardrobe1.jpeg',
                    description:
                        'Take photos of your clothing items or upload them from your gallery to build your virtual closet.',
                  ),
                  _OnboardingPage(
                    icon: Icons.grid_view,
                    title: 'Build Your Wardrobe',
                    imagePath: 'assets/images/build_your_wardrobe2.jpeg',
                    description:
                        'Organize your items by category, color, and occasion to create your personalized digital closet.',
                  ),
                  _OnboardingPage(
                    icon: Icons.auto_awesome,
                    title: 'Get Smart Suggestions',
                    imagePath: 'assets/images/get_outfit_suggestions.jpeg',
                    description:
                        'Our AI will analyze your items and suggest perfect outfit combinations based on color and style.',
                  ),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultSpacing),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Go to home screen
                        _completeOnboarding();
                      }
                    },
                    child: Text(_currentPage == 2 ? 'Get Started' : 'Continue'),
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single onboarding page widget
class _OnboardingPage extends StatelessWidget {
  /// Icon to display on the page
  final IconData icon;

  /// Title of the page
  final String title;

  /// Description text
  final String description;

  /// Image path
  final String imagePath;

  /// Default constructor
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.largeSpacing),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          // Placeholder for image
          const SizedBox(height: AppConstants.largeSpacing),
          Container(
            width: double.infinity,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            child: Center(
              child:
                  imagePath != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                      : const Icon(Icons.image, size: 60, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
