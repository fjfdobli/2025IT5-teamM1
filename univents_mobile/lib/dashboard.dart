import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  final String? userEmail;
  final String? userRole;

  const HomeScreen({super.key, this.userEmail, this.userRole = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String? _userEmail;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with values passed from login screen
    _userEmail = widget.userEmail;
    _userRole = widget.userRole;

    // If no values were passed, try to load from Supabase
    if (_userEmail == null) {
      _loadUserDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Very simple approach - just check if we have a current user
      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        developer.log('Current user found: ${currentUser.id}');
        developer.log('Email: ${currentUser.email}');

        // Set email and default role to student per exam requirements
        setState(() {
          _userEmail = currentUser.email ?? "Google User";
          _userRole = 'student'; // Default role per exam requirements
          _isLoading = false;
        });
      } else {
        developer.log('No user found - redirecting to login');
        setState(() {
          _isLoading = false;
        });

        // Redirect to login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      developer.log('Error getting user: $e');
      setState(() {
        _userEmail = "Google User";
        _userRole = 'student'; // Always default to student
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVents'),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserDetails,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Welcome card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to UniVents',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Logged in as: $_userEmail',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_userRole != null && _userRole != 'unknown')
                              Text(
                                'Role: $_userRole',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sign-in successful! 🎉',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }
}
