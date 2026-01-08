import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: const Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSection(
                title: 'Account',
                children: [
                  _buildMyTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Account information',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.security_outlined,
                    title: 'Security',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Content & Activity',
                children: [
                  _buildMyTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    value: 'English',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark mode',
                    value: 'On',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Support',
                children: [
                  _buildMyTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.flag_outlined,
                    title: 'Report a problem',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'About',
                children: [
                  _buildMyTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Community Guidelines',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.article_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  _buildMyTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Log Out
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // TODO: Implement logout
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Log out',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF4B4B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF555555),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF888888),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMyTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF666666),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
