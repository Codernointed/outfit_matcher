import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:outfit_matcher/core/models/clothing_analysis.dart';
import 'package:outfit_matcher/core/services/image_api_service.dart';
import 'package:outfit_matcher/core/utils/gemini_api_service_new.dart';
import 'package:outfit_matcher/core/utils/gallery_service.dart';
import 'package:outfit_matcher/core/utils/logger.dart';
import 'package:photo_view/photo_view.dart';

class EnhancedVisualSearchScreen extends ConsumerStatefulWidget {
  final List<ClothingAnalysis> analyses;
  final String? searchQuery;
  final List<String> itemImages;

  const EnhancedVisualSearchScreen({
    super.key,
    required this.analyses,
    this.searchQuery,
    this.itemImages = const [],
  });

  @override
  ConsumerState<EnhancedVisualSearchScreen> createState() => _EnhancedVisualSearchScreenState();
}

class _EnhancedVisualSearchScreenState extends ConsumerState<EnhancedVisualSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<OnlineInspiration> _inspirations = [];
  List<MannequinOutfit> _mannequinOutfits = [];

  bool _isLoadingInspirations = true;
  bool _isGeneratingMannequins = false;
  String _generationStatus = '';
  int _generationProgress = 0;
  int _totalPoses = 4;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🚀 EnhancedVisualSearchScreen initialized', data: {
      'analyses_count': widget.analyses.length,
      'item_images_count': widget.itemImages.length,
      'search_query': widget.searchQuery,
    });
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAllData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final tabNames = ['Inspiration', 'Try-On', 'Flat Lay'];
      AppLogger.info('📱 Tab switched', data: {
        'tab_index': _tabController.index,
        'tab_name': tabNames[_tabController.index],
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    AppLogger.info('🔄 Loading all visual search data');
    final startTime = DateTime.now();

    try {
      await Future.wait([
        _loadFashionInspirations(),
        _loadMannequinOutfits(),
      ]);

      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('Visual search data loading', duration, result: 'success');
      AppLogger.info('✅ All visual search data loaded successfully', data: {
        'inspirations_count': _inspirations.length,
        'mannequin_outfits_count': _mannequinOutfits.length,
        'duration_ms': duration.inMilliseconds,
      });
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.error('❌ Failed to load visual search data', error: e, stackTrace: stackTrace);
      AppLogger.performance('Visual search data loading', duration, result: 'error');
    }
  }

  String _buildSearchQuery() {
    // Use the provided search query or generate one from analyses
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return widget.searchQuery!;
    }

    // Fallback to generating a query from the analyses
    if (widget.analyses.isNotEmpty) {
      final firstItem = widget.analyses.first;
      final type = firstItem.itemType.toLowerCase();
      final color = firstItem.primaryColor.toLowerCase();
      final style = firstItem.style.toLowerCase();

      return '$color $style $type outfit';
    }

    // Default query
    return 'fashion outfit inspiration';
  }

  Future<void> _loadFashionInspirations() async {
    if (!mounted) return;

    setState(() => _isLoadingInspirations = true);

    try {
      AppLogger.debug('ℹ️ 🔍 Searching outfit inspiration');
      final query = _buildSearchQuery();
      AppLogger.debug('🔍 Search query: $query');

      final images = await ImageApiService.searchFashionImages(query: query);

      if (mounted) {
        setState(() {
          _inspirations = images.take(20).toList();
          AppLogger.debug('✨ Loaded ${_inspirations.length} inspirations');
        });
      }
    } catch (e) {
      AppLogger.error('❌ Error loading fashion inspirations', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoadingInspirations = false);
      }
    }
  }

  Future<List<MannequinOutfit>> _generateMannequinOutfits() async {
    AppLogger.info('🎨 Starting mannequin generation', data: {
      'analyses_count': widget.analyses.length,
      'item_images_count': widget.itemImages.length,
    });

    final startTime = DateTime.now();
    final outfits = <MannequinOutfit>[];

    if (widget.itemImages.isEmpty) {
      AppLogger.warning('❌ No item images available for mannequin generation');
      return outfits;
    }

    try {
      // Use the new mannequin generation method with progress callbacks
      final generatedOutfits = await GeminiApiService.generateMannequinOutfits(
        widget.analyses,
        onProgress: (status) {
          if (mounted) {
            setState(() => _generationStatus = status);
          }
        },
        onProgressUpdate: (completed, total) {
          if (mounted) {
            setState(() {
              _generationProgress = completed;
              _totalPoses = total;
            });
          }
        },
      );

      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('Mannequin generation', duration, result: 'success');
      AppLogger.info('✅ Generated mannequin outfits successfully', data: {
        'count': generatedOutfits.length,
        'duration_ms': duration.inMilliseconds,
      });

      return generatedOutfits;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.error('❌ Error generating mannequin outfits', error: e, stackTrace: stackTrace);
      AppLogger.performance('Mannequin generation', duration, result: 'error');

      // Fallback: create mock mannequin outfits
      if (widget.analyses.isNotEmpty) {
        final analysis = widget.analyses.first;
        for (int i = 0; i < 4; i++) {
          final pose = _getPoseForIndex(i);
          outfits.add(MannequinOutfit(
            id: 'mannequin_$i',
            items: [analysis],
            imageUrl: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400&h=600&fit=crop&crop=center',
            pose: pose,
            style: ['casual', 'business', 'trendy', 'elegant'][i],
            confidence: 0.8,
          ));
        }
      }

      AppLogger.info('✅ Created fallback mannequin outfits', data: {'count': outfits.length});
    }

    return outfits;
  }

  String _getPoseForIndex(int index) {
    const poses = [
      'standing straight, hands on hips',
      'walking pose, one foot forward',
      'casual standing, one hand in pocket',
      'sitting pose, legs crossed'
    ];
    return poses[index % poses.length];
  }

  Future<void> _loadMannequinOutfits() async {
    if (!mounted) return;

    setState(() {
      _isGeneratingMannequins = true;
      _generationStatus = 'Preparing mannequin generation...';
      _generationProgress = 0;
    });

    try {
      AppLogger.debug('ℹ️ 👤 Generating mannequin outfits');
      final outfits = await _generateMannequinOutfits();

      if (mounted) {
        setState(() {
          _mannequinOutfits = outfits;
          _isGeneratingMannequins = false;
          _generationStatus = '';
          _generationProgress = 0;
          AppLogger.debug('👗 Loaded ${_mannequinOutfits.length} mannequin outfits');
        });
      }
    } catch (e) {
      AppLogger.error('❌ Error generating mannequin outfits', error: e);
      if (mounted) {
        setState(() {
          _isGeneratingMannequins = false;
          _generationStatus = 'Failed to generate mannequins';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Style Inspiration',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.explore_outlined),
              text: 'Inspiration',
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Try-On',
            ),
            Tab(
              icon: Icon(Icons.view_comfy_outlined),
              text: 'Flat Lay',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInspirationTab(),
          _buildTryOnTab(),
          _buildFlatLayTab(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Progress bar for mannequin generation
          if (_isGeneratingMannequins && _totalPoses > 0) ...[
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _generationProgress / _totalPoses,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_generationProgress} of ${_totalPoses} looks created',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ] else ...[
            Text(
              'This may take a moment...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInspirationTab() {
    if (_isLoadingInspirations) {
      return _buildLoadingIndicator('Loading fashion inspiration...');
    }

    if (_inspirations.isEmpty) {
      return _buildEmptyState('No inspiration found', 'Try a different search term');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _inspirations.length,
        itemBuilder: (context, index) {
          final inspiration = _inspirations[index];
          return _buildInspirationCard(inspiration);
        },
      ),
    );
  }

  Widget _buildInspirationCard(OnlineInspiration inspiration) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showInspirationDetail(inspiration),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 0.75,
                child: CachedNetworkImage(
                  imageUrl: inspiration.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surface,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surface,
                    child: Icon(
                      Icons.image_not_supported,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              // Info overlay
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inspiration.title != null)
                      Text(
                        inspiration.title!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.source,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          inspiration.source,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(inspiration.confidence * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTryOnTab() {
    if (_isGeneratingMannequins) {
      return _buildLoadingIndicator('Creating virtual try-on looks...');
    }

    if (_mannequinOutfits.isEmpty) {
      return _buildEmptyState(
        'No virtual try-ons available',
        'We couldn\'t generate any virtual try-ons for your item',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 0, // Cards have their own bottom margin
        childAspectRatio: 0.7, // Better aspect ratio for fashion images
      ),
      itemCount: _mannequinOutfits.length,
      itemBuilder: (context, index) {
        final outfit = _mannequinOutfits[index];
        return _buildMannequinCard(outfit);
      },
    );
  }

  Widget _buildMannequinCard(MannequinOutfit outfit) {
    final theme = Theme.of(context);
    final hasValidImage = outfit.imageUrl.isNotEmpty &&
        (outfit.imageUrl.startsWith('http') || outfit.imageUrl.startsWith('data:'));

    return GestureDetector(
      onTap: hasValidImage ? () => _showMannequinDetail(outfit) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Main image - takes full space
              AspectRatio(
                aspectRatio: 0.7, // Portrait aspect ratio for fashion
                child: hasValidImage
                    ? (outfit.imageUrl.startsWith('data:')
                        ? Image.memory(
                            _dataUrlToBytes(outfit.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: outfit.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildElegantLoading(),
                            errorWidget: (context, url, error) => _buildImageError(),
                          ))
                    : _isGeneratingMannequins
                        ? _buildElegantLoading()
                        : _buildImageError(),
              ),

              // Very subtle download hint - only visible on hover/press
              if (hasValidImage)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _downloadMannequinImage(outfit),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),

              // Retry overlay for failed generations
              if (!hasValidImage && !_isGeneratingMannequins)
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to retry',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _retryMannequinGeneration,
                          style: TextButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantLoading() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Beautiful loading animation
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Creating your look...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Image unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatLayTab() {
    // TODO: Implement flat lay suggestions
    return _buildEmptyState(
      'Coming Soon',
      'Flat lay suggestions will be available in the next update!',
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showMannequinDetail(MannequinOutfit outfit) {
    final theme = Theme.of(context);
    final hasValidImage = outfit.imageUrl.isNotEmpty &&
        (outfit.imageUrl.startsWith('http') || outfit.imageUrl.startsWith('data:'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      outfit.style?.toUpperCase() ?? 'STYLE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Image
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: hasValidImage
                      ? (outfit.imageUrl.startsWith('data:')
                          ? Image.memory(
                              _dataUrlToBytes(outfit.imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : CachedNetworkImage(
                              imageUrl: outfit.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => _buildElegantLoading(),
                              errorWidget: (context, url, error) => _buildImageError(),
                            ))
                      : _buildImageError(),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasValidImage ? () {
                        Navigator.of(context).pop();
                        _downloadMannequinImage(outfit);
                      } : null,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Save to Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Share functionality could go here
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        Icons.share_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadMannequinImage(MannequinOutfit outfit) async {
    if (!mounted) return; // Guard against BuildContext across async gaps

    if (outfit.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image available to download')),
      );
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading image...')),
      );

      bool success = false;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'mannequin_${outfit.style ?? 'style'}_$timestamp.png';

      if (outfit.imageUrl.startsWith('data:')) {
        // Base64 data URL
        success = await GalleryService.saveDataUrlImageToGallery(
          outfit.imageUrl,
          fileName,
        );
      } else if (outfit.imageUrl.startsWith('http')) {
        // Regular URL
        success = await GalleryService.saveUrlImageToGallery(
          outfit.imageUrl,
          fileName,
        );
      } else {
        // Assume base64
        success = await GalleryService.saveBase64ImageToGallery(
          outfit.imageUrl,
          fileName,
        );
      }

      if (success) {
        if (!mounted) return; // Guard after async operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved to gallery!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open Gallery',
              textColor: Colors.white,
              onPressed: () {
                // You could open the gallery app here if needed
              },
            ),
          ),
        );
      } else {
        if (!mounted) return; // Guard after async operation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error downloading mannequin image', error: e);
      if (!mounted) return; // Guard after async operation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _retryMannequinGeneration() {
    setState(() {
      _mannequinOutfits.clear();
    });
    _loadMannequinOutfits();
  }

  Uint8List _dataUrlToBytes(String dataUrl) {
    try {
      // Handle different data URL formats
      String base64Data;
      if (dataUrl.startsWith('data:')) {
        // Standard data URL format: data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...
        final parts = dataUrl.split(',');
        if (parts.length < 2) {
          throw FormatException('Invalid data URL format');
        }
        base64Data = parts[1];
      } else {
        // Raw base64 string
        base64Data = dataUrl;
      }

      // Clean the base64 string
      base64Data = base64Data.replaceAll(RegExp(r'\s+'), ''); // Remove whitespace
      base64Data = base64Data.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), ''); // Keep only valid base64 chars

      // Ensure proper padding
      while (base64Data.length % 4 != 0) {
        base64Data += '=';
      }

      return base64Decode(base64Data);
    } catch (e) {
      AppLogger.error('Error converting data URL to bytes', error: e);
      return Uint8List(0);
    }
  }

  void _showInspirationDetail(OnlineInspiration inspiration) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (inspiration.title != null)
                            Text(
                              inspiration.title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          Text(
                            inspiration.source,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Image
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PhotoView(
                    imageProvider: CachedNetworkImageProvider(inspiration.imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    backgroundDecoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inspiration.description != null) ...[
                      Text(
                        'Description:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inspiration.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Metadata
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Source',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                inspiration.source,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (inspiration.photographer != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photographer',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  inspiration.photographer!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Confidence indicator
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: inspiration.confidence > 0.8
                              ? Colors.green
                              : inspiration.confidence > 0.6
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Match: ${(inspiration.confidence * 100).toInt()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadInspirationImage(inspiration),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadInspirationImage(OnlineInspiration inspiration) async {
    if (!mounted) return; // Guard against BuildContext across async gaps
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading inspiration image...')),
      );

      final success = await GalleryService.saveUrlImageToGallery(
        inspiration.imageUrl,
        'inspiration_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (success) {
        if (!mounted) return; // Guard after async operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inspiration image saved to gallery!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      } else {
        if (!mounted) return; // Guard after async operation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error downloading inspiration image', error: e);
      if (!mounted) return; // Guard after async operation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}