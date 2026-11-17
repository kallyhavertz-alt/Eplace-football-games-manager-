import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatService {
  final String baseUrl = "http://YOUR_SERVER_IP:8081/api/chat";
  final String wsUrl = "ws://YOUR_SERVER_IP:8081/ws-chat/websocket";

  StompClient? stompClient;


  void connectWebSocket(Long currentUserId, Function(Map<String, dynamic>) onMessageReceived) {
    stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          print("Connected to WebSocket!");
          // Subscribe to private queue
          stompClient?.subscribe(
            destination: '/user/queue/messages',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final Map<String, dynamic> data = json.decode(frame.body!);
                onMessageReceived(data);
              }
            },
          );
        },
        onWebSocketError: (error) => print("WS Error: $error"),
        stompConnectHeaders: {'user-id': currentUserId.toString()},
        webSocketConnectHeaders: {'user-id': currentUserId.toString()},
      ),
    );
    stompClient?.activate();
  }


  void sendMessageViaSocket({Long? recipientId, String? conversationId, required String content}) {
    stompClient?.send(
      destination: '/app/chat.send',
      body: json.encode({
        'recipientId': recipientId,
        'conversationId': conversationId,
        'content': content,
        'type': 'TEXT'
      }),
    );
  }


  Future<List<dynamic>> getConversations(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/conversations?userId=$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load conversations');
  }


  Future<List<dynamic>> getMessages(int userId, String conversationId, {String? cursor}) async {
    String url = '$baseUrl/conversations/$conversationId/messages?userId=$userId';
    if (cursor != null) url += '&cursor=$cursor';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load messages');
  }
}