import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_preprocessing_service.dart';
import 'model_config.dart';

class PredictionResult {
  const PredictionResult({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;
}

class FoodAiService {
  FoodAiService({ImagePreprocessingService? preprocessingService})
      : _preprocessingService = preprocessingService ?? const ImagePreprocessingService();

  final ImagePreprocessingService _preprocessingService;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  String? _loadError;

  String? get loadError => _loadError;
  bool get isModelReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> loadModel() async {
    if (_interpreter != null && _labels.isNotEmpty) return;

    try {
      _interpreter = await _loadInterpreterWithFallbackPaths();
      final labelsRaw = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _loadError = null;
    } catch (e) {
      _loadError = 'Model loading failed: $e';
      _interpreter = null;
      _labels = const [];
    }
  }

  Future<Interpreter> _loadInterpreterWithFallbackPaths() async {
    const candidatePaths = [
      'assets/models/food_classifier.tflite',
      'models/food_classifier.tflite',
    ];

    Object? lastError;
    for (final path in candidatePaths) {
      try {
        return await Interpreter.fromAsset(path);
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('Unable to load model from known paths. Last error: $lastError');
  }

  Future<List<PredictionResult>> classifyImageBytes(Uint8List imageBytes) async {
    await loadModel();

    if (!isModelReady) {
      throw StateError(_loadError ?? 'Model is not ready.');
    }

    final interpreter = _interpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensors = interpreter.getOutputTensors();

    final inputShape = inputTensor.shape;
    if (inputShape.length != 4 || inputShape[3] != 3) {
      throw StateError('Model must use input shape [1,H,W,3]. Found: $inputShape');
    }

    final config = ModelConfig.fromInputTensor(inputTensor);
    final watch = Stopwatch()..start();

    final input = await _preprocessingService.preprocessImage(imageBytes, config);

    final outputs = <int, Object>{};
    for (int i = 0; i < outputTensors.length; i++) {
      outputs[i] = _buildOutputTensor(outputTensors[i].shape);
    }
    interpreter.runForMultipleInputs([input], outputs);

    List<double> decodedScores = const [];
    int selectedOutputIndex = -1;
    int minDiff = 1 << 30;
    for (int i = 0; i < outputTensors.length; i++) {
      final rawScores = _flattenToDoubleList(outputs[i]!);
      if (rawScores.isEmpty) continue;
      if (rawScores.length > 5000) continue;

      final scores = _decodeOutputIfQuantized(rawScores, outputTensors[i]);
      final diff = (scores.length - _labels.length).abs();
      if (diff < minDiff) {
        minDiff = diff;
        selectedOutputIndex = i;
        decodedScores = scores;
      }
    }

    if (decodedScores.isEmpty) {
      final shapes = outputTensors.map((t) => t.shape.toString()).join(', ');
      throw StateError('No valid classification output tensor found. Shapes: $shapes');
    }

    final probabilities = _softmaxIfNeeded(decodedScores);

    final results = <PredictionResult>[];
    final maxLen = probabilities.length < _labels.length ? probabilities.length : _labels.length;
    for (int i = 0; i < maxLen; i++) {
      results.add(PredictionResult(label: _labels[i], confidence: probabilities[i]));
    }
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    watch.stop();
    debugPrint(
      'Inference=${watch.elapsedMilliseconds}ms input=${config.inputWidth}x${config.inputHeight} '
      'quantized=${config.isQuantized} outIdx=$selectedOutputIndex',
    );

    return results.take(3).toList();
  }

  Future<List<PredictionResult>> classifyAssetImage(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    return classifyImageBytes(bytes.buffer.asUint8List());
  }

  PredictionResult getTopPrediction(List<PredictionResult> predictions) {
    if (predictions.isEmpty) {
      throw StateError('No predictions available.');
    }
    return predictions.first;
  }

  Object _buildOutputTensor(List<int> shape) {
    dynamic makeDim(int depth) {
      final length = shape[depth];
      if (depth == shape.length - 1) {
        return List<double>.filled(length, 0.0);
      }
      return List.generate(length, (_) => makeDim(depth + 1));
    }

    return makeDim(0);
  }

  List<double> _flattenToDoubleList(Object value) {
    if (value is num) return [value.toDouble()];
    if (value is List) {
      final out = <double>[];
      for (final child in value) {
        out.addAll(_flattenToDoubleList(child));
      }
      return out;
    }
    return const [];
  }

  List<double> _decodeOutputIfQuantized(List<double> scores, Tensor outputTensor) {
    final scale = outputTensor.params.scale;
    final zeroPoint = outputTensor.params.zeroPoint;
    if (outputTensor.type != TensorType.uint8 || scale == 0) {
      return scores;
    }
    return scores.map((q) => (q - zeroPoint) * scale).toList();
  }

  List<double> _softmaxIfNeeded(List<double> values) {
    if (values.isEmpty) return values;
    final sum = values.fold<double>(0, (a, b) => a + b);
    if (sum > 0.99 && sum < 1.01) {
      return values;
    }

    final maxLogit = values.reduce(math.max);
    final exps = values.map((v) => math.exp(v - maxLogit)).toList();
    final denom = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / denom).toList();
  }
}
