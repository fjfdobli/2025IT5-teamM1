import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'dashboard.dart';

Future<void> main() async {
  // Ensures Flutter is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with debugging enabled
  await Supabase.initialize(
    url: 'https://zsyxgeadumcnttknsfou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzeXhnZWFkdW1jbnR0a25zZm91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyNDk0NTQsImV4cCI6MjA1OTgyNTQ1NH0.INCpj7774cuvJ6sacPOf7arobGBM1Edw8WEct29GkUI',
    debug: true,
  );

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('User signed in');
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('User signed out');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniVents Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WebLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
