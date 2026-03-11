import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/food_profile.dart';
import '../models/nutrition_data.dart';

class NutritionService {
  Map<String, FoodProfile>? _cache;

  Future<FoodProfile> fetchProfile(String foodName) async {
    final db = await _loadDatabase();
    final key = _normalize(foodName);

    if (db.containsKey(key)) {
      return db[key]!;
    }

    // Fuzzy fallback for predictions like "chicken burger" vs "hamburger".
    final found = db.entries.where((e) => key.contains(e.key) || e.key.contains(key)).toList();
    if (found.isNotEmpty) {
      return found.first.value;
    }

    // Safe default profile.
    return const FoodProfile(
      label: 'Unknown Food',
      healthScore: 0,
      nutrition: NutritionData(
        calories: 150,
        sugar: 4,
        fat: 6,
        saturatedFat: 2,
        protein: 6,
        fiber: 2,
        sodium: 0.2,
      ),
      avoidFor: [
        'People with specific food allergies',
      ],
    );
  }

  Future<NutritionData> fetchNutrition(String foodName) async {
    final profile = await fetchProfile(foodName);
    return profile.nutrition;
  }

  Future<Map<String, FoodProfile>> _loadDatabase() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/food_database.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final foods = (json['foods'] as List<dynamic>? ?? const []);

    final map = <String, FoodProfile>{};
    for (final item in foods) {
      final profile = FoodProfile.fromMap(Map<String, dynamic>.from(item as Map));
      map[_normalize(profile.label)] = profile;
    }

    _cache = map;
    return map;
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }
}
