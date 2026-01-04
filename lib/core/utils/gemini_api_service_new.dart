import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/utils/api_rate_limiter.dart';

class GeminiApiService {
  static int _currentKeyIndex = 0;

  // Get API key directly from dotenv at request time (not cached)
  static String _getApiKey() {
    // Direct access to dotenv - read fresh every time
    final key1 = dotenv.env['GEMINI_API_KEY'];
    final key2 = dotenv.env['GEMINI_API_KEY2'];

    final keys = <String>[];
    if (key1 != null && key1.isNotEmpty) keys.add(key1);
    if (key2 != null && key2.isNotEmpty) keys.add(key2);

    if (keys.isEmpty) {
      AppLogger.error('⚠️ [SECURITY] No Gemini API keys found in .env file!');
      AppLogger.error(
        'DEBUG: dotenv.env keys: ${dotenv.env.keys.take(5).toList()}',
      );
      AppLogger.error(
        'DEBUG: GEMINI_API_KEY value: ${dotenv.env['GEMINI_API_KEY']}',
      );
      return '';
    }

    final selectedKey = keys[_currentKeyIndex % keys.length];
    return selectedKey;
  }

  static void _rotateApiKey() {
    // Get fresh count from dotenv
    final key1 = dotenv.env['GEMINI_API_KEY'];
    final key2 = dotenv.env['GEMINI_API_KEY2'];
    final keyCount = [
      key1,
      key2,
    ].where((k) => k != null && k.isNotEmpty).length;

    if (keyCount > 1) {
      _currentKeyIndex = (_currentKeyIndex + 1) % keyCount;
      AppLogger.info('🔄 Switching to API Key index: $_currentKeyIndex');
    }
  }

  static const String _modelAnalysis = 'gemini-3-pro-preview';
  static const String _modelImageGen = 'gemini-3-pro-image-preview';

  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelAnalysis:generateContent';

  static String get _imageEndpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelImageGen:generateContent';

  static Future<http.Response> _makeRequestWithRetry(
    String urlBase,
    Map<String, dynamic> body, {
    int retries = 2,
  }) async {
    for (int i = 0; i <= retries; i++) {
      final currentKey = _getApiKey();
      // Mask key for logging
      final maskedKey = currentKey.length > 10
          ? '${currentKey.substring(0, 5)}...${currentKey.substring(currentKey.length - 5)}'
          : 'invalid';

      print(
        '🔄 [Gemini] Request attempt ${i + 1}/$retries using key: $maskedKey index: $_currentKeyIndex',
      );

      final url = '$urlBase?key=$currentKey';

      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 45));

        print('📨 [Gemini] Response status: ${response.statusCode}');

        if (response.statusCode == 403 ||
            response.statusCode == 429 ||
            response.statusCode >= 500) {
          print('⚠️ [Gemini] Error ${response.statusCode}: ${response.body}');
          AppLogger.warning(
            '⚠️ API Error ${response.statusCode} with key index $_currentKeyIndex. Rotating...',
          );
          _rotateApiKey();
          continue;
        }
        return response;
      } catch (e) {
        print('❌ [Gemini] Exception: $e');
        AppLogger.error(
          '❌ Request failed with key index $_currentKeyIndex: $e',
        );
        _rotateApiKey();
        if (i == retries) {
          print('💀 [Gemini] All retries failed');
          rethrow;
        }
      }
    }
    throw Exception('All API keys failed');
  }

  static String _getMimeType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    if (path.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

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
        primaryColor:
            (result['normalizedPrimaryColor'] as String?)?.isNotEmpty == true
            ? result['normalizedPrimaryColor'] as String
            : result['primaryColor'] ?? '',
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
        colorFamily: result['colorFamily'],
        exactPrimaryColor:
            (result['exactPrimaryColor'] as String?)?.isNotEmpty == true
            ? result['exactPrimaryColor'] as String
            : result['primaryColor'],
        colorHex: result['colorHex'],
        colorKeywords: result['colorKeywords'] != null
            ? List<String>.from(result['colorKeywords'])
            : null,
        patternDetails: result['patternDetails'],
        patternKeywords: result['patternKeywords'] != null
            ? List<String>.from(result['patternKeywords'])
            : null,
        occasions: result['occasions'] != null
            ? List<String>.from(result['occasions'])
            : null,
        locations: result['locations'] != null
            ? List<String>.from(result['locations'])
            : null,
        styleHints: result['styleHints'] != null
            ? List<String>.from(result['styleHints'])
            : null,
        styleDescriptors: result['styleDescriptors'] != null
            ? List<String>.from(result['styleDescriptors'])
            : null,
        colorUndertone: result['colorUndertone'],
        complementaryColors: result['complementaryColors'] != null
            ? List<String>.from(result['complementaryColors'])
            : null,
        colorTemperature: result['colorTemperature'],
        designElements: result['designElements'] != null
            ? List<String>.from(result['designElements'])
            : null,
        visualWeight: result['visualWeight'],
        pairingHints: result['pairingHints'] != null
            ? List<String>.from(result['pairingHints'])
            : null,
        stylePersonality: result['stylePersonality'],
        detailLevel: result['detailLevel'],
        garmentKeywords: result['garmentKeywords'] != null
            ? List<String>.from(result['garmentKeywords'])
            : null,
        rawAttributes: result['rawAttributes'] as Map<String, dynamic>?,
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

      final prompt =
          '''
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
                  "mimeType": _getMimeType(imageFile),
                  "data": base64Image,
                },
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

      AppLogger.network(_endpoint, 'POST', body: requestBody);

      final response = await _makeRequestWithRetry(_endpoint, requestBody);

      AppLogger.network(_endpoint, 'POST', statusCode: response.statusCode);

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
                "inlineData": {
                  "mimeType": _getMimeType(imageFile),
                  "data": base64Image,
                },
              },
              {
                "text":
                    "You are an expert fashion analyst. Analyze this clothing item with EXTREME PRECISION for PERFECT OUTFIT PAIRING.\n\nCRITICAL RULES:\n1. FOOTWEAR DETECTION: If you see ANY shoes, sneakers, boots, sandals, heels, flats, mules, loafers, oxfords, pumps, stilettos, wedges, ankle boots, knee-high boots, combat boots, hiking boots, running shoes, athletic shoes, dress shoes, casual shoes, slippers, flip-flops, crocs, clogs, ballet flats, espadrilles, platform shoes, high heels, low heels, block heels, stiletto heels, kitten heels, chunky heels, wedges, peep-toe shoes, closed-toe shoes, open-toe shoes, lace-up shoes, slip-on shoes, buckle shoes, zipper shoes, velcro shoes, lace shoes, slip-ons, moccasins, boat shoes, driving shoes, work boots, rain boots, snow boots, winter boots, summer shoes, spring shoes, fall shoes, seasonal footwear - ALWAYS classify as 'Footwear' NOT 'Top'\n2. JEANS ANALYSIS: Look carefully at fit - distinguish between 'skinny jeans', 'baggy jeans', 'relaxed fit jeans', 'straight leg jeans'\n3. LOOK CAREFULLY at the actual colors in the image - don't default to common colors\n4. If you see GREEN fabric, say GREEN not blue\n5. If you see formal elements (lapels, structured shoulders, dress pants), classify as business/formal\n6. If you see suits, blazers, dress shirts, classify as 'business formal' or 'formal wear'\n\nReturn ONLY a JSON object with these exact keys:\n{\n  \"itemType\": \"Top|Bottom|Dress|Outerwear|Footwear|Accessory\",\n  \"primaryColor\": \"EXACT color you see (green, navy blue, charcoal gray, burgundy, etc.)\",\n  \"secondaryColors\": [\"array of other colors if any\"],\n  \"patternType\": \"solid|pinstripe|checkered|herringbone|floral|geometric\",\n  \"material\": \"wool|cotton|silk|linen|polyester|leather|denim\",\n  \"fit\": \"slim fit|regular fit|relaxed fit|tailored fit|oversized|baggy|skinny\",\n  \"style\": \"business formal|smart casual|casual|formal wear|streetwear\",\n  \"formality\": \"formal|business|smart casual|casual\",\n  \"subcategory\": \"specific type like 'baggy jeans', 'white sneakers', 'black ankle boots', 'nude heels', 'brown loafers', 'oxford shirt'\",\n  \"confidence\": 0.95,\n  \"colorUndertone\": \"warm|cool|neutral\" (analyze if colors have warm/cool undertones),\n  \"complementaryColors\": [\"specific colors that pair perfectly with this item\"],\n  \"colorTemperature\": \"warm|cool|neutral\" (overall temperature),\n  \"designElements\": [\"embellishments\", \"hardware\", \"unique features\", \"prints\", \"textures\"],\n  \"visualWeight\": \"light|medium|heavy\" (how visually heavy/busy for balance),\n  \"detailLevel\": \"minimal|moderate|detailed\" (complexity level),\n  \"pairingHints\": [\"specific items that work well (e.g., 'pairs with white sneakers', 'works with high-waisted jeans')\"],\n  \"stylePersonality\": \"edgy|classic|romantic|minimalist|bohemian|sporty|preppy|streetwear|vintage|modern\"\n}\n\nFASHION INTELLIGENCE:\n1. COLOR ANALYSIS: Identify undertones (warm=yellow/orange base, cool=blue/pink base, neutral=balanced)\n2. COMPLEMENTARY COLORS: Suggest 3-5 specific colors that create perfect color harmony\n3. VISUAL WEIGHT: Light=simple/minimal, Medium=moderate detail, Heavy=busy/bold patterns\n4. PAIRING HINTS: Be SPECIFIC (e.g., 'pairs with black ankle boots', not generic advice)\n5. DESIGN ELEMENTS: List ALL visible details (studs, embroidery, distressing, hardware, etc.)\n\nReturn ONLY the JSON, no explanation.",
              },
            ],
          },
        ],
      };

      AppLogger.network(_endpoint, 'POST', body: requestBody);

      final startTime = DateTime.now();
      final response = await _makeRequestWithRetry(_endpoint, requestBody);
      final duration = DateTime.now().difference(startTime);
      AppLogger.performance(
        'Gemini API call',
        duration,
        result: response.statusCode,
      );

      AppLogger.network(_endpoint, 'POST', statusCode: response.statusCode);

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

          final processedResult = <String, dynamic>{
            'itemType': result['itemType'] ?? 'Unknown',
            'primaryColor': result['primaryColor'] ?? 'Unknown',
            'normalizedPrimaryColor': _normalizeColor(
              result['primaryColor'] ??
                  result['exactPrimaryColor'] ??
                  'Unknown',
            ),
            'exactPrimaryColor': result['exactPrimaryColor'],
            'colorFamily': result['colorFamily'],
            'colorHex': result['colorHex'],
            'colorKeywords': _extractStringList(result['colorKeywords']),
            'patternType': result['patternType'] ?? 'solid',
            'patternDetails': result['patternDetails'],
            'patternKeywords': _extractStringList(result['patternKeywords']),
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
            'styleDescriptors': _extractStringList(result['styleDescriptors']),
            // Enhanced fashion intelligence fields
            'colorUndertone': result['colorUndertone'],
            'complementaryColors': _extractStringList(
              result['complementaryColors'],
            ),
            'colorTemperature': result['colorTemperature'],
            'designElements': _extractStringList(result['designElements']),
            'visualWeight': result['visualWeight'],
            'pairingHints': _extractStringList(result['pairingHints']),
            'stylePersonality': result['stylePersonality'],
            'detailLevel': result['detailLevel'],
            'garmentKeywords': _extractStringList(result['garmentKeywords']),
            'rawAttributes': result,
          };

          AppLogger.info(
            '✅ Clothing analysis complete',
            data: {
              'itemType': processedResult['itemType'],
              'primaryColor': processedResult['normalizedPrimaryColor'],
              'confidence': processedResult['confidence'],
              'occasions': processedResult['occasions'],
              'locations': processedResult['locations'],
              'styleHints': processedResult['styleHints'],
            },
          );
          // Cache the successful response
          ApiRateLimiter.instance.cacheResponse(
            cacheKey,
            jsonEncode(processedResult),
          );

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

  /// Generate enhanced mannequin outfits as a stream for progressive loading
  static Stream<MannequinOutfit> generateEnhancedMannequinOutfitsStream(
    List<ClothingAnalysis> items, {
    String? userNotes,
    String gender = 'male', // 'male' or 'female'
    void Function(String)? onProgress,
  }) async* {
    AppLogger.info(
      '👤 Streaming enhanced mannequin outfits',
      data: {'items': items.length, 'notes': userNotes?.length},
    );

    if (items.isEmpty) {
      AppLogger.warning('⚠️ No items provided for mannequin generation');
      return;
    }

    final combinations = _composeOutfitCombinations(items);
    final totalLooks = 6;

    for (int i = 0; i < totalLooks; i++) {
      final combo = combinations[i % combinations.length];
      final styleLabel = combo.metadata['styleLabel'] as String? ?? 'signature';
      final poseDescription =
          combo.metadata['pose'] as String? ??
          _poseLibrary[i % _poseLibrary.length];

      onProgress?.call('Styling look ${i + 1} of $totalLooks ($styleLabel)');

      try {
        final prompt = _buildMannequinPrompt(
          uploadedItemsToUse: combo.uploadedItems,
          unuploadedCategories: combo.unuploadedCategories,
          userNotes: userNotes,
          desiredStyle: styleLabel,
          pairingNotes: combo.metadata['pairingNotes'] as String?,
          gender: gender,
        );

        // Use the first uploaded item's image (most important piece)
        final primaryImagePath = combo.uploadedItems.isNotEmpty
            ? combo.uploadedItems.first.imagePath
            : combo.items
                  .firstWhere((item) => item.imagePath != null)
                  .imagePath;
        final imageFile = primaryImagePath != null
            ? File(primaryImagePath)
            : null;

        if (imageFile == null) {
          AppLogger.warning('⚠️ Missing image for mannequin combo, skipping');
          continue;
        }

        final imageResult = await _callImagePreview(prompt, imageFile);

        if (imageResult != null) {
          yield MannequinOutfit(
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
          );
        }

        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e, stackTrace) {
        AppLogger.error(
          '❌ Failed to build mannequin look',
          error: e,
          stackTrace: stackTrace,
        );
        yield MannequinOutfit(
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
        );
      }
    }

    onProgress?.call('All looks styled successfully.');
  }

  /// Generate a SINGLE mannequin preview (for pairing sheet preview button)
  static Future<String?> generateSingleMannequinPreview(
    List<ClothingAnalysis> items, {
    String? userNotes,
    String gender = '', // 'male' or 'female'
  }) async {
    AppLogger.info(
      '🎨 Generating SINGLE mannequin preview',
      data: {'items': items.length, 'gender': gender},
    );

    if (items.isEmpty) {
      AppLogger.warning('⚠️ No items provided for mannequin generation');
      return null;
    }

    // Generate only ONE mannequin
    final combinations = _composeOutfitCombinations(items);
    if (combinations.isEmpty) {
      AppLogger.warning('⚠️ No outfit combinations generated');
      return null;
    }

    // Use the first combination
    final combo = combinations.first;

    try {
      final prompt = _buildMannequinPrompt(
        uploadedItemsToUse: combo.uploadedItems,
        unuploadedCategories: combo.unuploadedCategories,
        userNotes: userNotes,
        desiredStyle: 'styled pairing',
        gender: gender,
      );

      // Get the first image file
      final imagePath = items.first.imagePath;
      if (imagePath == null || imagePath.isEmpty) {
        AppLogger.error('❌ No image path provided for first item');
        return null;
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        AppLogger.error('❌ Image file not found: $imagePath');
        return null;
      }

      final imageUrl = await _callImagePreview(prompt, imageFile);
      AppLogger.info('✅ Single mannequin preview generated successfully');
      return imageUrl;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to generate single mannequin preview',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate enhanced mannequin outfits using full wardrobe context and notes
  static Future<List<MannequinOutfit>> generateEnhancedMannequinOutfits(
    List<ClothingAnalysis> items, {
    String? userNotes,
    String gender = '', // 'male' or 'female'
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
        'item_types': items
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

    // Log distribution for transparency
    final distributionLog = <String, int>{};
    for (final combo in combinations.take(6)) {
      for (final item in combo.uploadedItems) {
        final key =
            '${item.itemType}: ${item.primaryColor} ${item.subcategory ?? ""}';
        distributionLog[key] = (distributionLog[key] ?? 0) + 1;
      }
    }

    AppLogger.info(
      '📊 Outfit distribution across 6 generations:',
      data: distributionLog,
    );

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
          uploadedItemsToUse: combo.uploadedItems,
          unuploadedCategories: combo.unuploadedCategories,
          userNotes: userNotes,
          desiredStyle: styleLabel,
          pairingNotes: combo.metadata['pairingNotes'] as String?,
          gender: gender,
        );

        // Use the first uploaded item's image (most important piece)
        final primaryImagePath = combo.uploadedItems.isNotEmpty
            ? combo.uploadedItems.first.imagePath
            : combo.items
                  .firstWhere((item) => item.imagePath != null)
                  .imagePath;
        final imageFile = primaryImagePath != null
            ? File(primaryImagePath)
            : null;

        if (imageFile == null) {
          AppLogger.warning('⚠️ Missing image for mannequin combo, skipping');
          continue;
        }

        // Log which items are being used in this combination
        AppLogger.info(
          '🎨 Generating mannequin with uploaded items',
          data: {
            'combo_index': i,
            'uploaded_items_count': combo.uploadedItems.length,
            'uploaded_items': combo.uploadedItems
                .map((item) => '${item.itemType} (${item.primaryColor})')
                .toList(),
            'unuploaded_categories': combo.unuploadedCategories,
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
    required List<ClothingAnalysis> uploadedItemsToUse,
    required List<String> unuploadedCategories,
    String? userNotes,
    String? desiredStyle,
    String? pairingNotes,
    String gender = 'male',
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'Design a premium full-body mannequin look using the wardrobe pieces provided.USE ONLY THE UPLOADED ITEMS LISTED BELOW',
    );
    buffer.writeln(
      'Keep the hero items front and center and stay true to their original details.',
    );
    buffer.writeln('DO NOT replace uploaded items with similar alternatives.');
    buffer.writeln('DO NOT blend multiple items from the same category.');
    buffer.writeln('DO NOT create new versions of uploaded items.');
    buffer.writeln();

    buffer.writeln('Must-use uploaded pieces (show exactly as described):');
    bool hasGraphicTop = false;

    for (final item in uploadedItemsToUse) {
      final isTop = item.itemType.toLowerCase().contains('top');
      final hasGraphics =
          item.patternType != 'solid' ||
          (item.subcategory?.toLowerCase().contains('graphic') ?? false) ||
          (item.subcategory?.toLowerCase().contains('jersey') ?? false) ||
          (item.subcategory?.toLowerCase().contains('print') ?? false) ||
          (item.designElements?.any(
                (e) =>
                    e.toLowerCase().contains('graphic') ||
                    e.toLowerCase().contains('text') ||
                    e.toLowerCase().contains('logo') ||
                    e.toLowerCase().contains('print'),
              ) ??
              false);

      if (isTop && hasGraphics) hasGraphicTop = true;

      buffer.writeln(
        '• ${item.itemType.toUpperCase()}: ${item.primaryColor} ${item.subcategory ?? item.itemType}',
      );
      if (item.material != null) {
        buffer.writeln('  Material: ${item.material}');
      }
      if (item.fit != null) {
        buffer.writeln('  Fit: ${item.fit}');
      }
      if (item.patternType.isNotEmpty) {
        buffer.writeln('  Pattern: ${item.patternType}');
      }
      if (item.exactPrimaryColor != null &&
          item.exactPrimaryColor!.isNotEmpty) {
        buffer.writeln('  Shade: ${item.exactPrimaryColor}');
      }
      if (hasGraphics && isTop) {
        buffer.writeln(
          '  ⚠️ HAS GRAPHICS/PRINTS/TEXT - SHOW BARE WITHOUT JACKET',
        );
      }
      buffer.writeln(
        '  🚨 USE THIS EXACT ${item.itemType.toUpperCase()} - NO SUBSTITUTIONS',
      );
      buffer.writeln();
    }

    if (unuploadedCategories.isNotEmpty) {
      buffer.writeln('Feel free to add tasteful complements for:');
      for (final category in unuploadedCategories) {
        if (category.toLowerCase() == 'bottoms') {
          buffer.writeln(
            '  - BOTTOMS: Vary styles across looks - skirts (fitting, flare, short, long, bodycon), trousers, shorts, wide-leg pants, baggy jeans, joggers, fitting jeans. Avoid defaulting to tight jeans every time.',
          );
        } else if (category.toLowerCase() == 'tops') {
          buffer.writeln(
            '  - TOPS: Vary between t-shirts, blouses, tanks, knits. Keep graphics/prints visible.',
          );
        } else if (category.toLowerCase() == 'outerwear') {
          buffer.writeln(
            '  - OUTERWEAR: Use sparingly (max 1-2 looks). Only add if it enhances the outfit without hiding key details.',
          );
        } else {
          buffer.writeln(
            '  - ${category.toUpperCase()}: design something cohesive that matches the uploaded items.',
          );
        }
      }
      buffer.writeln();
    }

    buffer.writeln('🎯 CRITICAL STYLING RULES:');
    buffer.writeln(
      '1. Keep uploaded pieces as the hero - let colors, patterns, graphics, and text visible.',
    );
    buffer.writeln('2. DO NOT create alternative versions of uploaded items.');
    buffer.writeln(
      '3. DO NOT merge or blend multiple uploaded items into one.',
    );
    buffer.writeln();

    buffer.writeln('🚫 LAYERING LIMITS:');
    if (hasGraphicTop) {
      buffer.writeln(
        '- ⚠️ IMPORTANT: The uploaded top has GRAPHICS/PRINTS/TEXT that MUST be visible',
      );
      buffer.writeln(
        '- DO NOT cover this top with jackets/sweaters/coats in ANY of the 6 looks',
      );
      buffer.writeln(
        '- Show the top BARE so graphics/text/designs are fully visible',
      );
    } else {
      buffer.writeln(
        '- Plain tops: Can have a light jacket in MAX 2 out of 6 looks',
      );
      buffer.writeln(
        '- MOST LOOKS (4-6 out of 6) should show tops WITHOUT jackets/sweaters/coats',
      );
    }
    buffer.writeln(
      '- Outerwear should only add interest, never hide the hero piece. DO NOT create alternative versions of uploaded items. Most looks should feature tops or dresses without heavy layering so the garment is fully visible.',
    );
    buffer.writeln();

    buffer.writeln('✨ Variety guidance:');
    buffer.writeln('- Ensure full-body mannequin view from head to toe');
    buffer.writeln(
      '- Professional fashion photography quality with studio lighting.For unuploaded categories, generate stylish matching pieces. Ensure a full-body mannequin view with polished fashion photography vibes.',
    );
    buffer.writeln();

    // Gender requirement
    final genderInstruction = gender.toLowerCase() == 'female'
        ? 'Female curvaceous/semi curvy mannequin with feminine styling and fit'
        : 'Male mannequin with masculine styling and fit';
    buffer.writeln('Gender: $genderInstruction');
    buffer.writeln();

    if (desiredStyle != null && desiredStyle.isNotEmpty) {
      buffer.writeln('Style direction: $desiredStyle');
      buffer.writeln();
    }

    if (userNotes != null && userNotes.isNotEmpty) {
      buffer.writeln('User preferences: $userNotes');
      buffer.writeln();
    }

    if (pairingNotes != null && pairingNotes.isNotEmpty) {
      buffer.writeln('Styling notes: $pairingNotes');
      buffer.writeln();
    }

    buffer.writeln('Create a professional full-body mannequin image showing:');
    buffer.writeln('- The exact uploaded items as the core of the outfit');
    buffer.writeln(
      '- AI-generated complementary pieces for unuploaded categories',
    );
    buffer.writeln('- Complete outfit from head to toe with visible footwear');
    buffer.writeln('- Professional fashion photography quality');
    buffer.writeln('- Studio lighting and clean background');

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
              'inlineData': {
                'mimeType': _getMimeType(imageFile),
                'data': base64Image,
              },
            },
          ],
        },
      ],
    };

    print('🚀 [Gemini] Calling image preview endpoint: $_imageEndpoint');

    // Log prompt for debugging
    if (prompt.length > 100) {
      print('📝 [Gemini] Prompt start: ${prompt.substring(0, 100)}...');
    }

    final response = await _makeRequestWithRetry(_imageEndpoint, requestBody);

    AppLogger.network(_imageEndpoint, 'POST', statusCode: response.statusCode);

    if (response.statusCode != 200) {
      print('❌ [Gemini] Image Generation Error Body: ${response.body}');
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
    // Step 1: Categorize ALL uploaded items
    final categoryMap = {
      'tops': items
          .where((item) => item.itemType.toLowerCase().contains('top'))
          .toList(),
      'bottoms': items
          .where((item) => item.itemType.toLowerCase().contains('bottom'))
          .toList(),
      'dresses': items
          .where((item) => item.itemType.toLowerCase().contains('dress'))
          .toList(),
      'footwears': items
          .where(
            (item) =>
                item.itemType.toLowerCase().contains('shoe') ||
                item.itemType.toLowerCase().contains('footwear'),
          )
          .toList(),
      'outerwear': items
          .where((item) => item.itemType.toLowerCase().contains('outer'))
          .toList(),
      'accessories': items
          .where((item) => item.itemType.toLowerCase().contains('accessory'))
          .toList(),
    };

    // Step 2: Identify uploaded vs unuploaded categories
    final uploadedCategories = categoryMap.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();

    AppLogger.info(
      '📋 Categorized uploaded items',
      data: {
        'tops': categoryMap['tops']!.length,
        'bottoms': categoryMap['bottoms']!.length,
        'dresses': categoryMap['dresses']!.length,
        'footwears': categoryMap['footwears']!.length,
        'outerwear': categoryMap['outerwear']!.length,
        'accessories': categoryMap['accessories']!.length,
      },
    );

    // Step 3: Generate exhaustive combinations
    final combinations = _generateExhaustiveCombinations(
      categoryMap,
      uploadedCategories,
    );

    // Step 4: Balance distribution to ensure all items appear
    final balancedCombinations = _balanceDistribution(
      combinations,
      categoryMap,
    );

    // Step 5: Limit to 6 outfits
    return balancedCombinations.take(6).toList();
  }

  static List<_OutfitCombination> _generateExhaustiveCombinations(
    Map<String, List<ClothingAnalysis>> categoryMap,
    List<String> uploadedCategories,
  ) {
    final combinations = <_OutfitCombination>[];

    // Handle dress as special case (dress replaces top+bottom)
    if (categoryMap['dresses']!.isNotEmpty) {
      for (final dress in categoryMap['dresses']!) {
        // If shoes uploaded, pair with each shoe
        if (categoryMap['footwears']!.isNotEmpty) {
          for (final shoe in categoryMap['footwears']!) {
            combinations.add(
              _OutfitCombination(
                items: [dress, shoe],
                uploadedItems: [dress, shoe],
                unuploadedCategories: const ['outerwear', 'accessories'],
                metadata: {
                  'styleLabel': 'elegant evening',
                  'description':
                      '${dress.primaryColor} dress with ${shoe.primaryColor} ${shoe.itemType}',
                },
              ),
            );
          }
        } else {
          // No shoes uploaded, let AI generate
          combinations.add(
            _OutfitCombination(
              items: [dress],
              uploadedItems: [dress],
              unuploadedCategories: const [
                'footwears',
                'outerwear',
                'accessories',
              ],
              metadata: {
                'styleLabel': 'dress ensemble',
                'description': '${dress.primaryColor} dress styling',
              },
            ),
          );
        }
      }
    }
    // Handle top + bottom combinations
    else {
      final tops = categoryMap['tops']!;
      final bottoms = categoryMap['bottoms']!;
      final shoes = categoryMap['footwears']!;

      // Generate all top+bottom pairs
      if (tops.isNotEmpty && bottoms.isNotEmpty) {
        for (final top in tops) {
          for (final bottom in bottoms) {
            // If shoes uploaded, add each shoe variation
            if (shoes.isNotEmpty) {
              for (final shoe in shoes) {
                combinations.add(
                  _OutfitCombination(
                    items: [top, bottom, shoe],
                    uploadedItems: [top, bottom, shoe],
                    unuploadedCategories: const ['outerwear', 'accessories'],
                    metadata: {
                      'styleLabel': 'complete look',
                      'description':
                          '${top.primaryColor} ${top.itemType} with ${bottom.primaryColor} ${bottom.itemType}',
                    },
                  ),
                );
              }
            } else {
              // No shoes uploaded, let AI generate
              combinations.add(
                _OutfitCombination(
                  items: [top, bottom],
                  uploadedItems: [top, bottom],
                  unuploadedCategories: const [
                    'footwears',
                    'outerwear',
                    'accessories',
                  ],
                  metadata: {
                    'styleLabel': 'styled pairing',
                    'description':
                        '${top.primaryColor} ${top.itemType} paired with ${bottom.primaryColor} ${bottom.itemType}',
                  },
                ),
              );
            }
          }
        }
      }
      // Only tops uploaded (no bottoms)
      else if (tops.isNotEmpty && bottoms.isEmpty) {
        for (final top in tops) {
          // If shoes uploaded, pair each top with each shoe
          if (shoes.isNotEmpty) {
            for (final shoe in shoes) {
              combinations.add(
                _OutfitCombination(
                  items: [top, shoe],
                  uploadedItems: [top, shoe],
                  unuploadedCategories: const [
                    'bottoms',
                    'footwears',
                    'outerwear',
                    'accessories',
                  ],
                  metadata: {
                    'styleLabel': 'top + shoe pairing',
                    'description':
                        '${top.primaryColor} ${top.itemType} with ${shoe.primaryColor} ${shoe.itemType}',
                  },
                ),
              );
            }
          } else {
            combinations.add(
              _OutfitCombination(
                items: [top],
                uploadedItems: [top],
                unuploadedCategories: const [
                  'bottoms',
                  'footwears',
                  'outerwear',
                  'accessories',
                ],
                metadata: {
                  'styleLabel': 'top styling',
                  'description':
                      'Outfit featuring ${top.primaryColor} ${top.itemType}',
                },
              ),
            );
          }
        }
      }
      // Only bottoms uploaded (no tops)
      else if (bottoms.isNotEmpty && tops.isEmpty) {
        for (final bottom in bottoms) {
          if (shoes.isNotEmpty) {
            for (final shoe in shoes) {
              combinations.add(
                _OutfitCombination(
                  items: [bottom, shoe],
                  uploadedItems: [bottom, shoe],
                  unuploadedCategories: const [
                    'tops',
                    'footwears',
                    'outerwear',
                    'accessories',
                  ],
                  metadata: {
                    'styleLabel': 'bottom + shoe pairing',
                    'description':
                        '${bottom.primaryColor} ${bottom.itemType} with ${shoe.primaryColor} ${shoe.itemType}',
                  },
                ),
              );
            }
          } else {
            combinations.add(
              _OutfitCombination(
                items: [bottom],
                uploadedItems: [bottom],
                unuploadedCategories: const [
                  'tops',
                  'footwears',
                  'outerwear',
                  'accessories',
                ],
                metadata: {
                  'styleLabel': 'bottom styling',
                  'description':
                      'Outfit featuring ${bottom.primaryColor} ${bottom.itemType}',
                },
              ),
            );
          }
        }
      }
      // Only shoes uploaded
      else if (shoes.isNotEmpty && tops.isEmpty && bottoms.isEmpty) {
        for (final shoe in shoes) {
          combinations.add(
            _OutfitCombination(
              items: [shoe],
              uploadedItems: [shoe],
              unuploadedCategories: const [
                'tops',
                'bottoms',
                'footwears',
                'outerwear',
                'accessories',
              ],
              metadata: {
                'styleLabel': 'shoe spotlight',
                'description':
                    'Complete look featuring ${shoe.primaryColor} ${shoe.itemType}',
              },
            ),
          );
        }
      }
    }

    AppLogger.info(
      '🔄 Generated ${combinations.length} exhaustive combinations',
    );

    return combinations;
  }

  static List<_OutfitCombination> _balanceDistribution(
    List<_OutfitCombination> combinations,
    Map<String, List<ClothingAnalysis>> categoryMap,
  ) {
    if (combinations.length >= 6) {
      // Ensure each uploaded item appears at least once
      final itemAppearances = <String, int>{};
      final selectedCombinations = <_OutfitCombination>[];

      // First pass: ensure each item appears at least once
      for (final category in categoryMap.entries) {
        if (category.value.isEmpty) continue;

        for (final item in category.value) {
          final itemId =
              '${item.itemType}_${item.primaryColor}_${item.subcategory}';
          if (itemAppearances[itemId] == null ||
              itemAppearances[itemId]! == 0) {
            // Find a combination that uses this item
            final combo = combinations.firstWhere(
              (c) => c.uploadedItems.contains(item),
              orElse: () => combinations.first,
            );
            selectedCombinations.add(combo);

            // Mark all items in this combo as used
            for (final usedItem in combo.uploadedItems) {
              final usedId =
                  '${usedItem.itemType}_${usedItem.primaryColor}_${usedItem.subcategory}';
              itemAppearances[usedId] = (itemAppearances[usedId] ?? 0) + 1;
            }
          }
        }
      }

      // Second pass: fill remaining slots with best combinations
      while (selectedCombinations.length < 6 && combinations.isNotEmpty) {
        // Pick combinations with least-used items
        final scoredCombos = combinations.map((combo) {
          var score = 0;
          for (final item in combo.uploadedItems) {
            final itemId =
                '${item.itemType}_${item.primaryColor}_${item.subcategory}';
            score += itemAppearances[itemId] ?? 0;
          }
          return {'combo': combo, 'score': score};
        }).toList();

        // Sort by score (lower score = less used items = pick this)
        scoredCombos.sort(
          (a, b) => (a['score'] as int).compareTo(b['score'] as int),
        );

        final bestCombo = scoredCombos.first['combo'] as _OutfitCombination;
        selectedCombinations.add(bestCombo);

        // Update appearances
        for (final item in bestCombo.uploadedItems) {
          final itemId =
              '${item.itemType}_${item.primaryColor}_${item.subcategory}';
          itemAppearances[itemId] = (itemAppearances[itemId] ?? 0) + 1;
        }
      }

      AppLogger.info('⚖️ Balanced distribution', data: itemAppearances);

      return selectedCombinations;
    } else {
      // Less than 6 combinations, repeat to reach 6
      final repeated = <_OutfitCombination>[];
      for (int i = 0; i < 6; i++) {
        repeated.add(combinations[i % combinations.length]);
      }

      AppLogger.info(
        '🔁 Repeated ${combinations.length} combinations to reach 6',
      );

      return repeated;
    }
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

      final prompt =
          '''
ANALYZE THIS CLOTHING ITEM AND CREATE A DETAILED DESCRIPTION FOR MANNEQUIN IMAGE GENERATION

Uploaded Item Details:
- Type: $itemType
- Color: $color
- Pose: $poseDescription

TASK: Create an extremely detailed description that can be used to generate a professional mannequin image wearing this exact item with a complete outfit.

Return a JSON object with:
{
  "mannequinType": "male/female/unisex professional full-body view mannequin",
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
                  "mimeType": _getMimeType(imageFile),
                  "data": base64Image,
                },
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

      AppLogger.network(_endpoint, 'POST', body: requestBody);

      final response = await _makeRequestWithRetry(_endpoint, requestBody);

      AppLogger.network(_endpoint, 'POST', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            '';
        AppLogger.debug(
          '📥 Mannequin description response received',
          data: {
            'response_length': text.length,
            'response_preview': text.length > 200
                ? text.substring(0, 200) + '...'
                : text,
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
              final jsonString = text
                  .substring(codeBlockStart + 7, codeBlockEnd)
                  .trim();
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
      final simplePrompt =
          '''
Create a professional full body view fashion mannequin wearing a complete outfit featuring the uploaded clothing item. 
Style: $poseDescription
The mannequin should be photorealistic and have a full body view, well-lit, against a clean background.
The mannequin should be a professional full body view mannequin.
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
                "inlineData": {
                  "mimeType": _getMimeType(imageFile),
                  "data": base64Image,
                },
              },
            ],
          },
        ],
      };

      final startTime = DateTime.now();
      final response = await _makeRequestWithRetry(_imageEndpoint, requestBody);

      final duration = DateTime.now().difference(startTime);

      AppLogger.performance(
        'Simple mannequin image generation API call',
        duration,
        result: response.statusCode,
      );
      AppLogger.network(
        _imageEndpoint,
        'POST',
        statusCode: response.statusCode,
      );

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
  const _OutfitCombination({
    required this.items,
    required this.uploadedItems,
    required this.unuploadedCategories,
    required this.metadata,
  });

  final List<ClothingAnalysis> items;
  final List<ClothingAnalysis> uploadedItems;
  final List<String> unuploadedCategories;
  final Map<String, Object?> metadata;
}

class OutfitSuggestion {
  const OutfitSuggestion({
    required this.id,
    required this.items,
    required this.matchScore,
    required this.style,
    required this.occasion,
    required this.description,
  });

  final String id;
  final List<ClothingAnalysis> items;
  final double matchScore;
  final String style;
  final String occasion;
  final String description;
}
