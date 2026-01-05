import 'dart:developer' as developer;

// import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {dynamic data}) {
    developer.log('🐛 $message', name: 'DEBUG', error: data?.toString());
    AppLogger.info('🐛 $message');
  }

  static void info(String message, {dynamic data}) {
    developer.log('ℹ️ $message', name: 'INFO', error: data?.toString());
    AppLogger.info('ℹ️ $message');
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '⚠️ $message',
      name: 'WARNING',
      error: error,
      stackTrace: stackTrace,
    );
    AppLogger.info('⚠️ $message');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      '❌ $message',
      name: 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
    AppLogger.info('❌ $message');
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
    AppLogger.info('🌐 API: $endpoint');
    if (request != null) AppLogger.info('📤 Request: $request');
    if (response != null) AppLogger.info('📥 Response: $response');
  }

  static void network(
    String url,
    String method, {
    int? statusCode,
    dynamic body,
  }) {
    developer.log('🌍 $method $url', name: 'NETWORK');
    AppLogger.info('🌍 $method $url');
    if (statusCode != null) AppLogger.info('📊 Status: $statusCode');
    if (body != null) AppLogger.info('📦 Body: $body');
  }

  static void ui(String screen, String action, {dynamic data}) {
    developer.log('📱 $screen: $action', name: 'UI');
    AppLogger.info('📱 $screen: $action');
    if (data != null) AppLogger.info('📋 Data: $data');
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
    AppLogger.info('⚡ $operation: ${duration.inMilliseconds}ms');
    if (result != null) AppLogger.info('🎯 Result: $result');
  }
}
