import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogItem {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final double price;
  final String type;
  final String color;
  final String pattern;

  const CatalogItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.color,
    required this.pattern,
  });
}

class VisualSearchScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>>? mannequinOutfits;
  
  // Main constructor with analysis data
  const VisualSearchScreen({
    super.key,
    required this.imagePath,
    this.analysis,
    this.mannequinOutfits,
  });
  
  // Factory constructor for backward compatibility
  factory VisualSearchScreen.withDetails({
    Key? key,
    required String imagePath,
    required String itemType,
    required String primaryColor,
    required String patternType,
  }) {
    return VisualSearchScreen(
      key: key,
      imagePath: imagePath,
      analysis: {
        'itemType': itemType,
        'primaryColor': primaryColor,
        'patternType': patternType,
      },
    );
  }

  @override
  ConsumerState<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends ConsumerState<VisualSearchScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingSimilar = true;
  bool _isLoadingComplements = true;
  String? _errorMessageSimilar;
  String? _errorMessageComplements;
  List<CatalogItem> _similarItems = [];
  List<CatalogItem> _complementaryItems = [];
  final ScrollController _scrollController = ScrollController();
  
  // Item properties extracted from analysis
  late String _itemType;
  late String _primaryColor;
  late String _patternType;
  
  // Tab controller for the tab bar
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Initialize with default values
    _itemType = 'clothing';
    _primaryColor = 'neutral';
    _patternType = 'solid';
    
    // If we have analysis data, use it
    if (widget.analysis != null) {
      _itemType = widget.analysis!['itemType'] ?? _itemType;
      _primaryColor = widget.analysis!['primaryColor'] ?? _primaryColor;
      _patternType = widget.analysis!['patternType'] ?? _patternType;
    }
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    // If we have mannequin outfits, add them to the similar items
    if (widget.mannequinOutfits != null && widget.mannequinOutfits!.isNotEmpty) {
      setState(() {
        _similarItems = widget.mannequinOutfits!.map((outfit) => CatalogItem(
          id: 'mannequin_${outfit['pose'] ?? 'pose'}_${DateTime.now().millisecondsSinceEpoch}',
          imageUrl: outfit['imageUrl'] ?? '',
          title: 'Mannequin (${outfit['pose'] ?? 'view'})',
          description: 'Generated mannequin wearing your item',
          price: 0.0,
          type: _itemType,
          color: _primaryColor,
          pattern: _patternType,
        )).toList();
        _isLoadingSimilar = false;
      });
    } else {
      await _loadSimilarItems();
    }
    
    await _loadComplementaryItems();
  }

  Future<void> _loadSimilarItems() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // This would be replaced with actual API call
      if (mounted) {
        setState(() {
          _similarItems = [
            // Sample data - replace with actual API response
            CatalogItem(
              id: '1',
              imageUrl: 'https://via.placeholder.com/300',
              title: 'Similar Item 1',
              description: 'Description for similar item 1',
              price: 49.99,
              type: _itemType,
              color: _primaryColor,
              pattern: _patternType,
            ),
            // Add more sample items as needed
          ];
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageSimilar = 'Failed to load similar items. Please try again.';
          _isLoadingSimilar = false;
        });
      }
    }
  }

  Future<void> _loadComplementaryItems() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // This would be replaced with actual API call
      if (mounted) {
        setState(() {
          _complementaryItems = [
            // Sample data - replace with actual API response
            CatalogItem(
              id: 'c1',
              imageUrl: 'https://via.placeholder.com/300',
              title: 'Complementary Item 1',
              description: 'Description for complementary item 1',
              price: 59.99,
              type: 'complementary',
              color: _primaryColor,
              pattern: _patternType,
            ),
            // Add more sample items as needed
          ];
          _isLoadingComplements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageComplements = 'Failed to load complementary items. Please try again.';
          _isLoadingComplements = false;
        });
      }
    }
  }

  Widget _buildSimilarItemsTab() {
    if (_isLoadingSimilar) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessageSimilar != null) {
      return Center(child: Text(_errorMessageSimilar!));
    }

    return _buildItemsGrid(_similarItems);
  }

  Widget _buildComplementsTab() {
    if (_isLoadingComplements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessageComplements != null) {
      return Center(child: Text(_errorMessageComplements!));
    }

    return _buildItemsGrid(_complementaryItems);
  }

  Widget _buildItemsGrid(List<CatalogItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(CatalogItem item) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Search Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Similar Items'),
            Tab(text: 'Complements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSimilarItemsTab(),
          _buildComplementsTab(),
        ],
      ),
    );
  }
}
