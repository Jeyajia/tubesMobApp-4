import 'package:flutter/material.dart';
import 'package:flutter_application_3/Register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_3/login_page.dart';
import 'package:flutter_application_3/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ygbijikysceyvynbuqgz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlnYmlqaWt5c2NleXZ5bmJ1cWd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4NzcyOTYsImV4cCI6MjA2NTQ1MzI5Nn0.PvabZwj7PniYVqrupkR5_sWQ8v5JL_BHYJMi4z_1cXg',
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder(
          future: _checkAuthState(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data == true ? const HomePage() : const LoginPage();
          },
        ),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }

  Future<bool> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    // Verifikasi user ada di tabel users
    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      return userData != null;
    } catch (e) {
      return false;
    }
  }
}