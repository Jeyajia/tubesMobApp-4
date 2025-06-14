import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  String? status; // Dropdown value
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nama = namaController.text.trim();
    final nim = nimController.text.trim();
    final selectedStatus = status;

    if (email.isEmpty || 
        password.isEmpty || 
        selectedStatus == null || 
        nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data')),
      );
      return;
    }

    // Validasi khusus untuk student harus punya NIM
    if (selectedStatus == 'student' && nim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mahasiswa harus memiliki NIM')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Daftar user di Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Gagal membuat akun');
      }

      // 2. Simpan data tambahan di tabel users
      final response = await Supabase.instance.client.from('users').insert({
        'id': authResponse.user!.id,
        'nama': nama,
        'nim': nim.isNotEmpty ? nim : null, // Ubah ini
        'status': selectedStatus,
      }).select();

      if (response.isEmpty) {
        throw Exception('Gagal menyimpan data user');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );
        Navigator.pop(context); // kembali ke login
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Buat akun',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Nama
              TextField(
                controller: namaController,
                decoration: inputDecoration('Nama Lengkap'),
              ),
              const SizedBox(height: 12),

              // NIM
              TextField(
                controller: nimController,
                decoration: inputDecoration('NIM (untuk mahasiswa)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Status (Dropdown)
              DropdownButtonFormField<String>(
                decoration: inputDecoration('Status'),
                value: status,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Mahasiswa')),
                  DropdownMenuItem(value: 'teacher', child: Text('Dosen')),
                ],
                onChanged: (value) {
                  setState(() => status = value);
                },
              ),
              const SizedBox(height: 12),

              // Email
              TextField(
                controller: emailController,
                decoration: inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: inputDecoration('Password'),
              ),
              const SizedBox(height: 24),

              // Tombol Daftar
              ElevatedButton(
                onPressed: isLoading ? null : signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Buat akun',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}