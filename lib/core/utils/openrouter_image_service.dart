import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vestiq/core/utils/logger.dart';

/// OpenRouter image generation client.
///
/// Uses the OpenAI-compatible Chat Completions endpoint to drive the
/// FLUX.2 / Riverflow / Seedream image models. Supports both text-to-image
/// and image-to-image (with a reference image) flows. Returns base64 image
/// data without the `data:image/...;base64,` prefix to match the rest of the
/// app's existing convention (see `_callImagePreview` in gemini service).
class OpenRouterImageService {
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Models tried in priority order. First non-null result wins.
  /// FLUX.2 Pro = best quality, Riverflow Fast = cheapest fast fallback,
  /// Seedream = $0.04 flat-rate budget option.
  static const List<String> _imageModels = [
    'black-forest-labs/flux.2-pro',
    'sourceful/riverflow-v2-fast',
    'bytedance-seed/seedream-4.5',
  ];

  static String? _getApiKey() {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      AppLogger.warning('⚠️ [OpenRouter] OPENROUTER_API_KEY not set in .env');
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

  /// Generate an image from a text prompt and optional reference image.
  /// Returns raw base64 PNG data (no `data:image/...` prefix), or null on
  /// failure. Tries each model in [_imageModels] until one succeeds.
  static Future<String?> generateImage({
    required String prompt,
    File? referenceImage,
  }) async {
    final apiKey = _getApiKey();
    if (apiKey == null) return null;

    AppLogger.info(
      '🌊 [OpenRouter] Starting image generation',
      data: {
        'has_reference': referenceImage != null,
        'prompt_length': prompt.length,
      },
    );

    for (final model in _imageModels) {
      try {
        final result = await _generateWithModel(
          apiKey: apiKey,
          model: model,
          prompt: prompt,
          referenceImage: referenceImage,
        );
        if (result != null) {
          AppLogger.info(
            '✅ [OpenRouter] Image generated successfully',
            data: {'model': model},
          );
          return result;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          '⚠️ [OpenRouter] Model $model failed, trying next',
          error: e,
        );
        AppLogger.debug('   stack: $stackTrace');
      }
    }

    AppLogger.warning('❌ [OpenRouter] All models failed');
    return null;
  }

  static Future<String?> _generateWithModel({
    required String apiKey,
    required String model,
    required String prompt,
    File? referenceImage,
  }) async {
    // Build user message content. If we have a reference image, send it as a
    // multimodal message so models that support image-to-image can use it.
    final List<Map<String, dynamic>> contentParts = [
      {'type': 'text', 'text': prompt},
    ];

    if (referenceImage != null && await referenceImage.exists()) {
      try {
        final bytes = await referenceImage.readAsBytes();
        // Sourceful imposes 4.5MB request size limit; skip ref if too big.
        if (bytes.lengthInBytes <= 4 * 1024 * 1024) {
          final base64Image = base64Encode(bytes);
          final mime = _getMimeType(referenceImage);
          contentParts.add({
            'type': 'image_url',
            'image_url': {'url': 'data:$mime;base64,$base64Image'},
          });
        } else {
          AppLogger.warning(
            '⚠️ [OpenRouter] Reference image too large, sending text-only',
            error: {'size_mb': bytes.lengthInBytes / (1024 * 1024)},
          );
        }
      } catch (e) {
        AppLogger.warning('⚠️ [OpenRouter] Failed to attach reference: $e');
      }
    }

    final requestBody = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'user', 'content': contentParts},
      ],
      'modalities': ['image'],
    };

    final startTime = DateTime.now();
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            // Optional but recommended by OpenRouter for analytics/billing
            'HTTP-Referer': 'https://vestiq.app',
            'X-Title': 'Vestiq',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 90));

    final duration = DateTime.now().difference(startTime);
    AppLogger.performance(
      'OpenRouter image gen ($model)',
      duration,
      result: response.statusCode,
    );

    if (response.statusCode != 200) {
      AppLogger.warning(
        '❌ [OpenRouter:$model] API error ${response.statusCode}',
        error: response.body,
      );
      return null;
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      AppLogger.warning('❌ [OpenRouter:$model] No choices in response');
      return null;
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    if (message == null) return null;

    // Per docs the assistant message has `images: [{image_url: {url: ...}}]`
    final images = message['images'] as List?;
    if (images != null && images.isNotEmpty) {
      for (final img in images) {
        final imgMap = (img is Map) ? img.cast<String, dynamic>() : null;
        if (imgMap == null) continue;

        final imageUrlFromImageUrl =
            (imgMap['image_url'] is Map)
                ? (imgMap['image_url'] as Map).cast<String, dynamic>()['url']
                        as String?
                : null;
        final imageUrlFromImageUrlAlt =
            (imgMap['imageUrl'] is Map)
                ? (imgMap['imageUrl'] as Map).cast<String, dynamic>()['url']
                        as String?
                : null;
        final imageUrlDirect = imgMap['url'] as String?;

        final imageUrl =
            imageUrlFromImageUrl ?? imageUrlFromImageUrlAlt ?? imageUrlDirect;
        if (imageUrl == null) continue;

        // OpenRouter typically returns a base64 data URL — strip the prefix
        // so the rest of the app gets just the base64 payload like Gemini.
        if (imageUrl.startsWith('data:')) {
          final commaIdx = imageUrl.indexOf(',');
          if (commaIdx != -1) {
            return imageUrl.substring(commaIdx + 1);
          }
        }

        // Fallback: if it's an http(s) URL, download and base64-encode.
        if (imageUrl.startsWith('http')) {
          try {
            final imgResp = await http
                .get(Uri.parse(imageUrl))
                .timeout(const Duration(seconds: 30));
            if (imgResp.statusCode == 200) {
              return base64Encode(imgResp.bodyBytes);
            }
          } catch (e) {
            AppLogger.warning('⚠️ [OpenRouter] Failed to fetch image URL: $e');
          }
        }
      }
    }

    AppLogger.warning('❌ [OpenRouter:$model] No image in response');
    return null;
  }
}
