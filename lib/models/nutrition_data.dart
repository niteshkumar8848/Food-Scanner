class NutritionData {
  const NutritionData({
    required this.calories,
    required this.sugar,
    required this.fat,
    required this.saturatedFat,
    required this.protein,
    required this.fiber,
    required this.sodium,
  });

  final double calories;
  final double sugar;
  final double fat;
  final double saturatedFat;
  final double protein;
  final double fiber;
  final double sodium;

  factory NutritionData.fromOpenFoodFacts(Map<String, dynamic> json) {
    final nutriments = (json['nutriments'] as Map<String, dynamic>? ?? {});
    double readNum(String key) {
      final value = nutriments[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return NutritionData(
      calories: readNum('energy-kcal_100g'),
      sugar: readNum('sugars_100g'),
      fat: readNum('fat_100g'),
      saturatedFat: readNum('saturated-fat_100g'),
      protein: readNum('proteins_100g'),
      fiber: readNum('fiber_100g'),
      sodium: readNum('sodium_100g'),
    );
  }

  factory NutritionData.fromMap(Map<String, dynamic> map) {
    return NutritionData(
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      saturatedFat: (map['saturatedFat'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'sugar': sugar,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'protein': protein,
      'fiber': fiber,
      'sodium': sodium,
    };
  }
}
