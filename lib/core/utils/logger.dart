import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static bool verboseConsole = true;

  static void _alsoPrint(String prefix, String message, Object? payload) {
    if (!verboseConsole) return;
    if (payload == null) {
      debugPrint('$prefix $message');
    } else {
      debugPrint('$prefix $message | $payload');
    }
  }

  static void debug(String message, {dynamic data}) {
    developer.log('🐛 $message', name: 'DEBUG', error: data?.toString());
    _alsoPrint('[DEBUG]', message, data);
  }

  static void info(String message, {dynamic data}) {
    developer.log('ℹ️ $message', name: 'INFO', error: data?.toString());
    _alsoPrint('[INFO]', message, data);
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '⚠️ $message',
      name: 'WARNING',
      error: error,
      stackTrace: stackTrace,
    );
    _alsoPrint('[WARN]', message, error);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '❌ $message',
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
    _alsoPrint('[ERROR]', message, error);
  }

  static void api(
    String endpoint, {
    Map<String, dynamic>? request,
    dynamic response,
  }) {
    developer.log(
      '🌐 $endpoint',
      name: 'API',
      error: {'request': request, 'response': response},
    );
    _alsoPrint('[API]', endpoint, {'request': request, 'response': response});
  }

  static void network(
    String url,
    String method, {
    int? statusCode,
    dynamic body,
  }) {
    developer.log('🌍 $method $url', name: 'NETWORK');
    _alsoPrint(
      '[NET]',
      '$method $url',
      statusCode == null ? null : {'status': statusCode},
    );
  }

  static void ui(String screen, String action, {dynamic data}) {
    developer.log('📱 $screen: $action', name: 'UI');
    _alsoPrint('[UI]', '$screen:$action', data);
  }

  static void performance(
    String operation,
    Duration duration, {
    dynamic result,
  }) {
    developer.log(
      '⚡ $operation completed in ${duration.inMilliseconds}ms',
      name: 'PERFORMANCE',
    );
    _alsoPrint(
      '[PERF]',
      '$operation ${duration.inMilliseconds}ms',
      result,
    );
  }
}
