import 'dart:convert';
import 'package:eplace/profile_completion_screen.dart';
import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JoinLeagueScreen extends StatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  static String get _baseUrl => '${ProfileService.baseUrl}/leagues';

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allLeagues = [];
  List<Map<String, dynamic>> _filteredLeagues = [];
  String? _currentUsername;
  int? _currentUserId;

  final TextEditingController _searchController = TextEditingController();
  double? _maxAmountFilter;

  @override
  void initState() {
    super.initState();
    _loadUserAndLeagues();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadUserAndLeagues() async {
    _currentUsername = await SessionManager.getUsername();
    _currentUserId = await SessionManager.getUserId();
    await _fetchLeagues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _fetchLeagues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/active'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allLeagues = List<Map<String, dynamic>>.from(data);
          _applyFilters();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load leagues (${response.statusCode})';
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


  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredLeagues = _allLeagues.where((league) {
        final name = (league['name'] ?? '').toString().toLowerCase();
        final amount = (league['joinAmount'] ?? 0).toDouble();

        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            amount.toString().contains(query);

        final matchesAmountFilter =
            _maxAmountFilter == null || amount <= _maxAmountFilter!;

        return matchesQuery && matchesAmountFilter;
      }).toList();
    });
  }


  Future<void> _checkAndProceedJoin(Map<String, dynamic> league) async {
    final int userId = _currentUserId ?? await SessionManager.getUserId() ?? 0;
    if (userId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session not found. Please log in again.')),
        );
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://172.16.123.181:8081/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print("🔍 [DEBUG] User Profile Check Status Code: ${response.statusCode}");
      print("🔍 [DEBUG] User Profile Check Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final String? phone = userData['phoneNumber'];
        final String? dob = userData['dateOfBirth'];



        if (phone == null || phone.isEmpty || dob == null || dob.toString().isEmpty) {
          if (!mounted) return;
          final bool? completed = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ProfileCompletionSheet(userId: userId),
          );

          if (completed != true) return;
        }
      }
    } catch (e) {
      debugPrint("Profile validation check error: $e");
    }

    if (!mounted) return;
    _showJoinDialog(league);
  }

  void _showJoinDialog(Map<String, dynamic> league) {
    final TextEditingController accountCodeController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Join ${league['name']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'How to Pay Entrance Fee',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('1. Go to M-Pesa -> Lipa na M-Pesa', style: TextStyle(color: Colors.white70)),
                          const Text('2. Paybill: 247247', style: TextStyle(color: Colors.white70)),
                          const Text('3. Account No: ePlace', style: TextStyle(color: Colors.white70)),
                          Text(
                            '4. Amount: KES ${league['joinAmount']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'After paying, copy the M-Pesa Confirmation Code below.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: accountCodeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'M-Pesa Transaction / Account Code',
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: 'e.g. QX78921KL',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black38,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.receipt_long, color: Colors.blueAccent),
                      ),
                    ),

                    const SizedBox(height: 20),


                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                          final code = accountCodeController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your transaction code'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);

                          final success = await _submitJoinRequest(
                            league['id'],
                            code,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Join request sent! Admin will review your payment.'
                                      : 'Failed to send join request.',
                                ),
                                backgroundColor: success ? Colors.green : Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : const Text(
                          'Submit Request',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitJoinRequest(dynamic leagueId, String accountCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$leagueId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountCode': accountCode,
          'username': _currentUsername ?? 'Unknown',
        }),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1E1E1E);

    return EPlaceScaffold(
      appBar: AppBar(
        title: const Text('Find & Join Leagues', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or amount (e.g. 500)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => _searchController.clear(),
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Fees'),
                        selected: _maxAmountFilter == null,
                        onSelected: (_) {
                          setState(() => _maxAmountFilter = null);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('<= 500 KES'),
                        selected: _maxAmountFilter == 500,
                        onSelected: (_) {
                          setState(() => _maxAmountFilter = 500);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('<= 1000 KES'),
                        selected: _maxAmountFilter == 1000,
                        onSelected: (_) {
                          setState(() => _maxAmountFilter = 1000);
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: EFootballLoader(size: 64))
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)))
                : _filteredLeagues.isEmpty
                ? const Center(child: Text('No leagues found matching your search.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: _filteredLeagues.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final league = _filteredLeagues[index];
                final bool isCreator = league['creatorUsername'] == _currentUsername;
                final int current = league['currentTeams'] ?? 0;
                final int max = league['maxTeams'] ?? 0;
                final bool isFull = current >= max;

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                league['name'] ?? 'Unnamed League',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCreator ? 'Host: You' : 'Host: ${league['creatorUsername']}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${league['joinAmount']} KES',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Teams: $current/$max',
                                    style: TextStyle(
                                      color: isFull ? Colors.redAccent : Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (isFull || isCreator) ? null : () => _checkAndProceedJoin(league),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCreator ? Colors.orangeAccent.withValues(alpha: 0.2) : (isFull ? Colors.grey : Colors.blueAccent),
                          ),
                          child: Text(
                            isCreator ? 'Owner' : (isFull ? 'Full' : 'Join'),
                            style: TextStyle(
                              color: isCreator ? Colors.orangeAccent : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
