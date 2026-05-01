import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vestiq/core/utils/logger.dart';

/// Groq Cloud client for fast multimodal vision analysis.
///
/// Uses the OpenAI-compatible Chat Completions endpoint with Llama 4 Scout
/// (a multimodal model with vision capabilities). Returns the same JSON
/// schema as Gemini so the orchestrator can race them and pick the first
/// successful response without provider-specific post-processing.
class GroqApiService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static String? _getApiKey() {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      AppLogger.warning('⚠️ [Groq] GROQ_API_KEY not set in .env');
      return null;
    }
    return key;
  }

  static String _getMimeType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// The exact same prompt sent to Gemini, asking for the same JSON schema
  /// so consumers don't need to know which provider answered.
  static const String _analysisPrompt =
      "You are an expert fashion analyst. Analyze this clothing item with EXTREME PRECISION for PERFECT OUTFIT PAIRING.\n\nCRITICAL RULES:\n1. FOOTWEAR DETECTION: If you see ANY shoes, sneakers, boots, sandals, heels, flats, mules, loafers, oxfords, pumps, stilettos, wedges, ankle boots, knee-high boots, combat boots, hiking boots, running shoes, athletic shoes, dress shoes, casual shoes, slippers, flip-flops, crocs, clogs, ballet flats, espadrilles, platform shoes, high heels, low heels, block heels, stiletto heels, kitten heels, chunky heels, wedges, peep-toe shoes, closed-toe shoes, open-toe shoes, lace-up shoes, slip-on shoes, buckle shoes, zipper shoes, velcro shoes, lace shoes, slip-ons, moccasins, boat shoes, driving shoes, work boots, rain boots, snow boots, winter boots, summer shoes, spring shoes, fall shoes, seasonal footwear - ALWAYS classify as 'Footwear' NOT 'Top'\n2. JEANS ANALYSIS: Look carefully at fit - distinguish between 'skinny jeans', 'baggy jeans', 'relaxed fit jeans', 'straight leg jeans'\n3. LOOK CAREFULLY at the actual colors in the image - don't default to common colors\n4. If you see GREEN fabric, say GREEN not blue\n5. If you see formal elements (lapels, structured shoulders, dress pants), classify as business/formal\n6. If you see suits, blazers, dress shirts, classify as 'business formal' or 'formal wear'\n\nReturn ONLY a JSON object with these exact keys:\n{\n  \"itemType\": \"Top|Bottom|Dress|Outerwear|Footwear|Accessory\",\n  \"primaryColor\": \"EXACT color you see (green, navy blue, charcoal gray, burgundy, etc.)\",\n  \"secondaryColors\": [\"array of other colors if any\"],\n  \"patternType\": \"solid|pinstripe|checkered|herringbone|floral|geometric\",\n  \"material\": \"wool|cotton|silk|linen|polyester|leather|denim\",\n  \"fit\": \"slim fit|regular fit|relaxed fit|tailored fit|oversized|baggy|skinny\",\n  \"style\": \"business formal|smart casual|casual|formal wear|streetwear\",\n  \"formality\": \"formal|business|smart casual|casual\",\n  \"subcategory\": \"specific type like 'baggy jeans', 'white sneakers', 'black ankle boots', 'nude heels', 'brown loafers', 'oxford shirt'\",\n  \"confidence\": 0.95,\n  \"colorUndertone\": \"warm|cool|neutral\",\n  \"complementaryColors\": [\"specific colors that pair perfectly with this item\"],\n  \"colorTemperature\": \"warm|cool|neutral\",\n  \"designElements\": [\"embellishments\", \"hardware\", \"unique features\", \"prints\", \"textures\"],\n  \"visualWeight\": \"light|medium|heavy\",\n  \"detailLevel\": \"minimal|moderate|detailed\",\n  \"pairingHints\": [\"specific items that work well\"],\n  \"stylePersonality\": \"edgy|classic|romantic|minimalist|bohemian|sporty|preppy|streetwear|vintage|modern\"\n}\n\nReturn ONLY the JSON, no explanation.";

  /// Analyze a clothing item image. Returns the raw JSON map from the model
  /// (same shape Gemini returns), or null on failure / missing key.
  static Future<Map<String, dynamic>?> analyzeClothing(File imageFile) async {
    final apiKey = _getApiKey();
    if (apiKey == null) return null;

    AppLogger.info(
      '🦙 [Groq] Starting clothing analysis',
      data: {'file': imageFile.path, 'model': _model},
    );

    try {
      final bytes = await imageFile.readAsBytes();
      // Groq base64 limit is 4MB — guard against oversize requests.
      if (bytes.lengthInBytes > 4 * 1024 * 1024) {
        AppLogger.warning(
          '⚠️ [Groq] Image exceeds 4MB base64 limit, skipping',
          error: {'size_mb': bytes.lengthInBytes / (1024 * 1024)},
        );
        return null;
      }

      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:${_getMimeType(imageFile)};base64,$base64Image';

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': _analysisPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
          },
        ],
        'temperature': 0.4,
        'max_completion_tokens': 1500,
        'response_format': {'type': 'json_object'},
      };

      final startTime = DateTime.now();
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      final duration = DateTime.now().difference(startTime);
      AppLogger.performance(
        'Groq vision call',
        duration,
        result: response.statusCode,
      );

      if (response.statusCode != 200) {
        AppLogger.warning(
          '❌ [Groq] API error ${response.statusCode}',
          error: response.body,
        );
        return null;
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = responseData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        AppLogger.warning('❌ [Groq] No choices in response');
        return null;
      }

      final firstChoice =
          (choices.first is Map) ? (choices.first as Map).cast<String, dynamic>() : null;
      final message =
          (firstChoice?['message'] is Map)
              ? (firstChoice!['message'] as Map).cast<String, dynamic>()
              : null;

      final rawContent = message?['content'];
      final content = switch (rawContent) {
        String s => s,
        Map m => jsonEncode(m),
        List l => jsonEncode(l),
        _ => '',
      };

      if (content.trim().isEmpty) {
        AppLogger.warning('❌ [Groq] Empty content in response');
        return null;
      }

      // Response should already be JSON (response_format=json_object) but
      // keep the same defensive extraction Gemini uses.
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        AppLogger.warning(
          '❌ [Groq] Failed to find JSON in response',
          error: content,
        );
        return null;
      }

      final jsonString = content.substring(jsonStart, jsonEnd + 1);
      final result = jsonDecode(jsonString) as Map<String, dynamic>;

      AppLogger.info(
        '✅ [Groq] Clothing analysis complete',
        data: {
          'itemType': result['itemType'],
          'primaryColor': result['primaryColor'],
        },
      );
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ [Groq] Exception in analyzeClothing',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
