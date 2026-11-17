import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'chat_models.dart';

class ChatApiService {
  static const String baseUrl = 'http://172.16.125.226:8081/api/chat';

  Future<List<ConversationItem>> fetchConversations(int currentUserId) async {
    final uri = Uri.parse('$baseUrl/conversations?userId=$currentUserId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => ConversationItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  Future<String?> findExistingConversationId(int currentUserId, int targetUserId) async {
    try {
      final conversations = await fetchConversations(currentUserId);
      for (var conv in conversations) {
        if (conv.otherParticipant.id == targetUserId) {
          return conv.conversationId;
        }
      }
    } catch (e) {
      debugPrint('Error checking existing conversation: $e');
    }
    return null;
  }
}