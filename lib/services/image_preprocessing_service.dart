import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'model_config.dart';

class ImagePreprocessingService {
  const ImagePreprocessingService();

  /// Standard mobile inference pipeline:
  /// decode -> orientation fix -> center crop -> resize -> normalize -> tensor.
  Future<Object> preprocessImage(Uint8List imageBytes, ModelConfig config) async {
    return compute(_preprocessOnIsolate, _PreprocessInput(imageBytes, config));
  }
}

class _PreprocessInput {
  const _PreprocessInput(this.imageBytes, this.config);

  final Uint8List imageBytes;
  final ModelConfig config;
}

Object _preprocessOnIsolate(_PreprocessInput input) {
  final decoded = img.decodeImage(input.imageBytes);
  if (decoded == null) {
    throw StateError('Invalid image file.');
  }

  final oriented = img.bakeOrientation(decoded);
  final cropped = _centerCropSquare(oriented);
  final resized = img.copyResize(
    cropped,
    width: input.config.inputWidth,
    height: input.config.inputHeight,
    interpolation: img.Interpolation.cubic,
  );

  // Soft recovery for low-detail images.
  final blurScore = _laplacianVariance(resized);
  if (blurScore < 28) {
    img.convolution(
      resized,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      div: 1,
    );
  }

  return input.config.isQuantized
      ? _buildQuantizedTensor(resized, input.config)
      : _buildFloatTensor(resized, input.config);
}

Object _buildFloatTensor(img.Image image, ModelConfig config) {
  final tensor = List.generate(
    config.inputHeight,
    (y) => List.generate(config.inputWidth, (x) {
      final p = image.getPixel(x, y);
      final rgb = _channelOrder(p.r.toDouble(), p.g.toDouble(), p.b.toDouble(), config.channelOrder);
      return [
        (rgb.$1 - config.normalizeMean) / config.normalizeStd,
        (rgb.$2 - config.normalizeMean) / config.normalizeStd,
        (rgb.$3 - config.normalizeMean) / config.normalizeStd,
      ];
    }),
  );
  return [tensor];
}

Object _buildQuantizedTensor(img.Image image, ModelConfig config) {
  final tensor = List.generate(
    config.inputHeight,
    (y) => List.generate(config.inputWidth, (x) {
      final p = image.getPixel(x, y);
      final rgb = _channelOrder(p.r.toDouble(), p.g.toDouble(), p.b.toDouble(), config.channelOrder);
      final r = _quantizeInput(rgb.$1, config);
      final g = _quantizeInput(rgb.$2, config);
      final b = _quantizeInput(rgb.$3, config);
      return [
        r,
        g,
        b,
      ];
    }),
  );
  return [tensor];
}

int _quantizeInput(double pixel, ModelConfig config) {
  final normalized = (pixel - config.normalizeMean) / config.normalizeStd;
  final raw = config.inputScale > 0
      ? (normalized / config.inputScale) + config.inputZeroPoint
      : normalized;

  if (config.isSignedInt8) {
    return raw.round().clamp(-128, 127);
  }
  return raw.round().clamp(0, 255);
}

(double, double, double) _channelOrder(double r, double g, double b, ChannelOrder order) {
  if (order == ChannelOrder.bgr) return (b, g, r);
  return (r, g, b);
}

img.Image _centerCropSquare(img.Image source) {
  final side = source.width < source.height ? source.width : source.height;
  final left = (source.width - side) ~/ 2;
  final top = (source.height - side) ~/ 2;
  return img.copyCrop(source, x: left, y: top, width: side, height: side);
}

double _laplacianVariance(img.Image image) {
  final values = <double>[];
  for (int y = 1; y < image.height - 1; y++) {
    for (int x = 1; x < image.width - 1; x++) {
      double luma(int px, int py) {
        final p = image.getPixel(px, py);
        return (0.299 * p.r) + (0.587 * p.g) + (0.114 * p.b);
      }

      final center = luma(x, y);
      final lap = (4 * center) - luma(x - 1, y) - luma(x + 1, y) - luma(x, y - 1) - luma(x, y + 1);
      values.add(lap);
    }
  }

  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values
          .map((v) => (v - mean) * (v - mean))
          .reduce((a, b) => a + b) /
      values.length;
  return variance;
}
