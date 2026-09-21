class AppConstants {
  static const int monthsCount = 14;
  static const int millimesPerDinar = 1000;
  static const int itemsPerPage = 10;
  static const String resetPassword = '1234';
  static const String storageKey = 'savings_app_data';

  /// Base collectible denominations (millimes).
  static const List<int> unitDenominationsMillimes = [
    5000, // 5 DT
    2000, // 2 DT
    1000, // 1 DT
    500, // 500 millimes
    200, // 200 millimes
    100, // 100 millimes
  ];

  static const int maxUnitMillimes = 5000;
}
