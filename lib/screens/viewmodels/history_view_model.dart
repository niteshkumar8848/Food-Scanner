import 'package:flutter/material.dart';

import '../../models/food_scan_result.dart';
import '../../repositories/food_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({required FoodRepository repository}) : _repository = repository;

  final FoodRepository _repository;

  List<FoodScanResult> _allItems = [];
  bool _isLoading = false;
  String _query = '';
  HistoryFilter _filter = HistoryFilter.all;

  List<FoodScanResult> get items {
    return _allItems.where((item) {
      final nameMatch = item.foodName.toLowerCase().contains(_query.toLowerCase());
      final filterMatch = switch (_filter) {
        HistoryFilter.all => true,
        HistoryFilter.healthy => item.healthScore >= 1,
        HistoryFilter.risky => item.healthScore <= -1,
      };
      return nameMatch && filterMatch;
    }).toList();
  }

  bool get isLoading => _isLoading;
  HistoryFilter get filter => _filter;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _allItems = await _repository.getHistory();
    _isLoading = false;
    notifyListeners();
  }

  void setQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setFilter(HistoryFilter filter) {
    _filter = filter;
    notifyListeners();
  }
}

enum HistoryFilter { all, healthy, risky }
