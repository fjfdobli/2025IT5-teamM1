import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zsyxgeadumcnttknsfou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzeXhnZWFkdW1jbnR0a25zZm91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQyNDk0NTQsImV4cCI6MjA1OTgyNTQ1NH0.INCpj7774cuvJ6sacPOf7arobGBM1Edw8WEct29GkUI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniVents Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WebLoginScreen(),
    );
  }
}
