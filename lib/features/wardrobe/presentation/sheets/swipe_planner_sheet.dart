import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/swipe_closet_request.dart';
import 'package:vestiq/features/wardrobe/presentation/providers/swipe_planner_providers.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/wardrobe/presentation/providers/swipe_planner_providers.dart'
    as swipePlannerProviders;

/// Sheet for planning a swipe closet session with occasion and preferences
class SwipePlannerSheet extends ConsumerStatefulWidget {
  const SwipePlannerSheet({super.key});

  @override
  ConsumerState<SwipePlannerSheet> createState() => _SwipePlannerSheetState();
}

class _SwipePlannerSheetState extends ConsumerState<SwipePlannerSheet> {
  final TextEditingController _occasionController = TextEditingController();
  final Set<String> _selectedOccasions = {};
  String? _selectedMood;
  String? _selectedWeather;
  String? _selectedColor;

  final List<String> _occasionChips = [
    'First day of school',
    'Church service',
    'Dinner with friends',
    'Meet the parents',
    'Weekend vibe',
    'Casual Friday',
    'Night out',
    'Formal event',
    'Beach day',
    'Work presentation',
  ];

  final List<String> _moodOptions = [
    'Casual',
    'Formal',
    'Playful',
    'Elegant',
    'Comfy',
    'Bold',
    'Minimal',
    'Trendy',
  ];

  final List<String> _weatherOptions = [
    'Hot & sunny',
    'Cool & breezy',
    'Cold & crisp',
    'Rainy day',
    'Indoor event',
  ];

  final List<String> _colorOptions = [
    'Neutral',
    'Vibrant',
    'Pastel',
    'Monochrome',
    'Earthy',
    'Bold colors',
  ];

  @override
  void dispose() {
    _occasionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_occasionController.text.trim().isEmpty && _selectedOccasions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an occasion or select from options'),
        ),
      );
      return;
    }

    final occasion = _selectedOccasions.isNotEmpty
        ? _selectedOccasions.first
        : _occasionController.text.trim();

    final request = SwipeClosetRequest(
      occasion: occasion,
      mood: _selectedMood,
      weather: _selectedWeather,
      colorPreference: _selectedColor,
      notes: _occasionController.text.trim().isNotEmpty
          ? _occasionController.text.trim()
          : null,
    );

    AppLogger.info(
      '🎯 Swipe closet request created',
      data: {
        'occasion': request.occasion,
        'mood': request.mood,
        'weather': request.weather,
        'colorPreference': request.colorPreference,
      },
    );

    // Store the request and close the sheet
    ref.read(swipePlannerProviders.swipeRequestProvider.notifier).state =
        request;
    Navigator.pop(context, request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Plan an Outfit',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell me about your plans and I\'ll help you find the perfect look',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Free-form occasion input
                  TextField(
                    controller: _occasionController,
                    decoration: InputDecoration(
                      labelText: 'What\'s the occasion?',
                      hintText:
                          'e.g., Dinner with friends, First day of school, Beach day...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Quick occasion chips
                  Text(
                    'Or choose from common occasions:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _occasionChips.map((occasion) {
                      final isSelected = _selectedOccasions.contains(occasion);
                      return FilterChip(
                        label: Text(occasion),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedOccasions.clear();
                              _selectedOccasions.add(occasion);
                            } else {
                              _selectedOccasions.remove(occasion);
                            }
                          });
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Optional preferences
                  if (_selectedOccasions.isNotEmpty ||
                      _occasionController.text.isNotEmpty) ...[
                    Text(
                      'Optional preferences:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mood selector
                    Text(
                      'Vibe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moodOptions.map((mood) {
                        return ChoiceChip(
                          label: Text(mood),
                          selected: _selectedMood == mood,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMood = selected ? mood : null;
                            });
                          },
                          selectedColor: theme.colorScheme.secondaryContainer,
                          checkmarkColor: theme.colorScheme.secondary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Weather selector
                    Text(
                      'Weather',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _weatherOptions.map((weather) {
                        return ChoiceChip(
                          label: Text(weather),
                          selected: _selectedWeather == weather,
                          onSelected: (selected) {
                            setState(() {
                              _selectedWeather = selected ? weather : null;
                            });
                          },
                          selectedColor: theme.colorScheme.tertiaryContainer,
                          checkmarkColor: theme.colorScheme.tertiary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color preference selector
                    Text(
                      'Color mood',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        return ChoiceChip(
                          label: Text(color),
                          selected: _selectedColor == color,
                          onSelected: (selected) {
                            setState(() {
                              _selectedColor = selected ? color : null;
                            });
                          },
                          selectedColor:
                              theme.colorScheme.surfaceContainerHighest,
                          checkmarkColor: theme.colorScheme.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Find my perfect look',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Show the swipe planner sheet
Future<SwipeClosetRequest?> showSwipePlannerSheet(BuildContext context) {
  return showModalBottomSheet<SwipeClosetRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SwipePlannerSheet(),
  );
}
