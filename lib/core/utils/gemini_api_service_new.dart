import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:outfit_matcher/core/models/clothing_analysis.dart';
// import 'package:outfit_matcher/core/models/mannequin_outfit.dart';
import 'package:outfit_matcher/core/utils/logger.dart';

class GeminiApiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Enhanced clothing analysis with detailed metadata
  static Future<ClothingAnalysis?> analyzeClothingItemDetailed(File imageFile) async {
    AppLogger.info('🔍 Starting detailed clothing analysis', data: {'file': imageFile.path});

    try {
      final result = await analyzeClothingItem(imageFile);
      if (result == null) {
        AppLogger.warning('❌ Basic analysis failed');
        return null;
      }

      AppLogger.debug('✅ Basic analysis successful, creating detailed analysis');
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
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error in detailed analysis', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Analyze single clothing item using Gemini API
  /// Generate detailed mannequin descriptions for the clothing item
  static Future<Map<String, dynamic>?> generateMannequinDescription({
    required File imageFile,
    required String poseDescription,
    required String itemType,
    required String color,
  }) async {
    AppLogger.info('🎨 Generating mannequin description', data: {
      'pose': poseDescription,
      'itemType': itemType,
      'color': color,
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final prompt = '''
      Analyze this clothing item and create a detailed description for generating a mannequin image wearing it.
      
      Item Type: $itemType
      Color: $color
      Pose: $poseDescription
      
      Return a JSON object with:
      {
        "mannequinDescription": "Detailed description of how the item should look on a mannequin",
        "styleDetails": "Specific style characteristics",
        "fitDescription": "How the item should fit on the mannequin",
        "colorDetails": "Exact color and pattern details",
        "poseInstructions": "Specific pose and positioning instructions",
        "backgroundSuggestion": "Background and lighting suggestions",
        "imagePrompt": "Complete prompt for image generation API"
      }
      
      Make the descriptions very detailed and specific for high-quality mannequin image generation.
      ''';

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
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topK": 32,
          "topP": 1.0,
          "maxOutputTokens": 4096
        }
      };

      final url = '$_endpoint?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      AppLogger.network(url, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        AppLogger.debug('📥 Mannequin description response received', data: {'response_length': text.length});

        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);
          
          AppLogger.info('✅ Mannequin description generated successfully');
          return result;
        } else {
          AppLogger.warning('❌ Failed to extract JSON from mannequin description response', error: text);
          return null;
        }
      } else {
        AppLogger.error('❌ Mannequin description API error', error: response.body);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Exception in generateMannequinDescription', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeClothingItem(File imageFile) async {
    AppLogger.info('🔍 Starting clothing item analysis', data: {'file': imageFile.path});

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      AppLogger.debug('📸 Image loaded', data: {'size': bytes.lengthInBytes});

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
                "text": "You are an expert fashion analyst. Analyze this clothing item with EXTREME PRECISION.\n\nCRITICAL RULES:\n1. LOOK CAREFULLY at the actual colors in the image - don't default to common colors\n2. If you see GREEN fabric, say GREEN not blue\n3. If you see formal elements (lapels, structured shoulders, dress pants), classify as business/formal\n4. If you see suits, blazers, dress shirts, classify as 'business formal' or 'formal wear'\n\nReturn ONLY a JSON object with these exact keys:\n{\n  \"itemType\": \"Top|Bottom|Dress|Outerwear|Shoes|Accessory\",\n  \"primaryColor\": \"EXACT color you see (green, navy blue, charcoal gray, burgundy, etc.)\",\n  \"secondaryColors\": [\"array of other colors if any\"],\n  \"patternType\": \"solid|pinstripe|checkered|herringbone|floral|geometric\",\n  \"material\": \"wool|cotton|silk|linen|polyester|leather|denim\",\n  \"fit\": \"slim fit|regular fit|relaxed fit|tailored fit|oversized\",\n  \"style\": \"business formal|smart casual|casual|formal wear|streetwear\",\n  \"formality\": \"formal|business|smart casual|casual\",\n  \"subcategory\": \"specific type like 'wool suit jacket', 'dress shirt', 'chinos'\",\n  \"confidence\": 0.95\n}\n\nEXAMPLES:\n- Green suit jacket → {\"primaryColor\": \"green\", \"style\": \"business formal\", \"formality\": \"formal\"}\n- Navy blazer → {\"primaryColor\": \"navy blue\", \"style\": \"business formal\"}\n- Casual t-shirt → {\"primaryColor\": \"white\", \"style\": \"casual\"}\n\nLook at the IMAGE carefully and describe what you actually see, not what's common."
              }
            ]
          }
        ]
      };

      final url = '$_endpoint?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final startTime = DateTime.now();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance('Gemini API call', duration, result: response.statusCode);

      AppLogger.network(url, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final content = jsonDecode(response.body);
        final text = content['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        AppLogger.debug('📥 Gemini API response received', data: {'response_length': text.length});

        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);

          final processedResult = {
            'itemType': result['itemType'] ?? 'Unknown',
            'primaryColor': _normalizeColor(result['primaryColor'] ?? 'Unknown'),
            'patternType': result['patternType'] ?? 'solid',
            'style': _normalizeStyle(result['style'] ?? 'casual'),
            'fit': result['fit'] ?? 'regular fit',
            'material': result['material'] ?? 'cotton',
            'seasons': result['seasons'] ?? ['All Seasons'],
            'formality': result['formality'] ?? 'casual',
            'subcategory': result['subcategory'] ?? '',
            'confidence': result['confidence'] ?? 0.8,
          };

          AppLogger.info('✅ Clothing analysis complete', data: {
            'itemType': processedResult['itemType'],
            'primaryColor': processedResult['primaryColor'],
            'confidence': processedResult['confidence']
          });

          return processedResult;
        } else {
          AppLogger.warning('❌ Failed to extract JSON from Gemini response', error: text);
          return null;
        }
      } else {
        AppLogger.error('❌ Gemini API error', error: response.statusCode);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error in analyzeClothingItem', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Analyze multiple clothing items
  static Future<List<ClothingAnalysis>> analyzeMultipleItems(List<File> images) async {
    AppLogger.info('🔍 Starting multiple items analysis', data: {'count': images.length});

    final List<ClothingAnalysis> results = [];

    for (int i = 0; i < images.length; i++) {
      AppLogger.debug('📸 Analyzing item ${i + 1}/${images.length}');
      final analysis = await analyzeClothingItemDetailed(images[i]);
      if (analysis != null) {
        results.add(analysis);
        AppLogger.info('✅ Item ${i + 1} analyzed successfully');
      } else {
        AppLogger.warning('❌ Item ${i + 1} analysis failed');
      }
    }

    AppLogger.info('🎉 Multiple items analysis complete', data: {'successful': results.length, 'total': images.length});
    return results;
  }

  /// Generate outfit suggestions based on analyzed items
  static Future<List<OutfitSuggestion>> generateOutfitSuggestions(
    List<ClothingAnalysis> items,
  ) async {
    AppLogger.info('👔 Generating outfit suggestions', data: {'items': items.length});

    await Future.delayed(const Duration(seconds: 1)); // Mock processing time

    final suggestions = <OutfitSuggestion>[];
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

    AppLogger.info('✅ Outfit suggestions generated', data: {'count': suggestions.length});
    return suggestions;
  }

  /// Generate REAL mannequin outfits using the uploaded items with complete styling
  static Future<List<MannequinOutfit>> generateMannequinOutfits(
    List<ClothingAnalysis> items, {
    void Function(String)? onProgress,
    void Function(int, int)? onProgressUpdate,
  }) async {
    AppLogger.info('👤 Generating REAL mannequin outfits', data: {'items': items.length});

    final outfits = <MannequinOutfit>[];
    const int totalPoses = 4;
    int completed = 0;

    try {
      // Generate 4 different mannequin outfits with graceful error handling
      for (int i = 0; i < totalPoses; i++) {
        onProgressUpdate?.call(completed, totalPoses);

        final poses = [
          'front view, hands at sides',
          'side profile view',
          'three-quarter angle view',
          'front view, one hand on hip'
        ];
        final styles = [
          'casual everyday',
          'business professional',
          'trendy modern',
          'elegant sophisticated'
        ];

        onProgress?.call('Generating ${styles[i]} mannequin...');

        // Use the first item's image file for mannequin generation
        final mainItem = items.first;
        final imageFile = File(mainItem.imagePath ?? '');

        AppLogger.info('🎨 Generating REAL mannequin for style: ${styles[i]}', data: {
          'item_type': mainItem.itemType,
          'color': mainItem.primaryColor,
          'pose': poses[i],
        });

        try {
          final mannequinResult = await generateMannequinImage(
            imageFile: imageFile,
            poseDescription: poses[i],
            itemType: mainItem.itemType,
            color: mainItem.primaryColor,
          );

          if (mannequinResult != null) {
            // Check if result is base64 image data or text description
            String imageUrl;
            String? description;

            if (mannequinResult.startsWith('data:image')) {
              // It's already a data URL
              imageUrl = mannequinResult;
              description = 'Generated mannequin image for ${styles[i]} style';
            } else if (mannequinResult.contains('👗') || mannequinResult.contains('**')) {
              // It's a text description
              imageUrl = '';
              description = mannequinResult;
            } else {
              // Assume it's base64 image data
              imageUrl = 'data:image/png;base64,$mannequinResult';
              description = 'Generated mannequin image for ${styles[i]} style';
            }

            outfits.add(MannequinOutfit(
              id: 'mannequin_$i',
              items: items,
              imageUrl: imageUrl,
              pose: poses[i],
              style: styles[i],
              confidence: 0.95,
              metadata: {'description': description},
            ));
            AppLogger.info('✅ Mannequin result generated successfully for style: ${styles[i]}');
          } else {
            AppLogger.warning('❌ Failed to generate mannequin result for style: ${styles[i]}');
            // Create fallback outfit with placeholder
            outfits.add(MannequinOutfit(
              id: 'mannequin_$i',
              items: items,
              imageUrl: '',
              pose: poses[i],
              style: styles[i],
              confidence: 0.8,
              metadata: {'description': 'Failed to generate image, please try again'},
            ));
          }

          completed++;
          onProgressUpdate?.call(completed, totalPoses);

        } catch (e) {
          AppLogger.error('❌ Error generating individual mannequin ${styles[i]}', error: e);
          // Continue with other poses even if one fails
          outfits.add(MannequinOutfit(
            id: 'mannequin_$i',
            items: items,
            imageUrl: '',
            pose: poses[i],
            style: styles[i],
            confidence: 0.7,
            metadata: {'description': 'Generation failed, please retry'},
          ));
          completed++;
        }

        // Add delay between requests to avoid rate limiting
        if (i < totalPoses - 1) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      onProgress?.call('All mannequins generated successfully!');

      AppLogger.info('✅ REAL mannequin outfits generation complete', data: {
        'successful': outfits.length,
        'total_attempted': totalPoses
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error generating REAL mannequin outfits', error: e, stackTrace: stackTrace);
      // Return what we have instead of empty list
      return outfits.isNotEmpty ? outfits : [];
    }

    return outfits;
  }

  /// Generate a detailed mannequin description that can be used for image generation
  static Future<Map<String, dynamic>?> generateDetailedMannequinDescription({
    required File imageFile,
    required String poseDescription,
    required String itemType,
    required String color,
  }) async {
    AppLogger.info('🎨 Generating detailed mannequin description for image generation', data: {
      'pose': poseDescription,
      'itemType': itemType,
      'color': color,
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''
ANALYZE THIS CLOTHING ITEM AND CREATE A DETAILED DESCRIPTION FOR MANNEQUIN IMAGE GENERATION

Uploaded Item Details:
- Type: $itemType
- Color: $color
- Pose: $poseDescription

TASK: Create an extremely detailed description that can be used to generate a professional mannequin image wearing this exact item with a complete outfit.

Return a JSON object with:
{
  "mannequinType": "male/female/unisex professional mannequin",
  "bodyType": "athletic/slim/average build",
  "pose": "exact pose description for photorealistic rendering",
  "uploadedItem": {
    "description": "hyper-detailed description of the uploaded item",
    "placement": "how it should be positioned on the mannequin",
    "fit": "how it should fit the mannequin"
  },
  "complementaryItems": {
    "top": "detailed description of complementary top",
    "bottom": "detailed description of complementary bottom",
    "shoes": "detailed description of shoes",
    "accessories": "detailed description of accessories"
  },
  "completeOutfitDescription": "full paragraph description for image generation AI",
  "imageGenerationPrompt": "complete prompt ready for DALL-E, Midjourney, or Stable Diffusion",
  "technicalDetails": {
    "lighting": "professional studio lighting setup",
    "background": "studio background description",
    "camera": "camera angle and perspective",
    "style": "photorealistic fashion photography style"
  },
  "confidence": 0.95
}

Make the descriptions so detailed that an image generation AI could create an exact visual match of what you see in the uploaded image, styled with complementary pieces.
      ''';

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
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.3,
          "topK": 32,
          "topP": 1.0,
          "maxOutputTokens": 4096
        }
      };

      final url = '$_endpoint?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      AppLogger.network(url, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        AppLogger.debug('📥 Mannequin description response received', data: {
          'response_length': text.length,
          'response_preview': text.length > 200 ? text.substring(0, 200) + '...' : text
        });

        // Try multiple approaches to extract JSON
        Map<String, dynamic>? result;

        // Approach 1: Look for JSON object
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          try {
            final jsonString = text.substring(jsonStart, jsonEnd + 1);
            result = jsonDecode(jsonString);
            AppLogger.info('✅ Successfully extracted JSON object');
          } catch (e) {
            AppLogger.warning('❌ Failed to parse JSON object', error: e);
          }
        }

        // Approach 2: If first approach failed, try to find JSON within code blocks
        if (result == null) {
          final codeBlockStart = text.indexOf('```json');
          final codeBlockEnd = text.indexOf('```', codeBlockStart + 1);
          if (codeBlockStart != -1 && codeBlockEnd != -1 && codeBlockEnd > codeBlockStart) {
            try {
              final jsonString = text.substring(codeBlockStart + 7, codeBlockEnd).trim();
              result = jsonDecode(jsonString);
              AppLogger.info('✅ Successfully extracted JSON from code block');
            } catch (e) {
              AppLogger.warning('❌ Failed to parse JSON from code block', error: e);
            }
          }
        }

        // Approach 3: Try to find any valid JSON in the text
        if (result == null) {
          final allJsonMatches = RegExp(r'\{[\s\S]*\}').allMatches(text);
          for (final match in allJsonMatches) {
            try {
              final jsonString = match.group(0)!;
              result = jsonDecode(jsonString);
              AppLogger.info('✅ Successfully extracted JSON using regex');
              break;
            } catch (e) {
              // Continue trying other matches
            }
          }
        }

        if (result != null) {
          AppLogger.info('✅ Detailed mannequin description generated successfully');
          return result;
        } else {
          AppLogger.warning('❌ Failed to extract any valid JSON from mannequin description response', error: {
            'full_response': text
          });
          return null;
        }
      } else {
        AppLogger.error('❌ Mannequin description API error', error: response.body);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Exception in generateDetailedMannequinDescription', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save generated image to assets directory for debugging
  static Future<String?> _saveGeneratedImageToAssets(String base64ImageData, String timestamp) async {
    try {
      if (kIsWeb) {
        AppLogger.info('🌐 Web platform detected, skipping image save');
        return null;
      }

      // Try to save to assets directory (this might not work in production)
      // But we'll also save to documents directory as backup
      final directory = await getApplicationDocumentsDirectory();
      final assetsPath = '${directory.path}/assets/images/mannequin_$timestamp.png';
      final documentsPath = '${directory.path}/mannequin_$timestamp.png';

      // Decode base64 image data
      final imageBytes = base64Decode(base64ImageData);

      // Save to documents directory (guaranteed to work)
      final documentsFile = File(documentsPath);
      await documentsFile.writeAsBytes(imageBytes);
      AppLogger.info('💾 Saved generated mannequin image to documents: $documentsPath');

      // Try to save to assets-like directory
      try {
        final assetsDir = Directory('${directory.path}/assets/images');
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }
        
        final assetsFile = File(assetsPath);
        await assetsFile.writeAsBytes(imageBytes);
        AppLogger.info('💾 Saved generated mannequin image to assets: $assetsPath');
        return assetsPath;
      } catch (e) {
        AppLogger.warning('⚠️ Could not save to assets directory: $e');
        return documentsPath;
      }
    } catch (e) {
      AppLogger.error('❌ Failed to save generated image', error: e);
      return null;
    }
  }

  /// Generate a REAL mannequin image with the uploaded clothing item + complete outfit
  static Future<String?> generateMannequinImage({
    required File imageFile,
    required String poseDescription,
    required String itemType,
    required String color,
  }) async {
    AppLogger.info('🎨 Generating REAL mannequin image with uploaded item', data: {
      'pose': poseDescription,
      'itemType': itemType,
      'color': color,
      'imageFile': imageFile.path,
    });

    try {
      // Simple, clean prompt - following the "nano banana" approach
      final simplePrompt = '''
Create a professional fashion mannequin wearing a complete outfit featuring the uploaded clothing item. 
Style: $poseDescription
The mannequin should be photorealistic, well-lit, against a clean background.
Show a complete, stylish outfit that includes the uploaded item plus complementary pieces.
Professional fashion photography style.
''';

      // Use the image generation model directly - no complex preprocessing
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": simplePrompt},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      };

      // Use the image generation model endpoint
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final startTime = DateTime.now();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      final duration = DateTime.now().difference(startTime);

      AppLogger.performance('Simple mannequin image generation API call', duration, result: response.statusCode);
      AppLogger.network(url, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final candidates = responseData['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates.first;
          final parts = candidate['content']?['parts'] as List?;

          if (parts != null) {
            // Look for image data in the response
            for (var part in parts) {
              if (part.containsKey('inlineData')) {
                final inlineData = part['inlineData'];
                final base64ImageData = inlineData['data'];

                if (base64ImageData != null) {
                  AppLogger.info('✅ REAL mannequin image generated successfully');

                  // Save the image to assets directory for debugging
                  await _saveGeneratedImageToAssets(base64ImageData, DateTime.now().millisecondsSinceEpoch.toString());

                  return base64ImageData; // Return the base64 image data
                }
              }
            }

            // Fallback: extract text description if no image
            final text = parts.where((part) => part.containsKey('text'))
                .map((part) => part['text'])
                .join(' ');

            if (text.isNotEmpty) {
              AppLogger.info('📝 No image generated, returning text description');
              return text;
            }
          }
        }

        AppLogger.warning('❌ No valid content in mannequin generation response');
        return null;
      } else {
        AppLogger.error('❌ Mannequin generation API error', error: response.body);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Exception in generateMannequinImage', error: e, stackTrace: stackTrace);
      return null;
    }
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

  /// Normalize color names to standard palette
  static String _normalizeColor(String color) {
    final colorLower = color.toLowerCase().trim();
    
    // Green variations
    if (colorLower.contains('green') || colorLower.contains('mint') || 
        colorLower.contains('sage') || colorLower.contains('olive')) {
      return 'green';
    }
    
    // Blue variations  
    if (colorLower.contains('blue') || colorLower.contains('navy') || 
        colorLower.contains('azure') || colorLower.contains('teal')) {
      return 'blue';
    }
    
    // Gray variations
    if (colorLower.contains('gray') || colorLower.contains('grey') || 
        colorLower.contains('charcoal') || colorLower.contains('silver')) {
      return 'gray';
    }
    
    // Black variations
    if (colorLower.contains('black') || colorLower.contains('ebony')) {
      return 'black';
    }
    
    // White variations
    if (colorLower.contains('white') || colorLower.contains('cream') || 
        colorLower.contains('ivory') || colorLower.contains('off-white')) {
      return 'white';
    }
    
    // Brown variations
    if (colorLower.contains('brown') || colorLower.contains('tan') || 
        colorLower.contains('beige') || colorLower.contains('khaki')) {
      return 'brown';
    }
    
    // Red variations
    if (colorLower.contains('red') || colorLower.contains('burgundy') || 
        colorLower.contains('maroon') || colorLower.contains('crimson')) {
      return 'red';
    }
    
    return color; // Return original if no match
  }

  /// Normalize style classifications
  static String _normalizeStyle(String style) {
    final styleLower = style.toLowerCase().trim();
    
    // Business formal variations
    if (styleLower.contains('business') || styleLower.contains('formal') || 
        styleLower.contains('professional') || styleLower.contains('office')) {
      return 'business formal';
    }
    
    // Smart casual variations
    if (styleLower.contains('smart') || styleLower.contains('semi-formal')) {
      return 'smart casual';
    }
    
    // Casual variations
    if (styleLower.contains('casual') || styleLower.contains('everyday') || 
        styleLower.contains('relaxed')) {
      return 'casual';
    }
    
    return style; // Return original if no match
  }

  /// Generate complimentary color combinations
  static Map<String, List<String>> getComplementaryColors(String primaryColor) {
    AppLogger.debug('🎨 Finding complementary colors', data: {'primary': primaryColor});

    final colorMap = {
      'red': 'blue',
      'blue': 'orange',
      'green': 'red',
      'yellow': 'purple',
      'black': 'white',
      'white': 'black',
    };

    final complement = colorMap[primaryColor.toLowerCase()] ?? 'black';
    AppLogger.debug('✅ Complementary color found', data: {'complement': complement});

    return {
      'complementary': [complement],
      'analogous': [primaryColor], // Simplified
      'triadic': [primaryColor], // Simplified
    };
  }
}
