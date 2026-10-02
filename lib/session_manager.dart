import 'package:shared_preferences/shared_preferences.dart';
import 'package:eplace/notification_service.dart';

class SessionManager {
  static const String _keyUsername = 'username';
  static const String _keyUserId = 'userId';

   static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

   static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  static Future<void> saveUserSession({required int userId, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
  }


  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }


  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUsername) || prefs.containsKey(_keyUserId);
  }

  static Future<void> clearSession() async {
    final userId = await getUserId();
    if (userId != null) {
      await NotificationService.unsubscribeFromUserTopic(userId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}