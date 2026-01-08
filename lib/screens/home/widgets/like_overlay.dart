import 'package:flutter/material.dart';

class LikeOverlay extends StatelessWidget {
  final AnimationController controller;

  const LikeOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          // Scale: grow in quickly, then shrink out
          final scale = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: 1.2,
              ).chain(CurveTween(curve: Curves.easeOut)),
              weight: 30,
            ),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.2,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeInOut)),
              weight: 20,
            ),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
            TweenSequenceItem(
              tween: Tween(
                begin: 1.0,
                end: 0.0,
              ).chain(CurveTween(curve: Curves.easeIn)),
              weight: 20,
            ),
          ]).evaluate(controller);

          // Opacity: fade in fast, hold, fade out
          final opacity = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
          ]).evaluate(controller);

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFFF2C55), // TikTok red
                size: 100,
              ),
            ),
          );
        },
      ),
    );
  }
}
