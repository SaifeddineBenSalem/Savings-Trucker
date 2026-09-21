import '../constants.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String formatMillimes(int millimes, {bool compact = false}) {
    final dinars = millimes ~/ AppConstants.millimesPerDinar;
    final remainder = millimes % AppConstants.millimesPerDinar;

    if (remainder == 0) {
      return compact ? '$dinars DT' : '$dinars DT';
    }

    final padded = remainder.toString().padLeft(3, '0');
    return compact
        ? '$dinars,$padded'
        : '$dinars DT $padded millimes';
  }

  static String formatInputDisplay(int millimes) {
    final dinars = millimes ~/ AppConstants.millimesPerDinar;
    final remainder = millimes % AppConstants.millimesPerDinar;
    return '$dinars,${remainder.toString().padLeft(3, '0')}';
  }

  static int? parseTargetInput(String input) {
    final cleaned = input.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length != 2) return null;
      final dinars = int.tryParse(parts[0]);
      final millimes = int.tryParse(parts[1]);
      if (dinars == null || millimes == null) return null;
      if (dinars < 0 || millimes < 0 || millimes >= AppConstants.millimesPerDinar) {
        return null;
      }
      return dinars * AppConstants.millimesPerDinar + millimes;
    }

    final dinarsOnly = int.tryParse(cleaned);
    if (dinarsOnly == null || dinarsOnly < 0) return null;
    return dinarsOnly * AppConstants.millimesPerDinar;
  }

  static int? parseCreditInput(String input) {
    final cleaned = input.trim().replaceAll(' ', '').toLowerCase();
    if (cleaned.isEmpty) return null;

    if (cleaned.endsWith('dt')) {
      final value = cleaned.replaceAll('dt', '').trim();
      final dinars = double.tryParse(value.replaceAll(',', '.'));
      if (dinars == null || dinars < 0) return null;
      return (dinars * AppConstants.millimesPerDinar).round();
    }

    if (cleaned.contains(',')) {
      return parseTargetInput(cleaned);
    }

    final asNumber = double.tryParse(cleaned.replaceAll(',', '.'));
    if (asNumber == null || asNumber < 0) return null;

    if (cleaned.contains('.')) {
      return (asNumber * AppConstants.millimesPerDinar).round();
    }

    return asNumber.round();
  }
}
