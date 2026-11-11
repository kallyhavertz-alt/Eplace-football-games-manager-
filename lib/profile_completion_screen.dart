import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eplace/session_manager.dart';
import 'package:eplace/profile_service.dart';

class ProfileCompletionSheet extends StatefulWidget {
  final int userId;

  const ProfileCompletionSheet({super.key, required this.userId});

  @override
  State<ProfileCompletionSheet> createState() => _ProfileCompletionSheetState();
}

class _ProfileCompletionSheetState extends State<ProfileCompletionSheet> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDob;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitDetails() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = "Please enter a valid Safaricom phone number.");
      return;
    }
    if (_selectedDob == null) {
      setState(() => _errorMessage = "Date of birth as per your ID is required.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final token = await SessionManager.getAuthToken();
    final Uri baseUri = Uri.parse(ProfileService.baseUrl);
    final String hostRoot = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';

    final url = Uri.parse('$hostRoot/api/users/${widget.userId}/complete-details');
    //final url = Uri.parse('${ProfileService.baseUrl}/api/users/${widget.userId}/complete-details');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phoneNumber': phone,
          'dateOfBirth': _selectedDob!.toIso8601String().split('T')[0],
          if (_passwordController.text.trim().isNotEmpty)
            'newPassword': _passwordController.text.trim(),
        }),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.statusCode == 200) {
          Navigator.pop(context, true);
        } else {
          final err = jsonDecode(response.body);
          setState(() => _errorMessage = err['message'] ?? "Failed to update details.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = "Network error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blueAccent, size: 26),
                SizedBox(width: 8),
                Text(
                  "Required Information",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "If you logged in with google, ePlace may not find relevant details required in league creation/joining. "
                  "This details include a valid Safaricom phone number with M-PESA service for receiving your rewards, "
                  "Date of birth as per your Id and you can optionally create a password to log in next time without Google. "
                  "Read Terms and Conditions and Privacy Policy for ePlace for more. Fill in these fields, thank you.",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "M-PESA Phone Number",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.phone_android, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2005),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDob = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDob == null
                          ? "Select Date of Birth (As per ID)"
                          : "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}",
                      style: TextStyle(color: _selectedDob == null ? Colors.grey : Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Create Password (Optional)",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submitDetails,
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Save & Proceed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}