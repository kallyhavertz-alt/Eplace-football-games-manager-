import 'dart:math' as math;
import 'package:flutter/material.dart';

class EFootballLoader extends StatefulWidget {
  final VoidCallback onComplete;

  const EFootballLoader({super.key, required this.onComplete});

  @override
  State<EFootballLoader> createState() => _EFootballLoaderState();
}

class _EFootballLoaderState extends State<EFootballLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _lineStrikeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Spin arcs for the first 2.2 seconds (0.0 to 0.73 timeline fraction)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 4 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.73, curve: Curves.easeInOutCubic),
      ),
    );

    // Strike the middle line during the remaining 0.8 seconds
    _lineStrikeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.73, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().whenComplete(() {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15), // Dark sports theme background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(100, 100),
              painter: _EFootballLogoPainter(
                rotationAngle: _rotationAnimation.value,
                lineProgress: _lineStrikeAnimation.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EFootballLogoPainter extends CustomPainter {
  final double rotationAngle;
  final double lineProgress;

  _EFootballLogoPainter({
    required this.rotationAngle,
    required this.lineProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final arcPaint = Paint()
      ..color = const Color(0xFFFFD700) // eFootball vibrant yellow/gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 1. Top Arc of the 'e'
    canvas.save();
    canvas.rotate(rotationAngle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      -math.pi,
      math.pi * 0.85,
      false,
      arcPaint,
    );
    canvas.restore();

    // 2. Bottom Arc of the 'e'
    canvas.save();
    canvas.rotate(-rotationAngle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0.15 * math.pi,
      math.pi * 0.85,
      false,
      arcPaint,
    );
    canvas.restore();

    // 3. Center Line Strike (Triggers when rotation settles)
    if (lineProgress > 0) {
      final startX = -radius * 0.8;
      final currentX = startX + (radius * 1.6 * lineProgress);
      canvas.drawLine(
        Offset(startX, 0),
        Offset(currentX, 0),
        linePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EFootballLogoPainter oldDelegate) => true;
}