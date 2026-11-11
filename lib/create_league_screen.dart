import 'dart:convert';
import 'package:eplace/profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eplace/session_manager.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxTeamsController = TextEditingController();

  static const String _backendApiUrl = 'http://172.16.123.181:8081/api/v1/leagues/create-request';

  final List<int> _allowedAmounts = [20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200, 300, 500, 600, 1000];
  int _selectedAmount = 50;

  String _selectedAwardDistribution = '1st only';
  final List<String> _awardOptions = ['1st only', '1st and 2nd', '1st, 2nd and 3rd'];

  bool _isProcessing = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await SessionManager.getUserId();
    if (mounted) {
      setState(() {
        _userId = id;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  String _mapAwardTypeToEnum(String uiValue) {
    switch (uiValue) {
      case '1st only':
        return 'FIRST_ONLY';
      case '1st and 2nd':
        return 'FIRST_AND_SECOND';
      case '1st, 2nd and 3rd':
        return 'FIRST_SECOND_AND_THIRD';
      default:
        return 'FIRST_ONLY';
    }
  }

  Future<void> _checkAndProceedCreation() async {
    final int userId = _userId ?? await SessionManager.getUserId() ?? 0;
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
      );

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
    _showPaymentInstructionsDialog(_selectedAmount);
  }

  void _showPaymentInstructionsDialog(int amount) {
    final String cleanAccount = _nameController.text.trim().replaceAll(RegExp(r'\s+'), '-').toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[950],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey[900]!),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text('Lipa Na M-Pesa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please complete your setup transaction to submit this league for admin review:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Paybill Number', '247247', isHighlight: true),
                  const Divider(color: Colors.white10, height: 20),
                  _buildPaymentRow('Account Name', cleanAccount, isHighlight: true),
                  const Divider(color: Colors.white10, height: 20),
                  _buildPaymentRow('Amount Due', 'KES $amount', isHighlight: false, color: Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Once you make the payment, click "Done" below. The admin will verify the payment and activate your league shortly.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitLeagueToAdminPipeline(cleanAccount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done, I have Paid', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isHighlight ? Colors.white : Colors.grey),
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
            fontSize: isHighlight ? 15 : 14,
            letterSpacing: isHighlight ? 1.1 : 1.0,
          ),
        ),
      ],
    );
  }

  Future<void> _submitLeagueToAdminPipeline(String accountCode) async {
    final int userId = _userId ?? await SessionManager.getUserId() ?? 1;

    setState(() => _isProcessing = true);

    final Map<String, dynamic> leagueData = {
      'creatorId': userId,
      'name': _nameController.text.trim(),
      'joinAmount': _selectedAmount,
      'maxTeams': int.parse(_maxTeamsController.text.trim()),
      'awardType': _mapAwardTypeToEnum(_selectedAwardDistribution),
      'accountCode': accountCode,
    };

    try {
      final response = await http.post(
        Uri.parse(_backendApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': userId.toString(),
        },
        body: jsonEncode(leagueData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Sent to Admin! Awaiting verification to go live.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final errorMsg = errorData['message'] ?? errorData['error'] ?? 'Failed to submit league';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _validateAndSubmitForm() {
    if (_formKey.currentState!.validate()) {
      _checkAndProceedCreation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EPlaceScaffold(
      appBar: AppBar(
        title: const Text('CREATE LEAGUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: _isProcessing,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildInputField(
                        controller: _nameController,
                        hint: 'Enter league name',
                        icon: Icons.emoji_events,
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'League title parameter required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      const Text('ENTRY FEE (KES)',
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[950],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[900]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedAmount,
                            dropdownColor: Colors.grey[950],
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                            isExpanded: true,
                            items: _allowedAmounts.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('KES $value'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedAmount = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildInputField(
                        controller: _maxTeamsController,
                        hint: 'Enter max teams',
                        icon: Icons.groups_outlined,
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Maximum competitor limit required'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      const Text('AWARD DISTRIBUTION STRUCTURE',
                          style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAwardDistribution,
                            dropdownColor: Colors.grey[900],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                            isExpanded: true,
                            items: _awardOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedAwardDistribution = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _validateAndSubmitForm,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('CREATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const EFootballLoader(size: 80),
                        const SizedBox(height: 24),
                        Text(
                          'Submitting to Admin Desk...',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[950],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[900]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
