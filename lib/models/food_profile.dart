import 'nutrition_data.dart';

class FoodProfile {
  const FoodProfile({
    required this.label,
    required this.healthScore,
    required this.nutrition,
    required this.avoidFor,
  });

  final String label;
  final int healthScore;
  final NutritionData nutrition;
  final List<String> avoidFor;

  factory FoodProfile.fromMap(Map<String, dynamic> map) {
    return FoodProfile(
      label: (map['label'] as String? ?? '').trim(),
      healthScore: (map['healthScore'] as num?)?.toInt().clamp(-10, 10) ?? 0,
      nutrition: NutritionData.fromMap(
        Map<String, dynamic>.from(map['nutrition'] as Map? ?? {}),
      ),
      avoidFor: List<String>.from(map['avoidFor'] as List? ?? const []),
    );
  }
}
