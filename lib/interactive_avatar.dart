import 'package:eplace/profile_screen.dart';
import 'package:eplace/session_manager.dart';
import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';

class InteractiveAvatar extends StatefulWidget {
  final String username;

  const InteractiveAvatar({
    super.key,
    required this.username,
  });

  @override
  State<InteractiveAvatar> createState() => _InteractiveAvatarState();
}

class _InteractiveAvatarState extends State<InteractiveAvatar> {
  static const String _adminPassword = "10388doc";

   String get _avatarLetter {
    if (widget.username.trim().isEmpty) return '?';
    return widget.username.trim()[0].toUpperCase();
  }

  // --- PASSWORD CHALLENGE DIALOG ---
  void _showAdminPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blueAccent[100]),
            const SizedBox(width: 10),
            Text(
              'Admin Authentication',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your private administrator key to gain system privileges.',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Admin Password',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark ? Colors.black38 : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == _adminPassword) {
                Navigator.pop(context); // Close password dialog

                // Navigate straight to the Admin Panel!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Access Denied: Invalid Admin Key'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Access',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'admin') {
          _showAdminPasswordDialog();
        } else if (value == 'profile') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        } else if (value == 'logout') {
          await SessionManager.clearSession();
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      offset: const Offset(0, 48), // Drops the menu down cleanly right below the avatar
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
        ),
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blueAccent,
        child: Text(
          _avatarLetter,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text('Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'admin',
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text('Admin Panel', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text('Logout', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
      ],
    );
  }
}