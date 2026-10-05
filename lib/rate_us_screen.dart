import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'local_database_helper.dart'; // 🛡️ Importing our stubborn-proof storage layer
// Ensure you have access to SessionManager in your app scope
import 'session_manager.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({Key? key}) : super(key: key);

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int _selectedStars = 0;
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 📡 THE PERSISTENCE PIPELINE METHOD
  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a star rating before submitting!'),
            backgroundColor: Colors.orangeAccent
        ),
      );
      return;
    }

    setState(() => _isSending = true);

     final int currentActiveUserId = SessionManager.currentUserId;

     final Map<String, dynamic> feedbackPayload = {
      "userId": currentActiveUserId,
      "starsRated": _selectedStars,
      "feedback": _commentController.text.trim(),
      "submittedAt": DateTime.now().toIso8601String(),
    };

    final String serverEndpointUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/feedback/submit';
    bool cloudSyncSuccess = false;

    try {
      print('📡 TRANSMISSION TRACE: Sending feedback to backend pipeline...');
      final response = await http.post(
        Uri.parse(serverEndpointUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(feedbackPayload),
      ).timeout(const Duration(seconds: 4)); // Strict timeout cutoff to prevent UI locks

      print('📡 SERVER RESPONSE CODE: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SERVER DISPATCH VERIFIED: Feedback logged in PostgreSQL.');
        cloudSyncSuccess = true;
      } else {
        print('🚨 SERVER ERR: Rejection caught on cloud controller. Status: ${response.statusCode}');
      }
    } catch (networkError) {
      // Catches socket dropouts, host exceptions, and timeouts
      print('📡 LOCAL FALLBACK TRIGGERED: Server pipeline unreachable. ($networkError)');
    }

    // 💾 4. HARDWARE QUEUE PERSISTENCE LAYER
    try {
      // Mutate payload map with state identifiers required by SQLite schema rows
      final Map<String, dynamic> localDbPayload = {
        ...feedbackPayload,
        "syncStatus": cloudSyncSuccess ? "SYNCED" : "PENDING",
      };

      int databaseRowId = await LocalDatabaseHelper.instance.insertOfflineFeedback(localDbPayload);
      print('💾 SQLITE STORAGE METRIC: Feedback saved locally into Row ID: $databaseRowId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cloudSyncSuccess
                ? 'Thank you! Your feedback has been synchronized to the cloud.'
                : 'Saved offline to device storage! Review will sync automatically later.'),
            backgroundColor: cloudSyncSuccess ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (sqliteError) {
      print('🚨 CRITICAL HARDWARE LAYER FAILURE: Could not record feedback. Error: $sqliteError');
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final Color inputFieldBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final Color accentColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: mainTextColor),
        title: Text('Rate App', style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text('Your Experience Matters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainTextColor)),
            const SizedBox(height: 8),
            Text('Tap the stars to score the current app layout performance metrics.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: subTextColor)),
            const SizedBox(height: 28),

            // ⭐ INTERACTIVE STAR SELECTOR MATRIX
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                int starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 42,
                  ),
                  color: starValue <= _selectedStars ? Colors.amber : (isDark ? Colors.white24 : Colors.grey.shade400),
                  onPressed: () {
                    setState(() {
                      _selectedStars = starValue;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),

            // 💬 WRITTEN OBSERVATIONS BLOCK
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              style: TextStyle(color: mainTextColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                hintText: 'Share bugs, feature requests, or UI observations...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: inputFieldBg,
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
              ),
            ),
            const SizedBox(height: 32),

            // SUBMIT INTERACTION BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[700] : const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSending
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Feedback', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}