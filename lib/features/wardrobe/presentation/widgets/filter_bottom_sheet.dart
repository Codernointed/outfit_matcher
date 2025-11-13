import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/wardrobe/presentation/providers/wardrobe_search_providers.dart';

/// Bottom sheet for filtering wardrobe items
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late WardrobeFilterCriteria _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = ref.read(filterCriteriaProvider);
  }

  void _applyFilters() {
    ref.read(filterCriteriaProvider.notifier).state = _localFilters;
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _localFilters = const WardrobeFilterCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableCategories =
        ref.watch(availableCategoriesProvider).value ?? [];
    final availableColors = ref.watch(availableColorsProvider).value ?? [];
    final availableSeasons = ref.watch(availableSeasonsProvider);
    final availableOccasions = ref.watch(availableOccasionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Wardrobe',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_localFilters.hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          // Filters content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Favorites toggle
                  SwitchListTile(
                    title: const Text('Favorites Only'),
                    subtitle: const Text('Show only favorited items'),
                    value: _localFilters.favoritesOnly,
                    onChanged: (value) {
                      setState(() {
                        _localFilters = _localFilters.copyWith(
                          favoritesOnly: value,
                        );
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 24),

                  // Categories
                  _buildFilterSection(
                    title: 'Categories',
                    selectedValues: _localFilters.categories,
                    availableValues: availableCategories,
                    onChanged: (values) {
                      setState(() {
                        _localFilters = _localFilters.copyWith(
                          categories: values,
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Colors
                  _buildFilterSection(
                    title: 'Colors',
                    selectedValues: _localFilters.colors,
                    availableValues: availableColors,
                    onChanged: (values) {
                      setState(() {
                        _localFilters = _localFilters.copyWith(colors: values);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Seasons
                  _buildFilterSection(
                    title: 'Seasons',
                    selectedValues: _localFilters.seasons,
                    availableValues: availableSeasons,
                    onChanged: (values) {
                      setState(() {
                        _localFilters = _localFilters.copyWith(seasons: values);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Occasions
                  _buildFilterSection(
                    title: 'Occasions',
                    selectedValues: _localFilters.occasions,
                    availableValues: availableOccasions,
                    onChanged: (values) {
                      setState(() {
                        _localFilters = _localFilters.copyWith(
                          occasions: values,
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _localFilters.hasActiveFilters
                        ? 'Apply Filters'
                        : 'Show All Items',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> selectedValues,
    required List<String> availableValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableValues.map((value) {
            final isSelected = selectedValues.contains(value);

            return FilterChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (selected) {
                final newValues = List<String>.from(selectedValues);
                if (selected) {
                  newValues.add(value);
                } else {
                  newValues.remove(value);
                }
                onChanged(newValues);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
