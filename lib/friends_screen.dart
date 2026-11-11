import 'dart:io';
import 'dart:convert';
import 'package:eplace/reusable_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _userId;
  bool _isLoading = true;

  List<dynamic> _friendsList = [];
  List<dynamic> _pendingList = [];
  List<dynamic> _receivedList = [];

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFriendsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final uri = Uri.parse(ProfileService.baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}${path.startsWith('/') ? '' : '/'}$path';
  }

  Future<void> _loadFriendsData() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final bool online = await _hasInternetConnection();

    if (online) {
      try {
        final overview = await ProfileService.fetchFriendshipOverview(userId);
        if (mounted && overview != null) {
          setState(() {
            _friendsList = overview['friends'] ?? [];
            _pendingList = overview['pendingSent'] ?? [];
            _receivedList = overview['receivedRequests'] ?? [];
            _isLoading = false;
          });
          await prefs.setString('cached_friendship_overview_$userId', jsonEncode(overview));
          return;
        }
      } catch (e) {
        debugPrint('Error loading friends overview online: $e');
      }
    }

    final cachedStr = prefs.getString('cached_friendship_overview_$userId');
    if (cachedStr != null) {
      try {
        final overview = jsonDecode(cachedStr);
        if (mounted) {
          setState(() {
            _friendsList = overview['friends'] ?? [];
            _pendingList = overview['pendingSent'] ?? [];
            _receivedList = overview['receivedRequests'] ?? [];
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    final results = await ProfileService.searchUsers(query.trim());

    if (mounted) {
      setState(() {
        _searchResults = results.where((u) {
          final targetId = u['userId'] ?? u['id'];
          return targetId != _userId;
        }).toList();
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(int targetUserId, String username) async {
    if (_userId == null) return;

    final success = await ProfileService.sendFriendRequest(_userId!, targetUserId);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Friend request sent to $username! Notification sent."),
          backgroundColor: Colors.green,
        ),
      );
      await _loadFriendsData();
    }
  }

  Future<void> _cancelRequest(int targetUserId) async {
    if (_userId == null) return;

    final success = await ProfileService.cancelFriendRequest(_userId!, targetUserId);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request canceled."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      await _loadFriendsData();
    }
  }

  Future<void> _handleResponse(int friendshipId, bool accept, String username) async {
    if (_userId == null) return;

    final success = await ProfileService.respondToFriendRequest(_userId!, friendshipId, accept);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? "Accepted $username's request!" : "Declined request.",
          ),
          backgroundColor: accept ? Colors.green : Colors.redAccent,
        ),
      );
      _loadFriendsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EPlaceScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Friends',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            const Tab(text: 'Friends'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingList.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('(${_pendingList.length})',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Received'),
                  if (_receivedList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_receivedList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: EFootballLoader(size: 64))
          : RefreshIndicator(
        onRefresh: _loadFriendsData,
        color: Colors.blueAccent,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFriendsTab(),
            _buildPendingTab(),
            _buildReceivedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friendsList.isEmpty) {
      return _buildEmptyState('No friends added yet');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _friendsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final friend = _friendsList[index];
        final bool isOnline = friend['isOnline'] ?? false;
        final String username = friend['username'] ?? 'User';
        final String location = friend['location'] ?? 'Nairobi, Kenya';
        final String resolvedAvatar = _resolveAvatarUrl(friend['profilePictureUrl'] ?? friend['avatarUrl']);
        final int? targetUserId = friend['userId'] ?? friend['id'];

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              if (targetUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(targetUserId: targetUserId),
                  ),
                );
              }
            },
            leading: GestureDetector(
              onTap: () {
                if (targetUserId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(targetUserId: targetUserId),
                    ),
                  );
                }
              },
              child: Stack(
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: isOnline ? Colors.greenAccent : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search username in ePlace...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              suffixIcon: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                ),
              )
                  : (_searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              )
                  : null),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        if (_searchResults.isNotEmpty) ...[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final int? targetUserId = user['userId'] ?? user['id'];
                final String username = user['username'] ?? '';
                final String bio = user['bio'] ?? 'No bio provided';
                final String location = user['location'] ?? 'Location hidden';
                final String resolvedAvatar = _resolveAvatarUrl(user['profilePictureUrl'] ?? user['avatarUrl']);

                final bool isAlreadyFriend = _friendsList.any(
                      (f) => (f['userId'] ?? f['id']) == targetUserId,
                );
                final bool isPending = _pendingList.any(
                      (item) => item['userId'] == targetUserId || item['username'] == username,
                );

                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF2A2A3C)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (targetUserId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(targetUserId: targetUserId),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF2A2A3C),
                            backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
                            child: resolvedAvatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.white, size: 28)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: Colors.blueAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      location,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          isAlreadyFriend
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.blueAccent, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "Friends",
                                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                              : isPending
                              ? OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              if (targetUserId != null) _cancelRequest(targetUserId);
                            },
                            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          )
                              : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              if (targetUserId != null) _sendRequest(targetUserId, username);
                            },
                            icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                            label: const Text('+ Add', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),


        ] else if (_pendingList.isNotEmpty)
          ...[
            Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _pendingList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _pendingList[index];
                final int? targetUserId = item['userId'] ?? item['id'];
                final String username = item['username'] ?? 'User';
                final String timeAgo = item['timeAgo'] ?? 'Recently';
                final String resolvedAvatar = _resolveAvatarUrl(item['profilePictureUrl'] ?? item['avatarUrl']);

                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () {
                      if (targetUserId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(targetUserId: targetUserId),
                          ),
                        );
                      }
                    },
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF2A2A3C),
                      backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
                      child: resolvedAvatar.isEmpty ? const Icon(Icons.person_outline, color: Colors.white70) : null,
                    ),
                    title: Text(
                      username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Sent $timeAgo',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        if (targetUserId != null) _cancelRequest(targetUserId);
                      },
                      child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_outlined, size: 60, color: Colors.grey[700]),
                  const SizedBox(height: 12),
                  const Text('No pending sent requests', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedList.isEmpty) {
      return _buildEmptyState('No incoming friend requests');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _receivedList[index];
        final int friendshipId = item['id'];
        final int? targetUserId = item['userId'] ?? item['id'];
        final String username = item['username'] ?? 'User';
        final String timeAgo = item['timeAgo'] ?? 'Recently';
        final String resolvedAvatar = _resolveAvatarUrl(item['profilePictureUrl'] ?? item['avatarUrl']);

        return Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (targetUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(targetUserId: targetUserId),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2A2A3C),
                    backgroundImage: resolvedAvatar.isNotEmpty ? NetworkImage(resolvedAvatar) : null,
                    child: resolvedAvatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _handleResponse(friendshipId, true, username),
                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => _handleResponse(friendshipId, false, username),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }
}
