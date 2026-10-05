/*import 'package:flutter/material.dart';
import 'main.dart';
// IMPORTS FOR THE DYNAMIC LIVE STREAMING ENGINE
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({Key? key}) : super(key: key);

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Live and ongoing events / sermons',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 ZONE 1: Bordered Search Input Bar
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black87, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search for events / sermons...',
                          hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🔴 ZONE 2: Live Now Module (Now Fully Powered by Spring Boot)
              const Text(
                'Live now on Player',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // 🎯 DROPPING OUR NEW LIVE ENGINE HERE - ZERO INTERFERENCE WITH OUTSIDE UI
              const CathedralPlayer(),

              const SizedBox(height: 32),

              // 📅 ZONE 3: Featured Upcoming Events Stream Section
              const Text(
                'Featured upcoming events.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // Upcoming Event Card matching your detailed Tuesday sketch box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lay Reader Appointment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left detail column housing day info and icons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tuesday',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.add, color: Colors.grey[700], size: 20),
                                const SizedBox(width: 12),
                                Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                              ],
                            ),
                          ],
                        ),
                        // Right detail side tracking schedule calendar line
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Scheduled at',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                            const Text(
                              '9th June 2026.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🏷️ ZONE 4: Interactive See All Action Bubble
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    // Placeholder handle for showing complete catalog
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏛️ SELF-CONTAINED ENGINE: Cathedral Streaming Player Widget
class CathedralPlayer extends StatefulWidget {
  const CathedralPlayer({Key? key}) : super(key: key);

  @override
  State<CathedralPlayer> createState() => _CathedralPlayerState();
}

class _CathedralPlayerState extends State<CathedralPlayer> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _errorMessage;
  String _streamTitle = "Fetching live feed data...";
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _initLiveStreamEngine();
  }

  // 📡 Upgraded to safely dispose and refresh stream allocations on demand
  Future<void> _initLiveStreamEngine() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Clean up active controller completely before initializing a replacement connection
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    try {
      // 📡 Request current live URL from your running Spring Boot server
      final response = await http.get(Uri.parse('http://10.34.113.23:8080/api/live/current'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String streamUrl = data['streamUrl'];
        final String title = data['title'] ?? "Cathedral Sermon Service";
        final bool liveStatus = data['live'] ?? false;

        // 🤖 Pass the server's URL straight into ExoPlayer
        _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl))
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {
              _streamTitle = title;
              _isLive = liveStatus;
              _isLoading = false;
            });
            _videoController!.play();
            WakelockPlus.enable(); // Keep user screen illuminated
          }).catchError((error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = "Unable to process video stream data format.";
            });
          });
      } else {
        throw Exception("Server connection error");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not link to backend streaming network.";
      });
    }
  }

  @override
  void dispose() {
    // 🧼 Clean hardware cache immediately on page transition to avoid leaks
    _videoController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // Dynamic Media Core Container Box
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.redAccent)
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    // Centered user notification message if connection drops
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                // Plays video neatly within bounds
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),

                // Static source banner indicator overlay matching your exact layout design
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CATHEDRAL LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // 🎯 NON-INTRUSIVE REFRESH ACTION BUTTON LAYER
                if (!_isLoading)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: _initLiveStreamEngine, // Directly updates system hardware endpoints safely
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Text Details Area
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _streamTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isLive ? Colors.red : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLive ? 'Live' : 'Offline',
                      style: TextStyle(
                          color: _isLive ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}












import 'package:flutter/material.dart';
import 'main.dart' show HomeScreen;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveEventsScreen extends StatefulWidget {
  const LiveEventsScreen({Key? key}) : super(key: key);

  @override
  State<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends State<LiveEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _upcomingEvents = [];
  bool _isEventsLoading = true;

  // 📡 Consistent API Configuration linked to your backend
  final String _eventsApiUrl = "http://10.34.113.23:8080/api/events/all";

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEventsCatalog();
  }

  Future<void> _fetchUpcomingEventsCatalog() async {
    try {
      final response = await http.get(Uri.parse(_eventsApiUrl));
      if (response.statusCode == 200) {
        if (!mounted) return;
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          // Grabs everything to display sequentially on the scheduling list
          _upcomingEvents = data;
          _isEventsLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isEventsLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEventsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Live and ongoing events / sermons',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0D47A1),
        onRefresh: _fetchUpcomingEventsCatalog,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 ZONE 1: Bordered Search Input Bar
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.black87, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search for events / sermons...',
                            hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 13.5),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🔴 ZONE 2: Live Now Module
                const Text(
                  'Live now on Player',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),

                // Native Stream Player
                const CathedralLivePlayer(),

                const SizedBox(height: 32),

                // 📅 ZONE 3: Dynamic Featured Upcoming Events Section
                const Text(
                  'Featured upcoming events.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // Checks network download status or renders items instantly
                if (_isEventsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
                    ),
                  )
                else if (_upcomingEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      'No upcoming cathedral events found.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                // Builds out the cards natively without hardcoded locks
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final item = _upcomingEvents[index];

                      // Safely grab dates or parse display properties if available
                      String eventDate = item['eventDate'] ?? "Upcoming";
                      if (eventDate.length >= 10) {
                        eventDate = eventDate.substring(0, 10);
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['eventTitle'] ?? 'Cathedral Fellowship',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description'] ?? 'Join us in prayer and worship.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Church Event',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.add, color: Colors.grey[700], size: 20),
                                        const SizedBox(width: 12),
                                        Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Scheduled at',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      eventDate,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // 🏷️ ZONE 4: Interactive See All Action Bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CathedralLivePlayer extends StatefulWidget {
  const CathedralLivePlayer({Key? key}) : super(key: key);

  @override
  State<CathedralLivePlayer> createState() => _CathedralLivePlayerState();
}

class _CathedralLivePlayerState extends State<CathedralLivePlayer> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _errorMessage;
  String _streamTitle = "Fetching live feed data...";
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _initLiveStreamEngine();
  }

  Future<void> _initLiveStreamEngine() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    try {
      final response = await http.get(Uri.parse('http://10.34.113.23:8080/api/live/current'));
if (response.statusCode == 200) {
final List<dynamic> dataList = jsonDecode(response.body); // Now: It's a list!

if (dataList.isNotEmpty) {
// Grabs index 0, which is the newest video stream uploaded by the media team
  final data = dataList[0];

  final String streamUrl = data['streamUrl'];
  final String title = data['title'] ?? "Cathedral Sermon Service";
  final bool liveStatus = data['live'] ?? false;

// ... rest of your initialization logic remains exactly the same ...

  _videoController = VideoPlayerController.networkUrl(Uri.parse(streamUrl))
    ..initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _streamTitle = title;
        _isLive = liveStatus;
        _isLoading = false;
      });
      _videoController!.play();
      WakelockPlus.enable();
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Unable to process video stream data format.";
      });
    });
}
      } else {
        throw Exception("Server configuration error");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not link to backend streaming network.";
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.redAccent)
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CATHEDRAL LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                if (!_isLoading)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: _initLiveStreamEngine,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _streamTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isLive ? Colors.red : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLive ? 'Live' : 'Offline',
                      style: TextStyle(
                          color: _isLive ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}*/
// NOTES SYNCS.

/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/main.dart';
import 'dart:convert';
import 'package:untitled/note_work_space_screen.dart';
import 'package:untitled/session_manager.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final String _fetchNotesUrl = 'http://10.34.113.23:8080/api/notes/user/1';
  // 📚 Section 1 Data: Saved Notes matching your exact blueprint text
  List<dynamic> _postgresNotes = [];
  String _formatPostgresDate(String? rawDateString) {
    if (rawDateString == null || rawDateString.isEmpty) {
      return 'Date Unknown';
    }

    try {
      // Parses the incoming ISO timestamp from PostgreSQL (e.g., "2026-05-26T12:34:56Z")
      DateTime parsedDate = DateTime.parse(rawDateString);

      // Extracts just the day, month, and year components
      String day = parsedDate.day.toString();
      String year = parsedDate.year.toString();

      // Maps out months to match your exact reading log style text
      List<String> months = [
        'Jan', 'Feb', 'March', 'April', 'May', 'June',
        'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
      ];
      String monthName = months[parsedDate.month - 1];

      // Returns a beautiful, clean string line: "26 May 2026"
      return '$day $monthName $year';
    } catch (e) {
      return 'Recent Note'; // Safe fallback if parsing hits a snag
    }
  }
  bool _isLoading = true;
 // final String _apiUrl = "http://10.34.113.23:8080/api/notes/user/{userId}/add/{userId}";

  // 🗓️ Section 2 Data: Event Readings matching your exact calendar logs
  final List<Map<String, String>> _eventReadings = [
    {
      'number': '1.',
      'title': 'Psalm Sunday reading',
      'date': '17th March 2026',
    },
    {
      'number': '2.',
      'title': 'Holy Communion reading',
      'date': '24th March 2026',
    },
  ];

  //final String _baseIpUrl = 'http://10.34.113.23:8080/api/notes/user/1';

  final int currentUserId = 1;
  @override
  void initState() {
    super.initState();
    _fetchUserNotesFromBackend();
  }
  Future<void> _fetchUserNotesFromBackend() async {
    // 🎯 DYNAMIC: Read the active ID directly from our SessionManager
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    try {
      print('📡 Loading Notes screen for: ${SessionManager.currentUserLabel}');
      print('📡 Dynamically fetching from: $dynamicFetchUrl');

      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse(dynamicFetchUrl));

      if (response.statusCode == 200) {
        setState(() {
          _postgresNotes = jsonDecode(response.body);
          _isLoading = false;
        });
        print('✅ Successfully loaded ${_postgresNotes.length} notes for User $activeId');
      } else {
        print('❌ Server error loading notes: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('🚨 Connection exception during fetch: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top Custom Navigation App Bar row matching your sketch top-line
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen())
            );
            // Optional back navigation logic
          },
        ),
        title: const Text(
          'My Notes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 SKETCH COMPONENT: Custom Styled Search Bar Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black54, width: 1.2),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for notes and readings',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 1: MY SAVED NOTES
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My saved notes.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _isLoading
                ? const Center(child:
                  CircularProgressIndicator.adaptive())
                : _postgresNotes.isEmpty
                ? const Padding(
                  padding:
                  EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('you have not saved any note yet. Add a note now!', style: TextStyle(color: Colors.grey)),
                )
                // Generating the numbered notes list
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _postgresNotes.length,
                  itemBuilder: (context, index) {
                    final note = _postgresNotes[index];
                    final int itemNumber = index + 1;
                    final bool isPersonalNote = note['eventId'] == null || note['eventId'] == 1;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NoteWorkspaceScreen(noteId: note['id'],
                          eventId: note['eventId'] ?? 1,
                          eventTitle: note['eventTitle'] ?? 'Cathedral Service',
                          isEditing: true,
                          initialTitle:
                            note['title'] ?? '',
                           initialContent:
                            note['content'] ?? '',
                          ),
                        ),
                        ).then((value) {
                          if (value == true) {
                            _fetchUserNotesFromBackend();
                          }
                        });
                      },

                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$itemNumber',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isPersonalNote)
                                  Text(
                                    note['eventTitle'] ?? 'General Sermon Note',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1)),
                                  ),
                               // Text(
                                //  note['type'] ?? 'my notes',
                               //   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1)),
                                //),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    children: [
                                      const TextSpan(text: 'Title: '),
                                      TextSpan(
                                        text: note['title'] ?? 'title',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isPersonalNote)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                    _formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date']),
                                      style: TextStyle(fontSize: 13, color: Colors.greenAccent,
                                      fontWeight: FontWeight.w500),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    );
                  },
                ),
                const SizedBox(height: 90),

                // ==========================================
                // SECTION 2: MY EVENTS READINGS
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My Events readings.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Generating the numbered events list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _eventReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _eventReadings[index];
                    final int readingNumber = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$readingNumber',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reading['title'] ?? 'General reading',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  reading['date'] ?? 'unknown',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80), // Creates safety spacing so content doesn't hide under the button
              ],
            ),
          ),

          // 🚀 SKETCH COMPONENT: Bottom Right Rectangular Custom "+ Add Note" Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: OutlinedButton.icon(
              onPressed: () {
                // 💡 Wires up opening NoteWorkspaceScreen for a BRAND NEW note
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteWorkspaceScreen(
                      noteId: null,                 // Null means Spring Boot treats this as a brand new insert!
                      eventId: 1,                    // 1 identifies it as a generic/personal note lane
                      eventTitle: 'Personal Note',
                      isEditing: false,             // False means start with empty fields!
                      initialTitle: '',
                      initialContent: '',
                    ),
                  ),
                ).then((value) {
                  // Automatically fetch records from PostgreSQL when you return from saving!
                  _fetchUserNotesFromBackend();
                });
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.redAccent),
              label: const Text(
                'Add Note',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.yellow, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard copying!
import 'package:untitled/note_work_space_screen.dart';


class EventDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> eventItem; // Accepts the tapped event data from HomeScreen

  const EventDetailsScreen({Key? key, winter, required this.eventItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("=== DEBUGGING EVENT ITEM TYPES ===");
    eventItem.forEach((key, value) {
      print("Key: '$key' | Value: $value | Type: ${value.runtimeType}");
    });
    print("==================================");
    // Extracting fields dynamically from your updated backend response
    final int eventId = eventItem['id'] ?? 0;
    final String eventTitle = (eventItem['title'] ?? 'Cathedral Event').toString();
    final String description = (eventItem['description'] ?? 'Join us for our specialized service.').toString();
    final String scheduledAt = (eventItem['eventDate'] ?? 'Date & Time Pending').toString();

    final String status = eventItem['status']?.toString() ?? 'upcoming';

    // New dynamic database reading columns
    final String featuredReading = (eventItem['featuredEventReading'] ?? 'Reading not specified').toString();
    final String readingText = eventItem['eventReadingText'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white, // 🎨 Matches sketch guideline: "background picture removed and remain white"
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          eventTitle,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Dynamic Header Card (Description & Meta info block)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(

                    children: [
                      const Icon(Icons.account_circle, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Scheduled at: $scheduledAt',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
              Text(
                'Status: $status', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w400),
              ),
        ],
            ),

            // 📑 SECTION: Featured Event Reading
            Row(
              children: [
                const Icon(Icons.menu_book, size: 20, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text(
                  'Featured Event Reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scripture Title (e.g., Romans 10:13)
            Text(
              featuredReading,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 6),

            // Scripture Verse Text Body
            if (readingText.isNotEmpty) ...[
              Text(
                readingText,
                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black, height: 1.4),
              ),
              const SizedBox(height: 16),

              // 📋 SKETCH COMPONENT: "Copy Reading" Button
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$featuredReading\n"$readingText"'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied "$featuredReading" to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF0D47A1),
                    ),
                  );eventItem.forEach((key, value) {
                    print("Key: '$key' | Value: $value | Type: ${value.runtimeType}");
                  });
                  print("==================================");
                },
                icon: const Icon(Icons.copy, size: 14, color: Colors.black87),
                label: const Text(
                  'Copy Reading',
                  style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  side: BorderSide(color: Colors.grey[400]!, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // ✍️ SKETCH COMPONENT: The "+" Interactive Action Block
            const Divider(),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                // 🚀 ROUTING MAGIC: Trigger workspace pre-loaded with this event's metrics
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteWorkspaceScreen(
                      noteId: null, // Brand new note entry
                      eventId: eventId, // Pass the explicit primary key ID from PostgreSQL
                      eventTitle: eventTitle, // Automatically pre-populates note headers
                      isEditing: false,
                      initialTitle: '$eventTitle Reflection',
                      initialContent: readingText.isNotEmpty ? 'Verse context: "$readingText"\n\n' : '',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF0D47A1), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Click here to write notes for this event',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            'Your note will be automatically saved under "My Events Readings"',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */
/*
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/main.dart';
import 'dart:convert';
import 'package:untitled/note_work_space_screen.dart';
import 'package:untitled/session_manager.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // 📚 Dynamic PostgreSQL Data Engine Array
  List<dynamic> _postgresNotes = [];
  bool _isLoading = true;

  String _formatPostgresDate(String? rawDateString) {
    if (rawDateString == null || rawDateString.isEmpty) {
      return 'Date Unknown';
    }

    try {
      // Parses the incoming ISO timestamp from PostgreSQL (e.g., "2026-05-26T12:34:56Z")
      DateTime parsedDate = DateTime.parse(rawDateString);

      // Extracts just the day, month, and year components
      String day = parsedDate.day.toString();
      String year = parsedDate.year.toString();

      // Maps out months to match your exact reading log style text
      List<String> months = [
        'Jan', 'Feb', 'March', 'April', 'May', 'June',
        'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
      ];
      String monthName = months[parsedDate.month - 1];

      // Returns a beautiful, clean string line: "26 May 2026"
      return '$day $monthName $year';
    } catch (e) {
      return 'Recent Note'; // Safe fallback if parsing hits a snag
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserNotesFromBackend();
  }

  Future<void> _fetchUserNotesFromBackend() async {
    // 🎯 DYNAMIC: Read the active ID directly from our SessionManager
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    try {
      print('📡 Loading Notes screen for: ${SessionManager.currentUserLabel}');
      print('📡 Dynamically fetching from: $dynamicFetchUrl');

      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse(dynamicFetchUrl));

      if (response.statusCode == 200) {
        setState(() {
          _postgresNotes = jsonDecode(response.body);
          _isLoading = false;
        });
        print('✅ Successfully loaded ${_postgresNotes.length} notes for User $activeId');
      } else {
        print('❌ Server error loading notes: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('🚨 Connection exception during fetch: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 SMART FILTER ENGINE: Segregating by title text patterns to bypass the forced database eventId=1 fallback behavior

    // Section 1: Personal Notes (No title background context, generic tags, or explicitly assigned personal tags)
    final List<dynamic> savedNotesList = _postgresNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty ||
          title == 'Personal Note' ||
          title == 'Cathedral Service' ||
          title == 'General Sermon Note';
    }).toList();

    // Section 2: My Events Readings (Contains explicitly named sermon milestones from the dynamic event timeline view)
    final List<dynamic> eventReadingsList = _postgresNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isNotEmpty &&
          title != 'Personal Note' &&
          title != 'Cathedral Service' &&
          title != 'General Sermon Note';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen())
            );
          },
        ),
        title: const Text(
          'My Notes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Search Bar Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black54, width: 1.2),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for notes and readings',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==========================================
                // SECTION 1: MY SAVED NOTES (Personal & Independent)
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My saved notes.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (savedNotesList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('You have not saved any note yet. Add a note now!', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: savedNotesList.length,
                    itemBuilder: (context, index) {
                      final note = savedNotesList[index];
                      final int itemNumber = index + 1;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteWorkspaceScreen(
                                noteId: note['id'],
                                eventId: note['eventId'] ?? 1,
                                eventTitle: note['eventTitle'] ?? 'Cathedral Service',
                                isEditing: true,
                                initialTitle: note['title'] ?? '',
                                initialContent: note['content'] ?? '',
                              ),
                            ),
                          ).then((value) {
                            if (value == true) _fetchUserNotesFromBackend();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$itemNumber.',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        children: [
                                          const TextSpan(text: 'Title: '),
                                          TextSpan(
                                            text: note['title'] ?? 'untitled',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        _formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date']),
                                        style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),

                // ==========================================
                // SECTION 2: MY EVENTS READINGS (Tied to Specific Sermons)
                // ==========================================
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text(
                      'My Events readings.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator.adaptive())
                else if (eventReadingsList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('Notes generated through church events will display down here.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: eventReadingsList.length,
                    itemBuilder: (context, index) {
                      final note = eventReadingsList[index];
                      final int readingNumber = index + 1;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteWorkspaceScreen(
                                noteId: note['id'],
                                eventId: note['eventId'] ?? 1,
                                eventTitle: note['eventTitle'] ?? 'Cathedral Service',
                                isEditing: true,
                                initialTitle: note['title'] ?? '',
                                initialContent: note['content'] ?? '',
                              ),
                            ),
                          ).then((value) {
                            if (value == true) _fetchUserNotesFromBackend();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$readingNumber.',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Displays the underlying church sermon event grouping name
                                    Text(
                                      note['eventTitle'] ?? 'General Sermon Note',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1)),
                                    ),
                                    const SizedBox(height: 2),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        children: [
                                          const TextSpan(text: 'Note: '),
                                          TextSpan(
                                            text: note['title'] ?? 'untitled',
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date']),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // 🚀 Bottom Right "+ Add Note" Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteWorkspaceScreen(
                      noteId: null,
                      eventId: 1,
                      eventTitle: 'Personal Note',
                      isEditing: false,
                      initialTitle: '',
                      initialContent: '',
                    ),
                  ),
                ).then((value) {
                  _fetchUserNotesFromBackend();
                });
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Add Note',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1), // Swapped color layout to match your clean Cathedral blue scheme
                side: const BorderSide(color: Colors.blue, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 */
/*
register screen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:untitled/main.dart';
import 'package:untitled/session_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers to grab what the user types
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dropdown value tracking
  String? _selectedFellowship;
  String? _selectedcellgroup;

  // Mock list of ACK St. James Fellowship/Cell Groups
  final List<String> _fellowshipGroups = [
    'The Eagles Link Chapel',
    'Teens Ministry',
    'Mother\'s Union',
    'Kenya Anglican Men\'s Association (KAMA)',
    'Cathedral Choir',
    'St. James Pillars (Clergy)',
  ];

  final List<String> _residentialcellgroup = [
    'Kirigiti',
    'Beersheba',
    'Ndumberi',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final group = _selectedFellowship;
      final cellgroup = _selectedcellgroup;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator.adaptive()),
      );

      final url = Uri.parse('http://10.34.113.23:8080/api/users/register');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fullName': name,
            'email': email,
            'password': password,
            'fellowshipGroup': group,
            'residentialCell': cellgroup,
          }),
        ).timeout(const Duration(seconds: 10));
        print('📡 Server Response Received! Status Code: ${response.statusCode}');
        print('📡 RAW PAYLOAD FROM BACKEND: ${response.body}');

        if (!mounted) return;

        // 🛡️ Safe context dismissal of loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          // 🎯 DECODE THE GENERATED IDENTITY FROM POSTGRESQL
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final dynamic rawId = responseData['id'];
          if (rawId == null) {
            throw Exception("The server saved the user but forgot to send back the 'id' key!");
          }
          final int registeredId = int.parse(responseData['id'].toString());
          print('🔑 SUCCESS: Lock SessionManager to unique User ID: $registeredId');

          SessionManager.currentUserId = registeredId;

          // 🎯 SECURE DATA ISOLATION: Lock session to this new ID instantly!
          SessionManager.currentUserId = registeredId;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('userId', registeredId);
          await prefs.setString('userName', name);
          await prefs.setString('userEmail', email);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account successfully created!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate cleanly to the dashboard dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
              //  (route) => false,
          );

        } else {
          // Handle registration rejections cleanly
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Registration failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        print('Fatal network intercept error: $e');
        if (!mounted) return;

        // Clean up navigation safely if a connection drops out mid-process
        try {
          Navigator.pop(context);
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lost connection to server. Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Join St. James Cathedral',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Register to access dynamic events and project tracking.'),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email Address Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),

              // Residential Cell Dropdown Menu
              DropdownButtonFormField<String>(
                value: _selectedcellgroup,
                hint: const Text('Select your residential group'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.group_sharp),
                  border: OutlineInputBorder(),
                ),
                items: _residentialcellgroup.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedcellgroup = value;
                  });
                },
                validator: (value) => value == null ? 'Please select your residential group' : null,
              ),
              const SizedBox(height: 16),

              // Fellowship Dropdown Menu
              DropdownButtonFormField<String>(
                value: _selectedFellowship,
                hint: const Text('Select your Fellowship Group'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.groups),
                  border: OutlineInputBorder(),
                ),
                items: _fellowshipGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFellowship = value;
                  });
                },
                validator: (value) => value == null ? 'Please select a group' : null,
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 6 ? 'Password must be 6+ chars' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 */