import 'dart:async';
import 'dart:io';

import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/groq_api_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/utils/openrouter_image_service.dart';

/// Central orchestrator that races multiple AI providers in parallel and
/// returns the first successful (non-null) result.
///
/// Design goals (from the product spec):
/// - SILENT to the user: no provider names surfaced, no extra UI states
/// - PARALLEL: all providers fire at once — never sequential queues
/// - RESILIENT: if any single provider fails (billing, rate limit, outage)
///   the user still gets a result from one of the others
/// - GEMINI-LEANING: Gemini gets a tiny head start so when it succeeds it
///   tends to win the race (it's the highest-quality model when available),
///   but if it's slow or fails, the fallback ships immediately
class AiOrchestrator {
  /// How long to wait for Gemini before accepting a fallback result.
  /// Keeps the "Gemini leads when it returns" guarantee without bottlenecking
  /// the user when Gemini is failing/slow.
  static const Duration _geminiHeadStart = Duration(milliseconds: 700);

  /// Hard ceiling on a single race so a stalled provider can't hang the UI.
  static const Duration _raceTimeout = Duration(seconds: 60);

  // ─────────────────────────────────────────────────────────────────────
  // CLOTHING ANALYSIS
  // ─────────────────────────────────────────────────────────────────────

  /// Race Gemini and Groq for clothing analysis. Both return the same JSON
  /// schema, so the caller doesn't need to know which provider answered.
  static Future<Map<String, dynamic>?> analyzeClothing(File imageFile) async {
    AppLogger.info('🎯 [Orchestrator] Racing analysis providers');
    final startTime = DateTime.now();

    final gemini = GeminiApiService.analyzeClothingRaw(imageFile);
    final groq = GroqApiService.analyzeClothing(imageFile);

    final result = await _raceWithPreference<Map<String, dynamic>>(
      preferred: gemini,
      preferredLabel: 'gemini',
      fallbacks: {'groq': groq},
    );

    final duration = DateTime.now().difference(startTime);
    AppLogger.performance(
      'Orchestrator analysis race',
      duration,
      result: result == null ? 'all_failed' : 'success',
    );
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────
  // MANNEQUIN / OUTFIT IMAGE GENERATION
  // ─────────────────────────────────────────────────────────────────────

  /// Race Gemini and OpenRouter for outfit/mannequin image generation.
  /// Returns raw base64 PNG (no data URL prefix), or null if all failed.
  static Future<String?> generateMannequinImage({
    required String prompt,
    required File referenceImage,
  }) async {
    AppLogger.info('🎯 [Orchestrator] Racing image-gen providers');
    final startTime = DateTime.now();

    final gemini = GeminiApiService.generateImageRaw(
      prompt: prompt,
      referenceImage: referenceImage,
    );
    final openrouter = OpenRouterImageService.generateImage(
      prompt: prompt,
      referenceImage: referenceImage,
    );

    final result = await _raceWithPreference<String>(
      preferred: gemini,
      preferredLabel: 'gemini',
      fallbacks: {'openrouter': openrouter},
    );

    final duration = DateTime.now().difference(startTime);
    AppLogger.performance(
      'Orchestrator image-gen race',
      duration,
      result: result == null ? 'all_failed' : 'success',
    );
    return result;
  }

  /// Polish a wardrobe image (clean background, fix lighting, etc.).
  /// Same race semantics as [generateMannequinImage].
  static Future<String?> polishImage({
    required File imageFile,
    required String itemType,
    required String color,
  }) async {
    AppLogger.info('🎯 [Orchestrator] Racing polish providers');
    final startTime = DateTime.now();

    final prompt = _buildPolishPrompt(itemType: itemType, color: color);

    final gemini = GeminiApiService.generateImageRaw(
      prompt: prompt,
      referenceImage: imageFile,
    );
    final openrouter = OpenRouterImageService.generateImage(
      prompt: prompt,
      referenceImage: imageFile,
    );

    final result = await _raceWithPreference<String>(
      preferred: gemini,
      preferredLabel: 'gemini',
      fallbacks: {'openrouter': openrouter},
    );

    final duration = DateTime.now().difference(startTime);
    AppLogger.performance(
      'Orchestrator polish race',
      duration,
      result: result == null ? 'all_failed' : 'success',
    );
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────
  // INTERNALS
  // ─────────────────────────────────────────────────────────────────────

  /// Race a "preferred" future against fallback futures.
  /// - If preferred completes first with a non-null value → use it.
  /// - If a fallback completes first, wait up to [_geminiHeadStart] in case
  ///   the preferred provider returns shortly after; otherwise ship fallback.
  /// - If preferred completes with null/error, fallback wins as soon as it
  ///   completes (no extra wait).
  static Future<T?> _raceWithPreference<T>({
    required Future<T?> preferred,
    required String preferredLabel,
    required Map<String, Future<T?>> fallbacks,
  }) async {
    final completer = Completer<T?>();

    bool preferredDone = false;
    T? preferredResult;
    final fallbackResults = <String, T?>{};
    int remaining = 1 + fallbacks.length;

    void tryComplete() {
      if (completer.isCompleted) return;

      // 1. Preferred provider succeeded → ship it immediately.
      if (preferredDone && preferredResult != null) {
        AppLogger.info(
          '🏆 [Orchestrator] $preferredLabel won the race',
        );
        completer.complete(preferredResult);
        return;
      }

      // 2. Preferred is done but null → as soon as ANY fallback has a value
      //    we can ship it. If all done with nulls, ship null.
      if (preferredDone && preferredResult == null) {
        for (final entry in fallbackResults.entries) {
          if (entry.value != null) {
            AppLogger.info(
              '🏆 [Orchestrator] ${entry.key} won (preferred returned null)',
            );
            completer.complete(entry.value);
            return;
          }
        }
        if (remaining == 0) {
          AppLogger.warning(
            '💀 [Orchestrator] All providers returned null',
          );
          completer.complete(null);
        }
        return;
      }

      // 3. Preferred not yet done. If a fallback has a value AND we've
      //    given preferred its head start grace period, ship fallback.
      //    The grace period is enforced by a delayed re-check below.
    }

    // Wire up preferred provider.
    preferred
        .then((value) {
          preferredDone = true;
          preferredResult = value;
          remaining--;
          tryComplete();
        })
        .catchError((e, st) {
          AppLogger.warning(
            '⚠️ [Orchestrator] $preferredLabel threw: $e',
          );
          preferredDone = true;
          preferredResult = null;
          remaining--;
          tryComplete();
        });

    // Wire up fallback providers, with grace-period handling.
    for (final entry in fallbacks.entries) {
      final label = entry.key;
      entry.value
          .then((value) {
            fallbackResults[label] = value;
            remaining--;

            // If preferred is already done, just resolve via tryComplete.
            if (preferredDone) {
              tryComplete();
              return;
            }

            // If fallback got a value but preferred isn't done yet, give
            // preferred a brief head start before shipping.
            if (value != null) {
              Timer(_geminiHeadStart, () {
                if (completer.isCompleted) return;
                if (preferredDone && preferredResult != null) {
                  AppLogger.info(
                    '🏆 [Orchestrator] $preferredLabel caught up and won',
                  );
                  completer.complete(preferredResult);
                } else {
                  AppLogger.info(
                    '🏆 [Orchestrator] $label won after head-start grace',
                  );
                  completer.complete(value);
                }
              });
            } else if (remaining == 0) {
              tryComplete();
            }
          })
          .catchError((e, st) {
            AppLogger.warning('⚠️ [Orchestrator] $label threw: $e');
            fallbackResults[label] = null;
            remaining--;
            tryComplete();
          });
    }

    return completer.future.timeout(
      _raceTimeout,
      onTimeout: () {
        AppLogger.warning('⏱️ [Orchestrator] Race timed out');
        return null;
      },
    );
  }

  static String _buildPolishPrompt({
    required String itemType,
    required String color,
  }) {
    return '''
Create a premium, polished version of this clothing item for a luxury wardrobe app.

Requirements:
- Clean, professional studio lighting
- Remove any background distractions or clutter
- Enhance colors to be vibrant but natural
- Smooth out wrinkles and imperfections
- Position item attractively (flat lay or hanging)
- Maintain the authentic look and details of the item
- Ensure high contrast and clarity

Item details:
- Type: $itemType
- Color: $color

Generate a clean, magazine-quality image suitable for a premium fashion app.
''';
  }
}
