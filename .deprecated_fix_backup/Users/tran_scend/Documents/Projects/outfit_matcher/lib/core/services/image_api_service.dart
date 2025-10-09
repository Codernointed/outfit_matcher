import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/clothing_analysis.dart';
import '../utils/logger.dart';

class ImageApiService {
  // Free API keys - replace with your own
  // static String get _pexelsApiKey => dotenv.env['PEXELS_API_KEY'] ?? '';
  static final String _pexelsApiKey = dotenv.env['PEXELS_API_KEY']!;
  // static String get _unsplashAccessKey => dotenv.env['UNSPLASH_API_KEY'] ?? '';
  static final String _unsplashAccessKey = dotenv.env['UNSPLASH_API_KEY']!;
  
  static const String _pexelsBaseUrl = 'https://api.pexels.com/v1';
  static const String _unsplashBaseUrl = 'https://api.unsplash.com';

  /// Search for fashion inspiration images using multiple sources
  static Future<List<OnlineInspiration>> searchFashionImages({
    required String query,
    int limit = 20,
  }) async {
    AppLogger.info('🔍 Starting fashion image search', data: {'query': query, 'limit': limit});
    final List<OnlineInspiration> results = [];
    
    try {
      AppLogger.debug('🔄 Attempting Pexels search...');
      final pexelsResults = await _searchPexels(query, limit ~/ 2);
      AppLogger.info('✅ Pexels search complete', data: {'results': pexelsResults.length});
      results.addAll(pexelsResults);
      
      AppLogger.debug('🔄 Attempting Unsplash search...');
      final unsplashResults = await _searchUnsplash(query, limit - pexelsResults.length);
      AppLogger.info('✅ Unsplash search complete', data: {'results': unsplashResults.length});
      results.addAll(unsplashResults);
      
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error in searchFashionImages', error: e, stackTrace: stackTrace);
      AppLogger.info('🔄 Falling back to mock data');
      return _getMockImages(query, limit);
    }
    
    AppLogger.info('🎉 Total fashion images found', data: {'total': results.length});
    return results;
  }

  /// Search Pexels API
  static Future<List<OnlineInspiration>> _searchPexels(String query, int limit) async {
    final url = '$_pexelsBaseUrl/search?query=${Uri.encodeComponent('$query fashion outfit')}&per_page=$limit';
    AppLogger.network(url, 'GET');
    
    try {
      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _pexelsApiKey,
        },
      );
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('Pexels API call', duration, result: response.statusCode);

      AppLogger.network(url, 'GET', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List? ?? [];
        AppLogger.info('📸 Pexels found ${photos.length} photos');
        
        final inspirations = photos.map((photo) => OnlineInspiration(
          id: photo['id'].toString(),
          imageUrl: photo['src']['medium'],
          source: 'Pexels',
          sourceUrl: photo['url'],
          confidence: 0.8,
          photographer: photo['photographer'],
          width: photo['width'],
          height: photo['height'],
          metadata: {
            'alt': photo['alt'] ?? '',
            'avg_color': photo['avg_color'] ?? '',
          },
        )).toList();
        
        AppLogger.debug('✅ Pexels processing complete', data: {'processed': inspirations.length});
        return inspirations;
      } else {
        AppLogger.warning('❌ Pexels API returned error', error: response.statusCode);
        throw Exception('Pexels API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Pexels API error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Search Unsplash API
  static Future<List<OnlineInspiration>> _searchUnsplash(String query, int limit) async {
    final url = '$_unsplashBaseUrl/search/photos?query=${Uri.encodeComponent('$query fashion')}&per_page=$limit';
    AppLogger.network(url, 'GET');
    
    try {
      final startTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Client-ID $_unsplashAccessKey',
        },
      );
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('Unsplash API call', duration, result: response.statusCode);

      AppLogger.network(url, 'GET', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['results'] as List? ?? [];
        AppLogger.info('📸 Unsplash found ${photos.length} photos');
        
        final inspirations = photos.map((photo) => OnlineInspiration(
          id: photo['id'],
          imageUrl: photo['urls']['regular'],
          source: 'Unsplash',
          sourceUrl: photo['links']['html'],
          confidence: 0.9,
          photographer: photo['user']['name'],
          width: photo['width'],
          height: photo['height'],
          description: photo['description'] ?? photo['alt_description'],
          metadata: {
            'likes': photo['likes'],
            'downloads': photo['downloads'],
            'color': photo['color'],
          },
        )).toList();
        
        AppLogger.debug('✅ Unsplash processing complete', data: {'processed': inspirations.length});
        return inspirations;
      } else {
        AppLogger.warning('❌ Unsplash API returned error', error: response.statusCode);
        throw Exception('Unsplash API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Unsplash API error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate mock images as fallback
  static List<OnlineInspiration> _getMockImages(String query, int limit) {
    AppLogger.info('🔄 Generating mock images', data: {'query': query, 'limit': limit});
    final mockImages = <OnlineInspiration>[];
    
    for (int i = 0; i < limit; i++) {
      mockImages.add(OnlineInspiration(
        id: 'mock_$i',
        imageUrl: 'https://picsum.photos/400/600?random=$i',
        source: 'Mock',
        confidence: 0.7,
        title: 'Fashion Inspiration ${i + 1}',
        description: 'Stylish outfit featuring $query',
        tags: [query, 'fashion', 'outfit', 'style'],
      ));
    }
    
    AppLogger.debug('✅ Generated ${mockImages.length} mock images');
    return mockImages;
  }

  /// Search for specific clothing items
  static Future<List<OnlineInspiration>> searchClothingItems({
    required ClothingAnalysis item,
    int limit = 10,
  }) async {
    final query = '${item.itemType} ${item.primaryColor} ${item.style}';
    AppLogger.info('🔍 Searching clothing items', data: {
      'itemType': item.itemType,
      'primaryColor': item.primaryColor,
      'style': item.style,
      'limit': limit
    });
    
    final result = await searchFashionImages(query: query, limit: limit);
    AppLogger.info('🎯 Clothing items search complete', data: {'results': result.length});
    return result;
  }

  /// Search for complete outfits
  static Future<List<OnlineInspiration>> searchOutfitInspiration({
    required List<ClothingAnalysis> items,
    String? occasion,
    int limit = 15,
  }) async {
    final itemTypes = items.map((item) => item.itemType).join(' ');
    final colors = items.map((item) => item.primaryColor).toSet().join(' ');
    final query = '$itemTypes $colors ${occasion ?? "outfit"} fashion';
    
    AppLogger.info('🔍 Searching outfit inspiration', data: {
      'items': itemTypes,
      'colors': colors,
      'occasion': occasion,
      'limit': limit
    });
    
    final result = await searchFashionImages(query: query, limit: limit);
    AppLogger.info('🎯 Outfit inspiration search complete', data: {'results': result.length});
    return result;
  }
}
