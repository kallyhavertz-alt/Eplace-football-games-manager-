import 'package:flutter/material.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'chat_api_service.dart';
import 'chat_models.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final int currentUserId;

  const InboxScreen({super.key, required this.currentUserId});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatApiService _apiService = ChatApiService();
  late Future<List<ConversationItem>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  void _loadInbox() {
    setState(() {
      _conversationsFuture = _apiService.fetchConversations(widget.currentUserId);
    });
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inDays}d';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
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
        title: const Text(
          'ePlace Codes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadInbox(),
        child: FutureBuilder<List<ConversationItem>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            final conversations = snapshot.data ?? [];

            return ListView(
              children: [
                // 1. Horizontal "ePlace Codes" Bar (Wireframe Top Section)
                _buildCodesHorizontalBar(conversations),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 2. Loading / Error / Empty / Data States for Messages
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text('Error loading chats: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadInbox,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (conversations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text(
                        'No messages yet.\nChallenge a player to start chatting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                else
                  ...conversations.map((chat) => _buildConversationTile(chat)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodesHorizontalBar(List<ConversationItem> conversations) {
    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: conversations.length + 1, // +1 for "You"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "You" bubble with quick-post badge
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade800,
                        child: const Icon(Icons.person, size: 32, color: Colors.white70),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('You', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            );
          }

          final user = conversations[index - 1].otherParticipant;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildAvatarWithStatus(user.username, user.isOnline, radius: 30),
                const SizedBox(height: 6),
                SizedBox(
                  width: 66,
                  child: Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ConversationItem chat) {
    final user = chat.otherParticipant;
    final hasUnread = chat.unreadCount > 0;

    String subtitleText;
    if (chat.lastMessageSnippet.isEmpty && user.isOnline) {
      subtitleText = 'Active Now';
    } else if (chat.lastMessageStatus == 'SENT' && !hasUnread) {
      subtitleText = 'Sent · ${_formatRelativeTime(chat.lastMessageAt)}';
    } else {
      subtitleText = '${chat.lastMessageSnippet} · ${_formatRelativeTime(chat.lastMessageAt)}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildAvatarWithStatus(user.username, user.isOnline, radius: 26),
      title: Text(
        user.username,
        style: TextStyle(
          color: Colors.white,
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        user.isOnline && chat.lastMessageSnippet.isEmpty ? 'Active Now' : subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread
              ? Colors.white
              : (user.isOnline ? Colors.greenAccent : Colors.grey.shade400),
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: widget.currentUserId,
              opponentUserId: user.id,
              recipientId: user.id,
              conversationId: chat.id,
              opponentUsername: user.username,
              isOpponentOnline: user.isOnline,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarWithStatus(String username, bool isOnline, {double radius = 26}) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.blueGrey.shade700,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.7,
              color: Colors.white,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
