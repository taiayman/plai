import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/game_model.dart';

/// Combined Creator Info + Action Buttons
class CreatorInfo extends StatelessWidget {
  final GameModel game;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onRemixPressed;

  const CreatorInfo({
    super.key,
    required this.game,
    this.onLikePressed,
    this.onCommentPressed,
    this.onRemixPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Profile Picture
          _buildProfilePic(),
          const SizedBox(width: 12),

          // Creator Name & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${game.creator.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (game.creator.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Color(0xFF20D5EC),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  game.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Action Buttons
          _buildActionButton(
            icon: game.isLiked ? Icons.favorite : Icons.favorite_border,
            color: game.isLiked ? const Color(0xFFFF2C55) : Colors.white,
            label: game.formattedLikes,
            onTap: onLikePressed,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.white,
            label: game.formattedComments,
            onTap: onCommentPressed,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            icon: Icons.auto_fix_high,
            color: Colors.white,
            label: 'Remix',
            onTap: onRemixPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePic() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: CachedNetworkImageProvider(game.creator.profilePicture),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFF2C55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
