import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateLeagueScreen extends StatefulWidget {
  final int userId;

  const CreateLeagueScreen({super.key, this.userId = 1});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxTeamsController = TextEditingController();

  static const String _backendApiUrl = 'http://192.168.1.167:8080/api/v1/leagues/create-request';

  final List<int> _allowedAmounts = [20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200, 300, 500, 600, 1000];
  int _selectedAmount = 50;

  String _selectedAwardDistribution = '1st only';
  final List<String> _awardOptions = ['1st only', '1st and 2nd', '1st, 2nd and 3rd'];

  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  // Helper method to convert UI display string to Spring Boot AwardType Enum
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
    setState(() => _isProcessing = true);

    final Map<String, dynamic> leagueData = {
      'creatorId': widget.userId,
      'name': _nameController.text.trim(),
      'joinAmount': _selectedAmount,
      'maxTeams': int.parse(_maxTeamsController.text.trim()),
      'awardType': _mapAwardTypeToEnum(_selectedAwardDistribution), // Fixed enum mapping
      'accountCode': accountCode,
    };

    try {
      final response = await http.post(
        Uri.parse(_backendApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': widget.userId.toString(),
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
      _showPaymentInstructionsDialog(_selectedAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CREATE LEAGUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
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
                        const EplaceStrikingLoader(size: 80),
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

// --- CUSTOM ROTATING E-LOADER WIDGET ---
class EplaceStrikingLoader extends StatefulWidget {
  final double size;
  const EplaceStrikingLoader({super.key, this.size = 70.0});

  @override
  State<EplaceStrikingLoader> createState() => _EplaceStrikingLoaderState();
}

class _EplaceStrikingLoaderState extends State<EplaceStrikingLoader> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _EplaceLoaderPainter(
            rotation: _rotationController.value,
          ),
        );
      },
    );
  }
}

class _EplaceLoaderPainter extends CustomPainter {
  final double rotation;
  _EplaceLoaderPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // 1. Top Arc
    final Paint topArcPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final double topStartAngle = (rotation * 2 * math.pi) - (math.pi / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      topStartAngle,
      math.pi * 0.9,
      false,
      topArcPaint,
    );

    // 2. Bottom Arc
    final Paint bottomArcPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final double bottomStartAngle = -(rotation * 2 * math.pi) + (math.pi / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      bottomStartAngle,
      math.pi * 0.9,
      false,
      bottomArcPaint,
    );

    // 3. Central Striking Dash
    final Paint dashPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - (radius * 0.45), center.dy),
      Offset(center.dx + (radius * 0.45), center.dy),
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}