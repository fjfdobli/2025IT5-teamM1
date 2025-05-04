import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  final _supabase = Supabase.instance.client;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _setupMessageListener();

    // Set up auth state listener
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _navigateToAdminDashboard();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupMessageListener() {
    // Listen for messages from JavaScript
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map) {
        if (data['type'] == 'google-sign-in' && data['idToken'] != null) {
          _handleGoogleSignIn(data['idToken'], data['email']);
        } else if (data['type'] == 'google-sign-in-error') {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Sign-in error: ${data['error'] ?? 'Unknown error'}';
          });
        }
      }
    });
  }

  Future<void> _handleGoogleSignIn(String idToken, String email) async {
    try {
      // Sign in with Supabase using the token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user != null) {
        _navigateToAdminDashboard();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to authenticate with Supabase';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _checkSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _navigateToAdminDashboard();
    }
  }

  Future<void> _navigateToAdminDashboard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Check if user exists in accounts table
        final data =
            await _supabase
                .from('accounts')
                .select('email')
                .eq('email', user.email ?? '')
                .maybeSingle();

        if (data == null) {
          // User doesn't exist, create account with admin role
          await _supabase.from('accounts').insert({
            'email': user.email,
            'firstname': user.userMetadata?['given_name'] ?? '',
            'lastname': user.userMetadata?['family_name'] ?? '',
            'role': 'admin',
            'status': 'active',
          });
        }
      }

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error handling session: $e');
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Ensure we have a properly set up redirect URL
      final redirectUrl = Uri.parse(html.window.location.href).origin;
      debugPrint('Using redirect URL: $redirectUrl');
      
      // Try direct Supabase approach
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      
      // Log auth attempt
      debugPrint('OAuth sign-in initiated: ${result.toString()}');

      // The above will redirect, so we normally won't reach this point
      // If we do, try the fallback approach
    } catch (e) {
      debugPrint('OAuth error: ${e.toString()}');
      
      // Try fallback approach with JavaScript
      try {
        // Send a message to JavaScript to trigger the Google auth
        html.window.parent?.postMessage({
          'action': 'triggerSupabaseGoogleAuth',
        }, '*');
      } catch (jsError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error launching sign-in: $jsError';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UniVents Admin')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Administrator Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Google login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Sign in with Google'),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}