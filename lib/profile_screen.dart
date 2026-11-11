import 'dart:io';
import 'dart:convert';
import 'package:eplace/reusable_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eplace/analysis_screen.dart';
import 'package:eplace/friends_screen.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/settings_screen.dart';
import 'package:eplace/edit_profile_screen.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  bool _isLoading = true;
  bool _isOffline = false;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _friendshipData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfileData() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    final bool online = await _hasInternetConnection();

    if (online) {
      try {
        final results = await Future.wait([
          ProfileService.fetchUserProfile(userId),
          ProfileService.fetchFriendshipOverview(userId),
        ]);

        if (mounted) {
          final profileData = results[0];
          final friendshipData = results[1];

          setState(() {
            _userProfile = profileData;
            _friendshipData = friendshipData;
            _isLoading = false;
            _isOffline = false;
          });

          // Cache details locally for offline use
          if (profileData != null) {
            final String? customAvatarPath = prefs.getString('user_avatar_path_$userId');
            if (customAvatarPath != null) {
              profileData['localAvatarPath'] = customAvatarPath;
            }
            await prefs.setString('cached_user_profile_$userId', jsonEncode(profileData));
            await prefs.setString('cached_email_$userId', profileData['email'] ?? '');
            await prefs.setString('cached_location_$userId', profileData['location'] ?? profileData['residentialCell'] ?? '');
            await prefs.setString('cached_bio_$userId', profileData['bio'] ?? '');
            if (profileData['profilePictureUrl'] != null) {
              await prefs.setString('cached_avatar_$userId', profileData['profilePictureUrl']);
            }
          }
          if (friendshipData != null) {
            final friendsList = friendshipData['friends'] as List? ?? [];
            await prefs.setInt('cached_friends_count_$userId', friendsList.length);
            await prefs.setString('cached_friendship_overview_$userId', jsonEncode(friendshipData));
          }
          return;
        }
      } catch (e) {
        debugPrint('Error fetching profile online, falling back to cache: $e');
      }
    }

    // Fallback to local cache when offline or network error
    final cachedProfileStr = prefs.getString('cached_user_profile_$userId');
    final cachedOverviewStr = prefs.getString('cached_friendship_overview_$userId');
    final customAvatarPath = prefs.getString('user_avatar_path_$userId');

    Map<String, dynamic>? localProfile;
    Map<String, dynamic>? localOverview;

    if (cachedProfileStr != null) {
      try {
        localProfile = jsonDecode(cachedProfileStr);
      } catch (_) {}
    }
    if (cachedOverviewStr != null) {
      try {
        localOverview = jsonDecode(cachedOverviewStr);
      } catch (_) {}
    }

    localProfile ??= {};
    if (customAvatarPath != null) {
      localProfile['localAvatarPath'] = customAvatarPath;
    }

    if (mounted) {
      setState(() {
        _userProfile = {
          'username': localProfile?['username'] ?? prefs.getString('username') ?? 'User',
          'email': localProfile?['email'] ?? prefs.getString('cached_email_$userId') ?? 'No email',
          'bio': localProfile?['bio'] ?? prefs.getString('cached_bio_$userId') ?? 'PES Master',
          'location': localProfile?['location'] ?? localProfile?['residentialCell'] ?? prefs.getString('cached_location_$userId') ?? 'Nairobi, Kenya',
          'efootballStrength': localProfile?['efootballStrength'] ?? 3000,
          'profilePictureUrl': localProfile?['profilePictureUrl'] ?? prefs.getString('cached_avatar_$userId') ?? '',
          'localAvatarPath': localProfile?['localAvatarPath'],
        };
        _friendshipData = localOverview ?? {'friends': [], 'suggestions': []};
        _isLoading = false;
        _isOffline = true;
      });
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
    final suggestions = (_friendshipData?['suggestions'] as List?) ?? [];

    return EPlaceScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: Colors.blueAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Offline Mode -',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // 1. TOP HEADER
                _buildTopHeader(),
                const SizedBox(height: 20),

                // 2. USER DETAILS + AVATAR & STRENGTH
                _buildUserInfoSection(),
                const SizedBox(height: 24),

                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),

                // 3. ACHIEVEMENTS SECTION
                _buildAchievementsSection(),
                const SizedBox(height: 24),

                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),

                // 4. FRIENDS SECTION
                _buildFriendsSection(friends),
                const SizedBox(height: 24),

                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),

                // 5. FRIEND SUGGESTIONS SECTION
                _buildSuggestionsSection(suggestions),
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
            Image.asset(
              'assets/eplace.png',
              height: 36,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sports_soccer,
                color: Colors.blueAccent,
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ePlace Football\nEvolution',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.1,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Profile',
              onPressed: () async {
                if (_userId != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        userId: _userId!,
                        baseUrl: ProfileService.baseUrl,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadProfileData();
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FriendsScreen()),
                ).then((_) => _loadProfileData());
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalysisScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    final username = _userProfile?['username'] ?? "User";
    final email = _userProfile?['email'] ?? "No email";
    final bio = _userProfile?['bio'] ?? "PES Master";
    final location = _userProfile?['location'] ?? _userProfile?['residentialCell'] ?? "Nairobi, Kenya";
    final strRating = _userProfile?['efootballStrength'] ?? 3000;
    final String? serverAvatarPath = _userProfile?['profilePictureUrl'];
    final String? localAvatarPath = _userProfile?['localAvatarPath'];

    ImageProvider? avatarImage;
    if (localAvatarPath != null && localAvatarPath.isNotEmpty && File(localAvatarPath).existsSync()) {
      avatarImage = FileImage(File(localAvatarPath));
    } else if (serverAvatarPath != null && serverAvatarPath.isNotEmpty) {
      avatarImage = NetworkImage(ProfileService.getProfilePictureUrl(serverAvatarPath));
    }

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
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
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
                backgroundImage: avatarImage,
                child: avatarImage == null
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Achievements",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "View all",
                style: TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
            ),
          ],
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FriendsScreen()),
                ).then((_) => _loadProfileData());
              },
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        friends.isEmpty
            ? const Text("No friends added yet.", style: TextStyle(color: Colors.grey, fontSize: 13))
            : SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final friend = friends[index];
              final bool isOnline = friend['isOnline'] ?? friend['online'] ?? false;
              final String location = friend['location'] ?? 'Nairobi, Kenya';
              final String? friendAvatarPath = friend['profilePictureUrl'] ?? friend['avatarUrl'];
              final String resolvedAvatarUrl = ProfileService.getProfilePictureUrl(friendAvatarPath);
              final int friendId = friend['userId'] ?? friend['id'];

              return GestureDetector(
                onTap: () {
                  if (friendId != null) {
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
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
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

  Widget _buildSuggestionsSection(List suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Suggestions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                "More",
                style: TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        suggestions.isEmpty
            ? const Text("No suggestions right now.", style: TextStyle(color: Colors.grey, fontSize: 13))
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final targetUserId = suggestion['userId'];
            final String? suggestionAvatarPath = suggestion['profilePictureUrl'] ?? suggestion['avatarUrl'];
            final String resolvedAvatarUrl = ProfileService.getProfilePictureUrl(suggestionAvatarPath);

            return Row(
              children: [
                GestureDetector(
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
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2A2A3C),
                    backgroundImage: resolvedAvatarUrl.isNotEmpty ? NetworkImage(resolvedAvatarUrl) : null,
                    child: resolvedAvatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['username'] ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestion['location'] ?? 'Nairobi, Kenya',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
                  tooltip: 'Add Friend',
                  onPressed: () async {
                    if (_userId != null && targetUserId != null) {
                      final success = await ProfileService.sendFriendRequest(
                          _userId!, targetUserId);
                      if (mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Friend request sent to ${suggestion['username']}!"),
                          ),
                        );
                        _loadProfileData();
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}