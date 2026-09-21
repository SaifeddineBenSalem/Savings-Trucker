import 'package:flutter/scheduler.dart';

import '../../core/constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/app_data.dart';
import '../../data/models/savings_unit.dart';
import '../../data/models/savings_unit.dart';
import '../../data/models/unit_status.dart';
import '../../data/services/storage_service.dart';
import '../../domain/services/savings_engine.dart';
import 'package:flutter/foundation.dart';

class SavingsProvider extends ChangeNotifier {
  SavingsProvider(this._storage);

  final StorageService _storage;

  AppData? _data;
  UnitFilter _filter = UnitFilter.pending;
  int _currentMonth = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  List<String> _recentlyMatchedIds = [];
  final Map<String, int> _pageIndexByKey = {};
  int _notifyEpoch = 0;

  bool get isLoading => _isLoading;
  bool get isConfigured => _data != null;
  UnitFilter get filter => _filter;
  int get currentMonth => _currentMonth;
  String get searchQuery => _searchQuery;
  bool get isSearchActive => _searchQuery.trim().isNotEmpty;
  List<String> get recentlyMatchedIds => List.unmodifiable(_recentlyMatchedIds);

  AppData? get data => _data;

  int get targetMillimes => _data?.targetMillimes ?? 0;
  int get completedUnitsMillimes => _data?.completedUnitsMillimes ?? 0;
  int get collectedMillimes => _data?.collectedMillimes ?? 0;
  int get remainingMillimes => _data?.remainingMillimes ?? 0;
  int get creditsMillimes => _data?.creditsMillimes ?? 0;
  double get progress => _data?.progress ?? 0;
  List<String> get badges => _data?.unlockedBadges ?? [];

  Future<void> initialize() async {
    _data = _storage.load();
    if (_data != null) {
      final migrated = _migrateUnits(_data!.units);
      if (migrated != _data!.units) {
        _data = _data!.copyWith(units: migrated);
        await _storage.save(_data!);
      }
    }
    _isLoading = false;
    _notifyListenersSafely();
  }

  List<SavingsUnit> _migrateUnits(List<SavingsUnit> units) {
    if (units.isEmpty) return units;

    final zeroCount = units.where((u) => u.sequenceOrder == 0).length;
    final needsMigration = zeroCount > 1 ||
        units.asMap().entries.any((e) => e.value.sequenceOrder != e.key);

    if (!needsMigration) return units;

    return [
      for (var i = 0; i < units.length; i++)
        SavingsUnit(
          id: units[i].id,
          valueMillimes: units[i].valueMillimes,
          monthIndex: units[i].monthIndex,
          sequenceOrder: i,
          status: units[i].status,
        ),
    ];
  }

  String _pageKey(int month, UnitFilter filter) => 'm${month}_${filter.name}';

  String _searchPageKey(UnitFilter filter) => 'search_${filter.name}';

  int currentPageForMonth(int month) {
    final key = isSearchActive ? _searchPageKey(_filter) : _pageKey(month, _filter);
    final rawPage = _pageIndexByKey[key] ?? 0;
    final maxPage = pageCountForMonth(month) - 1;
    return rawPage.clamp(0, maxPage < 0 ? 0 : maxPage);
  }

  int pageCountForMonth(int month) {
    final total = isSearchActive
        ? searchResults(monthIndex: month).length
        : _filteredUnitsForMonth(month).length;
    if (total == 0) return 1;
    return (total / AppConstants.itemsPerPage).ceil();
  }

  void setPageForMonth(int month, int page) {
    final key = isSearchActive ? _searchPageKey(_filter) : _pageKey(month, _filter);
    final maxPage = pageCountForMonth(month) - 1;
    _pageIndexByKey[key] = page.clamp(0, maxPage < 0 ? 0 : maxPage);
    _notifyListenersSafely();
  }

  void nextPage(int month) {
    setPageForMonth(month, currentPageForMonth(month) + 1);
  }

  void previousPage(int month) {
    setPageForMonth(month, currentPageForMonth(month) - 1);
  }

  void setSearchQuery(String query) {
    final next = query.trim();
    if (_searchQuery == next) return;
    _searchQuery = next;
    _notifyListenersSafely();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _notifyListenersSafely();
  }

  List<SavingsUnit> searchResults({int? monthIndex, UnitFilter? filterOverride}) {
    if (_data == null || !isSearchActive) return [];
    final targetMonth = monthIndex ?? _currentMonth;
    final activeFilter = filterOverride ?? _filter;
    return _data!.units.where((unit) {
      if (unit.monthIndex != targetMonth) return false;
      if (!SavingsEngine.matchesSearchQuery(unit, _searchQuery)) return false;
      return _matchesFilter(unit, activeFilter);
    }).toList()
      ..sort((a, b) {
        final valCompare = a.valueMillimes.compareTo(b.valueMillimes);
        if (valCompare != 0) return valCompare;
        return a.sequenceOrder.compareTo(b.sequenceOrder);
      });
  }

  List<SavingsUnit> unitsForMonth(int month, {UnitFilter? filterOverride}) {
    if (_data == null) return [];
    if (isSearchActive) {
      return _paginate(searchResults(monthIndex: month, filterOverride: filterOverride), month);
    }
    return _paginate(_filteredUnitsForMonth(month, filterOverride: filterOverride), month);
  }

  List<SavingsUnit> _filteredUnitsForMonth(int month, {UnitFilter? filterOverride}) {
    final activeFilter = filterOverride ?? _filter;
    return _data!.units.where((unit) {
      if (unit.monthIndex != month) return false;
      return _matchesFilter(unit, activeFilter);
    }).toList()
      ..sort((a, b) {
        final valCompare = a.valueMillimes.compareTo(b.valueMillimes);
        if (valCompare != 0) return valCompare;
        return a.sequenceOrder.compareTo(b.sequenceOrder);
      });
  }

  bool _matchesFilter(SavingsUnit unit, UnitFilter filter) {
    switch (filter) {
      case UnitFilter.all:
        return true;
      case UnitFilter.pending:
        return unit.status == UnitStatus.pending;
      case UnitFilter.done:
        return unit.status == UnitStatus.done;
    }
  }

  List<SavingsUnit> _paginate(List<SavingsUnit> units, int month) {
    final page = currentPageForMonth(month);
    final start = page * AppConstants.itemsPerPage;
    final end = (start + AppConstants.itemsPerPage).clamp(0, units.length);
    if (start >= units.length) return [];
    return units.sublist(start, end);
  }

  int totalUnitsForMonth(int month) {
    if (isSearchActive) return searchResults(monthIndex: month).length;
    return _filteredUnitsForMonth(month).length;
  }

  int pendingCountForMonth(int month) =>
      _data?.units
          .where((u) => u.monthIndex == month && u.status == UnitStatus.pending)
          .length ??
      0;

  bool isMonthComplete(int month) =>
      _data != null &&
      _data!.units
          .where((u) => u.monthIndex == month)
          .every((u) => u.status == UnitStatus.done);

  void setFilter(UnitFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _notifyListenersSafely();
  }

  void setCurrentMonth(int month) {
    final clamped = month.clamp(0, AppConstants.monthsCount - 1);
    if (_currentMonth == clamped) return;
    _currentMonth = clamped;
    _notifyListenersSafely();
  }

  Future<void> configureTarget(int targetMillimes) async {
    if (_data != null) return;

    final units = SavingsEngine.createPlan(targetMillimes);
    _data = AppData(
      targetMillimes: targetMillimes,
      units: units,
    );
    await _storage.save(_data!);
    _notifyListenersSafely();
  }

  Future<int> addCredits(int amountMillimes) async {
    if (_data == null || amountMillimes <= 0) return 0;

    final credits = _data!.creditsMillimes + amountMillimes;
    final result = SavingsEngine.applyCreditMatching(
      units: _data!.units,
      creditsMillimes: credits,
    );

    _recentlyMatchedIds = List<String>.from(result.matchedUnitIds);
    _data = _data!.copyWith(
      units: result.units,
      creditsMillimes: result.creditsMillimes,
    );
    _updateBadges();
    await _storage.save(_data!);
    _notifyListenersSafely();
    return _recentlyMatchedIds.length;
  }

  Future<bool> confirmUnitCollection(String unitId, bool collected) async {
    if (_data == null || !collected) return false;

    final index = _data!.units.indexWhere((u) => u.id == unitId);
    if (index == -1) return false;

    final unit = _data!.units[index];
    if (unit.status == UnitStatus.done) return false;

    final updatedUnits = _data!.units.map((u) => u.copyWith()).toList();
    updatedUnits[index].status = UnitStatus.done;

    final result = SavingsEngine.applyCreditMatching(
      units: updatedUnits,
      creditsMillimes: _data!.creditsMillimes,
    );

    _recentlyMatchedIds = List<String>.from(result.matchedUnitIds);
    _data = _data!.copyWith(
      units: result.units,
      creditsMillimes: result.creditsMillimes,
    );

    _updateBadges();
    await _storage.save(_data!);
    _notifyListenersSafely();

    if (_recentlyMatchedIds.isNotEmpty) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        clearRecentMatches();
      });
    }

    return true;
  }

  void clearRecentMatches() {
    if (_recentlyMatchedIds.isEmpty) return;
    _recentlyMatchedIds = [];
    _notifyListenersSafely();
  }

  Future<bool> resetApp(String password) async {
    if (password != AppConstants.resetPassword) return false;

    await _storage.clear();

    _data = null;
    _filter = UnitFilter.pending;
    _currentMonth = 0;
    _searchQuery = '';
    _recentlyMatchedIds = [];
    _pageIndexByKey.clear();

    _notifyListenersSafely();
    return true;
  }

  Map<int, MonthStats> get monthlyStats {
    final stats = <int, MonthStats>{};
    if (_data == null) return stats;

    for (var m = 0; m < AppConstants.monthsCount; m++) {
      final monthUnits =
          _data!.units.where((u) => u.monthIndex == m).toList()
            ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
      final total = monthUnits.fold<int>(0, (s, u) => s + u.valueMillimes);
      final done = monthUnits
          .where((u) => u.status == UnitStatus.done)
          .fold<int>(0, (s, u) => s + u.valueMillimes);
      stats[m] = MonthStats(
        monthIndex: m,
        totalMillimes: total,
        collectedMillimes: done,
        unitCount: monthUnits.length,
        doneCount: monthUnits.where((u) => u.status == UnitStatus.done).length,
      );
    }
    return stats;
  }

  void _updateBadges() {
    if (_data == null) return;
    final badges = List<String>.from(_data!.unlockedBadges);

    void unlock(String badge) {
      if (!badges.contains(badge)) badges.add(badge);
    }

    if (_data!.collectedMillimes >= 1000) {
      unlock('First 1 DT saved');
    }
    if (_data!.collectedMillimes >= 10000) {
      unlock('10 DT milestone');
    }
    if (_data!.progress >= 0.25) unlock('25% progress');
    if (_data!.progress >= 0.5) unlock('Halfway there');
    if (_data!.progress >= 1.0) unlock('Goal achieved!');

    for (var m = 0; m < AppConstants.monthsCount; m++) {
      if (isMonthComplete(m)) {
        unlock('Month ${m + 1} complete');
      }
    }

    _data = _data!.copyWith(unlockedBadges: badges);
  }

  void _notifyListenersSafely() {
    final epoch = ++_notifyEpoch;
    void emit() {
      if (epoch != _notifyEpoch) return;
      notifyListeners();
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      emit();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) => emit());
  }
}

class MonthStats {
  MonthStats({
    required this.monthIndex,
    required this.totalMillimes,
    required this.collectedMillimes,
    required this.unitCount,
    required this.doneCount,
  });

  final int monthIndex;
  final int totalMillimes;
  final int collectedMillimes;
  final int unitCount;
  final int doneCount;

  double get progress =>
      totalMillimes == 0 ? 0 : collectedMillimes / totalMillimes;
}
