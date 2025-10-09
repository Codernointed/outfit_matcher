import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';

/// Screen for adding details to a new clothing item after image selection.
class AddItemScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, String>? aiResults;

  const AddItemScreen({super.key, required this.imagePath, this.aiResults});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _itemType;
  String? _primaryColor;
  String? _patternType;
  // TODO: Add state for other fields: Occasion, Season, Brand, Notes

  // Dummy options for dropdowns - replace with actual data/enums
  final List<String> _itemTypeOptions = [
    'Top',
    'Bottom',
    'Dress',
    'Outerwear',
    'Accessory',
    'Shoes',
  ];
  final List<String> _colorOptions = [
    'Red',
    'Blue',
    'Green',
    'Black',
    'White',
    'Yellow',
    'Pink',
    'Purple',
    'Orange',
    'Brown',
    'Grey',
    'Beige',
    'Multi-color',
  ];
  final List<String> _patternOptions = [
    'Solid',
    'Striped',
    'Floral',
    'Checkered',
    'Polka Dot',
    'Animal Print',
    'Geometric',
    'Abstract',
  ];
  final List<String> _occasionOptions = [
    'Casual',
    'Formal',
    'Work',
    'Party',
    'Sporty',
    'Evening',
    'Business Casual',
    'Travel',
  ];
  final List<String> _seasonOptions = [
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
    'All Seasons',
  ];

  // For multi-select chips
  final Set<String> _selectedOccasions = {};
  final Set<String> _selectedSeasons = {};

  @override
  void initState() {
    super.initState();
    // Initialize fields from AI results if available
    if (widget.aiResults != null) {
      _itemType = widget.aiResults!['itemType'];
      _primaryColor = widget.aiResults!['primaryColor'];
      _patternType = widget.aiResults!['patternType'];
    }
    // Ensure default values are part of the options list if they exist
    if (_itemType != null && !_itemTypeOptions.contains(_itemType)) {
      _itemTypeOptions.add(_itemType!);
    }
    if (_primaryColor != null && !_colorOptions.contains(_primaryColor)) {
      _colorOptions.add(_primaryColor!);
    }
    if (_patternType != null && !_patternOptions.contains(_patternType)) {
      _patternOptions.add(_patternType!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell me about this item'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultSpacing),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Hero Image with natural presentation
                      Container(
                        height: 280,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey,
                                      size: 60,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),

                      // Smart suggestions with natural flow
                      _buildSmartSuggestionSection(
                        'What type of item is this?',
                        _itemTypeOptions,
                        _itemType,
                        (value) => setState(() => _itemType = value),
                        Icons.checkroom_outlined,
                      ),
                      const SizedBox(height: 32),

                      _buildSmartSuggestionSection(
                        'What\'s the main color?',
                        _colorOptions,
                        _primaryColor,
                        (value) => setState(() => _primaryColor = value),
                        Icons.palette_outlined,
                      ),
                      const SizedBox(height: 32),

                      _buildSmartSuggestionSection(
                        'Any pattern or texture?',
                        _patternOptions,
                        _patternType,
                        (value) => setState(() => _patternType = value),
                        Icons.texture_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Natural occasion selection
                      _buildNaturalChipSection(
                        'When would you wear this?',
                        _occasionOptions,
                        _selectedOccasions,
                        Icons.event_outlined,
                      ),
                      const SizedBox(height: 32),

                      _buildNaturalChipSection(
                        'Perfect for which seasons?',
                        _seasonOptions,
                        _selectedSeasons,
                        Icons.wb_sunny_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Optional details with natural styling
                      _buildOptionalField(
                        'Brand or store?',
                        'e.g., Zara, H&M, vintage...',
                        Icons.store_outlined,
                      ),
                      const SizedBox(height: 24),

                      _buildOptionalField(
                        'Any special notes?',
                        'Fit, comfort, styling tips...',
                        Icons.note_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(
                        height: 100,
                      ), // Extra space for floating button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item saved (mock)')),
              );
              // Navigate back to previous screen
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Save & Get Outfit Suggestions'),
        ),
      ),
    );
  }

  // Natural suggestion section with conversational feel
  Widget _buildSmartSuggestionSection(
    String question,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Natural chip selection with conversational feel
  Widget _buildNaturalChipSection(
    String question,
    List<String> options,
    Set<String> selectedOptions,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedOptions.remove(option);
                  } else {
                    selectedOptions.add(option);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Optional field with natural styling
  Widget _buildOptionalField(
    String question,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
