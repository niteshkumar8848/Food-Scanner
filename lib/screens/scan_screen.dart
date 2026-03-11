import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../widgets/scan_overlay.dart';
import 'viewmodels/scan_view_model.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = ScanViewModel(repository: context.read());
        vm.initializeCamera();
        return vm;
      },
      child: const _ScanScreenBody(),
    );
  }
}

class _ScanScreenBody extends StatelessWidget {
  const _ScanScreenBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    final CameraController? controller = vm.cameraController;
    final frozenFrame = vm.frozenFrameBytes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Food',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        actions: [
          // Torch button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: vm.isTorchOn ? 'Turn flashlight off' : 'Turn flashlight on',
              onPressed: vm.isLoading ? null : vm.toggleTorch,
              icon: Icon(
                vm.isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                color: Colors.white,
              ),
            ),
          ),
          // Gallery button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Upload debug image',
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (!context.mounted || picked == null) return;
                      final bytes = await picked.readAsBytes();
                      final result = await vm.scanFromImageBytes(bytes);
                      if (!context.mounted || result == null) return;
                      Navigator.pushNamed(context, AppRoutes.result, arguments: result);
                    },
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview or frozen frame
          Positioned.fill(
            child: frozenFrame != null
                ? Image.memory(
                    frozenFrame,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : _buildLivePreview(context, controller),
          ),
          
          // Scan overlay
          const Positioned.fill(child: ScanOverlay()),
          
          // Loading overlay
          if (vm.isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 28,
                                color: Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI is Detecting...',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyzing your food item',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Error message
          if (vm.error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 130,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vm.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: vm.isLoading
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () async {
                  final result = await vm.scanFromCamera();
                  if (!context.mounted || result == null) return;
                  Navigator.pushNamed(context, AppRoutes.result, arguments: result);
                },
                child: Container(
                  width: 180,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.document_scanner_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Scan Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLivePreview(BuildContext context, CameraController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    // Keep native camera proportions to prevent vertical stretching.
    final screenSize = MediaQuery.sizeOf(context);
    final screenAspectRatio = screenSize.width / screenSize.height;
    final previewAspectRatio = controller.value.previewSize == null
        ? controller.value.aspectRatio
        : controller.value.previewSize!.height / controller.value.previewSize!.width;

    double scale = previewAspectRatio / screenAspectRatio;
    if (scale < 1) {
      scale = 1 / scale;
    }

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }
}
