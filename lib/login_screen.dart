import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  void _openPasswordRecoveryDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    int recoveryStep = 1; // Step 1: Input Email | Step 2: Input Code & New Password
    bool isLoading = false;
    String? modalError;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(recoveryStep == 1 ? 'Reset Password' : 'Verify Code'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(modalError!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
                      ),
                    ],
                    if (recoveryStep == 1) ...[
                      const Text("Enter your registered email below to receive a 6-digit recovery code:"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      const Text("Enter the 6-digit verification code sent to your inbox along with your new password:"),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-Digit Code',
                          prefixIcon: Icon(Icons.pin_outlined),
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                  onPressed: isLoading
                      ? null
                      : () async {
                    setModalState(() {
                      isLoading = true;
                      modalError = null;
                    });

                    try {
                      if (recoveryStep == 1) {
                        // 🛰️ Submit Stage 1 Request
                        final response = await http.post(
                          Uri.parse('http://192.168.100.33:8080/api/users/forgot-password'),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode({"email": emailController.text.trim()}),
                        );

                        if (response.statusCode == 200) {
                          setModalState(() {
                            recoveryStep = 2; // Advance to verification payload block
                            isLoading = false;
                          });
                        } else {
                          final Map<String, dynamic> err = json.decode(response.body);
                          setModalState(() {
                            modalError = err['message'] ?? 'Email verification failed.';
                            isLoading = false;
                          });
                        }
                      } else {
                        // 🛰️ Submit Stage 2 Verification Request
                        final response = await http.post(
                          Uri.parse('http://192.168.100.33:8080/api/users/reset-password'),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode({
                            "token": codeController.text.trim(),
                            "newPassword": newPasswordController.text.trim(),
                          }),
                        );

                        if (response.statusCode == 200) {
                          if (!context.mounted) return;
                          Navigator.pop(context); // Dismiss dialog frame
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🎉 Password updated successfully! Log in now.')),
                          );
                        } else {
                          final Map<String, dynamic> err = json.decode(response.body);
                          setModalState(() {
                            modalError = err['message'] ?? 'Failed to apply new credentials.';
                            isLoading = false;
                          });
                        }
                      }
                    } catch (e) {
                      setModalState(() {
                        modalError = '🚨 Failed to connect to server backend system.';
                        isLoading = false;
                      });
                    }
                  },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(recoveryStep == 1 ? 'Send Code' : 'Verify & Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    const String url = "http://192.168.100.33:8080/api/users/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print("Base Network Check - Payload Received: $responseData");

        final dynamic rawId = responseData['id'];
        if (rawId != null) {
          final int loggedInId = int.parse(rawId.toString());
          final String userLabel = loggedInId == 1 ? "elias(user1)" : "machs (user 2)";

          await SessionManager.saveUserSession(loggedInId, userLabel);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          await prefs.setString(
              'userName', responseData['fullName'] ?? 'Cathedral Member');
          await prefs.setString(
              'userEmail', responseData['email'] ?? _emailController.text);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged in successfully! WELCOME BACK!!'),
                backgroundColor: Colors.green,
              ));

          print("🔒 Isolation Layer Engaged: Verified login for $userLabel");
        } else {
          print("❌ CRITICAL ERROR: Backend missing user identification map keys!");
        }

        if (!mounted) return;

        // Turn off loading animation right before transitioning out
        setState(() {
          _isLoading = false;
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );

      } else {
        // 🚨 Handling Non-200 HTTP Bad Responses cleanly
        String errorMessage = 'Invalid email or password.';
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (_) {
          // Fallback if the error response wasn't structured as a JSON string map
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print("❌ Connection error mapped out: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Network error: Could not reach server.'),
          backgroundColor: Colors.black26,
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
    // 🎨 CONDITIONAL BRIGHTNESS INTERCEPT ENGINE
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor = isDark ? Colors.white : const Color(0xFF0D47A1);
    final Color headingIconColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey;
    final Color inputFieldBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final Color borderStrokeColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final Color focusBorderColor = isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1);

    // Reuse field decoration constraints securely
    InputDecoration fieldDecoration({required String label, required IconData prefixIcon, Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
        prefixIcon: Icon(prefixIcon, color: isDark ? Colors.blue.shade300 : const Color(0xFF0D47A1)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputFieldBg,
        counterStyle: TextStyle(color: subTextColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderStrokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderStrokeColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusBorderColor, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 80,
                    color: headingIconColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your cathedral account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                    decoration: fieldDecoration(
                      label: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                    decoration: fieldDecoration(
                      label: 'Password',
                      prefixIcon: Icons.lock_open_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blue[700] : const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isDark ? 0 : 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.blue.shade200 : Colors.white),
                      ),
                    )
                        : const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openPasswordRecoveryDialog, // 🟩 Triggers the multi-step flow
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}