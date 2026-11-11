import 'package:eplace/reusable_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:eplace/session_manager.dart';

class ProfileNavigator {
  /// Opens the user profile screen. If tapping your own avatar, it pops back or handles accordingly.
  static Future<void> openProfile(BuildContext context, int targetUserId) async {
    final currentUserId = await SessionManager.getUserId();

    if (!context.mounted) return;

    if (currentUserId != null && currentUserId == targetUserId) {
      // Optional: If it's your own ID, you can either do nothing or navigate to your main ProfileScreen tab.
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(targetUserId: targetUserId),
      ),
    );
  }
}