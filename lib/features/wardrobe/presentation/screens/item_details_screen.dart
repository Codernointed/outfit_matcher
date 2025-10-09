import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/wardrobe/domain/entities/clothing_item.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_visual_search_screen.dart';
import 'package:lottie/lottie.dart';

class ItemDetailsScreen extends StatefulWidget {
  final List<String> imagePaths;

  const ItemDetailsScreen({required this.imagePaths, super.key});

  factory ItemDetailsScreen.single({required String imagePath}) {
    return ItemDetailsScreen(imagePaths: [imagePath]);
  }

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemEditorState {
  _ItemEditorState({required this.imagePath})
    : brandController = TextEditingController(),
      subcategoryController = TextEditingController();

  final String imagePath;
  ClothingAnalysis? analysis;
  ClothingType selectedType = ClothingType.top;
  ClothingColor selectedColor = ClothingColor.blue;
  ClothingOccasion selectedOccasion = ClothingOccasion.casual;
  ClothingPattern selectedPattern = ClothingPattern.solid;
  ClothingMaterial selectedMaterial = ClothingMaterial.cotton;
  ClothingFit selectedFit = ClothingFit.regular;
  ClothingFormality selectedFormality = ClothingFormality.casual;
  final Set<String> selectedSeasons = <String>{};
  final TextEditingController brandController;
  final TextEditingController subcategoryController;

  void dispose() {
    brandController.dispose();
    subcategoryController.dispose();
  }
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isAnalyzing = true;
  String? _error;
  late final PageController _pageController;
  late final List<_ItemEditorState> _itemStates;
  late final TextEditingController _globalNotesController;
  int _currentIndex = 0;
  String _currentGender = 'female'; // Default gender
  final ProfileService _profileService = getIt<ProfileService>();

  _ItemEditorState get _currentState => _itemStates[_currentIndex];
  bool get _canContinue =>
      !_isAnalyzing && _itemStates.every((state) => state.analysis != null);
  List<String> get _imagePaths =>
      _itemStates.map((state) => state.imagePath).toList(growable: false);

  late AnimationController _animationController;

  final List<ClothingType> _itemTypeOptions = ClothingType.values.toList();
  final List<ClothingColor> _colorOptions = ClothingColor.values.toList();
  final List<ClothingOccasion> _occasionOptions = ClothingOccasion.values
      .toList();
  final List<ClothingPattern> _patternOptions = ClothingPattern.values.toList();
  final List<ClothingMaterial> _materialOptions = ClothingMaterial.values
      .toList();
  final List<ClothingFit> _fitOptions = ClothingFit.values.toList();
  final List<ClothingFormality> _formalityOptions = ClothingFormality.values
      .toList();
  final List<String> _seasonOptions = ['Spring', 'Summer', 'Fall', 'Winter'];

  @override
  void initState() {
    super.initState();
    AppLogger.info('📝 Item Details Screen initialized');
    _itemStates = widget.imagePaths
        .map((path) => _ItemEditorState(imagePath: path))
        .toList();
    _pageController = PageController();
    _globalNotesController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadGenderPreference();
    _analyzeImages();
  }

  Future<void> _loadGenderPreference() async {
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _currentGender = profile.preferredGender.apiValue;
      });
      AppLogger.info('✅ Loaded gender preference: $_currentGender');
    } catch (e) {
      AppLogger.error('❌ Error loading gender preference', error: e);
    }
  }

  @override
  void dispose() {
    for (final state in _itemStates) {
      state.dispose();
    }
    _pageController.dispose();
    _globalNotesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImages() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final files = widget.imagePaths.map(File.new).toList();
      final analyses = await GeminiApiService.analyzeMultipleItems(files);

      if (!mounted) return;

      if (analyses.isEmpty) {
        setState(() {
          _error = 'Could not analyze the images. Please try again.';
          _isAnalyzing = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        for (var i = 0; i < _itemStates.length; i++) {
          final state = _itemStates[i];
          if (i < analyses.length) {
            final analysis = analyses[i].copyWith(imagePath: state.imagePath);
            _applyAnalysisToState(state, analysis);
          }
        }

        if (_itemStates.isNotEmpty && _itemStates.first.analysis == null) {
          _itemStates.first.analysis = analyses.first;
        }

        _isAnalyzing = false;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Error analyzing images. Please check your connection and try again.';
          _isAnalyzing = false;
          _isLoading = false;
        });
      }
    }
  }

  void _applyAnalysisToState(
    _ItemEditorState state,
    ClothingAnalysis analysis,
  ) {
    state.analysis = analysis;
    state.selectedType = _mapStringToClothingType(analysis.itemType);
    state.selectedColor = _mapStringToClothingColor(analysis.primaryColor);
    state.selectedOccasion = _mapStringToClothingOccasion(analysis.style);
    state.selectedPattern = _mapStringToClothingPattern(analysis.patternType);
    state.selectedMaterial = _mapStringToClothingMaterial(
      analysis.material ?? 'cotton',
    );
    state.selectedFit = _mapStringToClothingFit(analysis.fit ?? 'regular');
    state.selectedFormality = _mapStringToClothingFormality(
      analysis.formality ?? 'casual',
    );
    state.selectedSeasons
      ..clear()
      ..addAll(analysis.seasons);
    state.brandController.text = analysis.brand ?? '';
    state.subcategoryController.text = analysis.subcategory ?? '';
  }

  ClothingType _mapStringToClothingType(String type) {
    return ClothingType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ClothingType.top,
    );
  }

  ClothingColor _mapStringToClothingColor(String color) {
    return ClothingColor.values.firstWhere(
      (e) => e.name.toLowerCase() == color.toLowerCase(),
      orElse: () => ClothingColor.blue,
    );
  }

  ClothingOccasion _mapStringToClothingOccasion(String occasion) {
    return ClothingOccasion.values.firstWhere(
      (e) => e.name.toLowerCase() == occasion.toLowerCase(),
      orElse: () => ClothingOccasion.casual,
    );
  }

  ClothingPattern _mapStringToClothingPattern(String pattern) {
    return ClothingPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == pattern.toLowerCase(),
      orElse: () => ClothingPattern.solid,
    );
  }

  ClothingMaterial _mapStringToClothingMaterial(String material) {
    return ClothingMaterial.values.firstWhere(
      (e) => e.name.toLowerCase() == material.toLowerCase(),
      orElse: () => ClothingMaterial.cotton,
    );
  }

  ClothingFit _mapStringToClothingFit(String fit) {
    return ClothingFit.values.firstWhere(
      (e) => e.name.toLowerCase() == fit.toLowerCase(),
      orElse: () => ClothingFit.regular,
    );
  }

  ClothingFormality _mapStringToClothingFormality(String formality) {
    return ClothingFormality.values.firstWhere(
      (e) => e.name.toLowerCase() == formality.toLowerCase(),
      orElse: () => ClothingFormality.casual,
    );
  }

  Future<void> _saveAndContinue() async {
    final analyses = _collectAnalyses();

    if (analyses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We need at least one analyzed item to continue.'),
          ),
        );
      }
      return;
    }

    final primaryAnalysis = analyses.first;
    final searchQuery = _buildSearchQuery(primaryAnalysis);
    final userNotes = _collectUserNotes();

    if (!mounted) return;

    FocusScope.of(context).unfocus();

    AppLogger.info(
      '🎯 Navigating to visual search with gender: $_currentGender',
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EnhancedVisualSearchScreen(
          analyses: analyses,
          searchQuery: searchQuery,
          itemImages: _imagePaths,
          userNotes: userNotes,
          preferredGender: _currentGender,
        ),
      ),
    );
  }

  List<ClothingAnalysis> _collectAnalyses() {
    return _itemStates
        .map(_buildUpdatedAnalysis)
        .whereType<ClothingAnalysis>()
        .toList(growable: false);
  }

  ClothingAnalysis? _buildUpdatedAnalysis(_ItemEditorState state) {
    final base = state.analysis;
    if (base == null) return null;

    return base.copyWith(
      itemType: state.selectedType.name,
      primaryColor: state.selectedColor.name,
      style: state.selectedOccasion.name,
      patternType: state.selectedPattern.name,
      material: state.selectedMaterial.name,
      fit: state.selectedFit.name,
      formality: state.selectedFormality.name,
      seasons: state.selectedSeasons.toList(growable: false),
      brand: _normalizeText(state.brandController.text),
      subcategory: _normalizeText(state.subcategoryController.text),
      imagePath: state.imagePath,
    );
  }

  String? _collectUserNotes() {
    final note = _normalizeText(_globalNotesController.text);
    return note;
  }

  String? _normalizeText(String? input) {
    final value = input?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String _buildSearchQuery(ClothingAnalysis analysis) {
    final type = analysis.itemType.toLowerCase();
    final color = analysis.primaryColor.toLowerCase();
    final occasion = analysis.style.toLowerCase();
    final subcategory = (analysis.subcategory ?? '').toLowerCase().trim();

    switch (type) {
      case 'top':
        return '$color $occasion outfit with ${subcategory.isEmpty ? 'stylish top' : subcategory}'
            .trim();
      case 'bottom':
        return '$color $occasion outfit featuring ${subcategory.isEmpty ? 'statement bottoms' : subcategory}'
            .trim();
      case 'dress':
        return '$color $occasion ${subcategory.isEmpty ? 'dress' : subcategory} styling'
            .trim();
      case 'shoes':
      case 'footwear':
        return '$color $occasion footwear outfit inspiration'.trim();
      case 'accessory':
        return '$color $occasion accessory outfit ideas'.trim();
      case 'outerwear':
        return '$color $occasion layered look with ${subcategory.isEmpty ? 'outerwear' : subcategory}'
            .trim();
      default:
        return '$color $occasion $type outfit inspiration'.trim();
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
            _isAnalyzing ? 'Analyzing your items...' : 'Loading...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.8),
            ),
          ),
          if (_isAnalyzing) ...[
            const SizedBox(height: 8),
            Text(
              'Our AI is examining each item to understand its vibe and styling potential.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeImages,
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
          Container(
            height: 300,
            margin: const EdgeInsets.only(bottom: 24),
            child: PageView.builder(
              controller: _pageController,
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
                            color: Colors.black.withValues(alpha:0.1),
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
                  ),
                );
              },
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() => _currentIndex = index);
              },
            ),
          ),

          if (widget.imagePaths.length > 1) ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.imagePaths.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: index == _currentIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: index == _currentIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha:0.2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Align(
            alignment: Alignment.center,
            child: Text(
              'Item ${_currentIndex + 1} of ${widget.imagePaths.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_currentState.analysis?.confidence != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha:0.1),
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
                        '${((_currentState.analysis!.confidence) * 100).toStringAsFixed(0)}% Confident',
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
            const SizedBox(height: 24),
          ],

          // Prominent gender selection section
          _buildGenderSelectionSection(theme),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'What type of item is this?',
            _itemTypeOptions,
            _currentState.selectedType,
            (value) => setState(() => _currentState.selectedType = value),
            Icons.checkroom_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'What\'s the main color?',
            _colorOptions,
            _currentState.selectedColor,
            (value) => setState(() => _currentState.selectedColor = value),
            Icons.palette_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'When would you wear this?',
            _occasionOptions,
            _currentState.selectedOccasion,
            (value) => setState(() => _currentState.selectedOccasion = value),
            Icons.event_available_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'Any pattern or texture?',
            _patternOptions,
            _currentState.selectedPattern,
            (value) => setState(() => _currentState.selectedPattern = value),
            Icons.texture_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'What\'s the main material?',
            _materialOptions,
            _currentState.selectedMaterial,
            (value) => setState(() => _currentState.selectedMaterial = value),
            Icons.layers_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'How does it fit?',
            _fitOptions,
            _currentState.selectedFit,
            (value) => setState(() => _currentState.selectedFit = value),
            Icons.straighten_outlined,
          ),
          const SizedBox(height: 24),

          _buildSmartSuggestionSection(
            'What\'s the formality level?',
            _formalityOptions,
            _currentState.selectedFormality,
            (value) => setState(() => _currentState.selectedFormality = value),
            Icons.business_center_outlined,
          ),
          const SizedBox(height: 24),

          _buildNaturalChipSection(
            'Perfect for which seasons?',
            _seasonOptions,
            _currentState.selectedSeasons,
            Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 24),

          _buildOptionalField(
            'Specific type or subcategory?',
            'e.g., crew neck t-shirt, skinny jeans, blazer...',
            _currentState.subcategoryController,
            Icons.category_outlined,
          ),
          const SizedBox(height: 24),

          _buildOptionalField(
            'Brand or store?',
            'e.g., Zara, H&M, vintage...',
            _currentState.brandController,
            Icons.store_outlined,
          ),
          const SizedBox(height: 24),

          _buildOptionalField(
            'Any special notes?',
            'Fit, comfort, styling tips...',
            _globalNotesController,
            Icons.note_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 100),
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
            color: theme.shadowColor.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _canContinue ? _saveAndContinue : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(
          _canContinue ? 'Find Matching Outfits' : 'Review Item Details',
        ),
      ),
    );
  }

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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
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
            ).colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
    return words
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
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

  Widget _buildGenderSelectionSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha:0.08),
            theme.colorScheme.primaryContainer.withValues(alpha:0.4),
            theme.colorScheme.secondaryContainer.withValues(alpha:0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha:0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha:0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha:0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha:0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mannequin Style Preference',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the mannequin style for outfit previews',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  gender: 'male',
                  icon: Icons.man,
                  label: 'Male',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  gender: 'female',
                  icon: Icons.woman,
                  label: 'Female',
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _currentGender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentGender = gender;
        });
        AppLogger.info('👤 Gender toggled to: $_currentGender');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 160,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha:0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha:0.2),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha:0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha:0.25)
                    : theme.colorScheme.primary.withValues(alpha:0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.white.withValues(alpha:0.3)
                        : theme.colorScheme.primary.withValues(alpha:0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Label
            Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
