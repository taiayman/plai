import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'discover/discover_screen.dart';
import 'create/create_screen.dart';
import 'inbox/inbox_screen.dart';
import 'profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DiscoverScreen(),
    SizedBox(), // Placeholder - Create navigates separately
    InboxScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // Navigate to Create Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: const Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0F0F0F),
        body: Column(
          children: [
            // Main content takes remaining space
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),

            // Bottom Nav Bar - solid, not overlay
            Container(
              color: const Color(0xFF0F0F0F),
              padding: EdgeInsets.only(bottom: bottomPadding + 8, top: 12),
              child: _buildBottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildNavItem(0, 'Home', Icons.home_filled, Icons.home_outlined),
        _buildNavItem(1, 'Discover', Icons.search, Icons.search),

        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildCreateButton(),
        ),

        _buildNavItem(
          3,
          'Inbox',
          Icons.notifications,
          Icons.notifications_outlined,
          hasNotification: true,
        ),
        _buildNavItem(4, 'Profile', Icons.person, Icons.person_outline),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData activeIcon,
    IconData inactiveIcon, {
    bool hasNotification = false,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? Colors.white : Colors.white60;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  size: 26,
                  color: color,
                ),
                if (hasNotification)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTertiary,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }
}
