import 'package:flutter/material.dart';
import 'package:eplace/notification_service.dart';
import 'package:eplace/session_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;
    final list = await NotificationService.fetchUserNotifications(userId);

    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleMarkAsRead(int notificationId, bool isRead) async {
    if (!isRead) {
      await NotificationService.markAsRead(notificationId);
      _loadNotifications(); // Refresh state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: Colors.blueAccent,
        child: ListView.builder(
          itemCount: _notifications.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final bool isRead = item['read'] ?? false;
            final String title = item['title'] ?? 'Notification';
            final String message = item['message'] ?? '';
            final int notificationId = item['id'];

            return Card(
              color: isRead ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A3C),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isRead ? Colors.transparent : Colors.blueAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: ListTile(
                onTap: () => _handleMarkAsRead(notificationId, isRead),
                leading: CircleAvatar(
                  backgroundColor: title.contains('Approved') || title.contains('Verified')
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  child: Icon(
                    title.contains('Approved') || title.contains('Verified')
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: title.contains('Approved') || title.contains('Verified')
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.grey[300], fontSize: 13),
                  ),
                ),
                trailing: !isRead
                    ? const CircleAvatar(radius: 4, backgroundColor: Colors.blueAccent)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}