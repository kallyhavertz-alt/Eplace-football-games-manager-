import 'package:eplace/create_league_screen.dart';
import 'package:eplace/interactive_avatar.dart';
import 'package:eplace/join_league_screen.dart';
import 'package:eplace/notification_service.dart';
import 'package:eplace/notifications_screen.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/eplace_scaffold.dart';
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
    return EPlaceScaffold(
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => print('Global Search Clicked'),
                      ),
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

              // --- FEATURED SECTIONS (SWAPPING CARDS / EFOOTBALL STYLE) ---

              // 1. UCL Championship Section
              _buildFeaturedSection(
                title: 'UCL Championship',
                cards: [
                  _buildEFootballCard(
                    leagueName: 'Estate Champions',
                    tagline: 'High member count & massive prize pool',
                    winnerPrize: 'Kes 2,500',
                    joinFee: 'Kes 100',
                    slots: '12/36',
                    imageUrl: 'https://picsum.photos/seed/ucl1/600/300',
                  ),
                  _buildEFootballCard(
                    leagueName: 'Global Mega UCL',
                    tagline: 'Elite tier championship',
                    winnerPrize: 'Kes 5,000',
                    joinFee: 'Kes 200',
                    slots: '28/48',
                    imageUrl: 'https://picsum.photos/seed/ucl2/600/300',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Top Leagues Section
              _buildFeaturedSection(
                title: 'Top Leagues',
                cards: [
                  _buildEFootballCard(
                    leagueName: 'Premier League Pro',
                    tagline: 'High eFootball player strength',
                    winnerPrize: 'Kes 2,000',
                    joinFee: 'Kes 70',
                    slots: '15/25',
                    imageUrl: 'https://picsum.photos/seed/league1/600/300',
                  ),
                  _buildEFootballCard(
                    leagueName: 'Serie A Elite',
                    tagline: 'Intense tactical matches',
                    winnerPrize: 'Kes 1,800',
                    joinFee: 'Kes 50',
                    slots: '19/20',
                    imageUrl: 'https://picsum.photos/seed/league2/600/300',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Top Tournaments Section
              _buildFeaturedSection(
                title: 'Top Tournaments',
                cards: [
                  _buildEFootballCard(
                    leagueName: 'Heha Tournament',
                    tagline: 'Knockout from Group Stage',
                    winnerPrize: 'Kes 3,000',
                    joinFee: 'Kes 200',
                    slots: '13/40',
                    imageUrl: 'https://picsum.photos/seed/tourn1/600/300',
                  ),
                  _buildEFootballCard(
                    leagueName: 'Weekend Clash Cup',
                    tagline: 'Winner takes all format',
                    winnerPrize: 'Kes 4,000',
                    joinFee: 'Kes 250',
                    slots: '30/32',
                    imageUrl: 'https://picsum.photos/seed/tourn2/600/300',
                  ),
                ],
              ),

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
              //_buildHistoryList(),
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
        backgroundColor: Colors.transparent.withValues(alpha: 0.0),
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

  // Helper widget to render category titles with swappable card carousels
  Widget _buildFeaturedSection({required String title, required List<Widget> cards}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: PageView(
            controller: PageController(viewportFraction: 0.92),
            padEnds: false,
            children: cards,
          ),
        ),
      ],
    );
  }

  // Individual eFootball style card with background image & overlay
  Widget _buildEFootballCard({
    required String leagueName,
    required String tagline,
    required String winnerPrize,
    required String joinFee,
    required String slots,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.65),
            BlendMode.darken,
          ),
        ),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leagueName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: Text(
                    slots,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Winner: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(winnerPrize, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Join Fee: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(joinFee, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JoinLeagueScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                  ),
                  child: const Text('Join Now ↗', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /*

  Widget _buildHistoryList() {
    final List> historyData = [
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
    color: Colors.grey[950]?.withValues(alpha: 0.4),
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

   */
}