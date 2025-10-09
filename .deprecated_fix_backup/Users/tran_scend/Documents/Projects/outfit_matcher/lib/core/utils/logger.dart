import 'dart:developer' as developer;

class AppLogger {
  static void debug(String message, {dynamic data}) {
    developer.log('🐛 $message', name: 'DEBUG', error: data?.toString());
    print('🐛 $message');
  }

  static void info(String message, {dynamic data}) {
    developer.log('ℹ️ $message', name: 'INFO', error: data?.toString());
    print('ℹ️ $message');
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log('⚠️ $message', name: 'WARNING', error: error, stackTrace: stackTrace);
    print('⚠️ $message');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log('❌ $message', name: 'ERROR', error: error, stackTrace: stackTrace);
    print('❌ $message');
  }

  static void api(String endpoint, {Map<String, dynamic>? request, dynamic response}) {
    developer.log('🌐 $endpoint', name: 'API', error: {'request': request, 'response': response});
    print('🌐 API: $endpoint');
    if (request != null) print('📤 Request: $request');
    if (response != null) print('📥 Response: $response');
  }

  static void network(String url, String method, {int? statusCode, dynamic body}) {
    developer.log('🌍 $method $url', name: 'NETWORK');
    print('🌍 $method $url');
    if (statusCode != null) print('📊 Status: $statusCode');
    if (body != null) print('📦 Body: $body');
  }

  static void ui(String screen, String action, {dynamic data}) {
    developer.log('📱 $screen: $action', name: 'UI');
    print('📱 $screen: $action');
    if (data != null) print('📋 Data: $data');
  }

  static void performance(String operation, Duration duration, {dynamic result}) {
    developer.log('⚡ $operation completed in ${duration.inMilliseconds}ms', name: 'PERFORMANCE');
    print('⚡ $operation: ${duration.inMilliseconds}ms');
    if (result != null) print('🎯 Result: $result');
  }
}
