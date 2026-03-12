import 'package:hive/hive.dart';

import '../models/food_scan_result.dart';

class StorageService {
  static const _historyBoxName = 'scan_history_box';

  late Box _historyBox;

  Future<void> initialize() async {
    _historyBox = await Hive.openBox(_historyBoxName);
  }

  List<FoodScanResult> getHistory() {
    return _historyBox.values
        .map((raw) => FoodScanResult.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
  }

  Future<void> saveScanResult(FoodScanResult result) async {
    // Local-only persistence: scan history is written only to on-device Hive storage.
    await _historyBox.add(result.toMap());
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
  }
}
