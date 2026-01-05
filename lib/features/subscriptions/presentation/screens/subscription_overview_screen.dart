import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/user_profile.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/subscriptions/subscription_controller.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:vestiq/features/subscriptions/presentation/widgets/payment_in_progress_bottom_sheet.dart';
import 'package:vestiq/features/subscriptions/presentation/widgets/plan_comparison_sheet.dart';

class SubscriptionOverviewScreen extends ConsumerStatefulWidget {
  const SubscriptionOverviewScreen({super.key});

  @override
  ConsumerState<SubscriptionOverviewScreen> createState() =>
      _SubscriptionOverviewScreenState();
}

class _SubscriptionOverviewScreenState
    extends ConsumerState<SubscriptionOverviewScreen> {
  final AppSettingsService _settings = getIt<AppSettingsService>();
  bool _progressSheetVisible = false;
  BuildContext? _progressSheetContext;

  @override
  Widget build(BuildContext context) {
    ref.listen<SubscriptionCheckoutState>(
      subscriptionControllerProvider,
      (previous, next) => _handleCheckoutState(previous, next),
    );

    final subscription = _settings.subscriptionSnapshot;
    final checkoutState = ref.watch(subscriptionControllerProvider);
    final isPremium = subscription.tier != SubscriptionTier.free;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription & billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Billing history coming soon.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _CurrentPlanCard(subscription: subscription),
          const SizedBox(height: 24),
          _BenefitList(isPremium: isPremium),
          const SizedBox(height: 24),
          _buildCtaSection(context, checkoutState, isPremium),
          const SizedBox(height: 32),
          _buildFaqSection(context),
        ],
      ),
    );
  }

  Widget _buildCtaSection(
    BuildContext context,
    SubscriptionCheckoutState state,
    bool isPremium,
  ) {
    final theme = Theme.of(context);
    final buttonLabel = isPremium
        ? 'You\'re already Premium'
        : state.isLoading
        ? 'Processing...'
        : 'Upgrade to Premium';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isPremium || state.isLoading
              ? null
              : () => _startCheckout(context),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(buttonLabel),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const PlanComparisonSheet(),
            );
          },
          child: const Text('Compare plans'),
        ),
        if (!isPremium) ...[
          const SizedBox(height: 12),
          Text(
            'Paystack securely handles your card. Cancel anytime inside the app.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need to know',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _FaqTile(
          question: 'Can I cancel anytime?',
          answer:
              'Yes. Premium downgrades at the end of the billing cycle and you keep your wardrobe.',
        ),
        _FaqTile(
          question: 'Will uploads stop immediately if I hit a limit?',
          answer:
              'We provide a 24-hour grace period before pausing mannequin rendering or pairings.',
        ),
        _FaqTile(
          question: 'Is my payment information safe?',
          answer:
              'All card data is handled by Paystack. Vestiq never touches your payment details.',
        ),
      ],
    );
  }

  Future<void> _startCheckout(BuildContext context) async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to upgrade.')),
      );
      return;
    }

    if (user.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an email to your profile first.')),
      );
      return;
    }

    await ref
        .read(subscriptionControllerProvider.notifier)
        .startCheckout(
          context: context,
          userId: user.uid,
          email: user.email,
          tier: SubscriptionTier.premium,
        );
  }

  void _handleCheckoutState(
    SubscriptionCheckoutState? previous,
    SubscriptionCheckoutState next,
  ) {
    if (!mounted) return;

    if (next.step == SubscriptionFlowStep.verifying && !_progressSheetVisible) {
      _progressSheetVisible = true;
      showModalBottomSheet<void>(
        context: context,
        barrierColor: Colors.black54,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) {
          _progressSheetContext = sheetContext;
          return const PaymentInProgressBottomSheet();
        },
      ).whenComplete(() {
        _progressSheetVisible = false;
        _progressSheetContext = null;
      });
    } else if (next.step != SubscriptionFlowStep.verifying &&
        _progressSheetVisible &&
        _progressSheetContext != null) {
      Navigator.of(_progressSheetContext!).pop();
    }

    if (previous?.step != SubscriptionFlowStep.completed &&
        next.step == SubscriptionFlowStep.completed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'re Premium! Enjoy the upgrade.')),
        );
      }
    }

    if (next.hasError &&
        next.errorMessage != null &&
        next.errorMessage!.isNotEmpty &&
        previous?.errorMessage != next.errorMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      AppLogger.warning('Subscription flow error', error: next.errorMessage);
    }
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final UserSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = subscription.tier != SubscriptionTier.free;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHighest,
                ],
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPremium
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subscription.tier.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isPremium
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isPremium ? Icons.workspace_premium : Icons.lock_open_rounded,
                color: isPremium
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isPremium
                ? 'Premium gives you unlimited creative freedom.'
                : 'Free keeps things playful. Premium takes it couture.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isPremium
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subscription.status.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isPremium
                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (subscription.currentPeriodEnd != null) ...[
            const SizedBox(height: 8),
            Text(
              'Renews on ${_formatDate(subscription.currentPeriodEnd!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPremium
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final benefits = _premiumBenefits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPremium ? 'Premium unlocked' : 'Premium benefits',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...benefits.map((benefit) => _BenefitTile(benefit: benefit)),
      ],
    );
  }

  List<_Benefit> get _premiumBenefits => const [
    _Benefit(
      icon: Icons.flash_on,
      title: 'Double wardrobe uploads',
      description:
          'Upload up to ${AppConstants.premiumDailyUploadLimit} looks daily versus ${AppConstants.freeDailyUploadLimit} on Free.',
    ),
    _Benefit(
      icon: Icons.auto_awesome,
      title: 'Unlimited pairings & inspiration',
      description:
          'AI styling, pairings, and inspiration search no longer pause when creativity strikes.',
    ),
    _Benefit(
      icon: Icons.brush,
      title: 'Couture image polishing',
      description:
          '${AppConstants.premiumMonthlyPolishingLimit} premium-grade polish sessions every month.',
    ),
    _Benefit(
      icon: Icons.rocket_launch,
      title: 'Early feature drops',
      description: 'Premium users are first to test new AI wardrobe powers.',
    ),
  ];
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.benefit});

  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(benefit.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    benefit.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
