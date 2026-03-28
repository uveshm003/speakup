import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Simple radial particle burst (~1.5s) for celebration screens.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          height: 200,
          width: constraints.maxWidth,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _ConfettiPainter(progress: _controller.value),
              );
            },
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _colors = <Color>[
    Color(0xFF5C4EFA), // brand primary
    Color(0xFFEEF0FF), // brand primaryLight
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // purple
  ];

  static const int _kDots = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height * 0.55);
    final double maxR = size.width * 0.42;
    for (int i = 0; i < _kDots; i++) {
      final double angle = (i / _kDots) * math.pi * 2 + 0.15;
      final double r = maxR * Curves.easeOut.transform(progress);
      final Offset p = c + Offset(math.cos(angle), math.sin(angle)) * r;
      final double fade = (1 - progress).clamp(0.0, 1.0);
      final Color color = _colors[i % _colors.length].withValues(alpha: fade);
      final Paint paint = Paint()..color = color;
      if (i.isEven) {
        canvas.drawCircle(p, 4 + progress * 2, paint);
      } else {
        final double w = 8 + progress * 2;
        canvas.drawRRect(
          RRect.fromRectXY(
            Rect.fromCenter(center: p, width: w, height: w * 0.5),
            2,
            2,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
