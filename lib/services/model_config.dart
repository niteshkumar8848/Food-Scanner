import 'package:tflite_flutter/tflite_flutter.dart';

enum ChannelOrder { rgb, bgr }

class ModelConfig {
  const ModelConfig({
    required this.inputWidth,
    required this.inputHeight,
    required this.isQuantized,
    required this.channelOrder,
    required this.normalizeMean,
    required this.normalizeStd,
    required this.minConfidence,
  });

  final int inputWidth;
  final int inputHeight;
  final bool isQuantized;
  final ChannelOrder channelOrder;
  final double normalizeMean;
  final double normalizeStd;
  final double minConfidence;

  factory ModelConfig.fromInputTensor(Tensor inputTensor) {
    final shape = inputTensor.shape;
    if (shape.length != 4 || shape[3] != 3) {
      throw StateError('Unsupported input tensor shape: $shape. Expected [1,H,W,3].');
    }

    final isQuantized = inputTensor.type == TensorType.uint8;
    return ModelConfig(
      inputWidth: shape[2],
      inputHeight: shape[1],
      isQuantized: isQuantized,
      channelOrder: ChannelOrder.rgb,
      // Default model normalization for float classifiers.
      normalizeMean: isQuantized ? 0.0 : 0.0,
      normalizeStd: isQuantized ? 1.0 : 255.0,
      minConfidence: 0.22,
    );
  }
}
