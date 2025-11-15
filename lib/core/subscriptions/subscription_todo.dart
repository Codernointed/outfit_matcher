/// Subscription implementation checklist for Paystack-first rollout.
/// Keep this in sync with PricingPlan.md roadmap. Mark items as completed
/// and remove TODOs only after code, tests, and enforcement are merged.
class SubscriptionTodo {
  static const paystackIntegration = [
    // Phase 0
    'TODO: Wire PAYSTACK_PUBLIC_KEY / PAYSTACK_SECRET_KEY into AppConfig via service_locator.dart.',
    'TODO: Add SubscriptionTier enum + helpers for entitlement parsing.',
    'TODO: Expose quota telemetry streams from AppSettingsService.',
    // Phase 1
    'TODO: Implement /subscriptions/paystack/initialize + verify backend endpoints.',
    'TODO: Build webhook handler validating x-paystack-signature and updating SubscriptionRecord.',
    'TODO: Persist SubscriptionRecord snapshots in Firestore with idempotency tokens.',
    // Phase 2
    'TODO: Add flutter_paystack + flutter_dotenv packages and configure PaystackPaymentService.',
    'TODO: Create subscriptionControllerProvider managing checkout states.',
    'TODO: Cache entitlement snapshot locally with TTL + offline grace.',
    // Phase 3
    'TODO: Ship SubscriptionOverviewScreen, PlanComparisonSheet, and PaymentInProgressBottomSheet.',
    'TODO: Surface upgrade CTAs on home_screen, upload_options_screen, saved_looks_screen.',
    // Phase 4
    'TODO: Centralize quota enforcement via UsageGuard middleware.',
    'TODO: Implement grace-period + auto-downgrade logic on failed invoices.',
    // Phase 5
    'TODO: Add analytics events for checkout started/completed/downgraded.',
    'TODO: Build automated test matrix covering card/bank/mobile money flows.',
    // Phase 6
    'TODO: Abstract payment provider interface to allow future RevenueCat adapter.',
  ];
}
