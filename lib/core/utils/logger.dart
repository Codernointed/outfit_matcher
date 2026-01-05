import 'dart:developer' as developer;

// import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {dynamic data}) {
    developer.log('🐛 $message', name: 'DEBUG', error: data?.toString());
  }

  static void info(String message, {dynamic data}) {
    developer.log('ℹ️ $message', name: 'INFO', error: data?.toString());
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '⚠️ $message',
      name: 'WARNING',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '❌ $message',
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
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
  }

  static void network(
    String url,
    String method, {
    int? statusCode,
    dynamic body,
  }) {
    developer.log('🌍 $method $url', name: 'NETWORK');
  }

  static void ui(String screen, String action, {dynamic data}) {
    developer.log('📱 $screen: $action', name: 'UI');
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
  }
}
