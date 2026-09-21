import 'savings_unit.dart';
import 'unit_status.dart';

class AppData {
  AppData({
    required this.targetMillimes,
    required this.units,
    this.creditsMillimes = 0,
    this.unlockedBadges = const [],
  });

  final int targetMillimes;
  final List<SavingsUnit> units;
  final int creditsMillimes;
  final List<String> unlockedBadges;

  /// Completed units plus unmatched credit buffer count toward collected total.
  int get completedUnitsMillimes => units
      .where((u) => u.status == UnitStatus.done)
      .fold(0, (sum, u) => sum + u.valueMillimes);

  int get collectedMillimes => completedUnitsMillimes + creditsMillimes;

  int get remainingMillimes =>
      (targetMillimes - collectedMillimes).clamp(0, targetMillimes);

  double get progress =>
      targetMillimes == 0 ? 0 : (collectedMillimes / targetMillimes).clamp(0.0, 1.0);

  AppData copyWith({
    int? targetMillimes,
    List<SavingsUnit>? units,
    int? creditsMillimes,
    List<String>? unlockedBadges,
  }) {
    return AppData(
      targetMillimes: targetMillimes ?? this.targetMillimes,
      units: units ?? this.units,
      creditsMillimes: creditsMillimes ?? this.creditsMillimes,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetMillimes': targetMillimes,
        'units': units.map((u) => u.toJson()).toList(),
        'creditsMillimes': creditsMillimes,
        'unlockedBadges': unlockedBadges,
      };

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      targetMillimes: json['targetMillimes'] as int,
      units: (json['units'] as List<dynamic>)
          .map((e) => SavingsUnit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      creditsMillimes: json['creditsMillimes'] as int? ?? 0,
      unlockedBadges: (json['unlockedBadges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
