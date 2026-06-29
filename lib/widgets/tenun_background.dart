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
                color: const Color(0xFF0F0918),
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
                  const Color(0xFF1A0B2E).withOpacity(0.8),
                  const Color(0xFF1A0B2E).withOpacity(0.4),
                  const Color(0xFF000000).withOpacity(0.9),
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
