import 'package:vestiq/core/constants/app_constants.dart';

/// Defines all supported subscription tiers in the app.
enum SubscriptionTier {
  /// Forever-free tier with generous limits
  free,

  /// Premium, paid monthly/annually tier
  premium,

  /// Pro tier reserved for year-two rollout
  pro,
}

extension SubscriptionTierX on SubscriptionTier {
  /// Display label for UI surfaces.
  String get label {
    switch (this) {
      case SubscriptionTier.free:
        return AppConstants.subscriptionFreeLabel;
      case SubscriptionTier.premium:
        return AppConstants.subscriptionPremiumLabel;
      case SubscriptionTier.pro:
        return AppConstants.subscriptionProLabel;
    }
  }

  /// Whether this tier requires payment.
  bool get isPaid => this != SubscriptionTier.free;

  /// Usage policy describing resource caps for the tier.
  SubscriptionUsagePolicy get usagePolicy {
    switch (this) {
      case SubscriptionTier.free:
        return const SubscriptionUsagePolicy(
          dailyUploads: AppConstants.freeDailyUploadLimit,
          monthlyMannequins: AppConstants.freeMonthlyMannequinLimit,
          monthlyPairings: AppConstants.freeMonthlyPairingLimit,
          monthlyInspirationSearches: AppConstants.freeMonthlyInspirationLimit,
          monthlyImagePolish: 0,
        );
      case SubscriptionTier.premium:
        return const SubscriptionUsagePolicy(
          dailyUploads: AppConstants.premiumDailyUploadLimit,
          monthlyMannequins: AppConstants.premiumMonthlyMannequinLimit,
          monthlyPairings: SubscriptionUsagePolicy.unlimited,
          monthlyInspirationSearches: SubscriptionUsagePolicy.unlimited,
          monthlyImagePolish: AppConstants.premiumMonthlyPolishingLimit,
        );
      case SubscriptionTier.pro:
        return const SubscriptionUsagePolicy(
          dailyUploads: SubscriptionUsagePolicy.unlimited,
          monthlyMannequins: SubscriptionUsagePolicy.unlimited,
          monthlyPairings: SubscriptionUsagePolicy.unlimited,
          monthlyInspirationSearches: SubscriptionUsagePolicy.unlimited,
          monthlyImagePolish: SubscriptionUsagePolicy.unlimited,
        );
    }
  }
}

/// Possible subscription lifecycle states mapped from Paystack events.
enum SubscriptionStatus {
  /// No active subscription (default for new accounts)
  inactive,

  /// Active paid/trial subscription in good standing
  active,

  /// Active trial period before first billing cycle
  trialing,

  /// Grace period after failed renewal but before downgrade
  grace,

  /// Active but scheduled to end at current period
  nonRenewing,

  /// Payment attention required (e.g., invoice.failed)
  attention,

  /// Subscription cancelled by user/support
  cancelled,

  /// Subscription expired and user is back on free
  expired,
}

extension SubscriptionStatusX on SubscriptionStatus {
  /// User-facing explanation for the status.
  String get description {
    switch (this) {
      case SubscriptionStatus.inactive:
        return 'No active subscription';
      case SubscriptionStatus.active:
        return 'Subscription active';
      case SubscriptionStatus.trialing:
        return 'Trial in progress';
      case SubscriptionStatus.grace:
        return 'Payment issue, grace period active';
      case SubscriptionStatus.nonRenewing:
        return 'Will not renew at period end';
      case SubscriptionStatus.attention:
        return 'Payment method requires attention';
      case SubscriptionStatus.cancelled:
        return 'Subscription cancelled';
      case SubscriptionStatus.expired:
        return 'Subscription expired';
    }
  }
}

/// Canonical usage policy for a subscription tier.
class SubscriptionUsagePolicy {
  /// Sentinel representing unlimited quota.
  static const int unlimited = -1;

  /// Daily upload limit (-1 for unlimited)
  final int dailyUploads;

  /// Monthly mannequin generation limit (-1 for unlimited)
  final int monthlyMannequins;

  /// Monthly AI pairing limit (-1 for unlimited)
  final int monthlyPairings;

  /// Monthly inspiration search limit (-1 for unlimited)
  final int monthlyInspirationSearches;

  /// Monthly AI polishing limit (-1 for unlimited)
  final int monthlyImagePolish;

  const SubscriptionUsagePolicy({
    required this.dailyUploads,
    required this.monthlyMannequins,
    required this.monthlyPairings,
    required this.monthlyInspirationSearches,
    required this.monthlyImagePolish,
  });

  /// Convenience flag for unlimited uploads.
  bool get hasUnlimitedUploads => dailyUploads == unlimited;

  /// Convenience flag for unlimited mannequins.
  bool get hasUnlimitedMannequins => monthlyMannequins == unlimited;

  /// Convenience flag for unlimited pairings.
  bool get hasUnlimitedPairings => monthlyPairings == unlimited;

  /// Convenience flag for unlimited inspiration lookups.
  bool get hasUnlimitedInspiration => monthlyInspirationSearches == unlimited;

  /// Convenience flag for unlimited polishing.
  bool get hasUnlimitedPolishing => monthlyImagePolish == unlimited;
}

/// Snapshot of subscription usage metrics persisted locally.
class SubscriptionUsageSnapshot {
  final int dailyUploadsUsed;
  final int monthlyMannequinsUsed;
  final int monthlyPairingsUsed;
  final int monthlyInspirationUsed;
  final int monthlyPolishingUsed;
  final DateTime dailyResetAt;
  final DateTime monthlyResetAt;

  SubscriptionUsageSnapshot({
    this.dailyUploadsUsed = 0,
    this.monthlyMannequinsUsed = 0,
    this.monthlyPairingsUsed = 0,
    this.monthlyInspirationUsed = 0,
    this.monthlyPolishingUsed = 0,
    DateTime? dailyResetAt,
    DateTime? monthlyResetAt,
  }) : dailyResetAt = dailyResetAt ?? DateTime.now(),
       monthlyResetAt = monthlyResetAt ?? DateTime.now();

  SubscriptionUsageSnapshot copyWith({
    int? dailyUploadsUsed,
    int? monthlyMannequinsUsed,
    int? monthlyPairingsUsed,
    int? monthlyInspirationUsed,
    int? monthlyPolishingUsed,
    DateTime? dailyResetAt,
    DateTime? monthlyResetAt,
  }) {
    return SubscriptionUsageSnapshot(
      dailyUploadsUsed: dailyUploadsUsed ?? this.dailyUploadsUsed,
      monthlyMannequinsUsed:
          monthlyMannequinsUsed ?? this.monthlyMannequinsUsed,
      monthlyPairingsUsed: monthlyPairingsUsed ?? this.monthlyPairingsUsed,
      monthlyInspirationUsed:
          monthlyInspirationUsed ?? this.monthlyInspirationUsed,
      monthlyPolishingUsed: monthlyPolishingUsed ?? this.monthlyPolishingUsed,
      dailyResetAt: dailyResetAt ?? this.dailyResetAt,
      monthlyResetAt: monthlyResetAt ?? this.monthlyResetAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'dailyUploadsUsed': dailyUploadsUsed,
    'monthlyMannequinsUsed': monthlyMannequinsUsed,
    'monthlyPairingsUsed': monthlyPairingsUsed,
    'monthlyInspirationUsed': monthlyInspirationUsed,
    'monthlyPolishingUsed': monthlyPolishingUsed,
    'dailyResetAt': dailyResetAt.toIso8601String(),
    'monthlyResetAt': monthlyResetAt.toIso8601String(),
  };

  factory SubscriptionUsageSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SubscriptionUsageSnapshot();
    }
    return SubscriptionUsageSnapshot(
      dailyUploadsUsed: json['dailyUploadsUsed'] as int? ?? 0,
      monthlyMannequinsUsed: json['monthlyMannequinsUsed'] as int? ?? 0,
      monthlyPairingsUsed: json['monthlyPairingsUsed'] as int? ?? 0,
      monthlyInspirationUsed: json['monthlyInspirationUsed'] as int? ?? 0,
      monthlyPolishingUsed: json['monthlyPolishingUsed'] as int? ?? 0,
      dailyResetAt:
          DateTime.tryParse(json['dailyResetAt'] as String? ?? '') ??
          DateTime.now(),
      monthlyResetAt:
          DateTime.tryParse(json['monthlyResetAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Determines whether daily counters should reset for the provided timestamp.
  bool needsDailyReset(DateTime now) {
    return now.year != dailyResetAt.year ||
        now.month != dailyResetAt.month ||
        now.day != dailyResetAt.day;
  }

  /// Determines whether monthly counters should reset for the provided timestamp.
  bool needsMonthlyReset(DateTime now) {
    return now.year != monthlyResetAt.year || now.month != monthlyResetAt.month;
  }
}

/// Canonical subscription object stored with each user profile.
class UserSubscription {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? startedAt;
  final DateTime? currentPeriodEnd;
  final DateTime? nextBillingAt;
  final bool autoRenew;
  final bool isTrial;
  final String? paystackCustomerCode;
  final String? paystackSubscriptionCode;

  const UserSubscription({
    this.tier = SubscriptionTier.free,
    this.status = SubscriptionStatus.inactive,
    this.startedAt,
    this.currentPeriodEnd,
    this.nextBillingAt,
    this.autoRenew = false,
    this.isTrial = false,
    this.paystackCustomerCode,
    this.paystackSubscriptionCode,
  });

  /// True when user should have premium/pro capabilities.
  bool get hasEntitlement => tier != SubscriptionTier.free && isActive;

  /// Whether the subscription is currently in good standing.
  bool get isActive {
    switch (status) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.trialing:
        return true;
      case SubscriptionStatus.grace:
        if (currentPeriodEnd == null) return true;
        return currentPeriodEnd!.isAfter(DateTime.now());
      default:
        return false;
    }
  }

  /// Usage policy derived from tier.
  SubscriptionUsagePolicy get usagePolicy => tier.usagePolicy;

  UserSubscription copyWith({
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startedAt,
    DateTime? currentPeriodEnd,
    DateTime? nextBillingAt,
    bool? autoRenew,
    bool? isTrial,
    String? paystackCustomerCode,
    String? paystackSubscriptionCode,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      nextBillingAt: nextBillingAt ?? this.nextBillingAt,
      autoRenew: autoRenew ?? this.autoRenew,
      isTrial: isTrial ?? this.isTrial,
      paystackCustomerCode: paystackCustomerCode ?? this.paystackCustomerCode,
      paystackSubscriptionCode:
          paystackSubscriptionCode ?? this.paystackSubscriptionCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier.name,
    'status': status.name,
    'startedAt': startedAt?.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'nextBillingAt': nextBillingAt?.toIso8601String(),
    'autoRenew': autoRenew,
    'isTrial': isTrial,
    'paystackCustomerCode': paystackCustomerCode,
    'paystackSubscriptionCode': paystackSubscriptionCode,
  };

  factory UserSubscription.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const UserSubscription();
    }

    SubscriptionTier parseTier(String? raw) {
      return SubscriptionTier.values.firstWhere(
        (tier) => tier.name == raw,
        orElse: () => SubscriptionTier.free,
      );
    }

    SubscriptionStatus parseStatus(String? raw) {
      return SubscriptionStatus.values.firstWhere(
        (status) => status.name == raw,
        orElse: () => SubscriptionStatus.inactive,
      );
    }

    DateTime? parseDate(String? raw) =>
        raw == null ? null : DateTime.tryParse(raw);

    return UserSubscription(
      tier: parseTier(json['tier'] as String?),
      status: parseStatus(json['status'] as String?),
      startedAt: parseDate(json['startedAt'] as String?),
      currentPeriodEnd: parseDate(json['currentPeriodEnd'] as String?),
      nextBillingAt: parseDate(json['nextBillingAt'] as String?),
      autoRenew: json['autoRenew'] as bool? ?? false,
      isTrial: json['isTrial'] as bool? ?? false,
      paystackCustomerCode: json['paystackCustomerCode'] as String?,
      paystackSubscriptionCode: json['paystackSubscriptionCode'] as String?,
    );
  }
}
