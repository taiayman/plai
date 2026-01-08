import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildPulsingCircle(),
              const Icon(
                Icons.auto_fix_high,
                size: 40,
                color: AppColors.accentPrimary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
              'Curating for you...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: const Duration(seconds: 2),
              color: AppColors.accentPrimary,
            ),
      ],
    );
  }

  Widget _buildPulsingCircle() {
    return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentPrimary.withOpacity(0.1),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          duration: const Duration(seconds: 1),
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
        )
        .then()
        .scale(
          duration: const Duration(seconds: 1),
          begin: const Offset(1.2, 1.2),
          end: const Offset(0.8, 0.8),
        );
  }
}
