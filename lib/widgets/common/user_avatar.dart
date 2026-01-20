import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/profile_update_service.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String? initialPhotoUrl;
  final String displayName;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.userId,
    this.initialPhotoUrl,
    required this.displayName,
    this.radius = 24,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _currentPhotoUrl;
  
  bool get _isCurrentUser => widget.userId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _currentPhotoUrl = widget.initialPhotoUrl;
    
    if (_isCurrentUser) {
      // If we already have a more recent URL in the notifier, use it
      final latestUrl = ProfileUpdateService().photoUrlNotifier.value;
      if (latestUrl != null) {
        _currentPhotoUrl = latestUrl;
      }
      ProfileUpdateService().photoUrlNotifier.addListener(_onPhotoUpdate);
    }
  }

  void _onPhotoUpdate() {
    if (mounted) {
      setState(() {
        _currentPhotoUrl = ProfileUpdateService().photoUrlNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    ProfileUpdateService().photoUrlNotifier.removeListener(_onPhotoUpdate);
    super.dispose();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotoUrl != widget.initialPhotoUrl) {
      setState(() {
        // Always start with the initialPhotoUrl from the widget
        _currentPhotoUrl = widget.initialPhotoUrl;
        
        // If it's the current user, and the notifier has a value, it takes precedence
        if (_isCurrentUser && ProfileUpdateService().photoUrlNotifier.value != null) {
          _currentPhotoUrl = ProfileUpdateService().photoUrlNotifier.value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xFF5DBDA8).withOpacity(0.2),
      backgroundImage: _currentPhotoUrl != null
          ? NetworkImage(_currentPhotoUrl!)
          : null,
      child: _currentPhotoUrl == null
          ? Text(
              widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
              style: TextStyle(
                color: const Color(0xFF5DBDA8),
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * 0.8,
              ),
            )
          : null,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
