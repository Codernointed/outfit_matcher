import 'package:flutter/material.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:vestiq/core/subscriptions/subscription_api_client.dart';
import 'package:vestiq/core/subscriptions/subscription_config.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service responsible for orchestrating Paystack SDK interactions.
class PaystackPaymentService {
  PaystackPaymentService({required SubscriptionConfig config})
      : _config = config;

  final SubscriptionConfig _config;

  bool get isConfigured => _config.paystack.isConfigured;

  /// Launches the Paystack checkout UI for the provided initialization payload.
  /// Returns true if payment was successful, false otherwise.
  Future<PaystackCheckoutResult> checkout({
    required BuildContext context,
    required SubscriptionInitializationResult initialization,
    required String email,
  }) async {
    if (!isConfigured) {
      throw StateError('Paystack configuration missing');
    }

    if (!initialization.isValid) {
      throw StateError('Invalid Paystack initialization payload');
    }

    AppLogger.info(
      '💰 Starting Paystack checkout',
      data: {
        'reference': initialization.reference,
        'tier': initialization.tier.name,
        'amount': initialization.amount,
      },
    );

    bool paymentSuccessful = false;
    String? transactionReference;
    String? errorMessage;

    await PayWithPayStack().now(
      context: context,
      secretKey: _config.paystack.secretKey ?? '',
      customerEmail: email,
      reference: initialization.reference,
      currency: initialization.currency,
      amount: initialization.amount.toDouble(),
      callbackUrl: "https://vestiq.com/payment-callback",
      paymentChannel: const ["card", "bank", "ussd", "mobile_money"],
      transactionCompleted: (response) {
        AppLogger.info('✅ Payment completed', data: response.toJson());
        paymentSuccessful = true;
        transactionReference = response.reference;
      },
      transactionNotCompleted: (reason) {
        AppLogger.warning('❌ Payment not completed: $reason');
        paymentSuccessful = false;
        errorMessage = reason;
      },
    );

    return PaystackCheckoutResult(
      success: paymentSuccessful,
      reference: transactionReference ?? initialization.reference,
      message: errorMessage,
    );
  }
}

/// Result of a Paystack checkout operation.
class PaystackCheckoutResult {
  const PaystackCheckoutResult({
    required this.success,
    required this.reference,
    this.message,
  });

  final bool success;
  final String reference;
  final String? message;
}

