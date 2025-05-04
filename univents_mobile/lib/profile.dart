import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  final String? userEmail;
  final String? userRole;

  const ProfileScreen({super.key, this.userEmail, this.userRole});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic> _userProfile = {};
  File? _profileImage;
  final _imagePicker = ImagePicker();

  Future<void> _changeProfilePicture() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // In a real app, you would upload the image to storage
      // and update the user profile with the image URL
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));

      // Example of how you might upload to Supabase storage:
      // final String userId = _supabase.auth.currentUser!.id;
      // final String filePath = 'profile_images/$userId';
      // final fileBytes = await _profileImage!.readAsBytes();
      // final String fileExt = _profileImage!.path.split('.').last;
      // final response = await _supabase.storage
      //    .from('avatars')
      //    .uploadBinary(filePath, fileBytes, fileOptions: FileOptions(contentType: 'image/$fileExt'));
      // if (response.error == null) {
      //   final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      //   await _supabase.from('accounts').update({'avatar_url': imageUrl}).eq('id', userId);
      // }
    } catch (e) {
      developer.log('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current authenticated user
      final currentUser = _supabase.auth.currentUser;
      final userEmail = currentUser?.email ?? widget.userEmail;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // In a real app, you would fetch profile data from Supabase
      // For now, we'll use data from the current user session
      final userData =
          await _supabase
              .from('accounts')
              .select('*')
              .eq('email', userEmail)
              .single();

      // Get initials from email
      final initials = _getInitialsFromEmail(userEmail);

      // If Supabase query worked, use that data, otherwise use default values
      setState(() {
        _userProfile = {
          'id': userData['id'] ?? '2202201427440',
          'name': userData['name'] ?? userEmail.split('@')[0],
          'email': userEmail,
          'role': userData['role'] ?? widget.userRole ?? 'Student',
          'department': userData['department'] ?? 'Computer Studies',
          'yearLevel': userData['year_level'] ?? '3rd Year',
          'birthdate': userData['birthdate'] ?? 'April 01, 2002',
          'initials': initials,
        };
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading profile: $e');

      // Use the current user session data as fallback
      final currentUser = _supabase.auth.currentUser;
      final userEmail =
          currentUser?.email ?? widget.userEmail ?? 'user@addu.edu.ph';
      final initials = _getInitialsFromEmail(userEmail);

      setState(() {
        _userProfile = {
          'id': '2202201427440',
          'name': _generateNameFromEmail(userEmail),
          'email': userEmail,
          'role': widget.userRole ?? 'Student',
          'department': 'Computer Studies',
          'yearLevel': '3rd Year',
          'birthdate': 'April 01, 2002',
          'initials': initials,
        };
        _isLoading = false;
      });
    }
  }

  String _generateNameFromEmail(String email) {
    // Try to create a name from email
    final username = email.split('@')[0];

    // Convert dots to spaces and capitalize each word
    if (username.contains('.')) {
      return username
          .split('.')
          .map(
            (part) =>
                part.isNotEmpty
                    ? '${part[0].toUpperCase()}${part.substring(1)}'
                    : '',
          )
          .join(' ');
    }

    // Otherwise just capitalize the username
    return '${username[0].toUpperCase()}${username.substring(1)}';
  }

  String _getInitialsFromEmail(String email) {
    if (email.isEmpty) return 'JD';

    // Try to extract name parts from the email
    final username = email.split('@').first;

    // If email contains dots, treat as name separators
    if (username.contains('.')) {
      final parts = username.split('.');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }

    // If email starts with initials
    if (username.length >= 2 &&
        username[0].toUpperCase() != username[0].toLowerCase()) {
      return username.substring(0, 2).toUpperCase();
    }

    // Default to first letter of email
    return username[0].toUpperCase() +
        (username.length > 1
            ? username[1].toUpperCase()
            : username[0].toUpperCase());
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      developer.log('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _editProfile() {
    // Controllers for editing profile information
    final nameController = TextEditingController(text: _userProfile['name']);
    final departmentController = TextEditingController(
      text: _userProfile['department'],
    );
    final yearLevelController = TextEditingController(
      text: _userProfile['yearLevel'],
    );
    final birthdateController = TextEditingController(
      text: _userProfile['birthdate'],
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  TextField(
                    controller: yearLevelController,
                    decoration: const InputDecoration(labelText: 'Year Level'),
                  ),
                  TextField(
                    controller: birthdateController,
                    decoration: const InputDecoration(labelText: 'Birthdate'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Update local state first
                  setState(() {
                    _userProfile['name'] = nameController.text;
                    _userProfile['department'] = departmentController.text;
                    _userProfile['yearLevel'] = yearLevelController.text;
                    _userProfile['birthdate'] = birthdateController.text;
                  });

                  // Try to update in database
                  try {
                    final currentUser = _supabase.auth.currentUser;
                    final userEmail = currentUser?.email ?? widget.userEmail;

                    if (userEmail != null) {
                      await _supabase
                          .from('accounts')
                          .update({
                            'name': nameController.text,
                            'department': departmentController.text,
                            'year_level': yearLevelController.text,
                            'birthdate': birthdateController.text,
                          })
                          .eq('email', userEmail);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    developer.log('Error updating profile: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update profile: $e')),
                      );
                    }
                  }

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/addu_logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'UNIVENTS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Profile header with avatar
                  Container(
                    color: const Color(0xFFF5F5FA),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          // Avatar with initials
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFF3949AB),
                                backgroundImage:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                child:
                                    _profileImage == null
                                        ? Text(
                                          _userProfile['initials'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFF5F5FA),
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add_a_photo,
                                      color: Color(0xFF3949AB),
                                    ),
                                    onPressed: _changeProfilePicture,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name and role
                          Text(
                            _userProfile['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3949AB),
                            ),
                          ),
                          Text(
                            _userProfile['role'] ?? 'Student',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Personal information section
                  Container(
                    color: const Color(0xFFE5E9FF),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3949AB),
                          ),
                        ),
                        TextButton(
                          onPressed: _editProfile,
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Color(0xFF3949AB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Information fields
                  Expanded(
                    child: Container(
                      color: const Color(0xFFE5E9FF),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildInfoField(
                            'Student ID:',
                            _userProfile['id'] ?? '',
                          ),
                          _buildInfoField(
                            'Email:',
                            _userProfile['email'] ?? '',
                          ),
                          _buildInfoField(
                            'Department:',
                            _userProfile['department'] ?? '',
                          ),
                          _buildInfoField(
                            'Year Level:',
                            _userProfile['yearLevel'] ?? '',
                          ),
                          _buildInfoField(
                            'Birthdate:',
                            _userProfile['birthdate'] ?? '',
                          ),

                          const SizedBox(height: 24),

                          // Additional options or sections can be added here
                          _buildActionButton('My Events', Icons.event, () {
                            Navigator.pop(context);
                          }),

                          _buildActionButton('Settings', Icons.settings, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Settings functionality coming soon',
                                ),
                              ),
                            );
                          }),

                          _buildActionButton(
                            'Help & Support',
                            Icons.help_outline,
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Help & Support functionality coming soon',
                                  ),
                                ),
                              );
                            },
                          ),

                          _buildActionButton(
                            'Log Out',
                            Icons.logout,
                            _logout,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Profile tab
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index != 3) {
            // Not profile tab
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF3949AB),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isDestructive ? Colors.red : const Color(0xFF3949AB),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
