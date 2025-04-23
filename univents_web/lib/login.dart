import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '140959521015-35ienrnko4hnccue9ejmvum5gd1q0g4t.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // Start the Google sign-in flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get authentication details from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken ?? '',
      );

      if (response.user != null) {
        // Check if user exists in accounts table, if not, create with admin role
        final data =
            await _supabase
                .from('accounts')
                .select('email')
                .eq('email', response.user!.email ?? '')
                .maybeSingle();

        if (data == null) {
          // User doesn't exist in our database, add them with admin role
          await _supabase.from('accounts').insert({
            'email': response.user!.email,
            'firstname': response.user!.userMetadata?['given_name'] ?? '',
            'lastname': response.user!.userMetadata?['family_name'] ?? '',
            'role': 'admin', // Default role for web users is admin
            'status': 'active',
          });
        }

        // Navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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

// Simple admin dashboard with placeholder for CRUD functionality
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;

  final List<Widget> _screens = [const OrganizationsTab(), const EventsTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVents Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const WebLoginScreen(),
                  ),
                );
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation rail for desktop
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Organizations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text('Events'),
              ),
            ],
          ),

          // Content area
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

// Organization tab for CRUD operations
class OrganizationsTab extends StatelessWidget {
  const OrganizationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Organizations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Organization'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Placeholder for organizations list
          const Expanded(
            child: Center(child: Text('Organizations list will appear here')),
          ),
        ],
      ),
    );
  }
}

// Events tab for CRUD operations
class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Events',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Placeholder for events list
          const Expanded(
            child: Center(child: Text('Events list will appear here')),
          ),
        ],
      ),
    );
  }
}
