import 'package:flutter_test/flutter_test.dart';

import 'package:savings_tracker/core/constants.dart';
import 'package:savings_tracker/core/utils/currency_formatter.dart';
import 'package:savings_tracker/data/models/savings_unit.dart';
import 'package:savings_tracker/data/models/unit_status.dart';
import 'package:savings_tracker/domain/services/savings_engine.dart';

void main() {
  group('CurrencyFormatter', () {
    test('parses dinars,millimes format', () {
      expect(CurrencyFormatter.parseTargetInput('123,200'), 123200);
      expect(CurrencyFormatter.parseTargetInput('10,000'), 10000);
    });

    test('parses dinars only', () {
      expect(CurrencyFormatter.parseTargetInput('50'), 50000);
    });

    test('parses credit input', () {
      expect(CurrencyFormatter.parseCreditInput('300'), 300);
      expect(CurrencyFormatter.parseCreditInput('1.5'), 1500);
      expect(CurrencyFormatter.parseCreditInput('2dt'), 2000);
      expect(CurrencyFormatter.parseCreditInput('500'), 500);
    });
  });

  group('SavingsEngine', () {
    test('isTargetRepresentable requires multiples of 100', () {
      expect(SavingsEngine.isTargetRepresentable(100), isTrue);
      expect(SavingsEngine.isTargetRepresentable(500), isTrue);
      expect(SavingsEngine.isTargetRepresentable(123200), isTrue);
      expect(SavingsEngine.isTargetRepresentable(123233), isFalse);
    });

    test('generateUnits sums exactly to target', () {
      for (final target in [100, 200, 500, 1200, 5000, 123200, 50000]) {
        final units = SavingsEngine.generateUnits(target);
        final sum = units.fold<int>(0, (a, b) => a + b);
        expect(sum, target, reason: 'Target $target should match unit sum');
      }
    });

    test('generateUnits only uses allowed denomination values', () {
      for (final target in [10000, 25500, 123200, 500000]) {
        final units = SavingsEngine.generateUnits(target);
        for (final unit in units) {
          expect(
            SavingsEngine.isValidUnitValue(unit),
            isTrue,
            reason: 'Invalid unit value: $unit for target $target',
          );
          expect(unit, lessThanOrEqualTo(AppConstants.maxUnitMillimes));
        }
      }
    });

    test('generateUnits can produce 500 millime units', () {
      final units = SavingsEngine.generateUnits(5000);
      expect(units.any((u) => u == 500), isTrue);
    });

    test('credit matching follows FIFO month order', () {
      final units = [
        SavingsUnit(
          id: 'm2',
          valueMillimes: 200,
          monthIndex: 1,
          sequenceOrder: 1,
        ),
        SavingsUnit(
          id: 'm1',
          valueMillimes: 500,
          monthIndex: 0,
          sequenceOrder: 0,
        ),
        SavingsUnit(
          id: 'm1b',
          valueMillimes: 100,
          monthIndex: 0,
          sequenceOrder: 2,
        ),
      ];

      final result = SavingsEngine.applyCreditMatching(
        units: units,
        creditsMillimes: 600,
      );

      expect(result.matchedUnitIds, ['m1', 'm1b']);
      expect(result.creditsMillimes, 0);
      expect(
        result.units.firstWhere((u) => u.id == 'm1').status,
        UnitStatus.done,
      );
      expect(
        result.units.firstWhere((u) => u.id == 'm2').status,
        UnitStatus.pending,
      );
    });

    test('credit matching continues FIFO within same month', () {
      final units = [
        SavingsUnit(
          id: 'a',
          valueMillimes: 200,
          monthIndex: 0,
          sequenceOrder: 0,
        ),
        SavingsUnit(
          id: 'b',
          valueMillimes: 300,
          monthIndex: 0,
          sequenceOrder: 1,
        ),
      ];

      final result = SavingsEngine.applyCreditMatching(
        units: units,
        creditsMillimes: 800,
      );

      expect(result.matchedUnitIds, ['a', 'b']);
      expect(result.creditsMillimes, 300);
    });

    test('credit matching blocks later months if earlier month has pending unit', () {
      final units = [
        SavingsUnit(
          id: 'a',
          valueMillimes: 500,
          monthIndex: 0,
          sequenceOrder: 0,
        ),
        SavingsUnit(
          id: 'b',
          valueMillimes: 200,
          monthIndex: 1,
          sequenceOrder: 0,
        ),
      ];

      final result = SavingsEngine.applyCreditMatching(
        units: units,
        creditsMillimes: 200,
      );

      expect(result.matchedUnitIds, isEmpty);
      expect(result.creditsMillimes, 200);
      expect(result.units[0].status, UnitStatus.pending);
      expect(result.units[1].status, UnitStatus.pending);
    });

    test('credit matching allows matching subsequent units in the earliest month', () {
      final units = [
        SavingsUnit(
          id: 'a',
          valueMillimes: 500,
          monthIndex: 0,
          sequenceOrder: 0,
        ),
        SavingsUnit(
          id: 'b',
          valueMillimes: 200,
          monthIndex: 0,
          sequenceOrder: 1,
        ),
      ];

      final result = SavingsEngine.applyCreditMatching(
        units: units,
        creditsMillimes: 200,
      );

      expect(result.matchedUnitIds, ['b']);
      expect(result.creditsMillimes, 0);
      expect(result.units[0].status, UnitStatus.pending);
      expect(result.units[1].status, UnitStatus.done);
    });

    test('search matches exact amounts and handles different formats', () {
      final unit1500 = SavingsUnit(id: 'x', valueMillimes: 1500, monthIndex: 0, sequenceOrder: 0);
      final unit200 = SavingsUnit(id: 'y', valueMillimes: 200, monthIndex: 0, sequenceOrder: 1);

      expect(SavingsEngine.matchesSearchQuery(unit1500, '1500'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit1500, '1,500'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit1500, '500'), isFalse);
      expect(SavingsEngine.matchesSearchQuery(unit200, '200'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit1500, '200'), isFalse);
    });

    test('search matches decimal dinar values', () {
      final unit1500 = SavingsUnit(id: 'x', valueMillimes: 1500, monthIndex: 0, sequenceOrder: 0);
      final unit2000 = SavingsUnit(id: 'y', valueMillimes: 2000, monthIndex: 0, sequenceOrder: 1);

      expect(SavingsEngine.matchesSearchQuery(unit1500, '1.5'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit1500, '1.500'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit2000, '2'), isTrue);
      expect(SavingsEngine.matchesSearchQuery(unit1500, '2'), isFalse);
    });

    test('distributeUnits assigns sequence order', () {
      final values = SavingsEngine.generateUnits(50000);
      final units = SavingsEngine.distributeUnits(values);

      expect(units.length, values.length);
      expect(units.map((u) => u.sequenceOrder).toSet().length, units.length);
    });
  });
}
