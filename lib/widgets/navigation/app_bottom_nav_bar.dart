import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/post/create_post_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/map/map_screen.dart';
import '../../screens/community/community_list_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5DBDA8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              _buildNavItem(
                context: context,
                icon: Icons.home_rounded,
                index: 0,
              ),
              
              // Map/Location
              _buildNavItem(
                context: context,
                icon: Icons.location_on,
                index: 1,
              ),
              
              // Add Post (Center)
              _buildCenterAddButton(context),
              
              // Community
              _buildNavItem(
                context: context,
                icon: Icons.groups_rounded,
                index: 3,
              ),
              
              // Profile
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        debugPrint('Nav item tapped: $index, currentIndex: $currentIndex');
        _navigateToIndex(context, index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('Create post tapped');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    debugPrint('Navigating to index: $index, currentIndex: $currentIndex');
    if (index == currentIndex) {
      debugPrint('Same index, not navigating');
      return;
    }
    
    Widget? destination;
    
    switch (index) {
      case 0:
        debugPrint('Going to HomeScreen');
        destination = const HomeScreen();
        break;
      case 1:
        debugPrint('Going to MapScreen');
        destination = const MapScreen();
        break;
      case 3:
        debugPrint('Going to CommunityListScreen');
        destination = const CommunityListScreen();
        break;
      case 4:
        debugPrint('Going to ProfileScreen');
        destination = const ProfileScreen();
        break;
      default:
        debugPrint('Unknown index');
        return;
    }
    
    debugPrint('Pushing route');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => destination!),
      (route) => false,
    );
    }
}
