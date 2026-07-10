import 'package:flutter/material.dart';

class TenunBackground extends StatelessWidget {
  final Widget child;
  const TenunBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Real Tenun Fabric Image (Visible on all platforms)
        Positioned.fill(
          child: Image.asset(
            'assets/images/tenun_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFF9FAFC),
              );
            },
          ),
        ),
        
        // Premium Silk Overlay (Gradient on all platforms to show the fabric nicely)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.80),
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
