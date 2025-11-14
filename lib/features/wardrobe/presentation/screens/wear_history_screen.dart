import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/wear_history_event.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/features/wardrobe/data/firestore_wear_history_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Screen showing user's wear history with stats and insights
class WearHistoryScreen extends ConsumerStatefulWidget {
  const WearHistoryScreen({super.key});

  @override
  ConsumerState<WearHistoryScreen> createState() => _WearHistoryScreenState();
}

class _WearHistoryScreenState extends ConsumerState<WearHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wear History')),
        body: const Center(child: Text('Please sign in to view wear history')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wear History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(context),
            tooltip: 'Change month',
          ),
        ],
      ),
      body: StreamBuilder<List<WearHistoryEvent>>(
        stream: getIt<FirestoreWearHistoryService>().watchUserWearHistory(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading wear history',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          final allEvents = snapshot.data ?? [];

          if (allEvents.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Filter events for selected month
          final monthEvents = allEvents.where((event) {
            return event.wornAt.year == _selectedMonth.year &&
                event.wornAt.month == _selectedMonth.month;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Month selector
              SliverToBoxAdapter(child: _buildMonthSelector(theme)),

              // Stats overview
              SliverToBoxAdapter(
                child: _buildStatsOverview(theme, allEvents, monthEvents),
              ),

              // Wear history list
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _buildWearHistoryList(theme, monthEvents),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No wear history yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking when you wear items to see insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              if (nextMonth.isBefore(
                DateTime.now().add(const Duration(days: 1)),
              )) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(
    ThemeData theme,
    List<WearHistoryEvent> allEvents,
    List<WearHistoryEvent> monthEvents,
  ) {
    // Calculate stats
    final totalWears = monthEvents.length;
    final uniqueItems = monthEvents.map((e) => e.itemId).toSet().length;
    final avgRating =
        monthEvents
            .where((e) => e.userRating != null)
            .fold<double>(0, (sum, e) => sum + (e.userRating ?? 0)) /
        (monthEvents
            .where((e) => e.userRating != null)
            .length
            .clamp(1, double.infinity));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            theme,
            Icons.checkroom,
            totalWears.toString(),
            'Wears',
          ),
          _buildStatCard(
            theme,
            Icons.inventory_2_outlined,
            uniqueItems.toString(),
            'Items',
          ),
          _buildStatCard(
            theme,
            Icons.star,
            avgRating.isNaN ? '-' : avgRating.toStringAsFixed(1),
            'Rating',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildWearHistoryList(ThemeData theme, List<WearHistoryEvent> events) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No wears recorded for this month',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    // Group by date
    final eventsByDate = <DateTime, List<WearHistoryEvent>>{};
    for (final event in events) {
      final date = DateTime(
        event.wornAt.year,
        event.wornAt.month,
        event.wornAt.day,
      );
      eventsByDate.putIfAbsent(date, () => []).add(event);
    }

    final sortedDates = eventsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final date = sortedDates[index];
        final dateEvents = eventsByDate[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
              child: Text(
                DateFormat('EEEE, MMMM d').format(date),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...dateEvents.map((event) => _buildWearEventCard(theme, event)),
          ],
        );
      }, childCount: sortedDates.length),
    );
  }

  Widget _buildWearEventCard(ThemeData theme, WearHistoryEvent event) {
    return FutureBuilder<WardrobeItem?>(
      future: _getItemById(event.itemId),
      builder: (context, snapshot) {
        final item = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: item != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: item.displayImagePath.isNotEmpty
                          ? Image.file(
                              File(item.displayImagePath),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.checkroom,
                              color: theme.colorScheme.primary,
                            ),
                    ),
                  )
                : const CircleAvatar(child: Icon(Icons.checkroom)),
            title: Text(
              item != null
                  ? '${item.analysis.primaryColor} ${item.analysis.itemType}'
                  : event.itemId ?? 'Unknown item',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.occasion != null && event.occasion!.isNotEmpty)
                  Text('📍 ${event.occasion}'),
                if (event.userRating != null)
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < event.userRating!
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                if (event.notes != null && event.notes!.isNotEmpty)
                  Text(
                    event.notes!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Text(
              DateFormat.jm().format(event.wornAt),
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Future<WardrobeItem?> _getItemById(String? itemId) async {
    if (itemId == null) return null;

    try {
      final wardrobeService = getIt<EnhancedWardrobeStorageService>();
      final items = await wardrobeService.getWardrobeItems();
      return items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
      });
    }
  }
}
