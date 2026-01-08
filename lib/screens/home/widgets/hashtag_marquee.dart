import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class HashtagMarquee extends StatelessWidget {
  final List<String> hashtags;

  const HashtagMarquee({super.key, required this.hashtags});

  @override
  Widget build(BuildContext context) {
    if (hashtags.isEmpty) return const SizedBox.shrink();

    final hashtagText = hashtags.join('  •  ');

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Music/sound icon
          Container(
            width: 36,
            height: 30,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.music_note, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Scrolling hashtags
          Expanded(
            child: Marquee(
              text: hashtagText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 100.0,
              velocity: 30.0,
              pauseAfterRound: const Duration(seconds: 2),
              startPadding: 0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }
}
