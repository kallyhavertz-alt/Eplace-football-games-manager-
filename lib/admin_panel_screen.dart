import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const String _baseUrl = 'http://172.16.123.181:8081/api/v1/leagues';
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _pendingPayouts = [];
  List<Map<String, dynamic>> _historyLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminDashboardData();
  }

   Future<void> _fetchAdminDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequests = List<Map<String, dynamic>>.from(data['pendingRequests'] ?? []);
          _pendingPayouts = List<Map<String, dynamic>>.from(data['pendingPayouts'] ?? []);
          _historyLogs = List<Map<String, dynamic>>.from(data['historyLogs'] ?? []);
        });
      } else {
        setState(() {
          _errorMessage = 'Server error (${response.statusCode}): ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String id, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/requests/$id/accept'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _pendingRequests.removeWhere((item) => item['id'] == id);
          _historyLogs.insert(0, {
            'type': 'ACCEPTED_JOIN',
            'timeAgo': 'Just now',
            'details': 'You Accepted $message',
          });
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted: $message'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to accept request (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _rejectRequest(String id, String message) async {
    try {
       final String numericId = id.replaceAll('req_', '');

      final response = await http.post(
        Uri.parse('$_baseUrl/admin/$numericId/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _pendingRequests.removeWhere((item) => item['id'] == id);
          _historyLogs.insert(0, {
            'type': 'REJECTED_JOIN',
            'timeAgo': 'Just now',
            'details': 'You Rejected $message',
          });
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejected: $message'), backgroundColor: Colors.redAccent),
        );
      } else {
        throw Exception('Failed to reject request (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _confirmPayout(String id, String leagueTitle) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payouts/$id/confirm'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final targetPayout = _pendingPayouts.firstWhere((p) => p['id'] == id, orElse: () => {});

        setState(() {
          _pendingPayouts.removeWhere((item) => item['id'] == id);
          _historyLogs.insert(0, {
            'type': 'CONFIRMED_WINNER',
            'timeAgo': 'Just now',
            'details': 'You confirmed payout for $leagueTitle (${targetPayout['winner'] ?? 'Multiple Winners'})',
          });
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payout Confirmed for $leagueTitle!'), backgroundColor: Colors.blueAccent),
        );
      } else {
        throw Exception('Failed to confirm payout');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark ? Colors.black : Colors.grey[50]!;
    final Color cardColor = isDark ? const Color(0xFF080808) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final Color dividerColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;

    return EPlaceScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.4),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Admin Panel',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'ePlace',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _fetchAdminDashboardData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: EFootballLoader(size: 64))
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: subTextColor), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAdminDashboardData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Retry Connection'),
              )
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAdminDashboardData,
        color: Colors.blueAccent,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            if (_pendingRequests.isNotEmpty) ...[
              Text(
                'Pending Approvals',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            ..._pendingRequests.map((req) {
              final bool isJoin = req['type'] == 'JOIN';
              final String requestDetails = '${req['username']} -> ${req['target']}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                          child: Text(
                            req['userInitials'] ?? 'U',
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textColor, fontSize: 14, height: 1.3),
                              children: [
                                TextSpan(text: req['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: isJoin ? ' wanted to join ' : ' wanted to create '),
                                TextSpan(text: req['target'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(
                                  text: ' @ ${req['amount']} kes',
                                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        OutlinedButton(
                          onPressed: () => _rejectRequest(req['id'], requestDetails),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 1.2),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),

                        ElevatedButton(
                          onPressed: () => _acceptRequest(req['id'], requestDetails),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            if (_pendingPayouts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pending Winner Payouts',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
            ],
            ..._pendingPayouts.map((payout) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              payout['title'],
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          payout['timeAgo'] ?? '',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (payout['isMultiWinner'] ?? false) ? 'ended. Winners are:' : 'ended.',
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    if (!(payout['isMultiWinner'] ?? false)) ...[
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                          children: [
                            const TextSpan(text: 'winner takes '),
                            TextSpan(
                              text: 'kes ${payout['amount']}. ',
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: 'Phone number: '),
                            TextSpan(
                              text: '${payout['phone']} ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: payout['winner'],
                              style: TextStyle(color: Colors.blueAccent[100], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...((payout['winners'] ?? []) as List<dynamic>).map((w) {
                        final winnerMap = Map<String, dynamic>.from(w);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Text('${winnerMap['rank']} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text('${winnerMap['name']}: ', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                              Text('${winnerMap['phone']} - ', style: TextStyle(color: subTextColor)),
                              Text('${winnerMap['prize']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _confirmPayout(payout['id'], payout['title']),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Accepted and Confirmed',
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            ..._historyLogs.map((log) {
              final bool isWinner = log['type'] == 'CONFIRMED_WINNER';
              final bool isRejected = log['type'] == 'REJECTED_JOIN';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900]!.withValues(alpha: 0.4) : Colors.grey[200]!.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          isWinner
                              ? Icons.emoji_events_outlined
                              : (isRejected ? Icons.cancel_outlined : Icons.check_circle_outline),
                          color: isWinner
                              ? Colors.amber
                              : (isRejected ? Colors.redAccent : Colors.greenAccent),
                          size: 18,
                        ),
                        Text(
                          log['timeAgo'] ?? '',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      log['details'] ?? '',
                      style: TextStyle(color: subTextColor, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}