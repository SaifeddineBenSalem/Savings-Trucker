import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../../data/models/app_data.dart';

class StorageService {
  StorageService(this._box);

  final Box<dynamic> _box;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox('savings_tracker');
    return StorageService(box);
  }

  AppData? load() {
    final raw = _box.get(AppConstants.storageKey);
    if (raw == null) return null;
    return AppData.fromJson(Map<String, dynamic>.from(jsonDecode(raw as String) as Map));
  }

  Future<void> save(AppData data) async {
    await _box.put(AppConstants.storageKey, jsonEncode(data.toJson()));
  }

  Future<void> clear() async {
    await _box.delete(AppConstants.storageKey);
  }
}
