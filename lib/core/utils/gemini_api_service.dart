import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clothing_analysis.dart';

class GeminiApiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const String _imageEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';
  static const String _mockImageBaseUrl = 'https://picsum.photos';

  static Future<Map<String, dynamic>?> analyzeClothingItem(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              },
              {
                "text": "You are a fashion assistant. Analyze this clothing item and return a JSON object with the following keys: itemType (e.g. Top, Bottom, Dress, Outerwear, Shoes, Accessory), primaryColor, patternType, style (casual/formal/business), fit (slim/regular/oversized), material (cotton/silk/denim), seasons (array), formality (casual/business/formal), subcategory (specific type like blouse/t-shirt), confidence (0-1). Only return the JSON object, no explanation."
              }
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final content = jsonDecode(response.body);
        final text = content['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);
          return {
            'itemType': result['itemType']?.toString() ?? '',
            'primaryColor': result['primaryColor']?.toString() ?? '',
            'patternType': result['patternType']?.toString() ?? '',
            'style': result['style']?.toString() ?? '',
            'fit': result['fit']?.toString() ?? '',
            'material': result['material']?.toString() ?? '',
            'formality': result['formality']?.toString() ?? '',
            'subcategory': result['subcategory']?.toString() ?? '',
            'confidence': (result['confidence'] as num?)?.toDouble() ?? 0.8,
            'seasons': (result['seasons'] as List?)?.map((e) => e.toString()).toList() ?? [],
          };
        }
      }
      return null;
    } catch (e) {
      print('Gemini API error: $e');
      return null;
    }
  }

  /// Finds visually similar items from the catalog
  static Future<List<Map<String, dynamic>>> findSimilarItems({
    required String itemType,
    String? primaryColor,
    String? patternType,
  }) async {
    // TODO: Implement actual API call to find similar items
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock similar items based on the input
    final mockItems = [
      {
        'id': '1',
        'name': 'Similar $itemType 1',
        'imageUrl': '$_mockImageBaseUrl?text=Similar+1',
        'type': itemType,
        'color': primaryColor ?? 'Black',
        'pattern': patternType ?? 'Solid',
      },
      {
        'id': '2',
        'name': 'Matching $itemType',
        'imageUrl': '$_mockImageBaseUrl?text=Similar+2',
        'type': itemType,
        'color': primaryColor ?? 'Black',
        'pattern': patternType ?? 'Solid',
      },
    ];
    
    return List<Map<String, dynamic>>.from(mockItems);
  }

  /// Finds complementary items that go well with the given item
  static Future<List<Map<String, dynamic>>> findComplementaryItems({
    required String itemType,
    String? primaryColor,
  }) async {
    // TODO: Implement actual API call to find complementary items
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1));
    
    // Define complementary item types based on the input item type
    List<String> complementaryTypes = [];
    switch (itemType.toLowerCase()) {
      case 'top':
        complementaryTypes = ['Bottom', 'Outerwear', 'Accessory'];
        break;
      case 'bottom':
        complementaryTypes = ['Top', 'Shoes', 'Accessory'];
        break;
      case 'dress':
        complementaryTypes = ['Outerwear', 'Shoes', 'Accessory'];
        break;
      case 'shoes':
        complementaryTypes = ['Bottom', 'Socks', 'Accessory'];
        break;
      default:
        complementaryTypes = ['Top', 'Bottom', 'Accessory'];
    }
    
    // Mock complementary items
    final mockItems = <Map<String, dynamic>>[];
    for (var i = 0; i < complementaryTypes.length; i++) {
      final type = complementaryTypes[i];
      mockItems.add({
        'id': 'comp_$i',
        'name': 'Complementary $type',
        'imageUrl': '$_mockImageBaseUrl?text=${type.replaceAll(' ', '+')}',
        'type': type,
        'color': _getComplementaryColor(primaryColor) ?? 'Black',
        'description': 'Goes well with $itemType',
      });
    }
    
    return mockItems;
  }
  
  /// Helper method to get complementary colors
  static String? _getComplementaryColor(String? color) {
    if (color == null) return null;
    
    final colorMap = {
      'red': 'blue',
      'blue': 'orange',
      'green': 'red',
      'yellow': 'purple',
      'black': 'white',
      'white': 'black',
    };
    
    return colorMap[color.toLowerCase()] ?? 'black';
  }

  /// Enhanced clothing analysis with detailed metadata
  static Future<ClothingAnalysis?> analyzeClothingItemDetailed(File imageFile) async {
    final result = await analyzeClothingItem(imageFile);
    if (result == null) return null;

    return ClothingAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemType: result['itemType'] ?? '',
      primaryColor: result['primaryColor'] ?? '',
      patternType: result['patternType'] ?? '',
      style: result['style'] ?? 'casual',
      seasons: List<String>.from(result['seasons'] ?? ['All Seasons']),
      confidence: result['confidence'] ?? 0.8,
      tags: [],
      fit: result['fit'],
      material: result['material'],
      formality: result['formality'],
      subcategory: result['subcategory'],
      imagePath: imageFile.path,
    );
  }

  /// Analyze multiple clothing items
  static Future<List<ClothingAnalysis>> analyzeMultipleItems(List<File> images) async {
    final List<ClothingAnalysis> results = [];
    
    for (final image in images) {
      final analysis = await analyzeClothingItemDetailed(image);
      if (analysis != null) {
        results.add(analysis);
      }
    }
    
    return results;
  }

  /// Generate outfit suggestions based on analyzed items
  static Future<List<OutfitSuggestion>> generateOutfitSuggestions(
    List<ClothingAnalysis> items,
  ) async {
    // Mock implementation - in real app, this would use AI
    await Future.delayed(const Duration(seconds: 1));
    
    final suggestions = <OutfitSuggestion>[];
    
    // Generate different style combinations
    final styles = ['casual', 'business', 'formal', 'trendy'];
    
    for (int i = 0; i < styles.length; i++) {
      suggestions.add(OutfitSuggestion(
        id: 'suggestion_$i',
        items: items,
        matchScore: 0.8 + (i * 0.05),
        style: styles[i],
        occasion: _getOccasionForStyle(styles[i]),
        description: 'A ${styles[i]} outfit perfect for ${_getOccasionForStyle(styles[i])}',
      ));
    }
    
    return suggestions;
  }

  /// Generate mannequin images using Gemini
  static Future<List<MannequinOutfit>> generateMannequinOutfits(
    List<ClothingAnalysis> items,
  ) async {
    final outfits = <MannequinOutfit>[];
    
    try {
      // Generate 4 different outfit combinations
      for (int i = 0; i < 4; i++) {
        final prompt = _buildMannequinPrompt(items, i);
        final imageUrl = await _generateMannequinImage(prompt);
        
        outfits.add(MannequinOutfit(
          id: 'mannequin_$i',
          items: items,
          imageUrl: imageUrl ?? '$_mockImageBaseUrl/400/600?random=$i',
          pose: ['front', 'side', 'back', 'three-quarter'][i % 4],
          style: ['casual', 'business', 'trendy', 'elegant'][i],
          confidence: 0.85,
        ));
      }
    } catch (e) {
      print('Error generating mannequin outfits: $e');
      // Return mock data as fallback
      return _getMockMannequinOutfits(items);
    }
    
    return outfits;
  }

  /// Generate mannequin image using Gemini image generation
  static Future<String?> _generateMannequinImage(String prompt) async {
    try {
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 1024,
        }
      };

      final response = await http.post(
        Uri.parse('$_imageEndpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final content = jsonDecode(response.body);
        // Extract generated image URL from response
        return content['candidates']?[0]?['content']?['parts']?[0]?['text'];
      }
    } catch (e) {
      print('Mannequin generation error: $e');
    }
    
    return null;
  }

  /// Build prompt for mannequin generation
  static String _buildMannequinPrompt(List<ClothingAnalysis> items, int variation) {
    final itemDescriptions = items.map((item) => 
      '${item.primaryColor} ${item.itemType} with ${item.patternType} pattern'
    ).join(', ');
    
    final poses = ['front view', 'side profile', 'back view', 'three-quarter angle'];
    final styles = ['casual styling', 'business professional', 'trendy modern', 'elegant sophisticated'];
    
    return '''
Generate a high-quality fashion mannequin image showing:
- Items: $itemDescriptions
- Pose: ${poses[variation % 4]}
- Style: ${styles[variation]}
- Background: Clean, minimal studio background
- Lighting: Professional fashion photography lighting
- Quality: High resolution, realistic rendering

The mannequin should be wearing all the specified items in a coordinated, stylish way that showcases how they work together as a complete outfit.
''';
  }

  /// Get mock mannequin outfits as fallback
  static List<MannequinOutfit> _getMockMannequinOutfits(List<ClothingAnalysis> items) {
    return List.generate(4, (i) => MannequinOutfit(
      id: 'mock_mannequin_$i',
      items: items,
      imageUrl: '$_mockImageBaseUrl/400/600?random=${100 + i}',
      pose: ['front', 'side', 'back', 'three-quarter'][i],
      style: ['casual', 'business', 'trendy', 'elegant'][i],
      confidence: 0.7,
    ));
  }

  /// Helper to get occasion for style
  static String _getOccasionForStyle(String style) {
    switch (style.toLowerCase()) {
      case 'casual':
        return 'everyday wear';
      case 'business':
        return 'work meetings';
      case 'formal':
        return 'special events';
      case 'trendy':
        return 'social outings';
      default:
        return 'various occasions';
    }
  }
}
