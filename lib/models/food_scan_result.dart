import 'nutrition_data.dart';

class PredictionCandidate {
  const PredictionCandidate({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  factory PredictionCandidate.fromMap(Map<dynamic, dynamic> map) {
    return PredictionCandidate(
      label: map['label'] as String? ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
    };
  }
}

class FoodScanResult {
  const FoodScanResult({
    required this.id,
    required this.foodName,
    required this.confidence,
    this.topPredictions = const [],
    required this.healthScore,
    required this.nutrition,
    this.avoidFor = const [],
    required this.recommendedIntake,
    required this.riskWarnings,
    required this.scannedAt,
  });

  final String id;
  final String foodName;
  final double confidence;
  final List<PredictionCandidate> topPredictions;
  final int healthScore;
  final NutritionData nutrition;
  final List<String> avoidFor;
  final String recommendedIntake;
  final List<String> riskWarnings;
  final DateTime scannedAt;

  factory FoodScanResult.fromMap(Map<dynamic, dynamic> map) {
    return FoodScanResult(
      id: map['id'] as String? ?? '',
      foodName: map['foodName'] as String? ?? 'Unknown Food',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      topPredictions: ((map['topPredictions'] as List?) ?? const [])
          .map((item) => PredictionCandidate.fromMap(Map<dynamic, dynamic>.from(item as Map)))
          .toList(),
      healthScore: (map['healthScore'] as num?)?.toInt() ?? 0,
      nutrition: NutritionData.fromMap(
        Map<String, dynamic>.from(map['nutrition'] as Map? ?? {}),
      ),
      avoidFor: List<String>.from(map['avoidFor'] as List? ?? const []),
      recommendedIntake: map['recommendedIntake'] as String? ?? 'Consume in moderation.',
      riskWarnings: List<String>.from(map['riskWarnings'] as List? ?? const []),
      scannedAt: DateTime.tryParse(map['scannedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'confidence': confidence,
      'topPredictions': topPredictions.map((e) => e.toMap()).toList(),
      'healthScore': healthScore,
      'nutrition': nutrition.toMap(),
      'avoidFor': avoidFor,
      'recommendedIntake': recommendedIntake,
      'riskWarnings': riskWarnings,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  FoodScanResult copyWith({
    String? id,
    String? foodName,
    double? confidence,
    List<PredictionCandidate>? topPredictions,
    int? healthScore,
    NutritionData? nutrition,
    List<String>? avoidFor,
    String? recommendedIntake,
    List<String>? riskWarnings,
    DateTime? scannedAt,
  }) {
    return FoodScanResult(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      confidence: confidence ?? this.confidence,
      topPredictions: topPredictions ?? this.topPredictions,
      healthScore: healthScore ?? this.healthScore,
      nutrition: nutrition ?? this.nutrition,
      avoidFor: avoidFor ?? this.avoidFor,
      recommendedIntake: recommendedIntake ?? this.recommendedIntake,
      riskWarnings: riskWarnings ?? this.riskWarnings,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}
