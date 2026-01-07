import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context),
                    
                    const SizedBox(height: 20),
                    
                    // Settings List
                    _buildSettingsList(context),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF5DBDA8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Account Settings
          _buildSettingsItem(
            icon: Icons.person_outline,
            iconColor: Colors.grey[600]!,
            title: 'Account Settings',
            subtitle: 'Passwords, security, personal details.',
            onTap: () {
              // TODO: Navigate to account settings
            },
          ),
          
          _buildDivider(),
          
          // Saved Posts
          _buildSettingsItem(
            icon: Icons.bookmark_border,
            iconColor: Colors.grey[600]!,
            title: 'Saved Posts',
            onTap: () {
              // TODO: Navigate to saved posts
            },
          ),
          
          _buildDivider(),
          
          // Archive
          _buildSettingsItem(
            icon: Icons.archive_outlined,
            iconColor: Colors.grey[600]!,
            title: 'Archive',
            onTap: () {
              // TODO: Navigate to archive
            },
          ),
          
          _buildDivider(),
          
          // Notifications
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            iconColor: Colors.grey[600]!,
            title: 'Notifications',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          
          _buildDivider(),
          
          // Engaged posts
          _buildSettingsItem(
            icon: Icons.volunteer_activism_outlined,
            iconColor: Colors.grey[600]!,
            title: 'Engaged posts',
            onTap: () {
              // TODO: Navigate to engaged posts
            },
          ),
          
          _buildDivider(),
          
          // Reported posts
          _buildSettingsItem(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Reported posts',
            titleColor: Colors.red,
            onTap: () {
              // TODO: Navigate to reported posts
            },
          ),
          
          _buildDivider(),
          
          // Report the user
          _buildSettingsItem(
            icon: Icons.person_off_outlined,
            iconColor: Colors.red,
            title: 'Report the user',
            titleColor: Colors.red,
            onTap: () {
              // TODO: Navigate to report user
            },
          ),
          
          _buildDivider(),
          
          // Blocked Users
          _buildSettingsItem(
            icon: Icons.block,
            iconColor: Colors.red,
            title: 'Blocked Users',
            titleColor: Colors.red,
            onTap: () {
              // TODO: Navigate to blocked users
            },
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: 60,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
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
              _buildNavItem(context, icon: Icons.home_rounded),
              _buildNavItem(context, icon: Icons.location_on),
              _buildCenterAddButton(),
              _buildNavItem(context, icon: Icons.groups_rounded),
              _buildNavItem(context, icon: Icons.person_outline, isSelected: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context);
        }
      },
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return Container(
      width: 44,
      height: 44,
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
        size: 24,
      ),
    );
  }
}
