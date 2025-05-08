import 'dart:io';
import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/features/outfit_suggestions/presentation/screens/outfit_suggestions_screen.dart';
import 'package:outfit_matcher/features/wardrobe/domain/entities/clothing_item.dart';

/// Screen for entering details about a clothing item
class ItemDetailsScreen extends StatefulWidget {
  /// Path to the image of the clothing item
  final String imagePath;

  /// Default constructor
  const ItemDetailsScreen({required this.imagePath, super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  /// Selected clothing type
  ClothingType _selectedType = ClothingType.top;

  /// Selected clothing color
  ClothingColor _selectedColor = ClothingColor.blue;

  /// Selected clothing occasion
  ClothingOccasion _selectedOccasion = ClothingOccasion.casual;

  /// Notes about the item
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [TextButton(onPressed: _saveItem, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image preview
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(
                    AppConstants.smallBorderRadius,
                  ),
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.largeSpacing),

            // Item type selection
            _buildDropdownField(
              'Item Type',
              ClothingType.values.map((type) {
                return DropdownMenuItem<ClothingType>(
                  value: type,
                  child: Text(_capitalizeEnum(type.toString().split('.').last)),
                );
              }).toList(),
              _selectedType,
              (ClothingType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedType = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultSpacing),

            // Primary color selection
            _buildDropdownField(
              'Primary Color',
              ClothingColor.values.map((color) {
                return DropdownMenuItem<ClothingColor>(
                  value: color,
                  child: Text(
                    _capitalizeEnum(color.toString().split('.').last),
                  ),
                );
              }).toList(),
              _selectedColor,
              (ClothingColor? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedColor = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultSpacing),

            // Occasion selection
            _buildDropdownField(
              'Occasion',
              ClothingOccasion.values.map((occasion) {
                return DropdownMenuItem<ClothingOccasion>(
                  value: occasion,
                  child: Text(
                    _capitalizeEnum(occasion.toString().split('.').last),
                  ),
                );
              }).toList(),
              _selectedOccasion,
              (ClothingOccasion? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedOccasion = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: AppConstants.defaultSpacing),

            // Notes field
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.smallSpacing),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any additional details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.largeSpacing * 2),

            // Save button
            ElevatedButton(
              onPressed: _saveItem,
              child: const Text('Save & Get Outfit Suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a dropdown field with label
  Widget _buildDropdownField<T>(
    String label,
    List<DropdownMenuItem<T>> items,
    T value,
    Function(T?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppConstants.smallSpacing),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(
                AppConstants.smallBorderRadius,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Capitalize the first letter of a string
  String _capitalizeEnum(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Save the clothing item
  void _saveItem() {
    // TODO: Implement saving the item
    // Create a unique ID for the item
    final String id = DateTime.now().millisecondsSinceEpoch.toString();

    // Create the clothing item
    final ClothingItem item = ClothingItem(
      id: id,
      type: _selectedType,
      color: _selectedColor,
      occasion: _selectedOccasion,
      imagePath: widget.imagePath,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    // Save the item and navigate to outfit suggestions
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OutfitSuggestionsScreen(item: item),
      ),
    );
  }
}
