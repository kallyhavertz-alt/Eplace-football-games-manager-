import 'package:eplace/analysis_screen.dart';
import 'package:eplace/friends_screen.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/settings_screen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  bool _isLoading = true;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _friendshipData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = userId;

    final results = await Future.wait([
      ProfileService.fetchUserProfile(userId),
      ProfileService.fetchFriendshipOverview(userId),
    ]);

    if (mounted) {
      setState(() {
        _userProfile = results[0];
        _friendshipData = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final friends = (_friendshipData?['friends'] as List?) ?? [];
    final suggestions = (_friendshipData?['suggestions'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
    final location = _userProfile?['location'] ?? "Nairobi, Kenya";
    final strRating = _userProfile?['efootballStrength'] ?? 3000;

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
              child: const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFF2A2A3C),
                child: Icon(Icons.person, size: 48, color: Colors.white70),
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
                "$subtitle • $prize",
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
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Column(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF2A2A3C),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friend['username'] ?? 'User',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
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

            return Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF2A2A3C),
                  child: Icon(Icons.person, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      GestureDetector(
                        onTap: () async {
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
                        child: const Text(
                          "+ Add Friend",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}