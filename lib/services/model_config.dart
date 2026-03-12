import 'package:tflite_flutter/tflite_flutter.dart';

enum ChannelOrder { rgb, bgr }

class ModelConfig {
  const ModelConfig({
    required this.inputWidth,
    required this.inputHeight,
    required this.isQuantized,
    required this.inputTensorType,
    required this.inputScale,
    required this.inputZeroPoint,
    required this.channelOrder,
    required this.normalizeMean,
    required this.normalizeStd,
    required this.minConfidence,
  });

  final int inputWidth;
  final int inputHeight;
  final bool isQuantized;
  final TensorType inputTensorType;
  final double inputScale;
  final int inputZeroPoint;
  final ChannelOrder channelOrder;
  final double normalizeMean;
  final double normalizeStd;
  final double minConfidence;

  bool get isSignedInt8 => inputTensorType == TensorType.int8;
  bool get isUnsignedUInt8 => inputTensorType == TensorType.uint8;

  ModelConfig copyWith({
    int? inputWidth,
    int? inputHeight,
    bool? isQuantized,
    TensorType? inputTensorType,
    double? inputScale,
    int? inputZeroPoint,
    ChannelOrder? channelOrder,
    double? normalizeMean,
    double? normalizeStd,
    double? minConfidence,
  }) {
    return ModelConfig(
      inputWidth: inputWidth ?? this.inputWidth,
      inputHeight: inputHeight ?? this.inputHeight,
      isQuantized: isQuantized ?? this.isQuantized,
      inputTensorType: inputTensorType ?? this.inputTensorType,
      inputScale: inputScale ?? this.inputScale,
      inputZeroPoint: inputZeroPoint ?? this.inputZeroPoint,
      channelOrder: channelOrder ?? this.channelOrder,
      normalizeMean: normalizeMean ?? this.normalizeMean,
      normalizeStd: normalizeStd ?? this.normalizeStd,
      minConfidence: minConfidence ?? this.minConfidence,
    );
  }

  factory ModelConfig.fromInputTensor(Tensor inputTensor) {
    final shape = inputTensor.shape;
    if (shape.length != 4 || shape[3] != 3) {
      throw StateError('Unsupported input tensor shape: $shape. Expected [1,H,W,3].');
    }

    final type = inputTensor.type;
    final isQuantized = type == TensorType.uint8 || type == TensorType.int8;
    final inputScale = inputTensor.params.scale;
    final inputZeroPoint = inputTensor.params.zeroPoint;
    final expectsUnitRangeInput = isQuantized && inputScale > 0 && inputScale < 0.1;

    return ModelConfig(
      inputWidth: shape[2],
      inputHeight: shape[1],
      isQuantized: isQuantized,
      inputTensorType: type,
      inputScale: inputScale,
      inputZeroPoint: inputZeroPoint,
      channelOrder: ChannelOrder.rgb,
      // For quantized models, use tensor quantization params.
      // Models with small input scale usually expect [0..1] real values.
      normalizeMean: 0.0,
      normalizeStd: isQuantized
          ? (expectsUnitRangeInput ? 255.0 : 1.0)
          // Many exported Keras classifiers include an internal Rescaling layer
          // and expect raw [0..255] float pixels.
          : 1.0,
      minConfidence: 0.22,
    );
  }
}
