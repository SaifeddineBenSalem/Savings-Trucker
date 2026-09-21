import 'dart:math';

import '../../core/constants.dart';
import '../../data/models/savings_unit.dart';
import '../../data/models/unit_status.dart';
import 'package:uuid/uuid.dart';

/// Core savings splitting and credit matching engine.
class SavingsEngine {
  SavingsEngine._();

  static const _uuid = Uuid();
  static const _bases = AppConstants.unitDenominationsMillimes;
  static const _maxUnit = AppConstants.maxUnitMillimes;

  /// Target must be formable from allowed denominations (multiple of 100).
  static bool isTargetRepresentable(int totalMillimes) =>
      totalMillimes > 0 && totalMillimes % 100 == 0;

  /// A unit is either a base denomination or a sum of them, capped at 5000 millimes.
  static bool isValidUnitValue(int value) {
    if (value <= 0 || value > _maxUnit) return false;
    if (_bases.contains(value)) return true;
    return _canFormSum(value, _bases);
  }

  static bool _canFormSum(int target, List<int> coins) {
    final dp = List<bool>.filled(target + 1, false);
    dp[0] = true;
    for (final coin in coins) {
      for (var i = coin; i <= target; i++) {
        if (dp[i - coin]) dp[i] = true;
      }
    }
    return dp[target];
  }

  /// Breaks [totalMillimes] into collectible units that sum exactly to the target.
  static List<int> generateUnits(int totalMillimes) {
    if (totalMillimes <= 0) return [];
    if (!isTargetRepresentable(totalMillimes)) {
      throw ArgumentError(
        'Target must be a multiple of 100 millimes to use denominations '
        '100, 200, 500, 1000, 2000, 5000',
      );
    }

    final atomics = _splitIntoAtomics(totalMillimes);
    final units = _composeUnitsFromAtomics(atomics, totalMillimes);

    final sum = units.fold<int>(0, (a, b) => a + b);
    assert(sum == totalMillimes, 'Unit sum must equal target');
    for (final unit in units) {
      assert(isValidUnitValue(unit), 'Invalid unit value: $unit');
    }

    units.sort((a, b) => b.compareTo(a));
    return units;
  }

  /// Splits target into base denominations, biased toward small values.
  static List<int> _splitIntoAtomics(int total) {
    var remaining = total;
    final random = Random(total);
    final atomics = <int>[];

    while (remaining > 0) {
      final available = _bases.where((d) => d <= remaining).toList();

      int selected;
      if (remaining <= 500) {
        selected = remaining;
      } else {
        final small = available.where((d) => d <= 500).toList();
        if (small.isNotEmpty && random.nextDouble() < 0.85) {
          selected = small[random.nextInt(small.length)];
        } else {
          final medium = available.where((d) => d <= 2000).toList();
          if (medium.isNotEmpty && random.nextDouble() < 0.8) {
            selected = medium[random.nextInt(medium.length)];
          } else {
            selected = available.last;
          }
        }
      }

      atomics.add(selected);
      remaining -= selected;
    }

    return atomics;
  }

  /// Optionally merges atomics into composite units (e.g. 100+200=300), max 5000 each.
  static List<int> _composeUnitsFromAtomics(List<int> atomics, int seed) {
    final random = Random(seed + 17);
    final pool = List<int>.from(atomics)..shuffle(random);
    final units = <int>[];
    var index = 0;

    while (index < pool.length) {
      if (pool[index] <= 1000 &&
          index + 1 < pool.length &&
          random.nextDouble() < 0.22) {
        var sum = pool[index];
        var next = index + 1;
        while (next < pool.length &&
            sum + pool[next] <= _maxUnit &&
            next - index < 4 &&
            random.nextDouble() < 0.55) {
          sum += pool[next];
          next++;
        }

        if (next > index + 1 && isValidUnitValue(sum)) {
          units.add(sum);
          index = next;
          continue;
        }
      }

      units.add(pool[index]);
      index++;
    }

    return units;
  }

  /// Distributes units evenly across [months] by count and total value.
  static List<SavingsUnit> distributeUnits(
    List<int> unitValues, {
    int months = AppConstants.monthsCount,
  }) {
    if (unitValues.isEmpty) return [];

    final sorted = List<int>.from(unitValues)..sort((a, b) => b.compareTo(a));
    final monthCounts = List.filled(months, 0);
    final monthTotals = List.filled(months, 0);
    final result = <SavingsUnit>[];
    var sequence = 0;

    for (final value in sorted) {
      var bestMonth = 0;
      for (var m = 1; m < months; m++) {
        if (monthCounts[m] < monthCounts[bestMonth]) {
          bestMonth = m;
        } else if (monthCounts[m] == monthCounts[bestMonth] &&
            monthTotals[m] < monthTotals[bestMonth]) {
          bestMonth = m;
        }
      }

      result.add(
        SavingsUnit(
          id: _uuid.v4(),
          valueMillimes: value,
          monthIndex: bestMonth,
          sequenceOrder: sequence++,
        ),
      );
      monthCounts[bestMonth]++;
      monthTotals[bestMonth] += value;
    }

    result.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
    return result;
  }

  /// Creates the full unit plan from a target amount.
  static List<SavingsUnit> createPlan(int targetMillimes) {
    final values = generateUnits(targetMillimes);
    return distributeUnits(values);
  }

  /// Returns pending units in strict FIFO order: Month 1→14, top-to-bottom within month.
  static List<SavingsUnit> pendingUnitsInOrder(List<SavingsUnit> units) {
    return units
        .where((u) => u.status == UnitStatus.pending)
        .toList()
      ..sort((a, b) {
        final monthCompare = a.monthIndex.compareTo(b.monthIndex);
        if (monthCompare != 0) return monthCompare;
        return a.sequenceOrder.compareTo(b.sequenceOrder);
      });
  }

  /// Applies credits in strict chronological FIFO order.
  static ({
    List<SavingsUnit> units,
    int creditsMillimes,
    List<String> matchedUnitIds,
  }) applyCreditMatching({
    required List<SavingsUnit> units,
    required int creditsMillimes,
  }) {
    var credits = creditsMillimes;
    final matchedIds = <String>[];
    final updated = units.map((u) => u.copyWith()).toList();
    final byId = {for (final u in updated) u.id: u};

    while (credits > 0) {
      final orderedPending = updated
          .where((u) => u.status == UnitStatus.pending)
          .toList()
        ..sort((a, b) {
          final monthCompare = a.monthIndex.compareTo(b.monthIndex);
          if (monthCompare != 0) return monthCompare;
          return a.sequenceOrder.compareTo(b.sequenceOrder);
        });

      if (orderedPending.isEmpty) {
        break;
      }

      final earliestMonth = orderedPending.first.monthIndex;
      final candidatesInMonth = orderedPending
          .where((u) => u.monthIndex == earliestMonth)
          .toList();

      var matchedAny = false;
      for (final candidate in candidatesInMonth) {
        if (candidate.valueMillimes <= credits) {
          final unit = byId[candidate.id]!;
          unit.status = UnitStatus.done;
          credits -= unit.valueMillimes;
          matchedIds.add(unit.id);
          matchedAny = true;
          break;
        }
      }

      if (!matchedAny) {
        break;
      }
    }

    return (
      units: updated,
      creditsMillimes: credits,
      matchedUnitIds: matchedIds,
    );
  }

  static bool matchesSearchQuery(SavingsUnit unit, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return true;

    final cleaned = trimmed.toLowerCase().replaceAll('dt', '').replaceAll(' ', '');

    final queryMillimes = int.tryParse(cleaned);
    if (queryMillimes != null && queryMillimes == unit.valueMillimes) {
      return true;
    }

    final dinarDouble = double.tryParse(cleaned.replaceAll(',', '.'));
    if (dinarDouble != null) {
      final calculatedMillimes = (dinarDouble * AppConstants.millimesPerDinar).round();
      if (calculatedMillimes == unit.valueMillimes) {
        return true;
      }
    }

    return false;
  }
}
