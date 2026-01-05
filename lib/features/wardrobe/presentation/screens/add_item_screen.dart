import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/features/wardrobe/data/firestore_wardrobe_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Screen for adding details to a new clothing item or editing an existing one.
class AddItemScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, String>? aiResults;
  final WardrobeItem? itemToEdit;

  const AddItemScreen({
    super.key,
    required this.imagePath,
    this.aiResults,
    this.itemToEdit,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();

  String? _itemType;
  String? _primaryColor;
  String? _patternType;
  bool _isSaving = false;

  // Options
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

  final Set<String> _selectedOccasions = {};
  final Set<String> _selectedSeasons = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (widget.itemToEdit != null) {
      // Editing Mode
      final item = widget.itemToEdit!;
      _itemType = item.analysis.itemType;
      _primaryColor = item.analysis.primaryColor;
      _patternType = item.analysis.patternType;
      _selectedOccasions.addAll(item.occasions);
      _selectedSeasons.addAll(item.seasons);
      _notesController.text = item.userNotes ?? '';
      // Brand is not stored directly on WardrobeItem top-level, assume in tags or handled elsewhere.
      // For now we just handle what we have. If brand was in tags like "Brand:Zara", parse it.
      final brandTag = item.tags.firstWhere(
        (t) => t.startsWith('Brand:'),
        orElse: () => '',
      );
      if (brandTag.isNotEmpty) {
        _brandController.text = brandTag.substring(6);
      }
    } else if (widget.aiResults != null) {
      // New Item with AI results
      _itemType = widget.aiResults!['itemType'];
      _primaryColor = widget.aiResults!['primaryColor'];
      _patternType = widget.aiResults!['patternType'];
    }

    // Ensure options exist
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itemType == null || _primaryColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select item type and color')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final wardrobeService = getIt<FirestoreWardrobeService>();
      final isEditing = widget.itemToEdit != null;

      // Construct Analysis
      final analysis = ClothingAnalysis(
        id: isEditing ? widget.itemToEdit!.analysis.id : const Uuid().v4(),
        itemType: _itemType!,
        primaryColor: _primaryColor!,
        patternType: _patternType ?? 'Solid',
        style: isEditing
            ? widget.itemToEdit!.analysis.style
            : 'casual', // Default or preserve
        seasons: _selectedSeasons.toList(),
        confidence: 1.0, // Manual entry
        tags: [
          if (_brandController.text.isNotEmpty)
            'Brand:${_brandController.text}',
          _itemType!,
          _primaryColor!,
          ..._selectedOccasions,
        ],
        brand: _brandController.text.isNotEmpty ? _brandController.text : null,
      );

      final newItem = isEditing
          ? widget.itemToEdit!.copyWith(
              analysis: analysis, // Update analysis
              occasions: _selectedOccasions.toList(),
              seasons: _selectedSeasons.toList(),
              userNotes: _notesController.text,
              tags: analysis.tags,
            )
          : WardrobeItem(
              id: const Uuid().v4(),
              analysis: analysis,
              originalImagePath: widget.imagePath,
              occasions: _selectedOccasions.toList(),
              seasons: _selectedSeasons.toList(),
              userNotes: _notesController.text,
              createdAt: DateTime.now(),
              tags: analysis.tags,
            );

      if (isEditing) {
        await wardrobeService.updateWardrobeItem(newItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
        }
      } else {
        await wardrobeService.saveWardrobeItem(newItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to wardrobe')),
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      AppLogger.error('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Tell me about this item'),
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
                      // Hero Image
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
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),

                      // Item Type
                      _buildSmartSuggestionSection(
                        'What type of item is this?',
                        _itemTypeOptions,
                        _itemType,
                        (value) => setState(() => _itemType = value),
                        Icons.checkroom_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Color
                      _buildSmartSuggestionSection(
                        'What\'s the main color?',
                        _colorOptions,
                        _primaryColor,
                        (value) => setState(() => _primaryColor = value),
                        Icons.palette_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Pattern
                      _buildSmartSuggestionSection(
                        'Any pattern or texture?',
                        _patternOptions,
                        _patternType,
                        (value) => setState(() => _patternType = value),
                        Icons.texture_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Occasion
                      _buildNaturalChipSection(
                        'When would you wear this?',
                        _occasionOptions,
                        _selectedOccasions,
                        Icons.event_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Season
                      _buildNaturalChipSection(
                        'Perfect for which seasons?',
                        _seasonOptions,
                        _selectedSeasons,
                        Icons.wb_sunny_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Brand
                      _buildOptionalField(
                        'Brand or store?',
                        'e.g., Zara, H&M, vintage...',
                        Icons.store_outlined,
                        controller: _brandController,
                      ),
                      const SizedBox(height: 24),

                      // Notes
                      _buildOptionalField(
                        'Any special notes?',
                        'Fit, comfort, styling tips...',
                        Icons.note_outlined,
                        maxLines: 3,
                        controller: _notesController,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          onPressed: _isSaving ? null : _saveItem,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const CircularProgressIndicator()
              : Text(
                  isEditing ? 'Update Item' : 'Save & Get Outfit Suggestions',
                ),
        ),
      ),
    );
  }

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

  Widget _buildOptionalField(
    String question,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextEditingController? controller,
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
          controller: controller,
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
