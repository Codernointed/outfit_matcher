import 'dart:io';
import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';

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
    if (widget.aiResults != null) {
      _itemType = widget.aiResults!['itemType'];
      _primaryColor = widget.aiResults!['primaryColor'];
      _patternType = widget.aiResults!['patternType'];
    }
    // Ensure default values are part of the options list if they exist
    if (_itemType != null && !_itemTypeOptions.contains(_itemType))
      _itemTypeOptions.add(_itemType!);
    if (_primaryColor != null && !_colorOptions.contains(_primaryColor))
      _colorOptions.add(_primaryColor!);
    if (_patternType != null && !_patternOptions.contains(_patternType))
      _patternOptions.add(_patternType!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Save Item',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // TODO: Implement save logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item saved (mock)')),
                );
                // TODO: Navigate appropriately after save (e.g., back to closet or home)
                // Example: Pop twice to go back past ImagePreviewScreen
                int popCount = 0;
                Navigator.of(context).popUntil((_) => popCount++ >= 2);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Image Preview
              Center(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Type Dropdown (Example - AI could pre-select this)
              _buildDropdownFormField(
                label: 'Item Type',
                value: _itemType,
                items: _itemTypeOptions,
                onChanged: (value) => setState(() => _itemType = value),
                validator:
                    (value) =>
                        value == null ? 'Please select an item type' : null,
              ),
              const SizedBox(height: 16),

              // Primary Color Dropdown (Example)
              _buildDropdownFormField(
                label: 'Primary Color',
                value: _primaryColor,
                items: _colorOptions,
                onChanged: (value) => setState(() => _primaryColor = value),
                validator:
                    (value) => value == null ? 'Please select a color' : null,
              ),
              const SizedBox(height: 16),

              // Pattern Type Dropdown (Example)
              _buildDropdownFormField(
                label: 'Pattern Type',
                value: _patternType,
                items: _patternOptions,
                onChanged: (value) => setState(() => _patternType = value),
              ),
              const SizedBox(height: 24),

              // Occasion Tags (Multi-select Chips)
              _buildChipSelectionFormField(
                label: 'Occasions (Select one or more)',
                allOptions: _occasionOptions,
                selectedOptions: _selectedOccasions,
                onSelected: (selected) {
                  setState(() {
                    if (_selectedOccasions.contains(selected)) {
                      _selectedOccasions.remove(selected);
                    } else {
                      _selectedOccasions.add(selected);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Season Appropriateness (Multi-select Chips)
              _buildChipSelectionFormField(
                label: 'Seasons (Select one or more)',
                allOptions: _seasonOptions,
                selectedOptions: _selectedSeasons,
                onSelected: (selected) {
                  setState(() {
                    if (_selectedSeasons.contains(selected)) {
                      _selectedSeasons.remove(selected);
                    } else {
                      _selectedSeasons.add(selected);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Brand TextFormField
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  border: OutlineInputBorder(),
                ),
                // onSaved: ...
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                // onSaved: ...
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: items.contains(value) ? value : null,
      isExpanded: true,
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildChipSelectionFormField({
    required String label,
    required List<String> allOptions,
    required Set<String> selectedOptions,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              allOptions.map((option) {
                final isSelected = selectedOptions.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (bool newValue) {
                    onSelected(option);
                  },
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                );
              }).toList(),
        ),
      ],
    );
  }
}
