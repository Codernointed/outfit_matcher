import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/theme/vestiq_soft_theme.dart';
import 'package:vestiq/core/widgets/soft_glass/soft_glass.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Welcome screen with grid of outfit images and get started button
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = context.vestiqSoft;

    return Scaffold(
      backgroundColor: soft.canvas,
      body: VestiqCanvas(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.displayMedium?.copyWith(
                        height: 1.1,
                        letterSpacing: -0.02 * 28,
                      ),
                      children: [
                        const TextSpan(text: 'Your Wardrobe, '),
                        TextSpan(
                          text: 'Reimagined',
                          style: TextStyle(color: soft.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Discover perfect outfit combinations from your own clothes with AI-powered suggestions.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      Transform.rotate(
                        angle: -0.05,
                        child: _buildGridItem(
                          context,
                          'assets/images/top_left.png',
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.07,
                        child: _buildGridItem(
                          context,
                          'assets/images/top_right.png',
                        ),
                      ),
                      Transform.rotate(
                        angle: 0.03,
                        child: _buildGridItem(
                          context,
                          'assets/images/bottom_left.png',
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.08,
                        child: _buildGridItem(
                          context,
                          'assets/images/bottom_right.png',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: SoftButton(
                    label: 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const OnboardingScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String? imagePath) {
    final soft = context.vestiqSoft;
    return Container(
      decoration: BoxDecoration(
        color: soft.surfaceContainer,
        borderRadius: BorderRadius.circular(
          AppConstants.largeBorderRadius,
        ),
        boxShadow: soft.cardSoftShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null
          ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: soft.onPrimarySoft.withValues(alpha: 0.4),
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: soft.onPrimarySoft.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}
