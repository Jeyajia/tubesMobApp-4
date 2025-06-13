import 'package:flutter/material.dart';
import 'package:flutter_application_3/input_kuis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const Center(child: Text("Halaman Soal")),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.grey.shade300 : Colors.transparent,
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 2), // lebih kecil dari default
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // dikurangi
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: SizedBox(
        height: 60, // dikurangi dari 72
        child: BottomAppBar(
          color: Colors.white,
          elevation: 8,
          child: SafeArea(
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
      'nim': '1101213311',
      'image': 'assets/images/avatar.png',
    },
    {
      'nama': 'Jehan Fitria G.',
      'nim': '1101213311',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Daftar Anggota Kelompok',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: anggotaKelompok.length,
            itemBuilder: (context, index) {
              final anggota = anggotaKelompok[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(anggota['image']!),
                  radius: 26,
                ),
                title: Text(anggota['nama']!),
                subtitle: Text(anggota['nim']!),
              );
            },
          ),
        ),
      ],
    );
  }
}
