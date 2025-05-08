import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Welcome screen with grid of outfit images and get started button
class WelcomeScreen extends StatelessWidget {
  /// Default constructor
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading text
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 8.0),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.displayMedium,
                    children: [
                      const TextSpan(text: 'Your Wardrobe, '),
                      TextSpan(
                        text: 'Reimagined',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Description text
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Discover perfect outfit combinations from your own clothes with AI-powered suggestions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              // Image grid with rotated items
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,

                  children: [
                    // Top-left item - rotated slightly left
                    Transform.rotate(
                      angle: -0.05, // Small counter-clockwise rotation
                      child: _buildGridItem('assets/images/top_left.jpeg'),
                    ),

                    // Top-right item - rotated slightly right
                    Transform.rotate(
                      angle: 0.07, // Small clockwise rotation
                      child: _buildGridItem('assets/images/top_right.jpeg'),
                    ),

                    // Bottom-left item - rotated slightly right
                    Transform.rotate(
                      angle: 0.03, // Very slight clockwise rotation
                      child: _buildGridItem('assets/images/bottom_left.jpeg'),
                    ),

                    // Bottom-right item - rotated slightly left
                    Transform.rotate(
                      angle: -0.08, // Counter-clockwise rotation
                      child: _buildGridItem('assets/images/bottom_right.jpeg'),
                    ),
                  ],
                ),
              ),

              // Get Started button
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(Icons.arrow_forward, size: 20.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single grid item with placeholder for clothing image
  Widget _buildGridItem([String? imagePath]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
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
              : const Center(
                child: Icon(Icons.image, size: 40, color: Colors.grey),
              ),
    );
  }
}
