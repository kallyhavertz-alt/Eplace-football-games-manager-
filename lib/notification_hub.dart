import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationHub {
  static final NotificationHub instance = NotificationHub._init();
  NotificationHub._init();

  //  ValueNotifiers alert the UI instantly when values change
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<Map<String, dynamic>>> messagesList = ValueNotifier([]);

  ///  Call this inside your Firebase Messaging onMessage (Foreground) handler!
  Future<void> receiveForegroundNotification(String title, String body, String updateType, String createdAtTimeStr) async {
    // 1. Create the structured payload object matching your layout expectations
    final Map<String, dynamic> newAlert = {
      'title': title,
      'body': body,
      'updateType': updateType,
      'created_at': createdAtTimeStr,
      //'timestamp': DateTime.now().toIso8601String(),
      'isRead': false, // Added this key explicitly for history panel tracking
    };

    // 2. Safely clone and pull forward the existing memory state list
    final List<Map<String, dynamic>> currentList = List.from(messagesList.value);
    currentList.insert(0, newAlert); // Inject the newest alert right at the top

    // 3. Notify UI Listeners instantly by shifting values out loud
    messagesList.value = currentList;
    unreadCount.value = unreadCount.value + 1;

    print("📈 NotificationHub Updated: Unread count is now ${unreadCount.value}");

    // 4. Handle persistence to disk quietly in the background without blocking the UI thread
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = currentList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cached_cathedral_alerts', encodedList);
    await prefs.setInt('unread_alerts_count', unreadCount.value);
  }

  ///  Warm up cache memory on App startup (Called in main.dart)
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

  ///  Clear the badge tally once the user opens the notification drawer panel
  Future<void> markAllAsRead() async {
    // 1. Instantly reset the unread badge tally value notifier for the UI layer
    unreadCount.value = 0;

    // 2. Safely cycle through the memory list and update historical flags to true
    final List<Map<String, dynamic>> updatedList = messagesList.value.map((notification) {
      final copy = Map<String, dynamic>.from(notification);
      copy['isRead'] = true;
      return copy;
    }).toList();

    messagesList.value = updatedList;

    // 3. Commit changes to SharedPreferences disk storage
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList = updatedList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cached_cathedral_alerts', encodedList);
    await prefs.setInt('unread_alerts_count', 0);

    print("🧹 State Cleaned: All alerts marked as read locally.");
  }
}