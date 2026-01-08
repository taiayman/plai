import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notifications = await ApiService().getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications.isNotEmpty ? notifications : _mockNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifications = _mockNotifications;
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'favorite': return Icons.favorite_rounded;
      case 'person_add': return Icons.person_add_rounded;
      case 'chat_bubble': return Icons.chat_bubble_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'star': return Icons.star_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColorFromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => HapticFeedback.selectionClick(),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Notifications List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF5576F8)))
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFF5576F8),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return _buildNotificationItem(
                              icon: _getIconFromString(notif['icon'] as String? ?? 'notifications'),
                              iconColor: _getColorFromHex(notif['color'] as String? ?? '#5576F8'),
                              title: notif['title'] as String? ?? '',
                              subtitle: notif['subtitle'] as String? ?? '',
                              time: notif['time'] as String? ?? '',
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF888888),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: GoogleFonts.outfit(
              color: const Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'icon': 'favorite',
      'color': '#FE2C55',
      'title': 'gamer_pro liked your game',
      'subtitle': 'Space Shooter Adventure',
      'time': '2m',
    },
    {
      'icon': 'person_add',
      'color': '#5576F8',
      'title': 'New follower',
      'subtitle': 'pixel_master started following you',
      'time': '15m',
    },
    {
      'icon': 'chat_bubble',
      'color': '#25D366',
      'title': 'New comment',
      'subtitle': '"This game is amazing! 🔥"',
      'time': '1h',
    },
    {
      'icon': 'sports_esports',
      'color': '#FF9500',
      'title': 'Your game hit 1K plays!',
      'subtitle': 'Neon Racing Challenge',
      'time': '2h',
    },
    {
      'icon': 'favorite',
      'color': '#FE2C55',
      'title': 'indie_dev liked your game',
      'subtitle': 'Puzzle Master 3D',
      'time': '3h',
    },
    {
      'icon': 'person_add',
      'color': '#5576F8',
      'title': 'New follower',
      'subtitle': 'creative_coder started following you',
      'time': '5h',
    },
    {
      'icon': 'star',
      'color': '#FFD700',
      'title': 'Featured Game!',
      'subtitle': 'Your game was featured on Discover',
      'time': '1d',
    },
    {
      'icon': 'chat_bubble',
      'color': '#25D366',
      'title': 'New comment',
      'subtitle': '"How did you make this?"',
      'time': '1d',
    },
  ];
}
