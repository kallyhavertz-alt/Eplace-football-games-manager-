import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'http://172.16.123.181:8081/api/v1';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static String getProfilePictureUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final uri = Uri.parse(baseUrl);
    final baseHost = '${uri.scheme}://${uri.host}:${uri.port}';
    return '$baseHost${path.startsWith('/') ? '' : '/'}$path';
  }


  static Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchFriendshipOverview(int userId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/friends/$userId'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching friendship overview: $e');
    }
    return null;
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/profile/search?query=${Uri.encodeComponent(query)}'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('content')) {
          return data['content'] ?? [];
        }
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
    return [];
  }


  static Future<bool> sendFriendRequest(int currentUserId, int targetUserId) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/friends/request?requesterId=$currentUserId&addresseeId=$targetUserId'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }


  static Future<bool> cancelFriendRequest(int currentUserId, int targetUserId) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/friends/cancel?requesterId=$currentUserId&addresseeId=$targetUserId'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error canceling friend request: $e');
      return false;
    }
  }


  static Future<bool> respondToFriendRequest(int currentUserId, int friendshipId, bool accept) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/friends/respond?userId=$currentUserId&friendshipId=$friendshipId&accept=$accept'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error responding to friend request: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>?> fetchUserAnalytics(int userId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/profile/$userId/analytics'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching user analytics: $e');
    }
    return null;
  }
}

