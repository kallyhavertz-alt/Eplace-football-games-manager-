import 'dart:math' as math;
import 'package:eplace/eplace_dashboard_screen.dart';
import 'package:eplace/forgot_password_screen.dart';
import 'package:eplace/session_manager.dart';
import 'package:eplace/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:eplace/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  NotificationService.initialize().catchError((e) => debugPrint("Notification init error: $e"));

   _handleStartupSubscription();

  runApp(const EPlaceApp());
}

Future<void> _handleStartupSubscription() async {
  try {
    final int? savedUserId = await SessionManager.getUserId();
    if (savedUserId != null) {
      debugPrint("🚀 Startup session found: userId $savedUserId. Subscribing...");
      NotificationService.subscribeToUserTopic(savedUserId);
    }
  } catch (e) {
    debugPrint("Startup subscription error: $e");
  }
}

class EPlaceApp extends StatelessWidget {
  const EPlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/homescreen',
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/login': (context) => const AuthScreen(),
      },
      title: 'eplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<String?>(
        future: SessionManager.getUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            );
          }
           if (snapshot.hasData && snapshot.data != null) {
            return EplaceDashboardScreen(username: snapshot.data!);
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;

  final String _baseUrl = 'http://172.16.123.181:8081/api';
  static const String _webClientId = '910119612022-kpmtlbvtnd1msto82beg0j7lmqcnqd1h.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn.instance;

  static bool _isGoogleInitialized = false;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGooglePlugin();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeGooglePlugin() async {
    if (_isGoogleInitialized) return;
    try {
      await _googleSignIn.initialize(
        serverClientId: _webClientId,
      );
      _isGoogleInitialized = true;
    } catch (e) {
      debugPrint("Google Sign In init failed: $e");
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {

      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _showSnackbar('Failed to acquire secure Google Identity Token.');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint("Secure token retrieved successfully. Passing to Spring Boot pipeline...");
      final http.Response response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final String username = data['username'] ?? googleUser.displayName ?? 'Player';
        final String? email = data['email'] ?? googleUser.email;
        final String? jwtToken = data['token'] ?? data['jwtToken'];

        final dynamic rawId = data['userId'] ?? data['id'];
        final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

        debugPrint("Backend Response Data: $data");
        debugPrint("Extracted userId: $userId | jwtToken present: ${jwtToken != null}");

        if (userId == null || jwtToken == null) {
          _showSnackbar('Invalid credentials returned from server.');
          setState(() => _isLoading = false);
          return;
        }

         await Future.wait([
          SessionManager.saveUserId(userId),
          SessionManager.saveUsername(username),
          if (email != null) SessionManager.saveEmail(email),
          if (jwtToken.isNotEmpty) SessionManager.saveAuthToken(jwtToken),
        ]);


        debugPrint("Calling subscribeToUserTopic for userId: $userId");
        await NotificationService.subscribeToUserTopic(userId);

        if (!mounted) return;

        setState(() => _isLoading = false);
        _navigateToHome(username);
      } else {
        debugPrint("Backend authentication failed with status: ${response.statusCode}");
        _showSnackbar('Google registration/login rejected by eplace servers.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Critical Error encountered during Google Sign-In pipeline: $e");
      _showSnackbar('Google Sign-In integration error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAuthAction() async {
    final String identifier = _identifierController.text.trim();
    final String password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackbar('Please populate all required login fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        final bool isEmail = identifier.contains('@') && identifier.contains('.');
        final http.Response response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': isEmail ? identifier : null,
            'phoneNumber': !isEmail ? identifier : null,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          print('📡 Backend Login Response Payload: $data');

          final String username = data['username'];

           final dynamic rawId = data['userId'] ?? data['id'];
          final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

          print("Login Response Data: $data");
          print("Extracted userId: $userId");

          await SessionManager.saveUsername(username);

          if (userId != null) {
            await SessionManager.saveUserId(userId);
            print("Calling subscribeToUserTopic for userId: $userId");
            await NotificationService.subscribeToUserTopic(userId);
          } else {
            print("⚠️ userId is null, skipping FCM subscription.");
          }

          _navigateToHome(username);
        } else {
          final Map<String, dynamic> errData = jsonDecode(response.body);
          _showSnackbar(errData['message'] ?? 'Authentication authorization rejected.');
          setState(() => _isLoading = false);
        }
      } else {
        final String username = _usernameController.text.trim();
        final String dob = _dobController.text.trim();
        final String phone = _phoneController.text.trim();

        if (username.isEmpty || dob.isEmpty || phone.isEmpty) {
          _showSnackbar('Please complete all custom user creation parameters.');
          setState(() => _isLoading = false);
          return;
        }

        final http.Response response = await http.post(
          Uri.parse('$_baseUrl/users/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': identifier,
            'phoneNumber': phone,
            'dateOfBirth': dob.replaceAll('/', '-'),
            'password': password,
          }),
        );

        if (response.statusCode == 201) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          final dynamic rawId = data['id'];
          final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

          print(" Register Response Data: $data");
          print(" Extracted userId: $userId");


          await SessionManager.saveUsername(username);
          if (userId != null) {
            await SessionManager.saveUserId(userId);
            print("Calling subscribeToUserTopic for userId: $userId");
            await NotificationService.subscribeToUserTopic(userId);
          } else {
            print("userId is null, skipping FCM subscription.");
          }

          setState(() => _isLoading = false);
          _showSnackbar('Registration complete! Please verify your email.');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                baseUrl: _baseUrl,
                email: identifier,
                username: username,
              ),
            ),
          );
        } else {
          try {
            final Map<String, dynamic> errData = jsonDecode(response.body);
            _showSnackbar(errData['message'] ?? 'You must be 18 years of age or older to register.');
            setState(() => _isLoading = false);
            return;
          } catch (e) {
            _showSnackbar('You must be 18+ to use ePlace services');
          }

          _showSnackbar('Failed to compile application account profile.');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      _showSnackbar('Could not establish reliable channel links to eplace servers.');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String username) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EFootballTransitionScreen(
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, anim, secAnim) => EplaceDashboardScreen(username: username),
                    transitionsBuilder: (context, anim, secAnim, child) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showSnackbar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content), backgroundColor: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/eplace_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PesLoadingLogo(isLoading: _isLoading),

                    const SizedBox(height: 8),
                    const Text(
                      'eplace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin ? 'Welcome Back! For more prizes' : 'Join eplace! Win Big Prizes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!isLogin) ...[
                      _buildTextField(
                        controller: _usernameController,
                        hint: 'PES Username',
                        icon: Icons.sports_esports,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _dobController,
                        hint: 'Date of Birth (YYYY-MM-DD)',
                        icon: Icons.cake,
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Reward Phone Number (M-Pesa)',
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      controller: _identifierController,
                      hint: isLogin ? 'Email / Phone number' : 'Email Address',
                      icon: Icons.person,
                      keyboardType: isLogin ? TextInputType.text : TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    if (isLogin) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(baseUrl: _baseUrl),
                              ),
                            );
                          },
                          child: const Text(
                            'forgot password?',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                    ],

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuthAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLoading
                            ? 'Processing Match Links...'
                            : (isLogin ? 'Login' : 'Register Account'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'or',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                          : const Icon(Icons.g_mobiledata, size: 30, color: Colors.redAccent),
                      label: Text(_isLoading ? 'Signing in...' : 'Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin ? "don't have an eplace Account? " : "Already have an account? ",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                              _identifierController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: Text(
                            isLogin ? 'Register' : 'Login',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
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

// --- NEW EMAIL VERIFICATION SCREEN ---
class EmailVerificationScreen extends StatefulWidget {
  final String baseUrl;
  final String email;
  final String username;

  const EmailVerificationScreen({
    super.key,
    required this.baseUrl,
    required this.email,
    required this.username,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final TextEditingController _emailController;
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showSnackbar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content), backgroundColor: Colors.blueAccent),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please enter your email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/auth/send-verification-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackbar(data['message'] ?? 'Verification code sent successfully.');
      } else {
        _showSnackbar(data['message'] ?? 'Failed to send verification code.');
      }
    } catch (e) {
      _showSnackbar('Network error while sending verification code.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      _showSnackbar('Please provide both email and verification code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackbar(data['message'] ?? 'Email verified successfully!');
        _navigateToDashboard();
      } else {
        _showSnackbar(data['message'] ?? 'Verification failed.');
      }
    } catch (e) {
      _showSnackbar('Network error during verification.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EFootballTransitionScreen(
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, anim, secAnim) => EplaceDashboardScreen(username: widget.username),
                    transitionsBuilder: (context, anim, secAnim, child) {
                      return FadeTransition(opacity: anim, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/eplace_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.black,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PesLoadingLogo(isLoading: _isLoading),

                    const SizedBox(height: 12),
                    const Text(
                      'Verify your Email to participate\nin different leagues and tournaments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.grey),
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Send code'),
                      ),
                    ),
                    const SizedBox(height: 24),


                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_clock, color: Colors.grey),
                        hintText: 'Verification Code',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.4),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLoading ? 'Verifying...' : 'Verify',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: _navigateToDashboard,
                      child: const Text(
                        'Skip to Verify later',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class PesLoadingLogo extends StatefulWidget {
  final bool isLoading;
  const PesLoadingLogo({super.key, required this.isLoading});

  @override
  State<PesLoadingLogo> createState() => _PesLoadingLogoState();
}

class _PesLoadingLogoState extends State<PesLoadingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isLoading) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PesLoadingLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'e',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 0.9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class EFootballTransitionScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const EFootballTransitionScreen({super.key, required this.onComplete});

  @override
  State<EFootballTransitionScreen> createState() => _EFootballTransitionScreenState();
}

class _EFootballTransitionScreenState extends State<EFootballTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _spinnerRotation;
  late Animation<double> _brandScale;
  late Animation<double> _brandOpacity;

  bool _isLogoPhase = false;

  @override
  void initState() {
    super.initState();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _spinnerRotation = Tween<double>(begin: 0.0, end: 3 * 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOutCubic),
      ),
    );

   _brandScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeIn),
      ),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.65 && !_isLogoPhase) {
        setState(() {
          _isLogoPhase = true;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: !_isLogoPhase
            ? Container(
          key: const ValueKey('LoaderPhase'),
          color: const Color(0xFFFFD700),
          child: Center(
            child: AnimatedBuilder(
              animation: _spinnerRotation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _spinnerRotation.value,
                  child: child,
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 4,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: CircularProgressIndicator(
                    color: Colors.black87,
                    strokeWidth: 3.5,
                  ),
                ),
              ),
            ),
          ),
        )
            : Container(
          key: const ValueKey('LogoPhase'),
          color: const Color(0xFF00113B),
          child: Center(
            child: FadeTransition(
              opacity: _brandOpacity,
              child: ScaleTransition(
                scale: _brandScale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 50,
                        color: Color(0xFF00113B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "eplace™",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "LEAGUE MANAGER",
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}