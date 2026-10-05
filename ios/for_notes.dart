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
      DateTime parsedDate = DateTime.parse(rawDateString);
      String day = parsedDate.day.toString();
      String year = parsedDate.year.toString();

      List<String> months = [
        'Jan', 'Feb', 'March', 'April', 'May', 'June',
        'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
      ];
      String monthName = months[parsedDate.month - 1];

      return '$day $monthName $year';
    } catch (e) {
      return 'Recent Note';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserNotesFromBackend();
  }

  Future<void> _fetchUserNotesFromBackend() async {
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    try {
      setState(() => _isLoading = true);
      final response = await http.get(Uri.parse(dynamicFetchUrl));

      if (response.statusCode == 200) {
        setState(() {
          _postgresNotes = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 📝 Navigation Helper for Edit Action
  void _navigateToWorkspace(Map<String, dynamic> note) {
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
  }

  // 🗑️ Placeholder Action for Deleting a Note
  void _handleDeleteNote(int noteId) {
    print('🗑️ Delete requested for Note ID: $noteId. Ready for API endpoint implementation!');
    // Todo: Implement http.delete('http://10.34.113.23:8080/api/notes/delete/$noteId')
  }

  // 📤 Placeholder Action for Sharing a Note
  void _handleShareNote(Map<String, dynamic> note) {
    print('📤 Share requested for note: "${note['title']}"');
  }

  // 🛠️ Floating Menu Action Router Engine
  void _onMenuSelected(String value, Map<String, dynamic> note) {
    switch (value) {
      case 'share':
        _handleShareNote(note);
        break;
      case 'delete':
        _handleDeleteNote(note['id']);
        break;
      case 'edit':
        _navigateToWorkspace(note);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 SMART FILTER ENGINE
    final List<dynamic> savedNotesList = _postgresNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty ||
          title == 'Personal Note' ||
          title == 'Cathedral Service' ||
          title == 'General Sermon Note';
    }).toList();

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
          // 🧱 Layout Container changed from SingleChildScrollView to basic Padding + Column for independent list control
          Padding(
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
                const SizedBox(height: 20),

                // ==========================================
                // SECTION 1 HEADER: MY SAVED NOTES
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
                const SizedBox(height: 10),

                // 📜 SCROLLABLE CONTAINER 1: Independent Scroll Box for Section 1
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : savedNotesList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('You have not saved any note yet. Add a note now!', style: TextStyle(color: Colors.grey)),
                  )
                      : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(right: 8),
                      itemCount: savedNotesList.length,
                      itemBuilder: (context, index) {
                        final note = savedNotesList[index];
                        final int itemNumber = index + 1;

                        return InkWell(
                          onTap: () => _navigateToWorkspace(note),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                          _formatPostgresDate(note['createdAt']),
                                          style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 🎯 THE 3-DOT MENU BUTTON (SKETCH IMPLEMENTATION)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onSelected: (val) => _onMenuSelected(val, note),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 10),

                // ==========================================
                // SECTION 2 HEADER: MY EVENTS READINGS
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
                const SizedBox(height: 12),

                // 📜 SCROLLABLE CONTAINER 2: Independent Scroll Box for Section 2
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : eventReadingsList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Notes generated through church events will display down here.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                      : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(right: 8),
                      itemCount: eventReadingsList.length,
                      itemBuilder: (context, index) {
                        final note = eventReadingsList[index];
                        final int readingNumber = index + 1;

                        return InkWell(
                          onTap: () => _navigateToWorkspace(note),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                        _formatPostgresDate(note['createdAt']),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                // 🎯 THE 3-DOT MENU BUTTON (SKETCH IMPLEMENTATION)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onSelected: (val) => _onMenuSelected(val, note),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 70), // Spatial pad clearance for floating button placement
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
                backgroundColor: const Color(0xFF0D47A1),
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
work_space:
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/session_manager.dart';

class NoteWorkspaceScreen extends StatefulWidget {
  final int? noteId;         // Null if writing a new note, holds PK ID if editing
  final int eventId;         // The relational event link from database schema
  final String eventTitle;   // The inherited category name (e.g., 'Palm Sunday')
  final bool isEditing;      // Tracker flag determining mode strategy
  final String? initialTitle;
  final String? initialContent;

  const NoteWorkspaceScreen({
    super.key,
    this.noteId,
    required this.eventId,
    required this.eventTitle,
    required this.isEditing,
    this.initialTitle,
    this.initialContent,
  }); // end of constructor

  @override
  State<NoteWorkspaceScreen> createState() => _NoteWorkspaceScreenState();
} // end of NoteWorkspaceScreen class

class _NoteWorkspaceScreenState extends State<NoteWorkspaceScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  //static const int currentUserId = 1;

  // Change this IP to match your current Spring Boot local server network destination
 // final String _backendUrl = 'http://10.34.113.23:8080/api/notes/add/1';


  @override
  void initState() {
    super.initState();
    // If we are in edit mode, populate controllers with preexisting data rows
    if (widget.isEditing) {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
    } // end of edit validation check
  } // end of initState

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  } // end of dispose
  Future<void> _saveNoteToPostgres() async {
    // 🚫 1. Guard check: Ensure they entered a title
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title can't be empty.")),
      );
      return;
    }

    // 🎯 THE MASTER PAYLOAD: Gather everything into a unified map variable
    final Map<String, dynamic> notePayload = {
      "title": _titleController.text.trim(),
      "content": _contentController.text.trim(),
      "userId": SessionManager.currentUserId, // Automatically links it to the active logged-in member
      "eventId": widget.eventId,              // Links to the church event (e.g., 2, 3) or 1 for generic
      "eventTitle": widget.eventTitle,        // Keeps track of the sermon context string
      "createdAt": DateTime.now().toIso8601String(), // Explicit ISO timestamp
    };

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        // 📝 UPDATE ROUTE (PUT)
        final String updateUrl = 'http://10.34.113.23:8080/api/notes/update/${widget.noteId}';
        print('📡 Workspace Screen: Editing note. PUT to: $updateUrl');

        final response = await http.put(
          Uri.parse(updateUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload), // Uses the master payload
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print("✅ Note updated successfully linked to eventId: ${widget.eventId}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note updated!')));
            Navigator.pop(context, true);
          }
        } else {
          print('❌ Server rejected update status: ${response.statusCode}');
        }

      } else {
        // 💾 DYNAMIC CREATE ROUTE (POST)
        final int activeId = SessionManager.currentUserId;
        final String dynamicAddUrl = 'http://10.34.113.23:8080/api/notes/add/$activeId';

        print('📡 Saving note dynamically for User ID ($activeId) to: $dynamicAddUrl');

        final response = await http.post(
          Uri.parse(dynamicAddUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload), // 🎯 FIX: Pass the complete payload map here!
        );

        print('📡 SERVER RESPONSE RECEIVED: ${response.statusCode}');
        print('📡 RESPONSE BODY PAYLOAD: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note saved to Cathedral records!')),
            );
            Navigator.pop(context, true); // Drops back to My Notes screen, passing true to refresh
          }
        } else {
          print('❌ Server rejected creation status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🚨 Fatal exception inside workspace save handler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  } // end of _saveNoteToPostgres function // end of _saveNoteToPostgres function

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          }, // end of onPressed
        ), // end of leading IconButton
        title: const Text(
          'My Notes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ), // end of title Text
        actions: [
          // Dynamic Character Counter matching your "7/17" layout notebook sketch
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${_titleController.text.length}/${_titleController.text.length + _contentController.text.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ), // end of Text
            ), // end of Padding
          ), // end of Center
          _isSaving
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ) // end of internal loading Padding
              : IconButton(
            icon: const Icon(Icons.save_alt, color: Color(0xFF0D47A1), size: 28),
            onPressed: _saveNoteToPostgres,
          ), // end of conditional save IconButton
          const SizedBox(width: 8),
        ], // end of actions array
      ), // end of AppBar
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📝 NOTEBOOK SKETCH FIELD: Title Input Area
                const Text(
                  'Title',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ), // end of Text
                TextField(
                  controller: _titleController,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'e.g. palm Sunday',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ), // end of InputDecoration
                  onChanged: (val) => setState(() {}), // Force rebuild to update top string length counter
                ), // end of Title TextField
                const Divider(height: 20, thickness: 1, color: Colors.black12),
                const SizedBox(height: 10),

                // 📝 NOTEBOOK SKETCH FIELD: Content Document Workspace Writing Layer
                const Text(
                  'Content',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ), // end of Text
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null, // Allows endless multi-line typing expansion vertical tracking
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Start writing your sermon notes here...',
                      border: InputBorder.none,
                    ), // end of InputDecoration
                    onChanged: (val) => setState(() {}), // Sync workspace string counter variables
                  ), // end of Content TextField
                ), // end of Expanded
              ], // end of main column items array
            ), // end of primary Column widget
          ), // end of primary Padding container

          // 🎨 NOTEBOOK SKETCH FIELD: Bottom Toolbar formatting buttons (B / I / U) pinned to lower right
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormatButton('B'),
                const SizedBox(width: 8),
                _buildFormatButton('I'),
                const SizedBox(width: 8),
                _buildFormatButton('U'),
              ], // end of formatting row array
            ), // end of format container Row
          ), // end of Positioned toolbar layer
        ], // end of principal Stack elements array
      ), // end of Scaffold body Stack
    ); // end of return Scaffold
  } // end of Widget build

  // Formatting utility builder to render square options matching layout cells perfectly
  Widget _buildFormatButton(String label) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ), // end of BoxDecoration
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: label == 'B' ? FontWeight.bold : FontWeight.normal,
            fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
            decoration: label == 'U' ? TextDecoration.underline : TextDecoration.none,
            fontSize: 16,
            color: Colors.black87,
          ), // end of TextStyle
        ), // end of Center Text
      ), // end of Center
    ); // end of return Container
  } // end of _buildFormatButton function
} // end of _NoteWorkspaceScreenState class
 */
/*
updated notes page:
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // 🚀 Added for Share functionality
import 'dart:convert';
import 'package:untitled/main.dart';
import 'package:untitled/note_work_space_screen.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/local_database_helper.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> _displayNotes = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;

  String _formatPostgresDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent Note';
    final String rawDateString = rawDate.toString();
    if (rawDateString.isEmpty) return 'Recent Note';

    try {
      DateTime parsedDate = DateTime.parse(rawDateString);
      List<String> months = ['Jan', 'Feb', 'March', 'April', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return 'Recent Note';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotesDataEngine();
  }

  // 🔄 SMART DATA ENGINE: Fetches from network if online, falls back to local cache if offline
  Future<void> _loadNotesDataEngine() async {
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    setState(() => _isLoading = true);

    try {
      print('📡 Attempting network fetch from backend...');
      final response = await http.get(Uri.parse(dynamicFetchUrl)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> networkNotes = jsonDecode(response.body);
        print('✅ Server pull successful. Caching ${networkNotes.length} rows to SQLite.');

        // Save to native local storage device
        await LocalDatabaseHelper.instance.refreshLocalCache(networkNotes);
        _isOfflineMode = false;
      }
    } catch (e) {
      print('🚨 Offline Mode Active: Network pull failed ($e). Reading device cache instead.');
      _isOfflineMode = true;
    }

    // Always source UI display records straight from local engine storage for consistent tracking
    final localNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);
    setState(() {
      _displayNotes = localNotes;
      _isLoading = false;
    });

    // Run a background upload check if we are online to clear any cached pending updates
    if (!_isOfflineMode) {
      _synchronizePendingOfflineNotes();
    }
  }

  // 🚀 BACKGROUND SYNC ENGINE
  Future<void> _synchronizePendingOfflineNotes() async {
    final pendingNotes = await LocalDatabaseHelper.instance.getPendingNotes();
    if (pendingNotes.isEmpty) return;

    print('🔄 Found ${pendingNotes.length} offline notes waiting to sync. Uploading...');
    for (var note in pendingNotes) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/add/${note['userId']}';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': note['title'],
            'content': note['content'],
            'eventId': note['eventId'],
            'eventTitle': note['eventTitle'],
          }),
        );

        if (response.statusCode == 200) {
          // Sync complete, clear temporary cache copy row safely
          await LocalDatabaseHelper.instance.deleteNote(note['id']);
          print('✅ Synced offline note "${note['title']}" to production PostgreSQL server.');
        }
      } catch (e) {
        print('🚨 Sync upload failed re-attempt for note ID: ${note['id']}. Waiting for next network loop.');
        break;
      }
    }
  }

  // 🗑️ DOMINION ACTION: Delete a note completely
  // 🗑️ DOMINION ACTION: Delete a note with an elegant bottom confirmation sheet
  void _showDeleteConfirmationSheet(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete this note?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'It will be permanently deleted from your device.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // ❌ CANCEL BUTTON
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 🗑️ CONFIRM PERMANENT DELETE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          final dynamic targetId = note['id'];
                          print('🎯 Confirm clicked inside sheet for Note ID: $targetId');
                          _executeFinalDestruction(note['id']); // Run actual deletion
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 💥 The actual execution mechanism that drops the row from storage
  Future<void> _executeFinalDestruction(dynamic noteId) async {
    if (noteId == null) return;

    // Parse to integer safely for SQLite operations
    final int targetId = int.parse(noteId.toString());

    print('🗑️ Starting permanent purge execution for Target ID: $targetId');

    try {
      // 1. Remove from local device storage cache
      await LocalDatabaseHelper.instance.deleteNote(targetId);
      print('✅ Wiped successfully from SQLite storage engine.');
    } catch(e) {
      print('🚨 SQLite deletion encounter: $e');
    }
    // 1. Instantly drop from local UI cache view for instant visual feedback loop
    await LocalDatabaseHelper.instance.deleteNote(noteId);

    setState(() {
      _displayNotes.removeWhere((element) => element['id'] == noteId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note permanently deleted.', style: TextStyle(fontSize: 13))),
    );

    // 2. Fire backend destruction script if online (Ignore if negative temporary local ID)
    if (!_isOfflineMode && targetId > 0) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/delete/$targetId';
        final response = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
        print('🗑️ Server deletion execution returned status frame: ${response.statusCode}');
        await http.delete(Uri.parse(url));
        print('🗑️ System dropped backend system global ID: $targetId');
      } catch (e) {
        print('🚨 Backend deletion broadcast failed ($e). Local destruction intact.');
      }
    }
  }

  // 📤 DOMINION ACTION: Share note data natively using native sheet protocols
  void _handleShareNote(Map<String, dynamic> note) {
    final String shareBody = 'Reflections from: ${note['eventTitle'] ?? 'Personal Reflections'}\n\n'
        'Title: ${note['title'] ?? 'Untitled'}\n'
        'Date: ${_formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date'])}\n\n'
        '${note['content'] ?? ''}';

    Share.share(shareBody, subject: note['title'] ?? 'Cathedral Service Insights');
  }

  void _navigateToWorkspace(Map<String, dynamic> note) {
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
    ).then((value) => _loadNotesDataEngine());
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 INDEPENDENT STREAM SEGREGATION
    final List<dynamic> savedNotesList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty || title == 'Personal Note' || title == 'Cathedral Service' || title == 'General Sermon Note';
    }).toList();

    final List<dynamic> eventReadingsList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isNotEmpty && title != 'Personal Note' && title != 'Cathedral Service' && title != 'General Sermon Note';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
        ),
        title: Row(
          children: [
            const Text('My Notes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              const Icon(Icons.cloud_off, color: Colors.redAccent, size: 18),
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
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
                const SizedBox(height: 20),

                // SECTION 1 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My saved notes.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 10),

                // 📜 SCROLLABLE CONTAINER 1
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : savedNotesList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('You have not saved any note yet.', style: TextStyle(color: Colors.grey)),
                  )
                      : ListView.builder(
                    itemCount: savedNotesList.length,
                    itemBuilder: (context, index) {
                      final note = savedNotesList[index];
                      return _buildNoteItemRow(note, index + 1);
                    },
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 10),

                // SECTION 2 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My Events readings.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline)),
                  ],
                ),
                const SizedBox(height: 12),

                // 📜 SCROLLABLE CONTAINER 2
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : eventReadingsList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Notes generated through church events will display down here.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                      : ListView.builder(
                    itemCount: eventReadingsList.length,
                    itemBuilder: (context, index) {
                      final note = eventReadingsList[index];
                      return _buildEventItemRow(note, index + 1);
                    },
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),

          // 🚀 Add Note FAB
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
                ).then((value) => _loadNotesDataEngine());
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Colors.blue, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Personal Note Layout Style Variant
  Widget _buildNoteItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 13, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Event Sermon Layout Style Variant
  Widget _buildEventItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['eventTitle'] ?? 'General Sermon Note', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Note: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 12, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> note) {

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (val) {
        if (val == 'share') _handleShareNote(note);
       // if (val == 'delete') _executeFinalDestruction(note['id']);
        if (val == 'edit') _navigateToWorkspace(note);
        if (val == 'delete') _showDeleteConfirmationSheet(note);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
      ],
    );
  }
}
 */
/*
updated notes screen
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // 🚀 Added for Share functionality
import 'dart:convert';
import 'package:untitled/main.dart';
import 'package:untitled/note_work_space_screen.dart';
import 'package:untitled/session_manager.dart';
import 'package:untitled/local_database_helper.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> _displayNotes = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;

  String _formatPostgresDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent Note';
    final String rawDateString = rawDate.toString();
    if (rawDateString.isEmpty) return 'Recent Note';

    try {
      DateTime parsedDate = DateTime.parse(rawDateString);
      List<String> months = ['Jan', 'Feb', 'March', 'April', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return 'Recent Note';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotesDataEngine();
  }

  // 🔄 SMART DATA ENGINE: Fetches from network if online, falls back to local cache if offline
  Future<void> _loadNotesDataEngine() async {
    final int activeId = SessionManager.currentUserId;
    final String dynamicFetchUrl = 'http://10.34.113.23:8080/api/notes/user/$activeId';

    setState(() => _isLoading = true);

    try {
      print('📡 Attempting network fetch from backend...');
      final response = await http.get(Uri.parse(dynamicFetchUrl)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> networkNotes = jsonDecode(response.body);
        print('✅ Server pull successful. Caching ${networkNotes.length} rows to SQLite.');

        // Save to native local storage device
        await LocalDatabaseHelper.instance.refreshLocalCache(networkNotes);
        _isOfflineMode = false;
      }
    } catch (e) {
      print('🚨 Offline Mode Active: Network pull failed ($e). Reading device cache instead.');
      _isOfflineMode = true;
    }

    // Always source UI display records straight from local engine storage for consistent tracking
    final localNotes = await LocalDatabaseHelper.instance.getUserNotes(activeId);
    setState(() {
      _displayNotes = List.from(localNotes); // Create modifiable list copy
      _isLoading = false;
    });

    // Run a background upload check if we are online to clear any cached pending updates
    if (!_isOfflineMode) {
      _synchronizePendingOfflineNotes();
    }
  }

  // 🚀 BACKGROUND SYNC ENGINE
  Future<void> _synchronizePendingOfflineNotes() async {
    final pendingNotes = await LocalDatabaseHelper.instance.getPendingNotes();
    if (pendingNotes.isEmpty) return;

    print('🔄 Found ${pendingNotes.length} offline notes waiting to sync. Uploading...');
    for (var note in pendingNotes) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/add/${note['userId']}';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': note['title'],
            'content': note['content'],
            'eventId': note['eventId'],
            'eventTitle': note['eventTitle'],
          }),
        );

        if (response.statusCode == 200) {
          // Sync complete, clear temporary cache copy row safely
          await LocalDatabaseHelper.instance.deleteNote(note['id']);
          print('✅ Synced offline note "${note['title']}" to production PostgreSQL server.');
        }
      } catch (e) {
        print('🚨 Sync upload failed re-attempt for note ID: ${note['id']}. Waiting for next network loop.');
        break;
      }
    }
  }

  // 🗑️ DOMINION ACTION: Delete a note with an elegant bottom confirmation sheet
  void _showDeleteConfirmationSheet(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete this note?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'It will be permanently deleted from your device.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // ❌ CANCEL BUTTON
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 🗑️ CONFIRM PERMANENT DELETE BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          final dynamic targetId = note['id'];
                          print('🎯 Confirm clicked inside sheet for Note ID: $targetId');
                          _executeFinalDestruction(targetId); // Run actual deletion
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 💥 The actual execution mechanism that drops the row from storage
  Future<void> _executeFinalDestruction(dynamic noteId) async {
    if (noteId == null) return;

    // Parse to integer safely for SQLite operations
    final int targetId = int.parse(noteId.toString());
    print('🗑️ Starting permanent purge execution for Target ID: $targetId');

    try {
      // 1. Remove from local device storage cache securely using parsed target integer
      await LocalDatabaseHelper.instance.deleteNote(targetId);
      print('✅ Wiped successfully from SQLite storage engine.');
    } catch(e) {
      print('🚨 SQLite deletion encounter: $e');
    }

    // 2. Instantly drop from screen view state using string tracking checks to avoid type blocks
    setState(() {
      _displayNotes.removeWhere((element) => element['id'].toString() == targetId.toString());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note permanently deleted.', style: TextStyle(fontSize: 13))),
      );
    }

    // 3. Fire backend destruction script if online (Ignore if negative temporary local ID)
    if (!_isOfflineMode && targetId > 0) {
      try {
        final url = 'http://10.34.113.23:8080/api/notes/delete/$targetId';
        final response = await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
        print('🗑️ Server deletion execution returned status frame: ${response.statusCode}');
        print('🗑️ System dropped backend system global ID: $targetId');
      } catch (e) {
        print('🚨 Backend deletion broadcast failed ($e). Local destruction intact.');
      }
    }
  }

  // 📤 DOMINION ACTION: Share note data natively using native sheet protocols
  void _handleShareNote(Map<String, dynamic> note) {
    final String shareBody = 'Reflections from: ${note['eventTitle'] ?? 'Personal Reflections'}\n\n'
        'Title: ${note['title'] ?? 'Untitled'}\n'
        'Date: ${_formatPostgresDate(note['createdAt'] ?? note['dateCreated'] ?? note['date'])}\n\n'
        '${note['content'] ?? ''}';

    Share.share(shareBody, subject: note['title'] ?? 'Cathedral Service Insights');
  }

  void _navigateToWorkspace(Map<String, dynamic> note) {
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
    ).then((value) => _loadNotesDataEngine());
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 INDEPENDENT STREAM SEGREGATION
    final List<dynamic> savedNotesList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isEmpty || title == 'Personal Note' || title == 'Cathedral Service' || title == 'General Sermon Note';
    }).toList();

    final List<dynamic> eventReadingsList = _displayNotes.where((note) {
      final String title = (note['eventTitle'] ?? '').toString();
      return title.isNotEmpty && title != 'Personal Note' && title != 'Cathedral Service' && title != 'General Sermon Note';
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
        ),
        title: Row(
          children: [
            const Text('My Notes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 22)),
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              const Icon(Icons.cloud_off, color: Colors.redAccent, size: 18),
            ]
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
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
                const SizedBox(height: 20),

                // SECTION 1 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My saved notes.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 10),

                // 📜 SCROLLABLE CONTAINER 1
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : savedNotesList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('You have not saved any note yet.', style: TextStyle(color: Colors.grey)),
                  )
                      : ListView.builder(
                    itemCount: savedNotesList.length,
                    itemBuilder: (context, index) {
                      final note = savedNotesList[index];
                      return _buildNoteItemRow(note, index + 1);
                    },
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 10),

                // SECTION 2 HEADER
                const Row(
                  children: [
                    Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    SizedBox(width: 8),
                    Text('My Events readings.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, decoration: TextDecoration.underline)),
                  ],
                ),
                const SizedBox(height: 12),

                // 📜 SCROLLABLE CONTAINER 2
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : eventReadingsList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Notes generated through church events will display down here.', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
                  )
                      : ListView.builder(
                    itemCount: eventReadingsList.length,
                    itemBuilder: (context, index) {
                      final note = eventReadingsList[index];
                      return _buildEventItemRow(note, index + 1);
                    },
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),

          // 🚀 Add Note FAB
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
                ).then((value) => _loadNotesDataEngine());
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Colors.blue, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Personal Note Layout Style Variant
  Widget _buildNoteItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 13, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  // ROW COMPONENT GENERATOR: Event Sermon Layout Style Variant
  Widget _buildEventItemRow(Map<String, dynamic> note, int displayIndex) {
    final bool isPendingSync = note['syncStatus'] == 'PENDING';

    return InkWell(
      onTap: () => _navigateToWorkspace(note),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$displayIndex.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note['eventTitle'] ?? 'General Sermon Note', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      children: [
                        const TextSpan(text: 'Note: '),
                        TextSpan(text: note['title'] ?? 'untitled', style: const TextStyle(fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(_formatPostgresDate(note['createdAt']), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      if (isPendingSync) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.watch_later_outlined, size: 12, color: Colors.orange),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _buildActionMenu(note),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> note) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (val) {
        if (val == 'share') _handleShareNote(note);
        if (val == 'edit') _navigateToWorkspace(note);
        if (val == 'delete') _showDeleteConfirmationSheet(note);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
      ],
    );
  }
}
 */