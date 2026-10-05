import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:untitled/posts_tab.dart';


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

   void _deleteOffendingPost(int postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text('Confirm Post Deletion'),
            ],
          ),
          content: const Text(
            'Are you sure you want to remove this post from the community feed? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove Content'),
              onPressed: () {
                Navigator.pop(context);
                _executePostDeletion(postId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _executePostDeletion(int postId) async {
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
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
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
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final report = reportsList[index];

              final int reportId = report['reportId'] ?? 0;
              final String reporterName = report['reporterEmail'] ?? 'Anonymous';
              final String category = report['category'] ?? 'OTHER';
              final String detailedReason = report['reason'] ?? 'No comment context provided.';

               final Map<String, dynamic>? postData = report['post'];

              final int postId = postData != null ? (postData['id'] ?? 0) : (report['postId'] ?? 0);
              final String authorEmail = postData != null ? (postData['authorEmail'] ?? postData['email'] ?? report['reportedUserEmail'] ?? '') : '';
              final String authorName = postData != null ? (postData['memberName'] ?? postData['authorName'] ?? 'Unknown Member') : 'Unknown Member';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Flag Status Band
                    Container(
                      color: Colors.orange.withOpacity(0.12),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                category.replaceAll('_', ' '),
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          Text('Report #$reportId', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                    ),

                    // 🟩 REUSE FEED WIDGET PREVIEW FRAME
                    if (postData != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                         child: CommunityPostCard(
                          post: postData,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Targeted post context data could not be parsed or was cleaned up.',
                          style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
                        ),
                      ),

                    const Divider(height: 1),

                    // Audit Metadata Segment
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAuditLine('Flagged By:', reporterName, isDark),
                          _buildAuditLine('Report Reason:', detailedReason, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Admin Actions Control row
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Dismiss'),
                              onPressed: () => _dismissReport(reportId),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueGrey,
                                side: const BorderSide(color: Colors.blueGrey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete Post'),
                              onPressed: () => _deleteOffendingPost(postId),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.gavel_rounded, size: 16),
                              label: const Text('Ban User'),
                              onPressed: authorEmail.isEmpty ? null : () {
                                _showActionConfirmationDialog(authorName, authorEmail);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
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