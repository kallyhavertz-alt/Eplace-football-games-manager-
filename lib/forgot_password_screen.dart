import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eplace/eplace_scaffold.dart';
import 'package:eplace/Efootbal_loader.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String baseUrl;
  const ForgotPasswordScreen({super.key, required this.baseUrl});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isLoading = false;
  int _currentStep = 1; // 1: Enter Email, 2: Enter Token & New Password

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // --- STEP 1: Dispatch Recovery Token ---
  Future<void> _dispatchForgotPasswordCode() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please enter your account email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final http.Response response = await http.post(
        Uri.parse('${widget.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Verification code dispatched to your inbox!');
        setState(() {
          _currentStep = 2; // Transition smoothly to validation fields
        });
      } else {
        _showSnackbar('Could not initialize account recovery.');
      }
    } catch (e) {
      _showSnackbar('Network failure during reset dispatch.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- STEP 2: Execute Password Reset ---
  Future<void> _executePasswordReset() async {
    final String token = _tokenController.text.trim();
    final String newPassword = _newPasswordController.text.trim();

    if (token.length != 6 || newPassword.isEmpty) {
      _showSnackbar('Please supply the 6-digit token and a new password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final http.Response response = await http.post(
        Uri.parse('${widget.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackbar('Password updated successfully! Redirecting to login...');
        Navigator.pop(context); // Take them clean back to AuthScreen login
      } else {
        _showSnackbar('Invalid or expired 6-digit validation token.');
      }
    } catch (e) {
      _showSnackbar('Network execution error during token lifecycle reset.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content), backgroundColor: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Match your design asset background layout
          Positioned.fill(
            child: Image.asset(
              'assets/eplace_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.65)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      _currentStep == 1 ? 'Recover Password' : 'Verify Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 1
                          ? 'Enter your email below to receive your 6-digit verification code.'
                          : 'Provide the 6-digit verification code and construct your new login password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 32),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 1 ? _buildEmailStep() : _buildVerificationStep(),
                    ),

                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: EFootballLoader(size: 64)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _emailController,
          hint: 'Enter registered email address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _dispatchForgotPasswordCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputField(
          controller: _tokenController,
          hint: '6-Digit Token',
          icon: Icons.numbers,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _newPasswordController,
          hint: 'New Secure Password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _executePasswordReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Reset Account Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}