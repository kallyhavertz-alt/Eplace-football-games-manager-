import 'package:eplace/reusable_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:eplace/session_manager.dart';

class ProfileNavigator {
  static Future<void> openProfile(BuildContext context, int targetUserId) async {
    final currentUserId = await SessionManager.getUserId();

    if (!context.mounted) return;

    if (currentUserId != null && currentUserId == targetUserId) {
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