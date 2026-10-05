import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled/session_manager.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({Key? key}) : super(key: key);

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isInterestedChecked = false;
  bool _isCheckboxDisabled = false;
  bool _isLoading = false;

  // 📝 Text Controller to capture custom user view requests
  final TextEditingController _viewsController = TextEditingController();

  // 🎥 Mock Video Presentation States
  int _currentSlideIndex = 0;
  bool _isPlaying = true;
  double _videoProgress = 0.0;
  Timer? _slideTimer;
  Timer? _progressTimer;

  final List<Map<String, String>> _videoSlides = [
    {
      "title": "💳 Smooth M-Pesa Integration",
      "desc": "Direct Daraja API handshake ensures your tithes and cathedral building pledges update in real-time securely."
    },
    {
      "title": "📺 Live Stream Services",
      "desc": "Tap and tune into Sunday Main Sanctuary services directly from the app, wherever you are in Kenya."
    },
    {
      "title": "🔔 Real-Time Announcements",
      "desc": "Instant push notifications flash directly on your phone screen the moment church notice schedules are published."
    },
    {
      "title": "🏗️ The Grand Cathedral Tracker",
      "desc": "A fully audit-ready financial ledger tracking target milestones, monthly raised totals, and remaining goals."
    },
  ];

  @override
  void initState() {
    super.initState();
    _startMockVideoPlayback();
    _fetchCurrentSubmissionStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentSubmissionStatus();
    });
  }

  Future<void> _fetchCurrentSubmissionStatus() async {
    final int userId = SessionManager.currentUserId;
    print("📱 HARDWARE DIRECT CHECK: True active identity token -> $userId");

    setState(() {
      _isCheckboxDisabled = false;
      _isInterestedChecked = false;
      _viewsController.clear();
    });

    final Uri url = Uri.parse('https://cathedral-backend-server-files-6.onrender.com/api/v1/updates/check-status/$userId');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print("📡 RAW INTERNET PAYLOAD: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['hasSubmitted'] == true) {
          setState(() {
            _isInterestedChecked = true;
            _isCheckboxDisabled = true;
            _viewsController.text = "Feedback successfully registered!";
          });
        } else {
          setState(() {
            _isInterestedChecked = false;
            _isCheckboxDisabled = false;
            _viewsController.clear();
          });
        }
      }
    } catch (e) {
      print("silent background check bypass: $e");
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _progressTimer?.cancel();
    _viewsController.dispose();
    super.dispose();
  }

  void _startMockVideoPlayback() {
    _slideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isPlaying) {
        setState(() {
          _currentSlideIndex = (_currentSlideIndex + 1) % _videoSlides.length;
          _videoProgress = 0.0;
        });
      }
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_videoProgress < 1.0) {
            _videoProgress += 0.01;
          }
        });
      }
    });
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _submitUserInterest() async {
    final String userFeedback = _viewsController.text.trim();

    if (userFeedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your feature views before marking interest!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final int userId = SessionManager.currentUserId;
    final Uri url = Uri.parse('https://cathedral-backend-server-files-6.onrender.com/api/v1/updates/register-interest/$userId');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'otherUpdate': userFeedback,
        }),
      ).timeout(const Duration(seconds: 8));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isInterestedChecked = true;
          _isCheckboxDisabled = true;
          _viewsController.text = "Feedback successfully registered!";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(responseData['message'] ?? 'Interest logged!')),
              ],
            ),
            backgroundColor: const Color(0xFF0D47A1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to update configuration.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Could not reach backend server ($e)'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _videoSlides[_currentSlideIndex];

    // 🎨 DYNAMIC MODE INTERFACES MAP
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color sectionHeaderColor = isDark ? Colors.white54 : Colors.black54;
    final Color textParaColor = isDark ? Colors.white70 : Colors.grey.shade700;

    // Form Input Field Colors
    final Color formFieldBg = _isCheckboxDisabled
        ? (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100)
        : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50);
    final Color borderLineColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color focusBorderColor = isDark ? Colors.blue.shade400 : const Color(0xFF0D47A1);

    // Commit Status Box Colors
    final Color statusBoxBg = _isCheckboxDisabled
        ? (isDark ? const Color(0xFF1B382B) : Colors.green.shade50)
        : Colors.transparent;
    final Color statusTextColor = _isCheckboxDisabled
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : mainTextColor;

    // Bottom Footnote Endorsement Card
    final Color footnoteBg = isDark ? const Color(0xFF1A2638) : Colors.blue.shade50;
    final Color footnoteBorder = isDark ? Colors.blue.shade400.withValues(alpha: 0.2) : Colors.blue.shade100;
    final Color footnoteText = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Updates',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Praise the Lord!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome Member, here is the section where you see the actual app to come.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: mainTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Our upcoming framework patch transforms how our congregation interfaces with building plans. Take an exclusive look at the operational timeline features engineered for the next release.'
                'Note that the developer is also aware of the favoriting problem encountered during the test. the effort to accomplishing the user needs are still ongoing. Cathedral is for us all and we are all purposed to serve the Most High',
                style: TextStyle(fontSize: 14, color: textParaColor, height: 1.5),
              ),
              const SizedBox(height: 24),

              // 🎥 VIDEO PREVIEW HEADER
              Text(
                'Update Features Video Preview:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sectionHeaderColor),
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, const Color(0xFF0D47A1), Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        key: ValueKey<int>(_currentSlideIndex),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentSlide["title"]!,
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentSlide["desc"]!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _videoProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Preview Loop 00:0${_currentSlideIndex + 1} / 00:04",
                                style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                              ),
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 28),
                                onPressed: _togglePlayback,
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 📝 USER VIEWS INPUT
              Text(
                'Your Views on This Update:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sectionHeaderColor),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _viewsController,
                maxLength: 79,
                enabled: !_isCheckboxDisabled && !_isLoading,
                style: TextStyle(fontSize: 14, color: mainTextColor),

                decoration: InputDecoration(
                counterStyle: TextStyle(color: sectionHeaderColor),
                  hintText: "What else should this update contain?",
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: formFieldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderLineColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderLineColor),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderLineColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: focusBorderColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 🗳️ CHECKBOX STATUS ROW
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: statusBoxBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _isLoading
                        ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: focusBorderColor),
                      ),
                    )
                        : Checkbox(
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                      value: _isInterestedChecked,
                      onChanged: _isCheckboxDisabled
                          ? null
                          : (bool? value) {
                        if (value == true) {
                          _submitUserInterest();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        _isCheckboxDisabled
                            ? 'Your feedback has been committed to the server!'
                            : 'I agree that the update will have far reaching implication.',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: statusTextColor
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 🙏 ENDORSEMENT BRANDING FOOTNOTE (Themed Matrix)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: footnoteBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: footnoteBorder),
                ),
                child: Text(
                  '"We are making Cathedral known together, take your part by supporting this!"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: footnoteText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}