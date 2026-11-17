class UserSummary {
  final int id;
  final String username;
  final bool isOnline;
  final String lastSeenText;

  UserSummary({
    required this.id,
    required this.username,
    required this.isOnline,
    required this.lastSeenText,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'],
      username: json['username'] ?? 'eplace-user',
      isOnline: json['online'] ?? json['isOnline'] ?? false,
      lastSeenText: json['lastSeenText'] ?? 'Active now',
    );
  }
}

class ConversationItem {
  final String conversationId;
  final UserSummary otherParticipant;
  final String lastMessageSnippet;
  final String lastMessageStatus;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isNonFriendChat;
  final int messagesSentByMe;

  String get id => conversationId;

  ConversationItem({
    required this.conversationId,
    required this.otherParticipant,
    required this.lastMessageSnippet,
    required this.lastMessageStatus,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isNonFriendChat,
    required this.messagesSentByMe,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      conversationId: json['conversationId'],
      otherParticipant: UserSummary.fromJson(json['otherParticipant']),
      lastMessageSnippet: json['lastMessageSnippet'] ?? '',
      lastMessageStatus: json['lastMessageStatus'] ?? 'SENT',
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
      isNonFriendChat: json['nonFriendChat'] ?? json['isNonFriendChat'] ?? false,
      messagesSentByMe: json['messagesSentByMe'] ?? 0,
    );
  }
}