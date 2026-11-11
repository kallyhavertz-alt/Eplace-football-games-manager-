import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eplace/eplace_scaffold.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  final String baseUrl;

  const EditProfileScreen({
    super.key,
    required this.userId,
    this.baseUrl = 'http://172.16.123.181:8081/api/v1',
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _strengthController;

  bool _isSavingFile = false;
  String? _serverAvatarPath;
  String? _customImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _bioController = TextEditingController();
    _strengthController = TextEditingController();

    _loadUserData();
    _loadUserProfileFromServer();

    _bioController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadUserProfileFromServer() async {
    try {
      final String targetUrl = '${widget.baseUrl}/profile/${widget.userId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _serverAvatarPath = userData['profilePictureUrl'];
            _usernameController.text = userData['username'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _strengthController.text = userData['efootballStrength']?.toString() ?? '3000';
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user profile in Edit Screen: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${widget.userId}';
    if (mounted) {
      setState(() {
        _customImagePath = prefs.getString(storageKey);
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  void _showDeleteAccountConfirmation() {
    bool isPurging = false;

    showDialog(
      context: context,
      barrierDismissible: !isPurging,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              backgroundColor: Colors.grey[950],
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Account?'),
                ],
              ),
              content: const Text(
                'Warning: This action is permanent. All your data, profile records, '
                    'and login credentials will be completely expunged from our servers. This cannot be undone.',
                style: TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(
                  onPressed: isPurging ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isPurging
                      ? null
                      : () async {
                    setModalState(() => isPurging = true);

                    try {
                      final String deleteUrl = '${widget.baseUrl}/users/${widget.userId}';

                      final response = await http.delete(
                        Uri.parse(deleteUrl),
                        headers: {"Content-Type": "application/json"},
                      );

                      if (response.statusCode == 200) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Your account has been permanently removed.')),
                        );

                      } else {
                        throw Exception('Server rejected data deletion.');
                      }
                    } catch (e) {
                      setModalState(() => isPurging = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deletion failed. Check network connection.')),
                      );
                    }
                  },
                  child: isPurging
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordBottomSheet() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isUpdatingPassword = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade200, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isUpdatingPassword
                          ? null
                          : () async {
                        final String currentPwd = currentPasswordController.text.trim();
                        final String newPwd = newPasswordController.text.trim();

                        if (currentPwd.isEmpty || newPwd.isEmpty) {
                          setModalState(() => errorMessage = '⚠️ Both password fields are required.');
                          return;
                        }

                        setModalState(() {
                          isUpdatingPassword = true;
                          errorMessage = null;
                        });

                        try {
                          var request = http.MultipartRequest('PUT', Uri.parse('${widget.baseUrl}/profile/${widget.userId}'));
                          request.fields['currentPassword'] = currentPwd;
                          request.fields['newPassword'] = newPwd;

                          var streamedResponse = await request.send();
                          var response = await http.Response.fromStream(streamedResponse);

                          if (response.statusCode == 200) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(' Password updated successfully!')),
                            );
                          } else {
                            final Map<String, dynamic> err = json.decode(response.body);
                            setModalState(() {
                              errorMessage = err['message'] ?? 'Failed to update password. Check credentials.';
                              isUpdatingPassword = false;
                            });
                          }
                        } catch (e) {
                          setModalState(() {
                            isUpdatingPassword = false;
                            errorMessage = 'Connection error.';
                          });
                        }
                      },
                      child: isUpdatingPassword
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Update Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingFile = true);

      final String targetUrl = '${widget.baseUrl}/profile/${widget.userId}';
      final request = http.MultipartRequest('PUT', Uri.parse(targetUrl));

      request.files.add(await http.MultipartFile.fromPath('profilePicture', pickedFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String uploadedServerPath = responseData['profilePictureUrl'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_path_${widget.userId}', pickedFile.path);
        await prefs.setString('cached_avatar_${widget.userId}', uploadedServerPath);

        setState(() {
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          _serverAvatarPath = "$uploadedServerPath?v=$timestamp";
          _customImagePath = pickedFile.path;
          _isSavingFile = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo synced successfully!')),
        );
      } else {
        throw Exception("Upload not successful.");
      }
    } catch (e) {
      setState(() => _isSavingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo.')),
      );
    }
  }

  Future<void> _resetToDefaultAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${widget.userId}';
    await prefs.remove(storageKey);
    setState(() => _customImagePath = null);
  }

  void _showMediaSourceSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.blueAccent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.blueAccent),
                title: const Text('Take a New Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.camera);
                },
              ),
              if (_customImagePath != null || _serverAvatarPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _resetToDefaultAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    final String username = _usernameController.text.trim();
    final String location = _locationController.text.trim();
    final String bio = _bioController.text.trim();
    final int? strength = int.tryParse(_strengthController.text.trim());

    if (username.isEmpty || location.isEmpty || bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Required profile fields cannot be empty."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('cached_username_${widget.userId}', username);
    await prefs.setString('cached_location_${widget.userId}', location);
    await prefs.setString('cached_bio_${widget.userId}', bio);

    final Map<String, dynamic> localProfileUpdate = {
      'userId': widget.userId,
      'username': username,
      'email': _emailController.text,
      'location': location,
      'bio': bio,
      'efootballStrength': strength ?? 3000,
      'profilePictureUrl': _serverAvatarPath ?? '',
      'localAvatarPath': _customImagePath,
    };
    await prefs.setString('cached_user_profile_${widget.userId}', jsonEncode(localProfileUpdate));

    try {
      var request = http.MultipartRequest('PUT', Uri.parse('${widget.baseUrl}/profile/${widget.userId}'));
      request.fields['username'] = username;
      request.fields['location'] = location;
      request.fields['bio'] = bio;
      if (strength != null) {
        request.fields['efootballStrength'] = strength.toString();
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        final errData = json.decode(response.body);
        throw Exception(errData['message'] ?? "Failed to save profile state.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 Save failed: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    String fullAvatarUrl = '';
    if (_serverAvatarPath != null && _serverAvatarPath!.isNotEmpty) {
      if (_serverAvatarPath!.startsWith('http')) {
        fullAvatarUrl = _serverAvatarPath!;
      } else {
        final uri = Uri.parse(widget.baseUrl);
        final baseHost = '${uri.scheme}://${uri.host}:${uri.port}';
        fullAvatarUrl = '$baseHost${_serverAvatarPath!.startsWith('/') ? '' : '/'}$_serverAvatarPath';
      }
    }

    return EPlaceScaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("EDIT PROFILE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[900],
                        backgroundImage: _customImagePath != null
                            ? FileImage(File(_customImagePath!)) as ImageProvider
                            : (fullAvatarUrl.isNotEmpty ? NetworkImage(fullAvatarUrl) : null),
                        child: (_customImagePath == null && fullAvatarUrl.isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_isSavingFile)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: _isSavingFile ? null : _showMediaSourceSelectionModal,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PES Username", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text("eFootball Strength", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _strengthController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter your neighborhood or town",
                hintStyle: const TextStyle(color: Colors.grey),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[900],
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _bioController,
                    maxLength: 160,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write a short bio...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[900],
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("${_bioController.text.length}/160", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[950],
                border: Border.all(color: Colors.grey[900]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Verified Email (Protected)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_emailController.text.isEmpty ? 'Loading email...' : _emailController.text, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showChangePasswordBottomSheet,
                    child: const Text(
                      "Change password",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                onPressed: _showDeleteAccountConfirmation,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                label: const Text("Delete Account", style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}