import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, this.showQualityHints = true});

  final bool showQualityHints;

  @override
  Widget build(BuildContext context) {
    final frameSize = MediaQuery.sizeOf(context).width * 0.76;
    final cornerSize = frameSize * 0.12;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          // Quality hints at top
          if (showQualityHints)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined, 
                        color: Colors.white70, 
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Good light • single food item • fill frame',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Center frame with corner markers
          Positioned.fill(
            child: CustomPaint(
              painter: _SurroundingDimPainter(
                frameSize: frameSize,
                borderRadius: 24,
                dimColor: Colors.black.withValues(alpha: 0.22),
              ),
            ),
          ),

          // Center frame with corner markers
          Center(
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Frame border only (no center tint)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FrameOverlayPainter(
                        borderRadius: 24,
                        borderColor: Colors.white.withValues(alpha: 0.8),
                        borderWidth: 3,
                      ),
                    ),
                  ),
                  
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _CornerMarker(
                      size: cornerSize,
                      corner: _Corner.topLeft,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CornerMarker(
                      size: cornerSize,
                      corner: _Corner.topRight,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _CornerMarker(
                      size: cornerSize,
                      corner: _Corner.bottomLeft,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _CornerMarker(
                      size: cornerSize,
                      corner: _Corner.bottomRight,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom hint
          if (showQualityHints)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 190),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  'Hold steady for better results',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerMarker extends StatelessWidget {
  const _CornerMarker({
    required this.size,
    required this.corner,
    required this.color,
  });

  final double size;
  final _Corner corner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          corner: corner,
          color: color,
          strokeWidth: 4,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  final Color color;
  final double strokeWidth;

  _CornerPainter({
    required this.corner,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height * 0.6);
        path.lineTo(0, 0);
        path.lineTo(size.width * 0.6, 0);
        break;
      case _Corner.topRight:
        path.moveTo(size.width * 0.4, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height * 0.6);
        break;
      case _Corner.bottomLeft:
        path.moveTo(0, size.height * 0.4);
        path.lineTo(0, size.height);
        path.lineTo(size.width * 0.6, size.height);
        break;
      case _Corner.bottomRight:
        path.moveTo(size.width * 0.4, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, size.height * 0.4);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FrameOverlayPainter extends CustomPainter {
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;

  _FrameOverlayPainter({
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(borderWidth / 2, borderWidth / 2, 
                     size.width - borderWidth, size.height - borderWidth),
      Radius.circular(borderRadius),
    );

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SurroundingDimPainter extends CustomPainter {
  _SurroundingDimPainter({
    required this.frameSize,
    required this.borderRadius,
    required this.dimColor,
  });

  final double frameSize;
  final double borderRadius;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final holeRect = Rect.fromLTWH(left, top, frameSize, frameSize);
    final holeRRect = RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius));

    final outside = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(holeRRect);
    final overlayPath = Path.combine(PathOperation.difference, outside, hole);

    final paint = Paint()..color = dimColor;
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SurroundingDimPainter oldDelegate) {
    return oldDelegate.frameSize != frameSize ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dimColor != dimColor;
  }
}
