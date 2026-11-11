import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationHub {
  static final NotificationHub instance = NotificationHub._init();
  NotificationHub._init();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<Map<String, dynamic>>> messagesList = ValueNotifier([]);

   Future<void> receiveForegroundNotification(String title, String body, String updateType, String createdAtTimeStr) async {
     final Map<String, dynamic> newAlert = {
      'title': title,
      'body': body,
      'updateType': updateType,
      'created_at': createdAtTimeStr,
      //'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

     final List<Map<String, dynamic>> currentList = List.from(messagesList.value);
    currentList.insert(0, newAlert);
     messagesList.value = currentList;
    unreadCount.value = unreadCount.value + 1;

    print("📈 NotificationHub Updated: Unread count is now ${unreadCount.value}");

     final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = currentList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cached_cathedral_alerts', encodedList);
    await prefs.setInt('unread_alerts_count', unreadCount.value);
  }

  Future<void> initializeHubCache() async {
    final prefs = await SharedPreferences.getInstance();
    unreadCount.value = prefs.getInt('unread_alerts_count') ?? 0;

    final List<String>? cachedStrings = prefs.getStringList('cached_cathedral_alerts');
    if (cachedStrings != null) {
      messagesList.value = cachedStrings
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    }
  }

  Future<void> markAllAsRead() async {

    unreadCount.value = 0;

      final List<Map<String, dynamic>> updatedList = messagesList.value.map((notification) {
      final copy = Map<String, dynamic>.from(notification);
      copy['isRead'] = true;
      return copy;
    }).toList();

    messagesList.value = updatedList;

    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = updatedList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cached_cathedral_alerts', encodedList);
    await prefs.setInt('unread_alerts_count', 0);

    print(" State Cleaned: All alerts marked as read locally.");
  }
}