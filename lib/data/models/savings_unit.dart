import 'unit_status.dart';

class SavingsUnit {
  SavingsUnit({
    required this.id,
    required this.valueMillimes,
    required this.monthIndex,
    required this.sequenceOrder,
    this.status = UnitStatus.pending,
  });

  final String id;
  final int valueMillimes;
  final int monthIndex;
  final int sequenceOrder;
  UnitStatus status;

  SavingsUnit copyWith({UnitStatus? status}) {
    return SavingsUnit(
      id: id,
      valueMillimes: valueMillimes,
      monthIndex: monthIndex,
      sequenceOrder: sequenceOrder,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'valueMillimes': valueMillimes,
        'monthIndex': monthIndex,
        'sequenceOrder': sequenceOrder,
        'status': status.name,
      };

  factory SavingsUnit.fromJson(Map<String, dynamic> json) {
    return SavingsUnit(
      id: json['id'] as String,
      valueMillimes: json['valueMillimes'] as int,
      monthIndex: json['monthIndex'] as int,
      sequenceOrder: json['sequenceOrder'] as int? ?? 0,
      status: UnitStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => UnitStatus.pending,
      ),
    );
  }
}
