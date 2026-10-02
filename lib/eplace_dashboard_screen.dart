import 'package:eplace/create_league_screen.dart';
import 'package:eplace/interactive_avatar.dart';
import 'package:eplace/join_league_screen.dart';
import 'package:eplace/notification_service.dart';
import 'package:eplace/notifications_screen.dart';
import 'package:eplace/session_manager.dart';
import 'package:flutter/material.dart';

class EplaceDashboardScreen extends StatefulWidget {
  final String username;
  const EplaceDashboardScreen({super.key, required this.username});

  @override
  State<EplaceDashboardScreen> createState() => _EplaceDashboardScreenState();
}

class _EplaceDashboardScreenState extends State<EplaceDashboardScreen> {
  int _currentIndex = 0;

   String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER LAYER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getGreeting()}, ${widget.username}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => print('Global Search Clicked'),
                      ),
                     /* IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () => print('Shared Codes Notifications Clicked'),
                      ),

                      */
                      // Replace your existing IconButton with this:

                      FutureBuilder<int>(
                        future: SessionManager.getUserId().then((id) => id != null ? NotificationService.fetchUnreadCount(id) : 0),
                        builder: (context, snapshot) {
                          final int unreadCount = snapshot.data ?? 0;

                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.white),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                  );
                                  setState(() {});
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      InteractiveAvatar(username: widget.username),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              // --- CURRENTLY PARTICIPATING BOX ---
              const Text(
                'CURRENTLY PARTICIPATING',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              _buildOngoingCard(),

              const SizedBox(height: 16),
              // --- JOIN A LEAGUE NOW ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JoinLeagueScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.blueAccent),
                  label: const Text(
                    'Join a league now',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- MY LEAGUES HISTORY LIST ---
              Row(
                children: [
                  Icon(Icons.sort, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'My leagues',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHistoryList(),
            ],
          ),
        ),
      ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateLeagueScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[950],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Leagues'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 32, color: Colors.blueAccent), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Send Codes'),
        ],
      ),
    );
  }

  Widget _buildOngoingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Master-league',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Current Position: ', style: TextStyle(color: Colors.grey)),
                  Text('1', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 24),
                  const Text('Points: ', style: TextStyle(color: Colors.grey)),
                  Text('34', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('Ongoing', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final List<Map<String, dynamic>> historyData = [
      {'title': 'Weekend-Challenge-league', 'meta': 'Winner', 'prize': 'Kes 2,500', 'isWin': true},
      {'title': 'Estate-Champions', 'meta': 'Finished 5th', 'prize': null, 'isWin': false},
      {'title': 'Fist-tournament', 'meta': 'Knocked-Out | Round of 16', 'prize': null, 'isWin': false},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyData.length,
      itemBuilder: (context, index) {
        final item = historyData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[950],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[900]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    item['meta'],
                    style: TextStyle(color: item['isWin'] ? Colors.greenAccent : Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
              if (item['prize'] != null)
                Text(
                  item['prize'],
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                )
            ],
          ),
        );
      },
    );
  }
}