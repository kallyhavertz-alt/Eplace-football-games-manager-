import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:http/http.dart' as http;
import 'package:eplace/eplace_scaffold.dart';
import 'local_chat_db.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int opponentUserId;
  final int recipientId;
  final String? conversationId;
  final String opponentUsername;
  final bool isOpponentOnline;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.recipientId,
    required this.opponentUserId,
    required this.conversationId,
    required this.opponentUsername,
    required this.isOpponentOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _activeConversationId;

  List<Map<String, dynamic>> _messages = [];
  StompClient? _stompClient;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    if (_activeConversationId != null && _activeConversationId!.isNotEmpty) {
      _loadLocalMessages();
      _fetchServerMessages();
    }
    _connectWebSocket();
  }

  // 1. Load cached messages instantly for offline/fast rendering
  Future<void> _loadLocalMessages() async {
    if (_activeConversationId == null || _activeConversationId!.isEmpty) return;

    final cached = await LocalChatDb.instance.getCachedMessages(_activeConversationId!);
    setState(() {
      _messages = cached.toList();
    });
  }

  // 2. Connect to Spring Boot WebSocket (STOMP)
  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://172.16.125.226:8081/ws-chat/websocket',
        onConnect: (StompFrame frame) {
          _stompClient?.subscribe(
            destination: '/user/queue/messages',
            callback: (StompFrame frame) async {
              if (frame.body != null) {
                final Map<String, dynamic> incoming = json.decode(frame.body!);
                final String? incConvId = incoming['conversationId']?.toString();

                if ((_activeConversationId == null || _activeConversationId!.isEmpty) && incConvId != null) {
                  setState(() => _activeConversationId = incConvId);

                  final db = await LocalChatDb.instance.database;
                  await db.update(
                    'messages',
                    {'conversation_id': incConvId},
                    where: 'conversation_id = ? OR conversation_id = ?',
                    whereArgs: ['', 'null'],
                  );
                }

                final currentConvId = _activeConversationId ?? widget.conversationId;
                if (incConvId == currentConvId || currentConvId == null || currentConvId.isEmpty) {
                  _saveAndAddMessage(incoming);
                }
              }
            },
          );
        },
        stompConnectHeaders: {'user-id': widget.currentUserId.toString()},
      ),
    );
    _stompClient?.activate();
  }

  // 3. Fetch fresh history from server and update local cache
  Future<void> _fetchServerMessages() async {
    final convId = _activeConversationId ?? widget.conversationId;
    if (convId == null || convId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('http://172.16.125.226:8081/api/chat/conversations/$convId/messages?userId=${widget.currentUserId}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> serverData = json.decode(response.body);
        for (var msg in serverData) {
          await LocalChatDb.instance.saveMessage(msg);
        }
        await _loadLocalMessages();
      }
    } catch (e) {
      debugPrint("Offline mode: Using local cache. Error: $e");
    }
  }

  Future<void> _saveAndAddMessage(Map<String, dynamic> msg) async {
    await LocalChatDb.instance.saveMessage(msg);

    setState(() {
      _messages.removeWhere((msg) => msg['id'].toString().startsWith('temp_') && msg['content'] == msg['content']);
    });

    await _loadLocalMessages();
  }

  void _sendMessage() async {
    debugPrint("=== _sendMessage WAS TRIGGERD ===");
    final text = _controller.text.trim();
    if (text.isEmpty)

      return;

    _controller.clear();

    final nowIso = DateTime.now().toIso8601String();
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> localMsg = {
      'id': tempId,
      'conversationId': _activeConversationId ?? widget.conversationId ?? '',
      'conversation_id': _activeConversationId ?? widget.conversationId ?? '',
      'senderId': widget.currentUserId,
      'sender_id': widget.currentUserId,
      'recipientId': widget.recipientId,
      'content': text,
      'type': _isMatchCode(text) ? 'MATCH_CODE' : 'TEXT',
      'status': 'SENDING',
      'createdAt': nowIso,
      'created_at': nowIso,
    };

    setState(() {
      _messages.insert(0, localMsg);
    });

    await LocalChatDb.instance.saveMessage(localMsg);

    if (_stompClient != null) {
      try {
        _stompClient!.send(
          destination: '/app/chat.send',
          body: json.encode({
            'conversationId': _activeConversationId,
            'recipientId': widget.recipientId,
            'senderId': widget.currentUserId,
            'content': text,
            'type': localMsg['type'],
          }),
        );
        debugPrint("STOMP send invoked successfully for destination /app/chat.send");
      } catch (e) {
        debugPrint("Error sending STOMP message: $e");
      }
    } else {
      debugPrint("StompClient is null!");
    }
  }

  bool _isMatchCode(String text) {
    final regex = RegExp(r'\b\d{7,8}\b');
    return regex.hasMatch(text);
  }

  String _formatMessageTimeAndStatus(dynamic rawCreatedAt, String? status, bool isMe) {
    DateTime? dateTime;
    if (rawCreatedAt != null) {
      if (rawCreatedAt is DateTime) {
        dateTime = rawCreatedAt;
      } else {
        dateTime = DateTime.tryParse(rawCreatedAt.toString());
      }
    }

    if (status == 'SENDING') {
      return 'Sending...';
    }

    if (dateTime == null) {
      return isMe ? 'Sent' : '';
    }

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    String timePart;
    if (diff.inSeconds < 60) {
      timePart = 'Just now';
    } else if (diff.inMinutes < 60) {
      timePart = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dateTime.day == now.day) {
      final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      timePart = '$hour:$minute $period';
    } else if (diff.inDays < 7) {
      timePart = '${diff.inDays}d ago';
    } else {
      timePart = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    if (isMe) {
      return 'Sent · $timePart';
    } else {
      return timePart;
    }
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EPlaceScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueGrey.shade700,
                  child: Text(
                    widget.opponentUsername.isNotEmpty ? widget.opponentUsername[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                if (widget.isOpponentOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.opponentUsername,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isOpponentOnline ? 'Active now' : 'Offline',
                  style: TextStyle(color: widget.isOpponentOnline ? Colors.greenAccent : Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Chat starts from bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender_id'] == widget.currentUserId || msg['senderId'] == widget.currentUserId;
                final content = msg['content'] ?? '';
                final status = msg['status']?.toString();
                final rawCreatedAt = msg['created_at'] ?? msg['createdAt'];
                final isCode = _isMatchCode(content);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        if (isCode) ...[
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMe ? Colors.white : Colors.blueAccent,
                              foregroundColor: isMe ? Colors.blueAccent : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              minimumSize: const Size(0, 30),
                            ),
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text('Copy Match Code', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Match code copied to clipboard!'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatMessageTimeAndStatus(rawCreatedAt, status, isMe),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey.shade400,
                                fontStyle: status == 'SENDING' ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                            if (isMe && status == 'SENDING') ...[
                              const SizedBox(width: 4),
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ] else if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done, size: 12, color: Colors.white70),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              border: Border(top: BorderSide(color: Colors.grey.shade800)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.blueAccent),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.mic_none, color: Colors.white70),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.white70),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}