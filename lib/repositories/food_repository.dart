import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/food_scan_result.dart';
import '../services/food_ai_service.dart';
import '../services/nutrition_service.dart';
import '../services/storage_service.dart';
import '../utils/health_score_calculator.dart';

abstract class FoodRepository {
  Future<FoodScanResult> scanFood(Uint8List imageBytes);
  Future<FoodScanResult> scanDebugAsset(String assetPath);
  Future<List<FoodScanResult>> getHistory();
}

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl({
    required FoodAiService aiService,
    required NutritionService nutritionService,
    required StorageService storageService,
  })  : _aiService = aiService,
        _nutritionService = nutritionService,
        _storageService = storageService;

  final FoodAiService _aiService;
  final NutritionService _nutritionService;
  final StorageService _storageService;

  @override
  Future<FoodScanResult> scanFood(Uint8List imageBytes) async {
    try {
      return await _runPipeline(() => _aiService.classifyImageBytes(imageBytes));
    } catch (e) {
      if (!_isUnclearError(e)) rethrow;

      final retryInputs = await compute(_buildEnhancedRetryInputs, imageBytes);
      for (final enhancedBytes in retryInputs.take(3)) {
        try {
          return await _runPipeline(() => _aiService.classifyImageBytes(enhancedBytes));
        } catch (inner) {
          if (!_isUnclearError(inner)) rethrow;
        }
      }

      throw StateError('Image unclear. Please retake photo.');
    }
  }

  @override
  Future<FoodScanResult> scanDebugAsset(String assetPath) async {
    return _runPipeline(() => _aiService.classifyAssetImage(assetPath));
  }

  Future<FoodScanResult> _runPipeline(
    Future<List<PredictionResult>> Function() classifier,
  ) async {
    final predictions = await classifier().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw StateError('AI detection timed out. Please try again.'),
    );
    final top = _aiService.getTopPrediction(predictions);
    final second = predictions.length > 1 ? predictions[1].confidence : 0.0;
    final margin = top.confidence - second;

    if (top.confidence < 0.22) {
      throw StateError('Image unclear. Please retake photo.');
    }

    final profile = await _nutritionService.fetchProfile(top.label);
    final scoreDetails = HealthScoreCalculator.evaluate(profile.nutrition);

    final result = FoodScanResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      foodName: profile.label,
      confidence: top.confidence,
      topPredictions: predictions
          .take(3)
          .map((p) => PredictionCandidate(label: p.label, confidence: p.confidence))
          .toList(),
      healthScore: profile.healthScore,
      nutrition: profile.nutrition,
      avoidFor: profile.avoidFor,
      recommendedIntake: _buildRecommendation(
        scoreRecommendation: HealthScoreCalculator.recommendation(profile.healthScore),
        confidence: top.confidence,
        margin: margin,
      ),
      riskWarnings: _buildWarnings(
        baseWarnings: scoreDetails.warnings,
        confidence: top.confidence,
        margin: margin,
      ),
      scannedAt: DateTime.now(),
    );

    await _storageService.saveScanResult(result);
    return result;
  }

  @override
  Future<List<FoodScanResult>> getHistory() async {
    return _storageService.getHistory();
  }

  String _buildRecommendation({
    required String scoreRecommendation,
    required double confidence,
    required double margin,
  }) {
    if (confidence < 0.70 || margin < 0.12) {
      return 'Model confidence is moderate. Verify visually. $scoreRecommendation';
    }
    return scoreRecommendation;
  }

  List<String> _buildWarnings({
    required List<String> baseWarnings,
    required double confidence,
    required double margin,
  }) {
    final warnings = [...baseWarnings];
    if (confidence < 0.70 || margin < 0.12) {
      warnings.add(
        'AI confidence is moderate (${(confidence * 100).toStringAsFixed(1)}%). '
        'Retake scan in better light for more reliable detection.',
      );
    }
    return warnings;
  }

  bool _isUnclearError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('image unclear') ||
        message.contains('blurry') ||
        message.contains('retake photo');
  }
}

List<Uint8List> _buildEnhancedRetryInputs(Uint8List originalBytes) {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) return const [];

  img.Image clone() => img.Image.from(decoded);

  final v1 = img.adjustColor(
    clone(),
    contrast: 1.18,
    saturation: 1.06,
    brightness: 1.03,
  );
  img.convolution(v1, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1);

  final v2 = img.adjustColor(
    clone(),
    contrast: 1.1,
    gamma: 0.95,
    exposure: 0.15,
  );
  img.convolution(v2, filter: [1, 1, 1, 1, 1, 1, 1, 1, 1], div: 9);
  img.convolution(v2, filter: [-1, -1, -1, -1, 9, -1, -1, -1, -1], div: 1);

  final v3 = img.adjustColor(
    clone(),
    contrast: 1.28,
    brightness: 1.05,
    saturation: 1.04,
  );
  img.convolution(v3, filter: [0, -1, 0, -1, 6, -1, 0, -1, 0], div: 1);

  return [
    Uint8List.fromList(img.encodeJpg(v1, quality: 95)),
    Uint8List.fromList(img.encodeJpg(v2, quality: 95)),
    Uint8List.fromList(img.encodeJpg(v3, quality: 95)),
  ];
}
