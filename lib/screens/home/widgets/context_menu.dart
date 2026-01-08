import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/game_model.dart';

class ContextMenu extends StatelessWidget {
  final GameModel game;

  const ContextMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          _buildOption(
            context,
            icon: Icons.not_interested,
            label: 'Not Interested',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('We\'ll show you less content like this'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.bookmark_border,
            label: game.isSaved ? 'Remove from Saved' : 'Save',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildOption(
            context,
            icon: Icons.link,
            label: 'Copy Link',
            onTap: () {
              Clipboard.setData(
                ClipboardData(text: 'https://gameai.app/game/${game.id}'),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildOption(
            context,
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(color: AppColors.borderLight, height: 24),
          _buildOption(
            context,
            icon: Icons.flag_outlined,
            label: 'Report',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _showReportDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Report Content',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to report this content?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Report submitted. Thank you for your feedback.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Report',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
