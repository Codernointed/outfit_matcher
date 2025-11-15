import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/models/user_profile.dart';

/// Strongly typed access to Paystack + backend subscription configuration.
class SubscriptionConfig {
  SubscriptionConfig({required this.paystack, required this.backend});

  /// Paystack client configuration (public information only).
  final PaystackConfig paystack;

  /// Backend endpoints used to initialize/verify subscriptions.
  final SubscriptionBackendEndpoints backend;

  /// Convenience accessor for tier usage policies.
  SubscriptionUsagePolicy usagePolicy(SubscriptionTier tier) =>
      tier.usagePolicy;

  /// Factory that reads values from environment variables.
  factory SubscriptionConfig.fromEnv(DotEnv env) {
    return SubscriptionConfig(
      paystack: PaystackConfig.fromEnv(env),
      backend: SubscriptionBackendEndpoints.fromEnv(env),
    );
  }
}

/// Configuration required to talk to Paystack from the Flutter client.
class PaystackConfig {
  PaystackConfig({
    required this.publicKey,
    this.secretKey,
    required this.premiumPlanCode,
    this.proPlanCode,
  });

  /// Publishable Paystack key (safe to bundle with the app).
  final String publicKey;

  /// Secret key (should remain empty on client builds; used for backend mirroring).
  final String? secretKey;

  /// Paystack plan code for Premium tier.
  final String premiumPlanCode;

  /// Paystack plan code for upcoming Pro tier.
  final String? proPlanCode;

  bool get isConfigured => publicKey.isNotEmpty && premiumPlanCode.isNotEmpty;

  factory PaystackConfig.fromEnv(DotEnv env) {
    String read(String key, {String fallback = ''}) {
      final value = env.env[key];
      if (value == null || value.isEmpty) return fallback;
      return value;
    }

    return PaystackConfig(
      publicKey: read(AppConstants.envPaystackPublicKey),
      secretKey: env.env[AppConstants.envPaystackSecretKey],
      premiumPlanCode: read(AppConstants.envPaystackPlanPremium),
      proPlanCode: env.env[AppConstants.envPaystackPlanPro],
    );
  }
}

/// Backend endpoints facilitating initialize/verify/webhook flows.
class SubscriptionBackendEndpoints {
  SubscriptionBackendEndpoints({
    required this.initializeUrl,
    required this.verifyUrl,
    required this.entitlementUrl,
  });

  final Uri? initializeUrl;
  final Uri? verifyUrl;
  final Uri? entitlementUrl;

  bool get hasRequiredEndpoints =>
      initializeUrl != null && verifyUrl != null && entitlementUrl != null;

  factory SubscriptionBackendEndpoints.fromEnv(DotEnv env) {
    Uri? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return Uri.tryParse(raw);
    }

    return SubscriptionBackendEndpoints(
      initializeUrl: parse(env.env[AppConstants.envSubscriptionInitializeUrl]),
      verifyUrl: parse(env.env[AppConstants.envSubscriptionVerifyUrl]),
      entitlementUrl: parse(
        env.env[AppConstants.envSubscriptionEntitlementUrl],
      ),
    );
  }
}
