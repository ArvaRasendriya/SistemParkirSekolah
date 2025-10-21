import 'package:flutter/material.dart';

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class CornerPainter extends CustomPainter {
  final Color color;
  final CornerPosition position;
  final double thickness;

  CornerPainter({
    required this.color,
    required this.position,
    this.thickness = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cornerLength = size.width * 0.6;

    switch (position) {
      case CornerPosition.topLeft:
        path.moveTo(cornerLength, 0);
        path.lineTo(0, 0);
        path.lineTo(0, cornerLength);
        break;
      case CornerPosition.topRight:
        path.moveTo(size.width - cornerLength, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, cornerLength);
        break;
      case CornerPosition.bottomLeft:
        path.moveTo(0, size.height - cornerLength);
        path.lineTo(0, size.height);
        path.lineTo(cornerLength, size.height);
        break;
      case CornerPosition.bottomRight:
        path.moveTo(size.width, size.height - cornerLength);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width - cornerLength, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) =>
      oldDelegate.thickness != thickness;
}
