import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
// import 'package:vestiq/core/models/mannequin_outfit.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/utils/api_rate_limiter.dart';

class GeminiApiService {
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Enhanced clothing analysis with detailed metadata
  static Future<ClothingAnalysis?> analyzeClothingItemDetailed(
    File imageFile,
  ) async {
    AppLogger.info(
      '🔍 Starting detailed clothing analysis',
      data: {'file': imageFile.path},
    );

    try {
      final result = await analyzeClothingItem(imageFile);
      if (result == null) {
        AppLogger.warning('❌ Basic analysis failed');
        return null;
      }

      AppLogger.debug(
        '✅ Basic analysis successful, creating detailed analysis',
      );
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
      AppLogger.error(
        '❌ Error in detailed analysis',
        error: e,
        stackTrace: stackTrace,
      );
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
    AppLogger.info(
      '🎨 Generating mannequin description',
      data: {'pose': poseDescription, 'itemType': itemType, 'color': color},
    );

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
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {"text": prompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topK": 32,
          "topP": 1.0,
          "maxOutputTokens": 4096,
        },
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
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            '';
        AppLogger.debug(
          '📥 Mannequin description response received',
          data: {'response_length': text.length},
        );

        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);

          AppLogger.info('✅ Mannequin description generated successfully');
          return result;
        } else {
          AppLogger.warning(
            '❌ Failed to extract JSON from mannequin description response',
            error: text,
          );
          return null;
        }
      } else {
        AppLogger.error(
          '❌ Mannequin description API error',
          error: response.body,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Exception in generateMannequinDescription',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeClothingItem(
    File imageFile,
  ) async {
    AppLogger.info(
      '🔍 Starting clothing item analysis',
      data: {'file': imageFile.path},
    );

    // Check rate limits
    if (!await ApiRateLimiter.instance.isRequestAllowed()) {
      AppLogger.warning('🚦 API rate limit exceeded, waiting...');
      await ApiRateLimiter.instance.waitForRateLimitReset();

      // Try again after waiting
      if (!await ApiRateLimiter.instance.isRequestAllowed()) {
        AppLogger.error('❌ API rate limit still exceeded after waiting');
        return null;
      }
    }

    // Generate cache key
    final imageBytes = await imageFile.readAsBytes();
    final imageHash = imageBytes.hashCode.toString();
    final cacheKey = ApiRateLimiter.instance.generateCacheKey(
      endpoint: 'analyzeClothingItem',
      requestBody: null,
      imageHash: imageHash,
    );

    // Check cache first
    final cachedResponse = ApiRateLimiter.instance.getCachedResponse(cacheKey);
    if (cachedResponse != null) {
      AppLogger.debug('📦 Using cached analysis result');
      return jsonDecode(cachedResponse);
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      AppLogger.debug('📸 Image loaded', data: {'size': bytes.lengthInBytes});

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {
                "text":
                    "You are an expert fashion analyst. Analyze this clothing item with EXTREME PRECISION.\n\nCRITICAL RULES:\n1. FOOTWEAR DETECTION: If you see ANY shoes, sneakers, boots, sandals, heels, flats - ALWAYS classify as 'Shoes' NOT 'Top'\n2. JEANS ANALYSIS: Look carefully at fit - distinguish between 'skinny jeans', 'baggy jeans', 'relaxed fit jeans', 'straight leg jeans'\n3. LOOK CAREFULLY at the actual colors in the image - don't default to common colors\n4. If you see GREEN fabric, say GREEN not blue\n5. If you see formal elements (lapels, structured shoulders, dress pants), classify as business/formal\n6. If you see suits, blazers, dress shirts, classify as 'business formal' or 'formal wear'\n\nReturn ONLY a JSON object with these exact keys:\n{\n  \"itemType\": \"Top|Bottom|Dress|Outerwear|Shoes|Accessory\",\n  \"primaryColor\": \"EXACT color you see (green, navy blue, charcoal gray, burgundy, etc.)\",\n  \"secondaryColors\": [\"array of other colors if any\"],\n  \"patternType\": \"solid|pinstripe|checkered|herringbone|floral|geometric\",\n  \"material\": \"wool|cotton|silk|linen|polyester|leather|denim\",\n  \"fit\": \"slim fit|regular fit|relaxed fit|tailored fit|oversized|baggy|skinny\",\n  \"style\": \"business formal|smart casual|casual|formal wear|streetwear\",\n  \"formality\": \"formal|business|smart casual|casual\",\n  \"subcategory\": \"specific type like 'baggy jeans', 'sneakers', 'boots', 'oxford shirt'\",\n  \"confidence\": 0.95\n}\n\nEXAMPLES:\n- Green suit jacket → {\"primaryColor\": \"green\", \"style\": \"business formal\", \"formality\": \"formal\"}\n- Navy blazer → {\"primaryColor\": \"navy blue\", \"style\": \"business formal\"}\n- Casual t-shirt → {\"primaryColor\": \"white\", \"style\": \"casual\"}\n- Baggy jeans → {\"itemType\": \"Bottom\", \"fit\": \"baggy\", \"subcategory\": \"baggy jeans\"}\n- Sneakers → {\"itemType\": \"Shoes\", \"subcategory\": \"sneakers\"}\n\nLook at the IMAGE carefully and describe what you actually see, not what's common. Pay special attention to footwear and jeans fit.",
              },
            ],
          },
        ],
      };

      final url = '$_endpoint?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final startTime = DateTime.now();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30)); // Add timeout
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance(
        'Gemini API call',
        duration,
        result: response.statusCode,
      );

      AppLogger.network(url, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final content = jsonDecode(response.body);
        final text =
            content['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        AppLogger.debug(
          '📥 Gemini API response received',
          data: {'response_length': text.length},
        );

        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);

          final processedResult = {
            'itemType': result['itemType'] ?? 'Unknown',
            'primaryColor': _normalizeColor(
              result['primaryColor'] ?? 'Unknown',
            ),
            'patternType': result['patternType'] ?? 'solid',
            'style': _normalizeStyle(result['style'] ?? 'casual'),
            'fit': result['fit'] ?? 'regular fit',
            'material': result['material'] ?? 'cotton',
            'seasons': _extractStringList(result['seasons']) ?? ['All Seasons'],
            'formality': result['formality'] ?? 'casual',
            'subcategory': result['subcategory'] ?? '',
            'confidence': (result['confidence'] as num?)?.toDouble() ?? 0.8,
            'occasions':
                _extractStringList(result['occasions']) ??
                _defaultOccasions(result['formality'] as String?),
            'locations': _extractStringList(result['locations']),
            'styleHints': _extractStringList(result['styleHints']),
          };

          // Cache the successful response
          ApiRateLimiter.instance.cacheResponse(cacheKey, jsonEncode(processedResult));

          return processedResult;
        } else {
          AppLogger.warning(
            '❌ Failed to extract JSON from Gemini response',
            error: text,
          );
          return null;
        }
      } else {
        AppLogger.error('❌ Gemini API error', error: response.statusCode);
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error in analyzeClothingItem',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static List<String>? _extractStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .where((element) => element != null)
          .map((element) => element.toString())
          .where((element) => element.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((element) => element.trim())
          .where((element) => element.isNotEmpty)
          .toList();
    }
    return null;
  }

  static List<String> _defaultOccasions(String? formality) {
    switch (formality?.toLowerCase()) {
      case 'formal':
        return ['formal', 'evening', 'wedding'];
      case 'business':
        return ['work', 'business', 'smart casual'];
      case 'smart casual':
        return ['smart casual', 'date', 'brunch'];
      case 'casual':
      default:
        return ['casual', 'weekend', 'everyday'];
    }
  }

  /// Analyze multiple clothing items
  static Future<List<ClothingAnalysis>> analyzeMultipleItems(
    List<File> images,
  ) async {
    AppLogger.info(
      '🔍 Starting multiple items analysis',
      data: {'count': images.length},
    );

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

    AppLogger.info(
      '🎉 Multiple items analysis complete',
      data: {'successful': results.length, 'total': images.length},
    );
    return results;
  }

  /// Generate outfit suggestions based on analyzed items
  static Future<List<OutfitSuggestion>> generateOutfitSuggestions(
    List<ClothingAnalysis> items,
  ) async {
    AppLogger.info(
      '👔 Generating outfit suggestions',
      data: {'items': items.length},
    );

    await Future.delayed(const Duration(seconds: 1)); // Mock processing time

    final suggestions = <OutfitSuggestion>[];
    final styles = ['casual', 'business', 'formal', 'trendy'];

    for (int i = 0; i < styles.length; i++) {
      suggestions.add(
        OutfitSuggestion(
          id: 'suggestion_$i',
          items: items,
          matchScore: 0.8 + (i * 0.05),
          style: styles[i],
          occasion: _getOccasionForStyle(styles[i]),
          description:
              'A ${styles[i]} outfit perfect for ${_getOccasionForStyle(styles[i])}',
        ),
      );
    }

    AppLogger.info(
      '✅ Outfit suggestions generated',
      data: {'count': suggestions.length},
    );
    return suggestions;
  }

  /// Generate enhanced mannequin outfits using full wardrobe context and notes
  static Future<List<MannequinOutfit>> generateEnhancedMannequinOutfits(
    List<ClothingAnalysis> items, {
    String? userNotes,
    void Function(String)? onProgress,
    void Function(int, int)? onProgressUpdate,
  }) async {
    AppLogger.info(
      '👤 Generating enhanced mannequin outfits',
      data: {'items': items.length, 'notes': userNotes?.length},
    );

    if (items.isEmpty) {
      AppLogger.warning('⚠️ No items provided for mannequin generation');
      return const [];
    }

    // Log item details for debugging indecisiveness
    AppLogger.info(
      '📋 Uploaded items analysis:',
      data: {
        'total_items': items.length,
        'item_types':
            items
                .map(
                  (item) =>
                      '${item.itemType} (${item.primaryColor}) - ${item.subcategory ?? "no subcategory"}',
                )
                .toList(),
        'user_notes': userNotes ?? 'No notes provided',
        'has_footwear': items.any(
          (item) =>
              item.itemType.toLowerCase().contains('shoe') ||
              item.itemType.toLowerCase().contains('footwear'),
        ),
        'has_baggy_items': items.any(
          (item) =>
              item.fit?.toLowerCase().contains('baggy') == true ||
              item.subcategory?.toLowerCase().contains('baggy') == true,
        ),
      },
    );

    final combinations = _composeOutfitCombinations(items);
    final totalLooks = 6; // Always generate 6 looks
    final results = <MannequinOutfit>[];
    int completed = 0;

    for (int i = 0; i < totalLooks; i++) {
      final combo = combinations[i % combinations.length];
      final styleLabel = combo.metadata['styleLabel'] as String? ?? 'signature';
      final poseDescription =
          combo.metadata['pose'] as String? ??
          _poseLibrary[i % _poseLibrary.length];

      onProgress?.call('Styling look ${i + 1} of $totalLooks ($styleLabel)');
      onProgressUpdate?.call(completed, totalLooks);

      try {
        final prompt = _buildMannequinPrompt(
          uploadedItems: combo.items,
          userNotes: userNotes,
          desiredStyle: styleLabel,
          pairingNotes: combo.metadata['pairingNotes'] as String?,
        );

        // Use the first available image from the combination
        final primaryImagePath =
            combo.items.firstWhere((item) => item.imagePath != null).imagePath;
        final imageFile =
            primaryImagePath != null ? File(primaryImagePath) : null;

        if (imageFile == null) {
          AppLogger.warning('⚠️ Missing image for mannequin combo, skipping');
          continue;
        }

        // Log which items are being used in this combination
        AppLogger.info(
          '🎨 Generating mannequin with items',
          data: {
            'combo_index': i,
            'items_count': combo.items.length,
            'items':
                combo.items
                    .map((item) => '${item.itemType} (${item.primaryColor})')
                    .toList(),
            'style': styleLabel,
          },
        );

        final imageResult = await _callImagePreview(prompt, imageFile);

        if (imageResult != null) {
          results.add(
            MannequinOutfit(
              id: 'mannequin_${DateTime.now().millisecondsSinceEpoch}_$i',
              items: combo.items,
              imageUrl: 'data:image/png;base64,$imageResult',
              pose: poseDescription,
              style: styleLabel,
              confidence: 0.92,
              metadata: {
                'description':
                    combo.metadata['description'] ??
                    'Look $i styled with ${combo.items.length} of your pieces.',
                'occasion': combo.metadata['occasion'],
                'pairing': combo.metadata['pairingNotes'],
              },
            ),
          );
        }

        completed++;
        onProgressUpdate?.call(completed, totalLooks);
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e, stackTrace) {
        AppLogger.error(
          '❌ Failed to build mannequin look',
          error: e,
          stackTrace: stackTrace,
        );
        results.add(
          MannequinOutfit(
            id: 'mannequin_fallback_$i',
            items: combo.items,
            imageUrl: '',
            pose: poseDescription,
            style: styleLabel,
            confidence: 0.6,
            metadata: {
              'description':
                  'We couldn\'t render this look, but the pairing is ready to retry.',
              'occasion': combo.metadata['occasion'],
              'pairing': combo.metadata['pairingNotes'],
            },
          ),
        );
      }
    }

    onProgress?.call('All $completed looks styled successfully.');
    return results;
  }

  static String _buildMannequinPrompt({
    required List<ClothingAnalysis> uploadedItems,
    String? userNotes,
    String? desiredStyle,
    String? pairingNotes,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are a high-fashion stylist creating a photorealistic mannequin look.',
    );
    buffer.writeln('show the COMPLETE mannequin from head to toe!');
    buffer.writeln(
      'NEVER crop out feet, shoes, or footwear - they must be fully visible!',
    );
    buffer.writeln(
      'Blend the uploaded wardrobe pieces into a cohesive outfit.',
    );
    if (desiredStyle != null && desiredStyle.isNotEmpty) {
      buffer.writeln('Desired styling direction: $desiredStyle.');
    }

    // List all uploaded items
    buffer.writeln('Uploaded wardrobe pieces:');
    for (final item in uploadedItems) {
      buffer.writeln(
        '- ${item.itemType} in ${item.primaryColor}, style ${item.style}, formality ${item.formality}',
      );
      if (item.subcategory != null && item.subcategory!.isNotEmpty) {
        buffer.writeln('  subcategory: ${item.subcategory}');
      }
      if (item.brand != null && item.brand!.isNotEmpty) {
        buffer.writeln('  brand: ${item.brand}');
      }
    }

    if (pairingNotes != null && pairingNotes.isNotEmpty) {
      buffer.writeln('Pairing guidance: $pairingNotes');
    }

    if (userNotes != null && userNotes.isNotEmpty) {
      buffer.writeln('User preferences and notes to honour: $userNotes');
      buffer.writeln(
        'CRITICAL: The user specifically mentioned: "$userNotes" - make sure to address this in your styling!',
      );
    }

    // Add specific instructions for indecisiveness scenarios
    if (uploadedItems.length > 2) {
      buffer.writeln(
        'IMPORTANT: The user uploaded multiple items because they\'re indecisive about pairing.',
      );
      buffer.writeln(
        'Create a complete, harmonious outfit that showcases the best combination of their pieces.',
      );
      buffer.writeln(
        'Add complementary accessories, jewelry, and styling elements to complete the look.',
      );
    }

    // Special instructions for footwear visibility
    final hasFootwear = uploadedItems.any(
      (item) =>
          item.itemType.toLowerCase().contains('shoe') ||
          item.itemType.toLowerCase().contains('footwear'),
    );
    if (hasFootwear) {
      buffer.writeln(' FOOTWEAR ALERT: The user uploaded footwear items!');
      buffer.writeln(
        ' MANDATORY: The shoes/footwear MUST be the main focus of this image!',
      );
      buffer.writeln(
        ' REQUIRED: Show the mannequin from head to toe with shoes prominently displayed!',
      );
      buffer.writeln(
        'CRITICAL: Position the mannequin so footwear is clearly visible and not cropped!',
      );
      buffer.writeln(
        ' Make the footwear a focal point - it\'s what the user wants to see!',
      );
    }

    buffer.writeln(
      'Render a full-body mannequin in studio lighting with polished styling.',
    );
    buffer.writeln(
      '🚨 CRITICAL FOOTWEAR REQUIREMENT: ALWAYS show the COMPLETE outfit from head to toe!',
    );
    buffer.writeln(
      '🚨 NEVER crop out shoes, feet, or footwear - they must be fully visible!',
    );
    buffer.writeln(
      '🚨 The mannequin must be positioned to show the entire body including shoes!',
    );
    buffer.writeln(
      ' If footwear is mentioned in the outfit, make it a focal point of the image!',
    );
    buffer.writeln(
      'Ensure the outfit is color-harmonized, accessorized appropriately, and photography ready.',
    );
    buffer.writeln(
      'Pay special attention to the user\'s styling notes and preferences when creating the outfit.',
    );
    buffer.writeln(' Show the COMPLETE outfit with visible footwear !');
    return buffer.toString();
  }

  static Future<String?> _callImagePreview(
    String prompt,
    File imageFile,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
    };

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent?key=$_apiKey';
    AppLogger.network(url, 'POST', body: requestBody);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    AppLogger.network(url, 'POST', statusCode: response.statusCode);

    if (response.statusCode != 200) {
      AppLogger.error('❌ Mannequin generation API error', error: response.body);
      return null;
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = responseData['candidates'] as List<dynamic>?;

    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    for (final candidate in candidates) {
      final parts = candidate['content']?['parts'] as List<dynamic>?;
      if (parts == null) continue;
      for (final part in parts) {
        final inline = part['inlineData'];
        if (inline != null && inline['data'] != null) {
          return inline['data'] as String;
        }
      }
    }

    return null;
  }

  static List<_OutfitCombination> _composeOutfitCombinations(
    List<ClothingAnalysis> items,
  ) {
    final shoes =
        items
            .where(
              (item) =>
                  item.itemType.toLowerCase().contains('shoe') ||
                  item.itemType.toLowerCase().contains('footwear'),
            )
            .toList();
    final dresses =
        items
            .where((item) => item.itemType.toLowerCase().contains('dress'))
            .toList();
    final tops =
        items
            .where((item) => item.itemType.toLowerCase().contains('top'))
            .toList();
    final bottoms =
        items
            .where((item) => item.itemType.toLowerCase().contains('bottom'))
            .toList();
    final outerwear =
        items
            .where((item) => item.itemType.toLowerCase().contains('outer'))
            .toList();
    final accessories =
        items
            .where((item) => item.itemType.toLowerCase().contains('accessory'))
            .toList();

    final combinations = <_OutfitCombination>[];

    // Handle indecisiveness: Multiple shoes + dress scenario
    if (dresses.isNotEmpty && shoes.length > 1) {
      AppLogger.info(
        '🎯 Detected indecisiveness: ${shoes.length} shoes + dress - creating smart pairings',
      );

      for (final dress in dresses) {
        // Create multiple dress + shoe combinations for indecisive users
        for (int i = 0; i < shoes.length && i < 3; i++) {
          final shoe = shoes[i];
          final isBestMatch = i == 0; // First shoe is considered "best match"

          combinations.add(
            _OutfitCombination(
              items: [
                dress,
                shoe,
                if (outerwear.isNotEmpty) outerwear.first,
                if (accessories.isNotEmpty) accessories.first,
              ],
              metadata: {
                'styleLabel':
                    isBestMatch ? 'perfect pairing' : 'alternative style',
                'pose':
                    isBestMatch
                        ? 'elegant evening pose'
                        : 'confident runway stance',
                'occasion': 'evening event',
                'pairingNotes':
                    isBestMatch
                        ? 'Perfect harmony between your ${dress.primaryColor} dress and ${shoe.primaryColor} ${shoe.itemType}. This is the ideal pairing!'
                        : 'Alternative styling with your ${dress.primaryColor} dress and ${shoe.primaryColor} ${shoe.itemType}. A bold choice!',
                'description':
                    isBestMatch
                        ? 'The perfect dress and shoe combination - elegant and sophisticated'
                        : 'Alternative dress pairing - ${shoe.primaryColor} ${shoe.itemType} with ${dress.primaryColor} dress',
              },
            ),
          );
        }
      }
    }
    // Regular dress + shoes pairing
    else if (dresses.isNotEmpty) {
      for (final dress in dresses) {
        final matchingShoes =
            shoes.isNotEmpty
                ? shoes
                : bottoms.isNotEmpty
                ? [bottoms.first]
                : [];
        combinations.add(
          _OutfitCombination(
            items: [
              dress,
              ...matchingShoes.take(1),
              if (outerwear.isNotEmpty) outerwear.first,
              if (accessories.isNotEmpty) accessories.first,
            ],
            metadata: {
              'styleLabel': 'elevated evening',
              'pose': 'evening runway stance',
              'occasion': 'evening event',
              'pairingNotes':
                  'Highlight the dress silhouette with complementary footwear and sleek layers.',
              'description':
                  'A head-turning ensemble built around your ${dress.primaryColor} dress.',
            },
          ),
        );
      }
    }

    // Handle indecisiveness: Multiple shoes + top scenario
    if (tops.isNotEmpty && shoes.length > 1 && dresses.isEmpty) {
      AppLogger.info(
        '🎯 Detected indecisiveness: ${shoes.length} shoes + top - creating smart pairings',
      );

      for (final top in tops) {
        // Create multiple top + shoe combinations
        for (int i = 0; i < shoes.length && i < 2; i++) {
          final shoe = shoes[i];
          final isBestMatch = i == 0;

          combinations.add(
            _OutfitCombination(
              items: [
                top,
                shoe,
                if (bottoms.isNotEmpty) bottoms.first,
                if (accessories.isNotEmpty) accessories.first,
              ],
              metadata: {
                'styleLabel':
                    isBestMatch ? 'perfect casual' : 'alternative casual',
                'pose':
                    isBestMatch
                        ? 'relaxed street pose'
                        : 'dynamic urban stance',
                'occasion': 'casual day',
                'pairingNotes':
                    isBestMatch
                        ? 'Perfect casual pairing with your ${top.primaryColor} ${top.itemType} and ${shoe.primaryColor} ${shoe.itemType}'
                        : 'Alternative casual look featuring your ${top.primaryColor} ${top.itemType} and ${shoe.primaryColor} ${shoe.itemType}',
                'description':
                    isBestMatch
                        ? 'The ideal casual combination - comfortable and stylish'
                        : 'Alternative casual styling - ${shoe.primaryColor} ${shoe.itemType} with ${top.primaryColor} ${top.itemType}',
              },
            ),
          );
        }
      }
    }
    // Regular top + bottom pairing
    else if (tops.isNotEmpty && bottoms.isNotEmpty) {
      for (final top in tops) {
        final bottom = bottoms.first;
        combinations.add(
          _OutfitCombination(
            items: [
              top,
              bottom,
              if (shoes.isNotEmpty) shoes.first,
              if (accessories.isNotEmpty) accessories.first,
            ],
            metadata: {
              'styleLabel': 'smart casual',
              'pose': 'confident street pose',
              'occasion': 'day-to-night',
              'pairingNotes':
                  'Balance proportions between the ${top.itemType} and ${bottom.itemType}.',
              'description':
                  'A polished pairing featuring your ${top.primaryColor} ${top.itemType}.',
            },
          ),
        );
      }
    }

    // Individual shoe spotlights for remaining unmatched shoes
    for (final shoe in shoes) {
      // Skip if this shoe was already used in dress/top combinations
      final alreadyUsed = combinations.any(
        (combo) => combo.items.contains(shoe),
      );
      if (!alreadyUsed) {
        combinations.add(
          _OutfitCombination(
            items: [
              shoe,
              if (dresses.isNotEmpty)
                dresses.first
              else if (bottoms.isNotEmpty)
                bottoms.first,
            ],
            metadata: {
              'styleLabel': 'shoe spotlight',
              'pose': 'dynamic runway stride',
              'occasion': 'trend showcase',
              'pairingNotes':
                  'Design an outfit that elevates the footwear as the hero piece.',
              'description':
                  'A styled look to make your ${shoe.primaryColor} ${shoe.itemType} the hero.',
            },
          ),
        );
      }
    }

    if (combinations.isEmpty) {
      combinations.add(
        _OutfitCombination(
          items: items,
          metadata: {
            'styleLabel': 'creative mix',
            'pose': 'studio portrait pose',
            'occasion': 'creative editorial',
            'pairingNotes': 'Blend textures and colors harmoniously.',
            'description': 'An editorial concept using every uploaded item.',
          },
        ),
      );
    }

    return combinations.take(6).toList(growable: false);
  }

  static const List<String> _poseLibrary = [
    'studio front pose, arms relaxed',
    'runway walk, dynamic motion',
    'three-quarter stance with confidence',
    'seated pose with elegant posture',
    'leaning pose with casual vibe',
    'couture editorial pose',
  ];

  /// Generate a detailed mannequin description that can be used for image generation
  static Future<Map<String, dynamic>?> generateDetailedMannequinDescription({
    required File imageFile,
    required String poseDescription,
    required String itemType,
    required String color,
  }) async {
    AppLogger.info(
      '🎨 Generating detailed mannequin description for image generation',
      data: {'pose': poseDescription, 'itemType': itemType, 'color': color},
    );

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
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {"text": prompt},
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.3,
          "topK": 32,
          "topP": 1.0,
          "maxOutputTokens": 4096,
        },
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
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            '';
        AppLogger.debug(
          '📥 Mannequin description response received',
          data: {
            'response_length': text.length,
            'response_preview':
                text.length > 200 ? text.substring(0, 200) + '...' : text,
          },
        );

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
          if (codeBlockStart != -1 &&
              codeBlockEnd != -1 &&
              codeBlockEnd > codeBlockStart) {
            try {
              final jsonString =
                  text.substring(codeBlockStart + 7, codeBlockEnd).trim();
              result = jsonDecode(jsonString);
              AppLogger.info('✅ Successfully extracted JSON from code block');
            } catch (e) {
              AppLogger.warning(
                '❌ Failed to parse JSON from code block',
                error: e,
              );
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
          AppLogger.info(
            '✅ Detailed mannequin description generated successfully',
          );
          return result;
        } else {
          AppLogger.warning(
            '❌ Failed to extract any valid JSON from mannequin description response',
            error: {'full_response': text},
          );
          return null;
        }
      } else {
        AppLogger.error(
          '❌ Mannequin description API error',
          error: response.body,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Exception in generateDetailedMannequinDescription',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save generated image to assets directory for debugging
  static Future<String?> _saveGeneratedImageToAssets(
    String base64ImageData,
    String timestamp,
  ) async {
    try {
      if (kIsWeb) {
        AppLogger.info('🌐 Web platform detected, skipping image save');
        return null;
      }

      // Try to save to assets directory (this might not work in production)
      // But we'll also save to documents directory as backup
      final directory = await getApplicationDocumentsDirectory();
      final assetsPath =
          '${directory.path}/assets/images/mannequin_$timestamp.png';
      final documentsPath = '${directory.path}/mannequin_$timestamp.png';

      // Decode base64 image data
      final imageBytes = base64Decode(base64ImageData);

      // Save to documents directory (guaranteed to work)
      final documentsFile = File(documentsPath);
      await documentsFile.writeAsBytes(imageBytes);
      AppLogger.info(
        '💾 Saved generated mannequin image to documents: $documentsPath',
      );

      // Try to save to assets-like directory
      try {
        final assetsDir = Directory('${directory.path}/assets/images');
        if (!await assetsDir.exists()) {
          await assetsDir.create(recursive: true);
        }

        final assetsFile = File(assetsPath);
        await assetsFile.writeAsBytes(imageBytes);
        AppLogger.info(
          '💾 Saved generated mannequin image to assets: $assetsPath',
        );
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
    AppLogger.info(
      '🎨 Generating REAL mannequin image with uploaded item',
      data: {
        'pose': poseDescription,
        'itemType': itemType,
        'color': color,
        'imageFile': imageFile.path,
      },
    );

    try {
      // Simple, clean prompt - following the "nano banana" approach
      final simplePrompt = '''
Create a professional fashion mannequin wearing a complete outfit featuring the uploaded clothing item. 
Style: $poseDescription
The mannequin should be photorealistic and have a full body view, well-lit, against a clean background.
Show a complete, stylish outfit that includes the uploaded item plus complementary pieces and it should be an outfit that is perfect, based on color combination and style 
(eg, when you are having a blue shirt, you should wear a this pants, the footwear and accessories should be perfect based on the style).
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
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
      };

      // Use the image generation model endpoint
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent?key=$_apiKey';
      AppLogger.network(url, 'POST', body: requestBody);

      final startTime = DateTime.now();
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30)); // Add timeout
      final duration = DateTime.now().difference(startTime);

      AppLogger.performance(
        'Simple mannequin image generation API call',
        duration,
        result: response.statusCode,
      );
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
                  AppLogger.info(
                    '✅ REAL mannequin image generated successfully',
                  );

                  // Save the image to assets directory for debugging
                  await _saveGeneratedImageToAssets(
                    base64ImageData,
                    DateTime.now().millisecondsSinceEpoch.toString(),
                  );

                  return base64ImageData; // Return the base64 image data
                }
              }
            }

            // Fallback: extract text description if no image
            final text = parts
                .where((part) => part.containsKey('text'))
                .map((part) => part['text'])
                .join(' ');

            if (text.isNotEmpty) {
              AppLogger.info(
                '📝 No image generated, returning text description',
              );
              return text;
            }
          }
        }

        AppLogger.warning(
          '❌ No valid content in mannequin generation response',
        );
        return null;
      } else {
        AppLogger.error(
          '❌ Mannequin generation API error',
          error: response.body,
        );
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Exception in generateMannequinImage',
        error: e,
        stackTrace: stackTrace,
      );
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
    if (colorLower.contains('green') ||
        colorLower.contains('mint') ||
        colorLower.contains('sage') ||
        colorLower.contains('olive')) {
      return 'green';
    }

    // Blue variations
    if (colorLower.contains('blue') ||
        colorLower.contains('navy') ||
        colorLower.contains('azure') ||
        colorLower.contains('teal')) {
      return 'blue';
    }

    // Gray variations
    if (colorLower.contains('gray') ||
        colorLower.contains('grey') ||
        colorLower.contains('charcoal') ||
        colorLower.contains('silver')) {
      return 'gray';
    }

    // Black variations
    if (colorLower.contains('black') || colorLower.contains('ebony')) {
      return 'black';
    }

    // White variations
    if (colorLower.contains('white') ||
        colorLower.contains('cream') ||
        colorLower.contains('ivory') ||
        colorLower.contains('off-white')) {
      return 'white';
    }

    // Brown variations
    if (colorLower.contains('brown') ||
        colorLower.contains('tan') ||
        colorLower.contains('beige') ||
        colorLower.contains('khaki')) {
      return 'brown';
    }

    // Red variations
    if (colorLower.contains('red') ||
        colorLower.contains('burgundy') ||
        colorLower.contains('maroon') ||
        colorLower.contains('crimson')) {
      return 'red';
    }

    return color; // Return original if no match
  }

  /// Normalize style classifications
  static String _normalizeStyle(String style) {
    final styleLower = style.toLowerCase().trim();

    // Business formal variations
    if (styleLower.contains('business') ||
        styleLower.contains('formal') ||
        styleLower.contains('professional') ||
        styleLower.contains('office')) {
      return 'business formal';
    }

    // Smart casual variations
    if (styleLower.contains('smart') || styleLower.contains('semi-formal')) {
      return 'smart casual';
    }

    // Casual variations
    if (styleLower.contains('casual') ||
        styleLower.contains('everyday') ||
        styleLower.contains('relaxed')) {
      return 'casual';
    }

    return style; // Return original if no match
  }

  /// Generate complimentary color combinations
  static Map<String, List<String>> getComplementaryColors(String primaryColor) {
    AppLogger.debug(
      '🎨 Finding complementary colors',
      data: {'primary': primaryColor},
    );

    final colorMap = {
      'red': 'blue',
      'blue': 'orange',
      'green': 'red',
      'yellow': 'purple',
      'black': 'white',
      'white': 'black',
    };

    final complement = colorMap[primaryColor.toLowerCase()] ?? 'black';
    AppLogger.debug(
      '✅ Complementary color found',
      data: {'complement': complement},
    );

    return {
      'complementary': [complement],
      'analogous': [primaryColor], // Simplified
      'triadic': [primaryColor], // Simplified
    };
  }
}

class _OutfitCombination {
  const _OutfitCombination({required this.items, required this.metadata});

  final List<ClothingAnalysis> items;
  final Map<String, Object?> metadata;
}
