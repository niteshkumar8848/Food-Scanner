@Deprecated('Use PredictionResult in services/food_ai_service.dart')
class AiDetectionResult {
  const AiDetectionResult({
    required this.foodName,
    required this.confidence,
  });

  final String foodName;
  final double confidence;
}
