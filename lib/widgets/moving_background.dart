import 'package:flutter/material.dart';
import 'dart:math' as math;

class MovingSilkBackground extends StatefulWidget {
  final Widget child;
  const MovingSilkBackground({super.key, required this.child});

  @override
  State<MovingSilkBackground> createState() => _MovingSilkBackgroundState();
}

class _MovingSilkBackgroundState extends State<MovingSilkBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.sin(_controller.value * 2 * math.pi) * 0.5,
                math.cos(_controller.value * 2 * math.pi) * 0.5 - 1,
              ),
              end: Alignment(
                math.cos(_controller.value * 2 * math.pi) * 0.5,
                math.sin(_controller.value * 2 * math.pi) * 0.5 + 1,
              ),
              colors: [
                const Color(0xFF1A0B2E), // Deep Midnight Purple
                const Color(0xFF2E1065), // Rich Royal Purple
                const Color(0xFF4C1D95), // Vibrant Purple
                const Color(0xFF1E1B4B), // Deep Indigo
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle "Tenun" texture overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(painter: TenunPatternPainter()),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class TenunPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    double spacing = 20;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
