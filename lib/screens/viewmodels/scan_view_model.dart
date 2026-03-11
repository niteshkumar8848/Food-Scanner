import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/food_scan_result.dart';
import '../../repositories/food_repository.dart';

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({required FoodRepository repository}) : _repository = repository;

  final FoodRepository _repository;

  CameraController? _cameraController;
  bool _isLoading = false;
  String? _error;
  Uint8List? _frozenFrameBytes;
  bool _isTorchOn = false;

  CameraController? get cameraController => _cameraController;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Uint8List? get frozenFrameBytes => _frozenFrameBytes;
  bool get isTorchOn => _isTorchOn;

  Future<void> initializeCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _error = 'Camera permission denied. Please allow access to scan food.';
        notifyListeners();
        return;
      }

      await Permission.photos.request();
      await Permission.storage.request();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = 'No camera available on this device.';
        notifyListeners();
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      _isTorchOn = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      _error = 'Unable to initialize camera. Please check permissions.';
      notifyListeners();
    }
  }

  Future<FoodScanResult?> scanFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _error = 'Camera is not ready yet.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    final wasTorchOn = _isTorchOn;

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      _frozenFrameBytes = bytes;
      notifyListeners();
      return await _repository.scanFood(bytes);
    } catch (e) {
      _error = 'Failed to detect food from camera image: $e';
      return null;
    } finally {
      _frozenFrameBytes = null;
      if (wasTorchOn) {
        try {
          await _cameraController?.setFlashMode(FlashMode.off);
          _isTorchOn = false;
        } catch (_) {
          _isTorchOn = false;
        }
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodScanResult?> scanFromImageBytes(Uint8List bytes) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.scanFood(bytes);
    } catch (e) {
      _error = 'Failed to detect food from selected image: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FoodScanResult?> scanFromDebugAsset(String assetPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.scanDebugAsset(assetPath);
    } catch (e) {
      _error = 'Failed to run debug inference for selected test image: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      _isTorchOn = !_isTorchOn;
      await controller.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
      _error = null;
      notifyListeners();
    } catch (_) {
      _isTorchOn = false;
      _error = 'Flashlight is not supported on this device camera.';
      notifyListeners();
    }
  }

  Future<List<String>> getDebugAssets() async {
    final manifestString = await rootBundle.loadString('AssetManifest.json');
    final RegExp re = RegExp(r'"(assets/test_foods/[^"\\]+\.(?:png|jpg|jpeg|webp))"');
    return re
        .allMatches(manifestString)
        .map((m) => m.group(1)!)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
