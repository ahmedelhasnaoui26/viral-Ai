import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/viral_design_tokens.dart';

class ViralDottedUploadBox extends StatelessWidget {
  const ViralDottedUploadBox({
    required this.onTap,
    this.imagePath,
    this.height = 180,
    super.key,
  });

  final VoidCallback onTap;
  final String? imagePath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: ViralTokens.textDim,
          strokeWidth: 1.5,
          radius: ViralTokens.radiusMd,
        ),
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          child: imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(ViralTokens.radiusMd - 2),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 40,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tap to upload image',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
