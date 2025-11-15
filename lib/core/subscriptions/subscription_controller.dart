import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/user_profile.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/subscriptions/paystack_payment_service.dart';
import 'package:vestiq/core/subscriptions/subscription_api_client.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Describes the current checkout lifecycle stage.
enum SubscriptionFlowStep {
  idle,
  initializing,
  awaitingPayment,
  verifying,
  completed,
  error,
}

class SubscriptionCheckoutState {
  SubscriptionCheckoutState({
    required this.step,
    this.initialization,
    this.subscription,
    this.errorMessage,
    this.cancelledByUser = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final SubscriptionFlowStep step;
  final SubscriptionInitializationResult? initialization;
  final UserSubscription? subscription;
  final String? errorMessage;
  final bool cancelledByUser;
  final DateTime updatedAt;

  bool get isLoading =>
      step == SubscriptionFlowStep.initializing ||
      step == SubscriptionFlowStep.awaitingPayment ||
      step == SubscriptionFlowStep.verifying;

  bool get hasError => step == SubscriptionFlowStep.error;

  SubscriptionCheckoutState copyWith({
    SubscriptionFlowStep? step,
    SubscriptionInitializationResult? initialization,
    bool clearInitialization = false,
    UserSubscription? subscription,
    String? errorMessage,
    bool? cancelledByUser,
    bool clearError = false,
  }) {
    return SubscriptionCheckoutState(
      step: step ?? this.step,
      initialization: clearInitialization ? null : (initialization ?? this.initialization),
      subscription: subscription ?? this.subscription,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cancelledByUser: cancelledByUser ?? this.cancelledByUser,
      updatedAt: DateTime.now(),
    );
  }

  factory SubscriptionCheckoutState.initial() =>
    SubscriptionCheckoutState(step: SubscriptionFlowStep.idle);
}

class SubscriptionController extends StateNotifier<SubscriptionCheckoutState> {
  SubscriptionController({
    required SubscriptionApiClient apiClient,
    required PaystackPaymentService paymentService,
    required AppSettingsService settingsService,
  })  : _apiClient = apiClient,
        _paymentService = paymentService,
        _settingsService = settingsService,
        super(SubscriptionCheckoutState.initial());

  final SubscriptionApiClient _apiClient;
  final PaystackPaymentService _paymentService;
  final AppSettingsService _settingsService;

  Future<UserSubscription?> startCheckout({
    required BuildContext context,
    required String userId,
    required String email,
    required SubscriptionTier tier,
  }) async {
    try {
      state = state.copyWith(
        step: SubscriptionFlowStep.initializing,
        clearError: true,
        cancelledByUser: false,
      );

      final initResult = await _apiClient.initializeCheckout(
        userId: userId,
        email: email,
        tier: tier,
      );

      if (!initResult.isValid) {
        throw const SubscriptionApiException('Invalid checkout payload returned');
      }

      state = state.copyWith(
        step: SubscriptionFlowStep.awaitingPayment,
        initialization: initResult,
      );

      final result = await _paymentService.checkout(
        context: context,
        initialization: initResult,
        email: email,
      );

      if (!result.success) {
        state = state.copyWith(
          step: SubscriptionFlowStep.error,
          errorMessage: result.message ?? 'Payment cancelled',
          cancelledByUser: true,
        );
        return null;
      }

      state = state.copyWith(step: SubscriptionFlowStep.verifying);

      final verified = await _apiClient.verifyCheckout(reference: result.reference);
      await _persistSubscription(verified);

      state = state.copyWith(
        step: SubscriptionFlowStep.completed,
        subscription: verified,
        clearInitialization: true,
      );

      return verified;
    } catch (error, stackTrace) {
      AppLogger.error('❌ Subscription checkout failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        step: SubscriptionFlowStep.error,
        errorMessage: error.toString(),
        cancelledByUser: false,
      );
      return null;
    }
  }

  Future<UserSubscription?> refreshEntitlement({
    required String userId,
  }) async {
    try {
      final subscription = await _apiClient.fetchEntitlementSnapshot(userId: userId);
      await _persistSubscription(subscription);
      state = state.copyWith(subscription: subscription, clearError: true);
      return subscription;
    } catch (error, stackTrace) {
      AppLogger.error('❌ Entitlement refresh failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(
        step: SubscriptionFlowStep.error,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  Future<void> _persistSubscription(UserSubscription subscription) async {
    final previousTier = _settingsService.subscriptionSnapshot.tier;
    await _settingsService.saveSubscriptionSnapshot(subscription);
    if (previousTier != subscription.tier) {
      await _settingsService.clearUsageSnapshot();
    }
  }

  void resetFlow() {
    state = SubscriptionCheckoutState.initial();
  }
}

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionCheckoutState>(
  (ref) {
    return SubscriptionController(
      apiClient: getIt<SubscriptionApiClient>(),
      paymentService: getIt<PaystackPaymentService>(),
      settingsService: getIt<AppSettingsService>(),
    );
  },
);
