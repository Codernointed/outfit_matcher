import 'package:flutter/material.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Bottom sheet for customizing mood/style preferences for outfit suggestions
class CustomizeMoodSheet extends StatefulWidget {
  final String occasion;
  final VoidCallback? onApply;

  const CustomizeMoodSheet({super.key, required this.occasion, this.onApply});

  @override
  State<CustomizeMoodSheet> createState() => _CustomizeMoodSheetState();
}

class _CustomizeMoodSheetState extends State<CustomizeMoodSheet> {
  double _toneValue = 0.5; // 0 = Relaxed, 1 = Polished
  String _selectedPalette = 'Neutral';
  double _confidenceValue = 0.5; // 0 = Safe, 1 = Bold

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Mood',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fine-tune your ${widget.occasion.toLowerCase()} outfit style',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tone Slider
                  _buildSection(
                    theme: theme,
                    title: 'Tone',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Relaxed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            Text(
                              'Polished',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _toneValue,
                          onChanged: (value) {
                            setState(() {
                              _toneValue = value;
                            });
                            AppLogger.info(
                              '🎨 Tone adjusted: ${value.toStringAsFixed(2)}',
                            );
                          },
                          activeColor: theme.colorScheme.primary,
                          inactiveColor: theme.colorScheme.primary.withOpacity(
                            0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Palette Selector
                  _buildSection(
                    theme: theme,
                    title: 'Palette',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPaletteOption(
                            theme: theme,
                            label: 'Neutral',
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade500,
                              Colors.grey.shade700,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaletteOption(
                            theme: theme,
                            label: 'Vibrant',
                            colors: [
                              Colors.red.shade400,
                              Colors.blue.shade400,
                              Colors.green.shade400,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPaletteOption(
                            theme: theme,
                            label: 'Mono',
                            colors: [
                              Colors.black,
                              Colors.grey.shade600,
                              Colors.white,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confidence Slider
                  _buildSection(
                    theme: theme,
                    title: 'Confidence',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Safe',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            Text(
                              'Bold',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _confidenceValue,
                          onChanged: (value) {
                            setState(() {
                              _confidenceValue = value;
                            });
                            AppLogger.info(
                              '💪 Confidence adjusted: ${value.toStringAsFixed(2)}',
                            );
                          },
                          activeColor: theme.colorScheme.primary,
                          inactiveColor: theme.colorScheme.primary.withOpacity(
                            0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  AppLogger.info(
                    '✅ Apply mood: Tone=$_toneValue, '
                    'Palette=$_selectedPalette, Confidence=$_confidenceValue',
                  );
                  widget.onApply?.call();
                  Navigator.of(context).pop();
                  // TODO: Pass mood preferences to pairing service
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Apply Mood',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPaletteOption({
    required ThemeData theme,
    required String label,
    required List<Color> colors,
  }) {
    final isSelected = _selectedPalette == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPalette = label;
        });
        AppLogger.info('🎨 Palette selected: $label');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Color swatches
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: colors.map((color) {
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the customize mood sheet
Future<void> showCustomizeMoodSheet(
  BuildContext context, {
  required String occasion,
  VoidCallback? onApply,
}) async {
  AppLogger.info('📖 Opening Customize Mood sheet for: $occasion');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        CustomizeMoodSheet(occasion: occasion, onApply: onApply),
  );
}
