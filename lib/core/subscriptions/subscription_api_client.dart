import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vestiq/core/models/user_profile.dart';
import 'package:vestiq/core/subscriptions/subscription_config.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Lightweight API client responsible for talking to the subscriptions backend.
class SubscriptionApiClient {
  SubscriptionApiClient({
    required http.Client httpClient,
    required SubscriptionConfig config,
  })  : _http = httpClient,
        _config = config;

  final http.Client _http;
  final SubscriptionConfig _config;

  /// Initializes a Paystack checkout session on the backend and returns
  /// the access code + reference that should be supplied to Paystack's SDK.
  Future<SubscriptionInitializationResult> initializeCheckout({
    required String userId,
    required String email,
    required SubscriptionTier tier,
  }) async {
    final url = _config.backend.initializeUrl;
    if (url == null) {
      throw const SubscriptionApiException('Missing initialize endpoint');
    }

    final payload = await _post(
      url,
      body: {
        'userId': userId,
        'email': email,
        'tier': tier.name,
      },
    );

    return SubscriptionInitializationResult.fromJson(payload);
  }

  /// Verifies the Paystack transaction using the backend and returns the
  /// authoritative user subscription snapshot.
  Future<UserSubscription> verifyCheckout({
    required String reference,
  }) async {
    final url = _config.backend.verifyUrl;
    if (url == null) {
      throw const SubscriptionApiException('Missing verify endpoint');
    }

    final payload = await _post(url, body: {'reference': reference});
    return _parseSubscriptionFromPayload(payload);
  }

  /// Fetches the latest entitlement snapshot (e.g., after cold start).
  Future<UserSubscription> fetchEntitlementSnapshot({
    required String userId,
  }) async {
    final url = _config.backend.entitlementUrl;
    if (url == null) {
      throw const SubscriptionApiException('Missing entitlement endpoint');
    }

    final payload = await _post(url, body: {'userId': userId});
    return _parseSubscriptionFromPayload(payload);
  }

  Future<Map<String, dynamic>> _post(
    Uri url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body ?? <String, dynamic>{}),
      );

      if (response.statusCode >= 400) {
        final errorBody = response.body;
        AppLogger.error(
          '❌ Subscription API error (${response.statusCode})',
          error: errorBody,
        );
        throw SubscriptionApiException(
          'Subscription API request failed (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        // Most backend responses wrap payloads in a `data` object.
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        return decoded;
      }

      throw const SubscriptionApiException('Unexpected API response type');
    } catch (error, stackTrace) {
      AppLogger.error(
        '❌ Subscription API request failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is SubscriptionApiException) rethrow;
      throw SubscriptionApiException(error.toString());
    }
  }

  UserSubscription _parseSubscriptionFromPayload(
    Map<String, dynamic> payload,
  ) {
    final snapshot = payload['subscription'];
    if (snapshot is Map<String, dynamic>) {
      return UserSubscription.fromJson(snapshot);
    }

    // Some endpoints may return the subscription fields at the root level.
    return UserSubscription.fromJson(payload);
  }
}

/// Response returned by the backend initialize endpoint.
class SubscriptionInitializationResult {
  SubscriptionInitializationResult({
    required this.reference,
    required this.accessCode,
    required this.amount,
    required this.currency,
    required this.tier,
    this.authorizationUrl,
  });

  final String reference;
  final String accessCode;
  final int amount; // Amount expected by Paystack (in the smallest currency unit)
  final String currency;
  final SubscriptionTier tier;
  final String? authorizationUrl;

  factory SubscriptionInitializationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    SubscriptionTier parseTier(String? value) {
      return SubscriptionTier.values.firstWhere(
        (tier) => tier.name == value,
        orElse: () => SubscriptionTier.premium,
      );
    }

    return SubscriptionInitializationResult(
      reference: json['reference'] as String? ?? json['ref'] as String? ?? '',
      accessCode: json['accessCode'] as String? ?? json['access_code'] as String? ?? '',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      currency: json['currency'] as String? ?? 'NGN',
      tier: parseTier(json['tier'] as String? ?? json['plan'] as String?),
      authorizationUrl: json['authorizationUrl'] as String? ??
          json['authorization_url'] as String?,
    );
  }

  bool get isValid => reference.isNotEmpty && accessCode.isNotEmpty && amount > 0;
}

class SubscriptionApiException implements Exception {
  const SubscriptionApiException(this.message);
  final String message;

  @override
  String toString() => 'SubscriptionApiException: $message';
}
