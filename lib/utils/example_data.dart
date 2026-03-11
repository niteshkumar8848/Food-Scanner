import '../models/food_scan_result.dart';
import '../models/nutrition_data.dart';

class ExampleData {
  static final List<Map<String, dynamic>> dummyFoods = [
    {
      'name': 'Pizza',
      'nutrition': const NutritionData(
        calories: 266,
        sugar: 3.8,
        fat: 10,
        saturatedFat: 4.6,
        protein: 11,
        fiber: 2.3,
        sodium: 0.64,
      ),
    },
    {
      'name': 'Burger',
      'nutrition': const NutritionData(
        calories: 295,
        sugar: 5.2,
        fat: 14,
        saturatedFat: 5.2,
        protein: 16,
        fiber: 1.7,
        sodium: 0.72,
      ),
    },
    {
      'name': 'Salad',
      'nutrition': const NutritionData(
        calories: 80,
        sugar: 2.4,
        fat: 3,
        saturatedFat: 0.5,
        protein: 4,
        fiber: 5.8,
        sodium: 0.18,
      ),
    },
    {
      'name': 'Sushi',
      'nutrition': const NutritionData(
        calories: 130,
        sugar: 1.6,
        fat: 1.8,
        saturatedFat: 0.4,
        protein: 8.3,
        fiber: 0.6,
        sodium: 0.44,
      ),
    },
  ];

  static final List<FoodScanResult> historySeed = [
    FoodScanResult(
      id: 'seed-1',
      foodName: 'Greek Salad',
      confidence: 0.91,
      healthScore: 6,
      nutrition: const NutritionData(
        calories: 98,
        sugar: 2,
        fat: 6,
        saturatedFat: 1,
        protein: 4,
        fiber: 5,
        sodium: 0.32,
      ),
      avoidFor: const ['People with dairy sensitivity (if feta used)'],
      recommendedIntake: 'Good for regular meals in moderate portions.',
      riskWarnings: const ['Contains sodium from dressing'],
      scannedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    FoodScanResult(
      id: 'seed-2',
      foodName: 'Cheese Burger',
      confidence: 0.87,
      healthScore: -4,
      nutrition: const NutritionData(
        calories: 310,
        sugar: 5,
        fat: 15,
        saturatedFat: 6,
        protein: 17,
        fiber: 1,
        sodium: 0.77,
      ),
      avoidFor: const ['People with hypertension', 'People with high cholesterol'],
      recommendedIntake: 'Consume occasionally with high-fiber side options.',
      riskWarnings: const ['High saturated fat', 'High sodium'],
      scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];
}
