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

class _InferenceRun {
  const _InferenceRun({
    required this.probabilities,
    required this.topIndex,
    required this.config,
  });

  final List<double> probabilities;
  final int topIndex;
  final ModelConfig config;

  double get topConfidence => probabilities[topIndex];

  double get secondConfidence {
    if (probabilities.length < 2) return 0.0;
    double best = -double.infinity;
    double second = -double.infinity;
    for (final value in probabilities) {
      if (value > best) {
        second = best;
        best = value;
      } else if (value > second) {
        second = value;
      }
    }
    return second.isFinite ? second : 0.0;
  }
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
      _interpreter = await _loadInterpreterFromBundledAsset();
      final labelsRaw = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      _validateModelMetadata(_interpreter!, _labels);
      _loadError = null;
    } catch (e) {
      _loadError = 'Model loading failed: $e';
      _interpreter = null;
      _labels = const [];
    }
  }

  Future<Interpreter> _loadInterpreterFromBundledAsset() async {
    try {
      final modelData = await rootBundle.load('assets/models/food_classifier.tflite');
      final bytes = modelData.buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);
      return Interpreter.fromBuffer(bytes);
    } catch (e) {
      final message = e.toString();
      if (message.contains('Unable to create interpreter')) {
        throw StateError(
          'Unable to create interpreter for assets/models/food_classifier.tflite. '
          'The model may require a newer TensorFlow Lite runtime or Select TF Ops support. '
          'Original error: $e',
        );
      }
      throw StateError('Unable to load bundled model asset assets/models/food_classifier.tflite: $e');
    }
  }

  Future<List<PredictionResult>> classifyImageBytes(Uint8List imageBytes) async {
    await loadModel();

    if (!isModelReady) {
      throw StateError(_loadError ?? 'Model is not ready.');
    }

    final interpreter = _interpreter!;
    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);

    final inputShape = inputTensor.shape;
    if (inputShape.length != 4 || inputShape[3] != 3) {
      throw StateError('Model must use input shape [1,H,W,3]. Found: $inputShape');
    }

    final config = ModelConfig.fromInputTensor(inputTensor);
    final watch = Stopwatch()..start();

    var bestRun = await _runInference(interpreter, outputTensor, imageBytes, config);

    // If confidence is low on float models, probe common preprocessing variants.
    if (!config.isQuantized && bestRun.topConfidence < 0.35) {
      for (final candidate in _buildFloatFallbackConfigs(config)) {
        final run = await _runInference(interpreter, outputTensor, imageBytes, candidate);
        final bestScore = bestRun.topConfidence + (bestRun.topConfidence - bestRun.secondConfidence) * 0.5;
        final runScore = run.topConfidence + (run.topConfidence - run.secondConfidence) * 0.5;
        if (runScore > bestScore) {
          bestRun = run;
        }
      }
    }

    final probabilities = bestRun.probabilities;
    final topIndex = bestRun.topIndex;

    final results = <PredictionResult>[];
    for (int i = 0; i < _labels.length; i++) {
      results.add(PredictionResult(label: _labels[i], confidence: probabilities[i]));
    }
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    watch.stop();
    debugPrint(
      'Inference=${watch.elapsedMilliseconds}ms input=${config.inputWidth}x${config.inputHeight} '
      'inputType=${inputTensor.type.name} inScale=${config.inputScale} inZp=${config.inputZeroPoint} '
      'outputType=${outputTensor.type.name} outScale=${outputTensor.params.scale} outZp=${outputTensor.params.zeroPoint} '
      'normMean=${bestRun.config.normalizeMean} normStd=${bestRun.config.normalizeStd} channel=${bestRun.config.channelOrder.name} '
      'topIndex=$topIndex topLabel=${_labels[topIndex]}',
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

  Future<_InferenceRun> _runInference(
    Interpreter interpreter,
    Tensor outputTensor,
    Uint8List imageBytes,
    ModelConfig config,
  ) async {
    final input = await _preprocessingService.preprocessImage(imageBytes, config);
    final output = _buildOutputTensor(outputTensor);
    interpreter.run(input, output);

    final rawScores = _flattenToDoubleList(output);
    if (rawScores.isEmpty) {
      throw StateError('Model returned an empty output tensor for shape ${outputTensor.shape}.');
    }

    final decodedScores = _decodeOutputIfQuantized(rawScores, outputTensor);
    if (decodedScores.length != _labels.length) {
      throw StateError(
        'Model output size (${decodedScores.length}) does not match labels.txt (${_labels.length}).',
      );
    }

    final probabilities = _softmaxIfNeeded(decodedScores);
    final topIndex = _argmax(probabilities);
    if (topIndex < 0 || topIndex >= _labels.length) {
      throw StateError('Predicted class index $topIndex is out of bounds for ${_labels.length} labels.');
    }
    return _InferenceRun(probabilities: probabilities, topIndex: topIndex, config: config);
  }

  List<ModelConfig> _buildFloatFallbackConfigs(ModelConfig base) {
    // Keep fallback set intentionally small to avoid multi-second scan delays.
    final variants = <ModelConfig>[
      base.copyWith(normalizeMean: 0.0, normalizeStd: 255.0, channelOrder: ChannelOrder.rgb),
      base.copyWith(normalizeMean: 127.5, normalizeStd: 127.5, channelOrder: ChannelOrder.rgb),
    ];

    final seen = <String>{};
    final unique = <ModelConfig>[];
    for (final v in variants) {
      final key = '${v.normalizeMean}|${v.normalizeStd}|${v.channelOrder.name}';
      if (seen.add(key)) unique.add(v);
    }
    return unique;
  }

  void _validateModelMetadata(Interpreter interpreter, List<String> labels) {
    final inputShape = interpreter.getInputTensor(0).shape;
    if (inputShape.length != 4 || inputShape[0] != 1 || inputShape[3] != 3) {
      throw StateError('Unsupported model input shape: $inputShape. Expected [1,H,W,3].');
    }

    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputSize = outputShape.fold<int>(1, (value, element) => value * element);
    if (outputSize != labels.length) {
      throw StateError(
        'Model output size ($outputSize) does not match labels.txt (${labels.length}).',
      );
    }
  }

  Object _buildOutputTensor(Tensor tensor) {
    final shape = tensor.shape;
    final typeName = tensor.type.name;
    final isIntegerTensor = typeName.startsWith('int') || typeName.startsWith('uint');

    dynamic makeDim(int depth) {
      final length = shape[depth];
      if (depth == shape.length - 1) {
        return isIntegerTensor
            ? List<int>.filled(length, 0)
            : List<double>.filled(length, 0.0);
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
    final isQuantized =
        outputTensor.type == TensorType.uint8 || outputTensor.type == TensorType.int8;
    if (!isQuantized || scale == 0) {
      return scores;
    }
    return scores.map((q) => (q - zeroPoint) * scale).toList();
  }

  List<double> _softmaxIfNeeded(List<double> values) {
    if (values.isEmpty) return values;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    // Many mobile classifiers already emit probabilities in [0,1] (often sigmoid).
    // In that case applying softmax distorts scores and can bias predictions.
    if (minValue >= 0.0 && maxValue <= 1.0) {
      return values;
    }

    final sum = values.fold<double>(0, (a, b) => a + b);
    if (sum > 0.99 && sum < 1.01) {
      return values;
    }

    final maxLogit = values.reduce(math.max);
    final exps = values.map((v) => math.exp(v - maxLogit)).toList();
    final denom = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / denom).toList();
  }

  int _argmax(List<double> values) {
    if (values.isEmpty) return -1;
    int bestIndex = 0;
    double bestValue = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > bestValue) {
        bestValue = values[i];
        bestIndex = i;
      }
    }
    return bestIndex;
  }
}
