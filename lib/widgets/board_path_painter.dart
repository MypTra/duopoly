import 'package:flutter/material.dart';

class BoardPathPainter extends CustomPainter {
  final Path gamePath;
  final Color pathColor;
  final double pathWidth;

  BoardPathPainter({
    required this.gamePath,
    this.pathColor = const Color(0xFF37474F), // Koyu bir yol rengi
    this.pathWidth = 90.0, // Kartların yüksekliğine yakın bir genişlik
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth
      ..strokeCap = StrokeCap.round; // Köşeleri yuvarlak yapar

    canvas.drawPath(gamePath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}