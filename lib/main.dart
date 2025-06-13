import 'package:flutter/material.dart';
import 'package:flutter_application_3/Register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_application_3/login_page.dart';
import 'package:flutter_application_3/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oxsstaxnbavviviqkuvl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94c3N0YXhuYmF2dml2aXFrdXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MjA0MDIsImV4cCI6MjA1ODA5NjQwMn0.09XIN9DOYIPwkQQuasTZqvUCR0OCwwHdAvEoXrCBUtU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuis App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(), // kalau ada halaman home
      },
    );
  }
}
