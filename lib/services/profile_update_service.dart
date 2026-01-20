import 'package:flutter/foundation.dart';

/// A service to notify the app when a user profile is updated.
/// This allows different parts of the app to refresh their UI (e.g., PFPs, names)
/// without a full page reload or manual refresh.
class ProfileUpdateService {
  static final ProfileUpdateService _instance = ProfileUpdateService._internal();
  
  factory ProfileUpdateService() {
    return _instance;
  }
  
  ProfileUpdateService._internal();

  /// A notifier that emits the updated photo URL (with timestamp to bust cache)
  final ValueNotifier<String?> photoUrlNotifier = ValueNotifier<String?>(null);
  
  /// A notifier that emits the updated display name
  final ValueNotifier<String?> displayNameNotifier = ValueNotifier<String?>(null);

  /// Call this when the profile picture is updated
  void notifyPhotoUpdate(String? newUrl) {
    if (newUrl == null) {
      photoUrlNotifier.value = null;
      return;
    }
    // Add a timestamp to bust the image cache as recommended
    final cacheBusterUrl = '$newUrl${newUrl.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}';
    photoUrlNotifier.value = cacheBusterUrl;
  }

  /// Call this when the display name is updated
  void notifyNameUpdate(String? newName) {
    displayNameNotifier.value = newName;
  }

  /// Reset all notifiers (e.g., on logout)
  void reset() {
    photoUrlNotifier.value = null;
    displayNameNotifier.value = null;
  }
}
