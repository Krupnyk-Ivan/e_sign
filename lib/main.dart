import 'package:e_sign/pages/login_page.dart';
import 'package:e_sign/pages/test_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://vmbiynqnnbqfroayyqey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtYml5bnFubmJxZnJvYXl5cWV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAzMjYyMjYsImV4cCI6MjA2NTkwMjIyNn0.qpw2uZ8Tdy6kT2lt7S9YNT1sbuCKywnEhlRtJrfIhL4',
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E APPLY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: LoginPage(),
    );
  }
}
