
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eplace/notification_service.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/Efootbal_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];

  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadLocalAndFetchNotifications();
  }


  Future<void> _loadLocalAndFetchNotifications() async {
    try {
      final userId = await SessionManager.getUserId();

      if (!mounted) return;

      _userId = userId;

      if (userId == null) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // 1. Load cached notifications first.
      final prefs = await SharedPreferences.getInstance();

      final cachedString =
      prefs.getString('cached_notifications_$userId');

      if (cachedString != null) {
        try {
          final List<dynamic> decoded =
          jsonDecode(cachedString) as List<dynamic>;

          final List<Map<String, dynamic>> cachedNotifications =
          decoded.map((e) {
            return Map<String, dynamic>.from(e as Map);
          }).toList();

          if (mounted) {
            setState(() {
              _notifications = cachedNotifications;
              _sortNotifications();
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error decoding cached notifications: $e');
        }
      }

      // 2. Fetch fresh notifications from backend.
      try {
        final List<dynamic> response =
        await NotificationService.fetchUserNotifications(userId);

        final List<Map<String, dynamic>> mapped =
        response.map((e) {
          return Map<String, dynamic>.from(e as Map);
        }).toList();

        if (!mounted) return;

        // Replace cache with the latest server response.
        setState(() {
          _notifications = mapped;
          _sortNotifications();
          _isLoading = false;
        });

        // Save fresh notifications locally.
        await _saveNotificationsLocally(userId, mapped);
      } catch (e) {
        debugPrint('Error fetching notifications: $e');

        if (mounted) {
          setState(() {
            // Keep cached notifications if API fails.
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _saveNotificationsLocally(
      int userId,
      List<Map<String, dynamic>> list,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'cached_notifications_$userId',
        jsonEncode(list),
      );
    } catch (e) {
      debugPrint('Error saving notifications locally: $e');
    }
  }


  DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is int) {
      // Unix timestamp in milliseconds.
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    final String timestamp = value.toString();

    final parsed = DateTime.tryParse(timestamp);

    if (parsed != null) {
      return parsed;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _sortNotifications() {
    _notifications.sort((a, b) {
      final timeA = _parseTimestamp(
        a['created_at'] ??
            a['createdAt'] ??
            a['timestamp'],
      );

      final timeB = _parseTimestamp(
        b['created_at'] ??
            b['createdAt'] ??
            b['timestamp'],
      );

      return timeB.compareTo(timeA);
    });
  }


  Future<void> _handleMarkAsRead(
      int? notificationId,
      bool isRead,
      ) async {
    if (notificationId == null || isRead) {
      return;
    }

    try {
      // Send request to backend.
      await NotificationService.markAsRead(notificationId);

      if (!mounted) return;

      // Update local notification state.
      setState(() {
        for (var item in _notifications) {
          final int? itemId = int.tryParse(
            item['id']?.toString() ?? '',
          );

          if (itemId == notificationId) {
            item['read'] = true;
            item['isRead'] = true;
          }
        }
      });

      // Save updated notifications.
      if (_userId != null) {
        await _saveNotificationsLocally(
          _userId!,
          _notifications,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }


  void _showFullMessageDrawer(
      Map<String, dynamic> item,
      ) {
    final int? notificationId = int.tryParse(
      item['id']?.toString() ?? '',
    );

    final bool isRead =
        item['read'] == true || item['isRead'] == true;

    final String title =
    (item['title'] ?? 'Notification').toString();

    final String message =
    (item['message'] ?? item['body'] ?? '').toString();

    final String timeStr = _formatTimestamp(
      item['created_at'] ??
          item['createdAt'] ??
          item['timestamp'],
    );

    // Mark as read when opening notification.
    _handleMarkAsRead(notificationId, isRead);

    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xFF1E1E1E).withValues(alpha: 0.95),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notification title.
              Row(
                children: [
                  _buildNotificationAvatar(
                    item,
                    radius: 18,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Notification timestamp.
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),

              const Divider(
                color: Colors.grey,
                height: 24,
              ),

              // Full notification message.
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Close button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildNotificationAvatar(
      Map<String, dynamic> item, {
        double radius = 16,
      }) {
    final String type = (
        item['type'] ??
            item['notification_type'] ??
            ''
    ).toString().toLowerCase();

    final String title =
    (item['title'] ?? '').toString().toLowerCase();

    final String message =
    (item['message'] ?? item['body'] ?? '')
        .toString()
        .toLowerCase();

    // Profile picture.
    final String? profilePicUrl = (
        item['profilePictureUrl'] ??
            item['profile_pic'] ??
            item['user_image'] ??
            item['avatar']
    )?.toString();

    // Friendship or user-related notifications.
    final bool isUserOrFriend =
        type.contains('social') ||
            type.contains('friend_request') ||
            type.contains('user') ||
            type.contains('chat') ||
            title.contains('friend') ||
            title.contains('user') ||
            message.contains('friend') ||
            message.contains('sent you');

    if (isUserOrFriend &&
        profilePicUrl != null &&
        profilePicUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: NetworkImage(profilePicUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint(
            'Error loading profile image: $exception',
          );
        },
      );
    }

    // League or tournament notifications.
    final bool isLeague =
        type.contains('league') ||
            title.contains('league') ||
            message.contains('league');

    final bool isTournament =
        type.contains('tournament') ||
            title.contains('tournament') ||
            message.contains('tournament');

    String? assetImagePath;

    if (isLeague || isTournament) {
      assetImagePath = 'assets/league.png';
    }

    if (assetImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetImagePath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: radius,
              backgroundColor:
              Colors.blueAccent.withValues(alpha: 0.3),
              child: Icon(
                Icons.sports_esports,
                size: radius,
                color: Colors.blueAccent,
              ),
            );
          },
        ),
      );
    }

    // Default fallback icon.
    final bool isApproved =
        title.contains('approved') ||
            title.contains('verified');

    return CircleAvatar(
      radius: radius,
      backgroundColor: isApproved
          ? Colors.green.withValues(alpha: 0.3)
          : Colors.red.withValues(alpha: 0.3),
      child: Icon(
        isApproved
            ? Icons.check_circle_outline
            : Icons.error_outline,
        size: radius + 2,
        color: isApproved
            ? Colors.greenAccent
            : Colors.redAccent,
      ),
    );
  }

  // ============================================================
  // FORMAT TIMESTAMP
  // ============================================================

  String _formatTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp == null) {
      return '';
    }

    final DateTime dt = _parseTimestamp(rawTimestamp);

    if (dt.millisecondsSinceEpoch == 0) {
      return rawTimestamp.toString();
    }

    final DateTime now = DateTime.now();

    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return 'Today at '
          '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';
    }

    return '${dt.year}-'
        '${_twoDigits(dt.month)}-'
        '${_twoDigits(dt.day)} '
        '${_twoDigits(dt.hour)}:'
        '${_twoDigits(dt.minute)}';
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image.
        Positioned.fill(
          child: Image.asset(
            'assets/screens.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
              );
            },
          ),
        ),

        // Transparent scaffold.
        Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            backgroundColor:
            const Color(0xFF1E1E1E).withValues(alpha: 0.0),
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            elevation: 0,
          ),

          body: _isLoading
              ? const Center(
            child: EFootballLoader(size: 64),
          )
              : _notifications.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),

                const SizedBox(height: 12),

                Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadLocalAndFetchNotifications,
            color: Colors.blueAccent,
            child: ListView.builder(
              itemCount: _notifications.length,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              itemBuilder: (context, index) {
                final item = _notifications[index];

                final bool isRead =
                    item['read'] == true ||
                        item['isRead'] == true;

                final String title =
                (item['title'] ?? 'Notification')
                    .toString();

                final String message =
                (item['message'] ??
                    item['body'] ??
                    '')
                    .toString();

                final String timeStr =
                _formatTimestamp(
                  item['created_at'] ??
                      item['createdAt'] ??
                      item['timestamp'],
                );

                final bool isLong =
                    message.length > 60;

                // Preview message.
                final String displayMessage =
                isLong
                    ? '${message.substring(0, 60)}...'
                    : message;

                return Card(
                  color: isRead
                      ? const Color(0xFF1E1E1E)
                      .withValues(alpha: 0.85)
                      : const Color(0xFF2A2A3C)
                      .withValues(alpha: 0.9),

                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                    side: BorderSide(
                      color: isRead
                          ? Colors.transparent
                          : Colors.blueAccent
                          .withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),

                  child: Padding(
                    padding:
                    const EdgeInsets.all(12.0),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // Notification header.
                        Row(
                          children: [
                            _buildNotificationAvatar(
                              item,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Notification preview.
                        Text(
                          displayMessage,
                          style: TextStyle(
                            color: Colors.grey[200],
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Read button.
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            if (!isRead || isLong)
                              TextButton(
                                style:
                                TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize:
                                  const Size(50, 30),
                                  tapTargetSize:
                                  MaterialTapTargetSize
                                      .shrinkWrap,
                                ),

                                onPressed: () {
                                  _showFullMessageDrawer(
                                    item,
                                  );
                                },

                                child: const Text(
                                  'read',
                                  style: TextStyle(
                                    color:
                                    Colors.blueAccent,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
