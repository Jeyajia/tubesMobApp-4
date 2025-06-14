import 'package:flutter/material.dart';
import 'package:flutter_application_3/input_kuis_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const SoalPage(),
    InputKuisPage(),
    const Center(child: Text("Halaman Input")),
    const Center(child: Text("Pengaturan")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue[800] : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue[800] : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomAppBar(
            color: Colors.white,
            elevation: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.home, 'Home'),
                    _navItem(1, Icons.edit, 'Soal'),
                    _navItem(2, Icons.quiz, 'Kuis'),
                    _navItem(3, Icons.assignment, 'Input'),
                    _navItem(4, Icons.settings, 'Setting'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoalPage extends StatefulWidget {
  const SoalPage({super.key});

  @override
  State<SoalPage> createState() => _SoalPageState();
}

class _SoalPageState extends State<SoalPage> {
  final TextEditingController _kodeKuisController = TextEditingController();
  List<Map<String, dynamic>> _soalList = [];
  bool _isLoading = false;
  bool _showQuestions = false;
  bool _showResult = false;
  Map<int, bool?> _jawabanMap = {};
  String? _userNim;
  String _mataKuliah = '';
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('nim, status')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null || response['status'] != 'student') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hanya mahasiswa yang dapat mengakses kuis')),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (response['nim'] == null || response['nim'].isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NIM belum terdaftar')),
          );
        }
        return;
      }

      setState(() {
        _userNim = response['nim'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadSoal(String kodeKuis) async {
    setState(() {
      _isLoading = true;
      _showQuestions = false;
      _showResult = false;
    });

    try {
      final kuisData = await Supabase.instance.client
          .from('kelas')
          .select('mata_kuliah, kode_kuis')
          .eq('kode_kuis', kodeKuis)
          .maybeSingle();

      if (kuisData == null) {
        throw Exception('Kode kuis tidak ditemukan');
      }

      final response = await Supabase.instance.client
          .from('pertanyaan')
          .select()
          .eq('kode_kuis', kodeKuis)
          .order('created_at', ascending: true);

      if (response.isEmpty) {
        throw Exception('Tidak ada soal untuk kuis ini');
      }

      setState(() {
        _mataKuliah = kuisData['mata_kuliah'] ?? 'Tanpa Judul';
        _soalList = List<Map<String, dynamic>>.from(response);
        _jawabanMap = {for (var soal in _soalList) soal['id']: null};
        _showQuestions = true;
      });

    } catch (e) {
      setState(() {
        _soalList = [];
        _showQuestions = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitJawaban() async {
    if (_userNim == null || _userNim!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIM tidak valid')),
      );
      return;
    }

    if (_jawabanMap.values.any((jawaban) => jawaban == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap jawab semua pertanyaan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final answers = _jawabanMap.entries.map((entry) {
        final soal = _soalList.firstWhere((s) => s['id'] == entry.key);
        return {
          'nim': _userNim!,
          'kode_kuis': _kodeKuisController.text,
          'id_pertanyaan': entry.key,
          'jawaban': entry.value,
          'nilai': (entry.value == soal['jawaban_benar']) ? 10 : 0,
        };
      }).toList();

      final totalScore = answers.fold(0, (sum, answer) => sum + (answer['nilai'] as int));
      
      await Supabase.instance.client
          .from('nilai')
          .upsert(answers);

      setState(() {
        _totalScore = totalScore;
        _showResult = true;
        _showQuestions = false;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan jawaban: ${e.toString().replaceAll('PostgrestException: ', '')}'),
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('Error details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetQuiz() {
    setState(() {
      _showQuestions = false;
      _showResult = false;
      _kodeKuisController.clear();
      _jawabanMap = {};
      _soalList = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 150,
                ),
                child: _showResult
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'Hasil Kuis',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nilai Anda:',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '$_totalScore',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _resetQuiz,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[800],
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Kerjakan Kuis Lain',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : _showQuestions
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _mataKuliah,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kode: ${_kodeKuisController.text}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._soalList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final soal = entry.value;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pertanyaan ${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          soal['pertanyaan'] ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Radio<bool>(
                                              value: true,
                                              groupValue: _jawabanMap[soal['id']],
                                              onChanged: (value) {
                                                setState(() {
                                                  _jawabanMap[soal['id']] = value;
                                                });
                                              },
                                            ),
                                            const Text('Benar'),
                                            const SizedBox(width: 16),
                                            Radio<bool>(
                                              value: false,
                                              groupValue: _jawabanMap[soal['id']],
                                              onChanged: (value) {
                                                setState(() {
                                                  _jawabanMap[soal['id']] = value;
                                                });
                                              },
                                            ),
                                            const Text('Salah'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitJawaban,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Submit Jawaban',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/quiz_illustration.png',
                                height: 180,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Masukkan Kode Kuis',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _kodeKuisController,
                                decoration: InputDecoration(
                                  labelText: 'Kode Kuis',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.code),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_kodeKuisController.text.isNotEmpty) {
                                      _loadSoal(_kodeKuisController.text);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Masukkan kode kuis terlebih dahulu'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mulai Kuis',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  final List<Map<String, String>> anggotaKelompok = const [
    {
      'nama': 'Haykal Azriel Priatama',
      'nim': '1101210297',
      'image': 'assets/images/avatar.png',
    },
    {
      'nama': 'Muhammad Farhan Atilla',
      'nim': '1101213311',
      'image': 'assets/images/avatar.png',
    },
    {
      'nama': 'Alvaro Ahmad Firdaus',
      'nim': '1101210339',
      'image': 'assets/images/avatar.png',
    },
    {
      'nama': 'Jeahan Fitria Goenadiningrat.',
      'nim': '1101213246',
      'image': 'assets/images/avatar.png',
    },
    {
      'nama': 'Rizal Akhlaqul Muslim',
      'nim': '1101213470',
      'image': 'assets/images/avatar.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Anggota Kelompok',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Proyek Aplikasi Kuis Digital',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...anggotaKelompok.map((anggota) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(anggota['image']!),
                    radius: 26,
                  ),
                  title: Text(
                    anggota['nama']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(anggota['nim']!),
                ),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}