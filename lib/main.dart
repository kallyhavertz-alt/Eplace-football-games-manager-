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

  // Initialize notifications in background - don't await to avoid blocking UI if offline
  NotificationService.initialize().catchError((e) => debugPrint("Notification init error: $e"));

  // Check for session and subscribe in background
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
      initialRoute: '/settings',
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
          // If a username exists, skip login
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



  final String _baseUrl = 'http://192.168.1.167:8080/api';
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
      // Force sign out to allow account selection
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.authenticate();
      
      final googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _showSnackbar('Failed to acquire secure Google Identity Token.');
        return;
      }

      print("🎉 Secure token retrieved successfully. Passing to Spring Boot pipeline...");
      final http.Response response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String username = data['username'] ?? googleUser.displayName ?? 'Player';
        
        // Safely parse userId regardless of whether it's an int or a String
        final dynamic rawId = data['id'];
        final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

        print("🎉 Backend Response Data: $data");
        print("🔍 Extracted userId: $userId");

        await SessionManager.saveUsername(username);
        if (userId != null) {
          await SessionManager.saveUserId(userId);
          print("🚀 Calling subscribeToUserTopic for userId: $userId");
          await NotificationService.subscribeToUserTopic(userId);
        } else {
          print("⚠️ userId is null, skipping FCM subscription.");
        }

        _navigateToHome(username);
      } else {
        print("Backend authentication failed with status: ${response.statusCode}");
        _showSnackbar('Google registration/login rejected by eplace servers.');
      }
    } catch (e) {
      print("🚨 Critical Error encountered during Google Sign-In pipeline: $e");
      _showSnackbar('Google Sign-In integration error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

    /*Future<void> _handleAuthAction() async {
    final String identifier = _identifierController.text.trim();
    final String password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackbar('Please populate all required login fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        final http.Response response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': identifier,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final String username = data['username'];
          await SessionManager.saveUsername(username);
          _navigateToHome(username);
        } else {
          final Map<String, dynamic> errData = jsonDecode(response.body);
          _showSnackbar(errData['message'] ?? 'Authentication authorization rejected.');
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
          await SessionManager.saveUsername(username);
          _showSnackbar('Registration complete! Welcome to eplace.');
          _navigateToHome(username);
        } else {
          try {
            final Map<String, dynamic> errData = jsonDecode(response.body);
            _showSnackbar(errData['message'] ?? 'You must be 18 years of age or older to register.');
            return;
          } catch (e) {
            _showSnackbar('You must be 18+ to use ePlace services');
          }

          _showSnackbar('Failed to compile application account profile.');
        }
      }
    } catch (e) {
      _showSnackbar('Could not establish reliable channel links to eplace servers.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

     */
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
        final http.Response response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': identifier,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
           final Map<String, dynamic> data = jsonDecode(response.body);
           print('📡 Backend Login Response Payload: $data');

           final String username = data['username'];
          
          // Safely parse userId regardless of whether it's an int or a String
           final dynamic rawId = data['userId'] ?? data['id'];
           final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

          print("🎉 Login Response Data: $data");
          print("🔍 Extracted userId: $userId");

          // 1. Save session details
          await SessionManager.saveUsername(username);

          if (userId != null) {
            await SessionManager.saveUserId(userId);
            print("🚀 Calling subscribeToUserTopic for userId: $userId");
            await NotificationService.subscribeToUserTopic(userId);
          } else {
            print("⚠️ userId is null, skipping FCM subscription.");
          }

          _navigateToHome(username);
        } else {
          final Map<String, dynamic> errData = jsonDecode(response.body);
          _showSnackbar(errData['message'] ?? 'Authentication authorization rejected.');
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
          
          // Safely parse userId regardless of whether it's an int or a String
          final dynamic rawId = data['id'];
          final int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');

          print("🎉 Register Response Data: $data");
          print("🔍 Extracted userId: $userId");

          // 1. Save session details
          await SessionManager.saveUsername(username);
          if (userId != null) {
            await SessionManager.saveUserId(userId);
            // 2. Subscribe to FCM topic for push notifications
            print("🚀 Calling subscribeToUserTopic for userId: $userId");
            await NotificationService.subscribeToUserTopic(userId);
          } else {
            print("⚠️ userId is null, skipping FCM subscription.");
          }

          _showSnackbar('Registration complete! Welcome to eplace.');
          _navigateToHome(username);
        } else {
          try {
            final Map<String, dynamic> errData = jsonDecode(response.body);
            _showSnackbar(errData['message'] ?? 'You must be 18 years of age or older to register.');
            return;
          } catch (e) {
            _showSnackbar('You must be 18+ to use ePlace services');
          }

          _showSnackbar('Failed to compile application account profile.');
        }
      }
    } catch (e) {
      _showSnackbar('Could not establish reliable channel links to eplace servers.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EplaceDashboardScreen(username: username)),
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
                          onPressed:() {
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
                      onPressed: _isLoading ? null : _handleGoogleSignIn, // WIRED UP
                      icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.redAccent),
                      label: const Text('Continue with Google'),
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

// --- DYNAMIC CUSTOM ANIMATED PES LOADING WIDGET LAYER ---
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
