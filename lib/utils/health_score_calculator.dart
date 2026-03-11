import 'package:flutter/material.dart';

import '../models/nutrition_data.dart';

class HealthScoreDetails {
  const HealthScoreDetails({required this.score, required this.warnings});

  final int score;
  final List<String> warnings;
}

class HealthScoreCalculator {
  static HealthScoreDetails evaluate(NutritionData nutritionData) {
    final score = calculateHealthScore(nutritionData);
    final warnings = <String>[];

    // OpenFoodFacts sodium is often in grams. Convert to mg for rule checks.
    final sodiumMg = nutritionData.sodium * 1000;

    if (nutritionData.sugar > 20) warnings.add('High sugar (>20g)');
    if (nutritionData.saturatedFat > 5) warnings.add('High saturated fat (>5g)');
    if (sodiumMg > 500) warnings.add('High sodium (>500mg)');

    return HealthScoreDetails(score: score, warnings: warnings);
  }

  static int calculateHealthScore(NutritionData nutritionData) {
    int score = 0;
    final sodiumMg = nutritionData.sodium * 1000;

    if (nutritionData.sugar > 20) score -= 3;
    if (nutritionData.saturatedFat > 5) score -= 3;
    if (sodiumMg > 500) score -= 2;
    if (nutritionData.fiber > 4) score += 2;
    if (nutritionData.protein > 8) score += 2;

    return score.clamp(-10, 10);
  }

  static Color scoreColor(int score, BuildContext context) {
    if (score >= 6) return Colors.green;
    if (score >= 1) return Colors.lightGreen;
    if (score >= -3) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  static String recommendation(int score) {
    if (score >= 6) return 'Great choice for regular intake.';
    if (score >= 1) return 'Decent choice. Keep portions balanced.';
    if (score >= -3) return 'Moderate option. Limit frequency.';
    return 'Low nutrition profile. Prefer healthier alternatives.';
  }
}

int calculateHealthScore(NutritionData nutritionData) {
  return HealthScoreCalculator.calculateHealthScore(nutritionData);
}
