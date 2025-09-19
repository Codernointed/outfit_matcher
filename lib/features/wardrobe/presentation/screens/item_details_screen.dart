import 'dart:io';
import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/core/models/clothing_analysis.dart';
import 'package:outfit_matcher/core/utils/gemini_api_service_new.dart';
import 'package:outfit_matcher/features/wardrobe/domain/entities/clothing_item.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';
import 'package:lottie/lottie.dart';

/// Screen for viewing and confirming AI-analyzed clothing item details
class ItemDetailsScreen extends StatefulWidget {
  /// List of image paths for the clothing items
  final List<String> imagePaths;

  /// Default constructor
  const ItemDetailsScreen({
    required this.imagePaths,
    super.key,
  });

  /// Constructor for single image
  factory ItemDetailsScreen.single({required String imagePath}) {
    return ItemDetailsScreen(imagePaths: [imagePath]);
  }

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isAnalyzing = true;
  ClothingAnalysis? _analysis;
  String? _error;

  /// Selected clothing type
  ClothingType _selectedType = ClothingType.top;

  /// Selected clothing color
  ClothingColor _selectedColor = ClothingColor.blue;

  /// Selected clothing occasion
  ClothingOccasion _selectedOccasion = ClothingOccasion.casual;

  /// Selected pattern type
  ClothingPattern _selectedPattern = ClothingPattern.solid;

  /// Selected material
  ClothingMaterial _selectedMaterial = ClothingMaterial.cotton;

  /// Selected fit
  ClothingFit _selectedFit = ClothingFit.regular;

  /// Selected formality level
  ClothingFormality _selectedFormality = ClothingFormality.casual;

  /// Animation controller for loading animation
  late AnimationController _animationController;

  /// Available options for the UI
  final List<ClothingType> _itemTypeOptions = ClothingType.values.toList();
  final List<ClothingColor> _colorOptions = ClothingColor.values.toList();
  final List<ClothingOccasion> _occasionOptions = ClothingOccasion.values.toList();
  final List<ClothingPattern> _patternOptions = ClothingPattern.values.toList();
  final List<ClothingMaterial> _materialOptions = ClothingMaterial.values.toList();
  final List<ClothingFit> _fitOptions = ClothingFit.values.toList();
  final List<ClothingFormality> _formalityOptions = ClothingFormality.values.toList();
  final Set<String> _selectedSeasons = {};
  final List<String> _seasonOptions = ['Spring', 'Summer', 'Fall', 'Winter'];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _brandController.dispose();
    _subcategoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Start analysis
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final files = widget.imagePaths.map((path) => File(path)).toList();
      final analyses = await GeminiApiService.analyzeMultipleItems(files);
      
      if (mounted) {
        if (analyses.isNotEmpty) {
          // For now, we'll use the first analysis, but you could combine them
          final firstAnalysis = analyses.first;
          setState(() {
            _analysis = firstAnalysis;
            // Update UI with analysis results
            _selectedType = _mapStringToClothingType(_analysis?.itemType ?? 'top');
            _selectedColor = _mapStringToClothingColor(_analysis?.primaryColor ?? 'blue');
            _selectedOccasion = _mapStringToClothingOccasion(_analysis?.style ?? 'casual');
            _selectedPattern = _mapStringToClothingPattern(_analysis?.patternType ?? 'solid');
            _selectedMaterial = _mapStringToClothingMaterial(_analysis?.material ?? 'cotton');
            _selectedFit = _mapStringToClothingFit(_analysis?.fit ?? 'regular');
            _selectedFormality = _mapStringToClothingFormality(_analysis?.formality ?? 'casual');
            
            // Prefill text controllers with analysis data
            if (_analysis?.brand != null && _analysis!.brand!.isNotEmpty) {
              _brandController.text = _analysis!.brand!;
            }
            if (_analysis?.subcategory != null && _analysis!.subcategory!.isNotEmpty) {
              _subcategoryController.text = _analysis!.subcategory!;
            }
            
            _isAnalyzing = false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Could not analyze the images. Please try again.';
            _isAnalyzing = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error analyzing images. Please check your connection and try again.';
          _isAnalyzing = false;
          _isLoading = false;
        });
      }
    }
  }

  ClothingType _mapStringToClothingType(String type) {
    return ClothingType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == type.toLowerCase(),
      orElse: () => ClothingType.top,
    );
  }

  ClothingColor _mapStringToClothingColor(String color) {
    return ClothingColor.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == color.toLowerCase(),
      orElse: () => ClothingColor.blue,
    );
  }

  ClothingOccasion _mapStringToClothingOccasion(String occasion) {
    return ClothingOccasion.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == occasion.toLowerCase(),
      orElse: () => ClothingOccasion.casual,
    );
  }

  ClothingPattern _mapStringToClothingPattern(String pattern) {
    return ClothingPattern.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == pattern.toLowerCase(),
      orElse: () => ClothingPattern.solid,
    );
  }

  ClothingMaterial _mapStringToClothingMaterial(String material) {
    return ClothingMaterial.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == material.toLowerCase(),
      orElse: () => ClothingMaterial.cotton,
    );
  }

  ClothingFit _mapStringToClothingFit(String fit) {
    return ClothingFit.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == fit.toLowerCase(),
      orElse: () => ClothingFit.regular,
    );
  }

  ClothingFormality _mapStringToClothingFormality(String formality) {
    return ClothingFormality.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == formality.toLowerCase(),
      orElse: () => ClothingFormality.casual,
    );
  }

  Future<void> _saveAndContinue() async {
    if (_analysis == null) return;
    
    // Update the analysis with user's changes before proceeding
    _updateAnalysis();

    // Create a more specific search query
    final searchQuery = _buildSearchQuery();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EnhancedVisualSearchScreen(
            analyses: [_analysis!],
            searchQuery: searchQuery,
            itemImages: widget.imagePaths,
          ),
        ),
      );
    }
  }
  
  String _buildSearchQuery() {
    final type = _selectedType.toString().split('.').last.toLowerCase();
    final color = _selectedColor.toString().split('.').last.toLowerCase();
    final occasion = _selectedOccasion.toString().split('.').last.toLowerCase();
    
    // Create a more specific search query based on item type and occasion
    switch (type) {
      case 'top':
        return '$color $occasion outfit with ${_analysis?.subcategory ?? ''} top';
      case 'bottom':
        return '$color $occasion outfit with ${_analysis?.subcategory ?? ''} bottom';
      case 'dress':
        return '$color $occasion ${_analysis?.subcategory ?? ''} dress outfit';
      case 'shoes':
        return '$color $occasion shoes with ${_analysis?.subcategory ?? ''}';
      case 'accessory':
        return '$color $occasion ${_analysis?.subcategory ?? 'accessory'} outfit';
      default:
        return '$color $occasion $type outfit';
    }
  }

  void _updateAnalysis() {
    if (_analysis != null) {
      _analysis = ClothingAnalysis(
        id: _analysis!.id,
        itemType: _selectedType.toString().split('.').last,
        primaryColor: _selectedColor.toString().split('.').last,
        patternType: _analysis?.patternType ?? '',
        style: _selectedOccasion.toString().split('.').last,
        seasons: _analysis?.seasons ?? [],
        confidence: _analysis?.confidence ?? 0.8,
        tags: _analysis?.tags ?? [],
        brand: _analysis?.brand,
        material: _analysis?.material,
        neckline: _analysis?.neckline,
        sleeveLength: _analysis?.sleeveLength,
        fit: _analysis?.fit,
        isPatterned: _analysis?.isPatterned ?? false,
        imagePath: _analysis?.imagePath,
        formality: _analysis?.formality,
        subcategory: _analysis?.subcategory,
        colors: _analysis?.colors,
        texture: _analysis?.texture,
        length: _analysis?.length,
        silhouette: _analysis?.silhouette,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Me About This Item'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _error != null
              ? _buildErrorState(theme)
              : _buildContent(theme),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isAnalyzing
              ? Lottie.asset(
                  'assets/animations/clothing_analysis.json',
                  width: 200,
                  height: 200,
                  controller: _animationController,
                  fit: BoxFit.cover,
                )
              : const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _isAnalyzing ? 'Analyzing your item...' : 'Loading...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          if (_isAnalyzing) ...[
            const SizedBox(height: 8),
            Text(
              'Our AI is examining the details of your clothing item',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeImage,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item images preview
          Container(
            height: 300,
            margin: const EdgeInsets.only(bottom: 24),
            child: PageView.builder(
              itemCount: widget.imagePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Hero(
                    tag: 'item-${widget.imagePaths[index]}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(widget.imagePaths[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
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
                  ),
                );
              },
            ),
          ),
          
          // Image indicators
          if (widget.imagePaths.length > 1) ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.imagePaths.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == 0 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI Analysis Summary
          if (_analysis?.confidence != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(_analysis!.confidence * 100).toStringAsFixed(0)}% Confident',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Item type selection
          _buildSmartSuggestionSection(
            'What type of item is this?',
            _itemTypeOptions,
            _selectedType,
            (value) => setState(() => _selectedType = value),
            Icons.checkroom_outlined,
          ),
          const SizedBox(height: 24),

          // Color selection
          _buildSmartSuggestionSection(
            'What\'s the main color?',
            _colorOptions,
            _selectedColor,
            (value) => setState(() => _selectedColor = value),
            Icons.palette_outlined,
          ),
          const SizedBox(height: 24),

          // Occasion selection
          _buildSmartSuggestionSection(
            'When would you wear this?',
            _occasionOptions,
            _selectedOccasion,
            (value) => setState(() => _selectedOccasion = value),
            Icons.event_available_outlined,
          ),
          const SizedBox(height: 24),

          // Pattern selection
          _buildSmartSuggestionSection(
            'Any pattern or texture?',
            _patternOptions,
            _selectedPattern,
            (value) => setState(() => _selectedPattern = value),
            Icons.texture_outlined,
          ),
          const SizedBox(height: 24),

          // Material selection
          _buildSmartSuggestionSection(
            'What\'s the main material?',
            _materialOptions,
            _selectedMaterial,
            (value) => setState(() => _selectedMaterial = value),
            Icons.layers_outlined,
          ),
          const SizedBox(height: 24),

          // Fit selection
          _buildSmartSuggestionSection(
            'How does it fit?',
            _fitOptions,
            _selectedFit,
            (value) => setState(() => _selectedFit = value),
            Icons.straighten_outlined,
          ),
          const SizedBox(height: 24),

          // Formality selection
          _buildSmartSuggestionSection(
            'What\'s the formality level?',
            _formalityOptions,
            _selectedFormality,
            (value) => setState(() => _selectedFormality = value),
            Icons.business_center_outlined,
          ),
          const SizedBox(height: 24),

          // Seasons selection
          _buildNaturalChipSection(
            'Perfect for which seasons?',
            _seasonOptions,
            _selectedSeasons,
            Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 24),

          // Subcategory (optional)
          _buildOptionalField(
            'Specific type or subcategory?',
            'e.g., crew neck t-shirt, skinny jeans, blazer...',
            _subcategoryController,
            Icons.category_outlined,
          ),
          const SizedBox(height: 24),

          // Brand (optional)
          _buildOptionalField(
            'Brand or store?',
            'e.g., Zara, H&M, vintage...',
            _brandController,
            Icons.store_outlined,
          ),
          const SizedBox(height: 24),
          
          // Notes (optional)
          _buildOptionalField(
            'Any special notes?',
            'Fit, comfort, styling tips...',
            _notesController,
            Icons.note_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveAndContinue,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: const Text('Find Matching Outfits'),
      ),
    );
  }

  // Smart suggestion section with conversational feel
  Widget _buildSmartSuggestionSection<T>(
    String question,
    List<T> options,
    T selectedValue,
    ValueChanged<T> onChanged,
    IconData icon, {
    bool multiSelect = false,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _capitalizeEnum(option.toString().split('.').last),
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
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
    TextEditingController controller,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  /// Capitalize the first letter of a string
  String _capitalizeEnum(String enumString) {
    if (enumString.isEmpty) return enumString;
    // Handle camelCase by adding spaces and capitalizing each word
    final words = enumString.split(RegExp(r'(?=[A-Z])'));
    return words.map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  // Natural chip section for multi-select
  Widget _buildNaturalChipSection(
    String question,
    List<String> options,
    Set<String> selectedValues,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedValues.remove(option);
                  } else {
                    selectedValues.add(option);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
