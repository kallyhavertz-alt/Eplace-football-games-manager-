import 'package:flutter/material.dart';
import 'package:eplace/Efootbal_loader.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/main.dart';
import 'package:eplace/eplace_scaffold.dart';

import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to log out of your account?', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                _triggerLogoutSequence(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _triggerLogoutSequence(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Center(
          child: EFootballLoader(
            onComplete: () async {
              Navigator.of(dialogContext).pop(); // Close loader dialog
              await SessionManager.clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EPlaceScaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        children: [
          // 1. Theme
          const ListTile(
            leading: Icon(Icons.palette_outlined, color: Colors.white70),
            title: Text('Theme', style: TextStyle(color: Colors.white)),
            subtitle: Text('System default', style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1, color: Colors.white12),

          // 2. Available updates
          const ListTile(
            leading: Icon(Icons.system_update_outlined, color: Colors.white70),
            title: Text('Available updates', style: TextStyle(color: Colors.white)),
            subtitle: Text('Version 1.0.0 (Latest)', style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1, color: Colors.white12),

          // 3. Edit profile
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white70),
            title: const Text('Edit profile', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            enabled: true,
            onTap: () async {
              final int? currentUserId = await SessionManager.getUserId();
              if (!context.mounted) return;

              if (currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userId: currentUserId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚠️ Session error. Please log in again.')),
                );
              }
            },
          ),
          const Divider(height: 1, color: Colors.white12),

          // 4. Clear local cache
          const ListTile(
            leading: Icon(Icons.cleaning_services_outlined, color: Colors.white70),
            title: Text('Clear local cache', style: TextStyle(color: Colors.white)),
            subtitle: Text('0.0 MB', style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1, color: Colors.white12),

          // 5. Rate us
          const ListTile(
            leading: Icon(Icons.star_outline, color: Colors.white70),
            title: Text('Rate us', style: TextStyle(color: Colors.white)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1, color: Colors.white12),

          // 6. About us
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.white70),
            title: Text('About us', style: TextStyle(color: Colors.white)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1, color: Colors.white12),

          const SizedBox(height: 24),

          // 7. Logout (Functional Option)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}
