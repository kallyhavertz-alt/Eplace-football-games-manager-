/*
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminReportsScreen extends StatefulWidget {
  final String? adminMemberId;

  const AdminReportsScreen({Key? key, required this.adminMemberId}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late Future<List<dynamic>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _refreshReports();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = _fetchPendingReports();
    });
  }

  Future<List<dynamic>> _fetchPendingReports() async {
    final String url = 'http://192.168.100.33:8080/api/v1/community/admin/reports';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error loading reports: ${response.statusCode}');
    }
  }

   Future<void> _banUserEmail(String email) async {
    final String url = 'http://192.168.100.33:8080/api/v1/community/admin/reports/ban-user?email=${Uri.encodeComponent(email)}';

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        _showFeedbackSnackBar('User account associated with $email banned permanently.', Colors.redAccent);
        _refreshReports();
      } else {
        throw Exception();
      }
    } catch (_) {
      _showFeedbackSnackBar('Failed to execute user restriction.', Colors.orange);
    }
  }

  // 🗑️ DELETE /api/v1/community/admin/reports/{reportId}/dismiss
  Future<void> _dismissReport(int reportId) async {
    final String url = 'http://192.168.100.33:8080/api/v1/community/admin/reports/$reportId/dismiss';

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        _showFeedbackSnackBar('Report cleared and dismissed safely.', Colors.green);
        _refreshReports();
      } else {
        throw Exception();
      }
    } catch (_) {
      _showFeedbackSnackBar('Error communicating report dismissal.', Colors.orange);
    }
  }

  Future<void> _deleteOffendingPost(int postId) async {
    final String url = 'http://192.168.100.33:8080/api/v1/community/posts/$postId?memberId=${widget.adminMemberId}';

    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        _showFeedbackSnackBar('Offending post removed successfully.', Colors.blueGrey);
        _refreshReports();
      } else {
        throw Exception();
      }
    } catch (_) {
      _showFeedbackSnackBar('Could not safely drop targeted post.', Colors.orange);
    }
  }

  void _showFeedbackSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Moderation Center',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: mainTextColor),
            onPressed: _refreshReports,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gpp_bad_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Error pulling audit report records.'),
                  TextButton(onPressed: _refreshReports, child: const Text('Retry'))
                ],
              ),
            );
          }

          final reportsList = snapshot.data!;

          if (reportsList.isEmpty) {
            return const Center(
              child: Text('Clear slate! No active flagged content reported.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: reportsList.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final report = reportsList[index];

               final int reportId = report['reportId'] ?? 0;
              final int postId = report['postId'] ?? 0;
              final String reporterName = report['reporterEmail'] ?? 'Anonymous';
              final String authorName = report['reportedUserEmail'] ?? 'Unknown Member';
              final String authorEmail = report['reportedUserEmail'] ?? '';
              final String category = report['category'] ?? 'OTHER';
              final String detailedReason = report['reason'] ?? 'No comment context provided.';
              final String postCaptionPreview = report['postMediaUrl'] ?? '[Empty Content File Attachment Only]';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Text(
                              category.replaceAll('_', ' '),
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Text('Report #${reportId}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text('Flagged Post Content Preview:', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '"$postCaptionPreview"',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 24),

                      _buildAuditLine('Posted By:', '$authorName ($authorEmail)', isDark),
                      _buildAuditLine('Flagged By:', reporterName, isDark),
                      _buildAuditLine('Report Reason:', detailedReason, isDark),
                      const SizedBox(height: 16),

                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Dismiss'),
                            onPressed: () => _dismissReport(reportId),
                          ),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueGrey,
                              side: const BorderSide(color: Colors.blueGrey),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete Post'),
                            onPressed: () => _deleteOffendingPost(postId),
                          ),

                           ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.gavel_rounded, size: 16),
                            label: const Text('Ban User'),
                            onPressed: authorEmail.isEmpty ? null : () {
                              _showActionConfirmationDialog(authorName, authorEmail);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditLine(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: value, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _showActionConfirmationDialog(String targetUser, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Global Ban Action'),
          content: Text('Are you absolutely sure you want to ban $targetUser ($email)? This will permanently prevent them from posting updates to the fellowship feed streams.'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm Isolation Ban'),
              onPressed: () {
                Navigator.pop(context);
                _banUserEmail(email);
              },
            ),
          ],
        );
      },
    );
  }
}
 */