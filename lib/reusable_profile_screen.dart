import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final int targetUserId;

  const UserProfileScreen({super.key, required this.targetUserId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int? _currentUserId;
  bool _isLoading = true;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _friendshipData;
  List<dynamic> _currentUserFriends = [];
  bool _isAlreadyFriend = false;

  @override
  void initState() {
    super.initState();
    _loadTargetProfileData();
  }

  Future<void> _loadTargetProfileData() async {
    final currentUserId = await SessionManager.getUserId();
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _currentUserId = currentUserId;

    try {
      final results = await Future.wait([
        ProfileService.fetchUserProfile(widget.targetUserId),
        ProfileService.fetchFriendshipOverview(widget.targetUserId),
        ProfileService.fetchFriendshipOverview(currentUserId),
      ]);

      if (mounted) {
        final profileData = results[0];
        final targetOverview = results[1];
        final currentUserOverview = results[2];

        final currentUserFriends = (currentUserOverview?['friends'] as List?) ?? [];
        bool isFriend = currentUserFriends.any((f) => (f['userId'] ?? f['id']) == widget.targetUserId);

        setState(() {
          _userProfile = profileData;
          _friendshipData = targetOverview;
          _currentUserFriends = currentUserFriends;
          _isAlreadyFriend = isFriend;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading target user profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFriendRequest(int userIdToobar, String username) async {
    if (_currentUserId == null) return;

    final success = await ProfileService.sendFriendRequest(_currentUserId!, userIdToobar);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request sent to $username!")),
      );
      _loadTargetProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const EPlaceScaffold(
        body: Center(
          child: EFootballLoader(size: 64),
        ),
      );
    }

    final friends = (_friendshipData?['friends'] as List?) ?? [];

    return EPlaceScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTargetProfileData,
          color: Colors.blueAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 20),
                _buildUserInfoSection(),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),
                _buildAchievementsSection(),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),
                _buildFriendsSection(friends),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Image.asset(
              'assets/eplace.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sports_soccer,
                color: Colors.blueAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ePlace Football\nEvolution',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    final username = _userProfile?['username'] ?? "User";
    final email = _userProfile?['email'] ?? "";
    final bio = _userProfile?['bio'] ?? "PES Master";
    final location = _userProfile?['location'] ?? _userProfile?['residentialCell'] ?? "Nairobi, Kenya";
    final strRating = _userProfile?['efootballStrength'] ?? 3000;
    final String? serverAvatarPath = _userProfile?['profilePictureUrl'];

    String resolvedAvatarUrl = ProfileService.getProfilePictureUrl(serverAvatarPath);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
              const SizedBox(height: 10),
              Text(
                bio,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentUserId != widget.targetUserId)
                _isAlreadyFriend
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.blueAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Friends",
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                )
                    : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _sendFriendRequest(widget.targetUserId, username),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text("Add Friend", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFF2A2A3C),
                backgroundImage: resolvedAvatarUrl.isNotEmpty ? NetworkImage(resolvedAvatarUrl) : null,
                child: resolvedAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 48, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Text(
                "STR $strRating",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Achievements",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _buildAchievementItem(
          rankText: "2",
          badgeColor: Colors.blueGrey,
          title: "Golden League",
          subtitle: "Finished #2",
          prize: "KES 2700",
        ),
        const SizedBox(height: 12),
        _buildAchievementItem(
          rankText: "1",
          badgeColor: Colors.amber,
          title: "Weekend Challenge",
          subtitle: "Winner 👑",
          prize: "KES 3000",
        ),
      ],
    );
  }

  Widget _buildAchievementItem({
    required String rankText,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String prize,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor.withOpacity(0.2),
            border: Border.all(color: badgeColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              rankText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                "$subtitle\n$prize",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(List friends) {
    // Restrict to max 5 friends for horizontal preview
    final displayedFriends = friends.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${friends.length} Friends",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (friends.length > 5)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TargetUserAllFriendsScreen(
                        targetUsername: _userProfile?['username'] ?? 'User',
                        allFriends: friends,
                        currentUserFriends: _currentUserFriends,
                        currentUserId: _currentUserId!,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "More",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        friends.isEmpty
            ? const Text("No friends listed.", style: TextStyle(color: Colors.grey, fontSize: 13))
            : SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayedFriends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final friend = displayedFriends[index];
              final bool isOnline = friend['isOnline'] ?? friend['online'] ?? false;
              final String location = friend['location'] ?? 'Nairobi, Kenya';
              final String? friendAvatarPath = friend['profilePictureUrl'] ?? friend['avatarUrl'];
              final String resolvedAvatarUrl = ProfileService.getProfilePictureUrl(friendAvatarPath);

              return GestureDetector(
                onTap: () {
                  final friendId = friend['userId'] ?? friend['id'];
                  if (friendId != null && friendId != _currentUserId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(targetUserId: friendId),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF2A2A3C),
                          backgroundImage: resolvedAvatarUrl.isNotEmpty ? NetworkImage(resolvedAvatarUrl) : null,
                          child: resolvedAvatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.greenAccent : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF121212), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend['username'] ?? 'User',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dedicated Screen to display all friends of the target user vertically
class TargetUserAllFriendsScreen extends StatelessWidget {
  final String targetUsername;
  final List<dynamic> allFriends;
  final List<dynamic> currentUserFriends;
  final int currentUserId;

  const TargetUserAllFriendsScreen({
    super.key,
    required this.targetUsername,
    required this.allFriends,
    required this.currentUserFriends,
    required this.currentUserId,
  });

  String _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final uri = Uri.parse(ProfileService.baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}${path.startsWith('/') ? '' : '/'}$path';
  }

  @override
  Widget build(BuildContext context) {
    return EPlaceScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$targetUsername's Friends",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: allFriends.isEmpty
          ? const Center(child: Text("No friends found.", style: TextStyle(color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: allFriends.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final friend = allFriends[index];
          final int friendId = friend['userId'] ?? friend['id'];
          final String username = friend['username'] ?? 'User';
          final String location = friend['location'] ?? 'Nairobi, Kenya';
          final bool isOnline = friend['isOnline'] ?? friend['online'] ?? false;
          final String resolvedAvatar = _resolveAvatarUrl(friend['profilePictureUrl'] ?? friend['avatarUrl']);

          // Check if current user is already friends with this person
          final bool isAlreadyFriend = friendId == currentUserId ||
              currentUserFriends.any((f) => (f['userId'] ?? f['id']) == friendId);

          return Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () {
                if (friendId != currentUserId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(targetUserId: friendId),
                    ),
                  );
                }
              },
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2A2A3C),
                    backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
                    child: resolvedAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: friendId == currentUserId
                  ? const SizedBox.shrink()
                  : isAlreadyFriend
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.blueAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Friends",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              )
                  : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () async {
                  final success = await ProfileService.sendFriendRequest(currentUserId, friendId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Friend request sent to $username!")),
                    );
                  }
                },
                icon: const Icon(Icons.person_add, size: 14, color: Colors.white),
                label: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          );
        },
      ),
    );
  }
}