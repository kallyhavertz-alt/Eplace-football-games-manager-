import 'dart:math' as math;
import 'package:flutter/material.dart';

class EFootballLoader extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;
  final bool loop;

  const EFootballLoader({
    super.key,
    this.onComplete,
    this.size = 64,
    this.loop = true,
  });

  @override
  State<EFootballLoader> createState() => _EFootballLoaderState();
}

class _EFootballLoaderState extends State<EFootballLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _barsIn;
  late final Animation<double> _barsOut;
  bool _completedOnce = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

     _rotation = Tween<double>(begin: 0, end: math.pi * 3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInOutCubic),
      ),
    );

    _barsIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.72, curve: Curves.easeOutCubic),
    );

     _barsOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.08, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_completedOnce) {
          _completedOnce = true;
          widget.onComplete?.call();
        }
        if (widget.loop && mounted) _controller.forward(from: 0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(s * 0.24),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
           final barsVisible = _completedOnce ? 1 - _barsOut.value : 0.0;
          final inProgress = _controller.value >= 0.5 ? _barsIn.value : 0.0;
          return CustomPaint(
            size: Size(s, s),
            painter: _EFootballLogoPainter(
              rotation: _rotation.value,
              barsIn: inProgress,
              barsLeftover: _controller.value < 0.5 ? barsVisible : 0.0,
            ),
          );
        },
      ),
    );
  }
}

class _EFootballLogoPainter extends CustomPainter {
  final double rotation;
  final double barsIn;
  final double barsLeftover;

  _EFootballLogoPainter({
    required this.rotation,
    required this.barsIn,
    required this.barsLeftover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.28; // ring radius (to stroke centre)
    final stroke = size.width * 0.15;

    final arcPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    const gap = math.pi * 0.24;
    const sweep = math.pi - gap;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
     canvas.drawArc(rect, math.pi + gap / 2, sweep, false, arcPaint);

    canvas.drawArc(rect, gap / 2, sweep, false, arcPaint);


    if (barsLeftover > 0) {
      _drawBars(canvas, r, stroke, 1.0, barsLeftover);
    }

    canvas.restore();

     if (barsIn > 0) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      _drawBars(canvas, r, stroke, barsIn, 1.0);
      canvas.restore();
    }
  }

  void _drawBars(
      Canvas canvas, double r, double stroke, double progress, double opacity) {
    final paint = Paint()..color = Colors.black.withOpacity(opacity);
    final barH = stroke * 0.55;
    final spacing = stroke * 0.45;
    final halfLen = r * 1.05;
    final dx = -r * 0.9 * (1 - progress);

    final topRect =
    Rect.fromLTWH(-halfLen + dx, -spacing / 2 - barH, halfLen * 2, barH);
    final botRect =
    Rect.fromLTWH(-halfLen + dx, spacing / 2, halfLen * 2, barH);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-r - stroke / 2, -r, r + stroke / 2, r));
    canvas.drawRect(topRect, paint);
    canvas.drawRect(botRect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EFootballLogoPainter old) =>
      old.rotation != rotation ||
          old.barsIn != barsIn ||
          old.barsLeftover != barsLeftover;
}
