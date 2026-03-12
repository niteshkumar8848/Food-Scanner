import 'dart:convert';
import 'dart:io';

class Nutrition {
  const Nutrition({
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

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'sugar': sugar,
        'fat': fat,
        'saturatedFat': saturatedFat,
        'protein': protein,
        'fiber': fiber,
        'sodium': sodium,
      };
}

void main() {
  final labelsFile = File('assets/models/labels.txt');
  if (!labelsFile.existsSync()) {
    stderr.writeln('labels.txt not found at assets/models/labels.txt');
    exit(1);
  }

  final labels = labelsFile
      .readAsLinesSync()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final items = labels.map((label) {
    final p = _buildProfile(label);
    return {
      'label': label,
      'healthScore': p.healthScore,
      'nutrition': p.nutrition.toJson(),
      'avoidFor': p.avoidFor,
    };
  }).toList();

  final output = {
    'version': 1,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'source': 'assets/models/labels.txt',
    'foods': items,
  };

  final outFile = File('assets/data/food_database.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln('Generated ${items.length} food records at ${outFile.path}');
}

class _Profile {
  const _Profile({
    required this.healthScore,
    required this.nutrition,
    required this.avoidFor,
  });

  final int healthScore;
  final Nutrition nutrition;
  final List<String> avoidFor;
}

_Profile _buildProfile(String label) {
  final l = label.toLowerCase();
  final seed = l.codeUnits.fold<int>(0, (a, b) => a + b);

  bool has(List<String> keys) => keys.any(l.contains);

  final isDessert = has(['cake', 'brownie', 'donut', 'ice cream', 'pudding', 'cup cake', 'cup cakes', 'muffin', 'cheesecake']);
  final isFastFood = has(['burger', 'pizza', 'hot dog', 'french fries', 'fried', 'sandwich', 'club sandwich', 'fish and chips']);
  final isFruit = has(['apple', 'apricot', 'banana', 'blackberry', 'blueberry', 'cherry', 'coconut', 'dates', 'fig', 'grape', 'grapefruit', 'kiwi', 'lemon', 'mango', 'melon', 'orange', 'peach', 'pear', 'pineapple', 'plum', 'pomegranate', 'raspberry', 'strawberry', 'tangerine', 'watermelon']);
  final isVegetable = has(['broccoli', 'cabbage', 'carrot', 'cauliflower', 'cucumber', 'eggplant', 'garlic', 'ginger', 'lettuce', 'mushroom', 'onion', 'peas', 'pepper', 'pumpkin', 'radish', 'spinach', 'sweet potato', 'tomato', 'okra', 'beet', 'corn']);
  final isProtein = has(['chicken', 'beef', 'steak', 'lamb', 'egg', 'eggs', 'meatball', 'sausage', 'hummus', 'lentil', 'chickpea', 'falafel']);
  final isSoupDish = has(['soup', 'dish', 'rice', 'porridge', 'dumplings', 'samosa', 'spring rolls', 'curry']);

  if (isDessert) {
    final n = Nutrition(
      calories: 320 + (seed % 40),
      sugar: 24 + (seed % 8).toDouble(),
      fat: 15 + (seed % 6).toDouble(),
      saturatedFat: 7 + (seed % 3).toDouble(),
      protein: 4 + (seed % 3).toDouble(),
      fiber: 1 + (seed % 2).toDouble(),
      sodium: 0.26 + ((seed % 30) / 100),
    );
    return _Profile(
      healthScore: -7 + (seed % 3),
      nutrition: n,
      avoidFor: const [
        'Diabetes mellitus',
        'Obesity or active weight-loss treatment',
        'Hypertriglyceridemia',
      ],
    );
  }

  if (isFastFood) {
    final n = Nutrition(
      calories: 280 + (seed % 80),
      sugar: 5 + (seed % 6).toDouble(),
      fat: 14 + (seed % 8).toDouble(),
      saturatedFat: 5 + (seed % 4).toDouble(),
      protein: 10 + (seed % 8).toDouble(),
      fiber: 2 + (seed % 3).toDouble(),
      sodium: 0.65 + ((seed % 35) / 100),
    );
    return _Profile(
      healthScore: -6 + (seed % 4),
      nutrition: n,
      avoidFor: const [
        'Hypertension',
        'Hypercholesterolemia or dyslipidemia',
        'Sodium-restricted diets',
      ],
    );
  }

  if (isFruit) {
    final n = Nutrition(
      calories: 50 + (seed % 20),
      sugar: 8 + (seed % 6).toDouble(),
      fat: 0.2 + ((seed % 4) / 10),
      saturatedFat: 0.05 + ((seed % 3) / 20),
      protein: 0.5 + ((seed % 5) / 2),
      fiber: 2 + (seed % 4).toDouble(),
      sodium: 0.005 + ((seed % 3) / 1000),
    );
    return _Profile(
      healthScore: 7 + (seed % 3),
      nutrition: n,
      avoidFor: const [
        'Hereditary fructose intolerance',
        'Diabetes mellitus if carbohydrate portions are not controlled',
      ],
    );
  }

  if (isVegetable) {
    final n = Nutrition(
      calories: 25 + (seed % 25),
      sugar: 2 + (seed % 3).toDouble(),
      fat: 0.2 + ((seed % 4) / 10),
      saturatedFat: 0.03 + ((seed % 3) / 30),
      protein: 1.5 + ((seed % 6) / 2),
      fiber: 3 + (seed % 4).toDouble(),
      sodium: 0.01 + ((seed % 4) / 100),
    );
    return _Profile(
      healthScore: 8 + (seed % 3),
      nutrition: n,
      avoidFor: const [
        'Documented allergy to this vegetable',
      ],
    );
  }

  if (isProtein) {
    final n = Nutrition(
      calories: 140 + (seed % 70),
      sugar: 0.5 + ((seed % 4) / 2),
      fat: 6 + (seed % 7).toDouble(),
      saturatedFat: 2 + (seed % 4).toDouble(),
      protein: 14 + (seed % 10).toDouble(),
      fiber: 0.5 + ((seed % 3) / 2),
      sodium: 0.18 + ((seed % 25) / 100),
    );
    return _Profile(
      healthScore: 2 + (seed % 5),
      nutrition: n,
      avoidFor: const [
        'Chronic kidney disease requiring protein restriction',
        'Hyperuricemia or gout',
      ],
    );
  }

  if (isSoupDish) {
    final n = Nutrition(
      calories: 120 + (seed % 80),
      sugar: 2 + (seed % 4).toDouble(),
      fat: 4 + (seed % 5).toDouble(),
      saturatedFat: 1.2 + ((seed % 4) / 2),
      protein: 5 + (seed % 7).toDouble(),
      fiber: 2 + (seed % 4).toDouble(),
      sodium: 0.35 + ((seed % 25) / 100),
    );
    return _Profile(
      healthScore: -1 + (seed % 6),
      nutrition: n,
      avoidFor: const [
        'Sodium-restricted diets',
      ],
    );
  }

  final n = Nutrition(
    calories: 130 + (seed % 80),
    sugar: 3 + (seed % 6).toDouble(),
    fat: 5 + (seed % 8).toDouble(),
    saturatedFat: 1.5 + ((seed % 5) / 2),
    protein: 5 + (seed % 8).toDouble(),
    fiber: 2 + (seed % 4).toDouble(),
    sodium: 0.2 + ((seed % 25) / 100),
  );
  return _Profile(
    healthScore: -2 + (seed % 6),
    nutrition: n,
    avoidFor: const [
      'Confirmed allergy to this food',
      'Condition-specific therapeutic diets',
    ],
  );
}
