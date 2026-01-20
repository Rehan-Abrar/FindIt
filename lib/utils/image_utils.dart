import 'package:flutter/material.dart';

class ImageUtils {
  /// Appends a timestamp to an image URL to bypass browser/app caching.
  /// Useful for profile pictures that might have the same URL even after an update.
  static String getCacheBustingUrl(String url) {
    if (url.isEmpty) return url;
    
    // Check if it's a network URL
    if (!url.startsWith('http')) return url;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=$timestamp';
  }

  /// Builds a NetworkImage with cache busting if needed.
  static ImageProvider getImageProvider(String? url, {bool useCacheBuster = false}) {
    if (url == null || url.isEmpty) {
      return const AssetImage('assets/placeholder_user.png'); // Fallback if you have it
    }
    
    String finalUrl = url;
    if (useCacheBuster) {
      finalUrl = getCacheBustingUrl(url);
    }
    
    return NetworkImage(finalUrl);
  }
}
