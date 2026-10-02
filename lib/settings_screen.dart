import 'package:flutter/material.dart';
import 'package:eplace/Efootbal_loader.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out of your account?'),
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
    // Navigate to full-screen eFootball loading animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return EFootballLoader(
            onComplete: () {

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                    (Route<dynamic> route) => false,
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        children: [
          // 1. Theme
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Theme'),
            subtitle: Text('System default'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

          // 2. Available updates
          const ListTile(
            leading: Icon(Icons.system_update_outlined),
            title: Text('Available updates'),
            subtitle: Text('Version 1.0.0 (Latest)'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

          // 3. Edit profile
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Edit profile'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

          // 4. Clear local cache
          const ListTile(
            leading: Icon(Icons.cleaning_services_outlined),
            title: Text('Clear local cache'),
            subtitle: Text('0.0 MB'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

          // 5. Rate us
          const ListTile(
            leading: Icon(Icons.star_outline),
            title: Text('Rate us'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

          // 6. About us
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About us'),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),
            enabled: false,
          ),
          const Divider(height: 1),

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