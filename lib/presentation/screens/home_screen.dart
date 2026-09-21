import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/savings_unit.dart';
import '../providers/savings_provider.dart';
import '../widgets/credits_modal.dart';
import '../widgets/filter_bar.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/progress_header.dart';
import '../widgets/search_bar.dart';
import '../widgets/unit_card.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final Set<int> _celebratedMonths = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.monthsCount, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    context.read<SavingsProvider>().setCurrentMonth(_tabController.index);
    _checkMonthCompletion(_tabController.index);
  }

  void _checkMonthCompletion(int month) {
    if (!mounted) return;
    final provider = context.read<SavingsProvider>();
    if (provider.isMonthComplete(month) && !_celebratedMonths.contains(month)) {
      _celebratedMonths.add(month);
      _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Month ${month + 1} completed! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleUnitTap(SavingsUnit unit) async {
    final confirmed = await showCollectionDialog(context, unit);
    if (confirmed == true && mounted) {
      await context.read<SavingsProvider>().confirmUnitCollection(unit.id, true);
      if (mounted) {
        _checkMonthCompletion(unit.monthIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Tracker'),
        actions: [
          IconButton(
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
              );
            },
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: () => handleResetAction(context),
            icon: const Icon(Icons.lock_reset_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const ProgressHeader(),
              FilterBar(
                selected: provider.filter,
                onChanged: provider.setFilter,
              ),
              const SearchBarWidget(),
              if (provider.isSearchActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${provider.searchResults(monthIndex: provider.currentMonth).length} match(es) in Month ${provider.currentMonth + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.lightMuted,
                      indicatorColor: AppColors.primary,
                      tabs: List.generate(AppConstants.monthsCount, (index) {
                        final pending = provider.pendingCountForMonth(index);
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('M${index + 1}'),
                              if (pending > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$pending',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          AppConstants.monthsCount,
                          (month) => _MonthUnitsList(
                            month: month,
                            onUnitTap: _handleUnitTap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 24,
              gravity: 0.2,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => handleCreditsAction(context),
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Credits'),
      ),
    );
  }
}

class _MonthUnitsList extends StatelessWidget {
  const _MonthUnitsList({
    required this.month,
    required this.onUnitTap,
    this.isGlobalSearch = false,
  });

  final int month;
  final Future<void> Function(SavingsUnit unit) onUnitTap;
  final bool isGlobalSearch;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final units = provider.unitsForMonth(month);
    final stats = provider.monthlyStats[month];
    final totalUnits = provider.totalUnitsForMonth(month);

    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: totalUnits == 0
                ? Center(
                    key: ValueKey('empty-$month-${provider.filter.name}'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.isSearchActive
                              ? 'No matching units found'
                              : 'No units in this filter',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    key: ValueKey(
                      'list-$month-${provider.filter.name}-${provider.currentPageForMonth(month)}-${provider.searchQuery}',
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    children: [
                      if (!isGlobalSearch && stats != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Month ${month + 1} Progress',
                                      style:
                                          Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stats.doneCount}/${stats.unitCount} units · '
                                      '${CurrencyFormatter.formatMillimes(stats.collectedMillimes)} collected',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: stats.progress,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...units.map(
                        (unit) => UnitCard(
                          unit: unit,
                          recentlyMatched:
                              provider.recentlyMatchedIds.contains(unit.id),
                          searchHighlighted: provider.isSearchActive,
                          monthLabel: isGlobalSearch
                              ? 'Month ${unit.monthIndex + 1}'
                              : null,
                          onTap: () => onUnitTap(unit),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PaginationBar(month: month),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
