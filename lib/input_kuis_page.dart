import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_application_3/buat_soal.dart';
//import 'package:flutter_application_3/kelas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InputKuisPage extends StatefulWidget {
  const InputKuisPage({Key? key}) : super(key: key);

  @override
  State<InputKuisPage> createState() => _InputKuisPageState();
}

class _InputKuisPageState extends State<InputKuisPage> {
  final List<Map<String, String>> _kuisList = [];

  @override
  void initState() {
    super.initState();
    _loadKuisFromSupabase();
  }

  Future<void> _loadKuisFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('kelas')
          .select()
          .eq('dosen_id', user.id);

      setState(() {
        _kuisList.clear();
        for (var row in response) {
          _kuisList.add({
            'mata_kuliah': row['mata_kuliah'],
            'kode_kuis': row['kode_kuis'],
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat kuis: $e')));
    }
  }

  void _tambahKuis() {
    String mata_kuliah = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Kuis'),
        content: TextField(
          decoration: InputDecoration(hintText: 'Nama Mata Kuliah'),
          onChanged: (value) => mata_kuliah = value,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (mata_kuliah.isNotEmpty) {
                final kode_kuis = _generateKodeKuis();
                final dosen_id = Supabase.instance.client.auth.currentUser!.id;

                try {
                  await Supabase.instance.client.from('kelas').insert({
                    'mata_kuliah': mata_kuliah,
                    'kode_kuis': kode_kuis,
                    'dosen_id': dosen_id,
                  });

                  await _loadKuisFromSupabase();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan kuis: $e')),
                  );
                }
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _generateKodeKuis() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return random.toRadixString(36);
  }

  void _showQRCode(String kode_kuis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code'),
        content: QrImageView(
          data: kode_kuis,
          version: QrVersions.auto,
          size: 200.0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusKuis(String kode_kuis) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus Kuis'),
        content: Text('Yakin ingin menghapus kuis "$kode_kuis"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('kelas')
            .delete()
            .eq('kode_kuis', kode_kuis);

        await _loadKuisFromSupabase();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus kuis: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F3F9),
      appBar: AppBar(
        title: const Text('Input Kuis - Khusus Dosen'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ListView', style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _tambahKuis,
                  icon: Icon(Icons.add),
                  label: Text('Tambah Kuis'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _kuisList.length,
                itemBuilder: (context, index) {
                  final kuis = _kuisList[index];
                  return Card(
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mata kuliah : ${kuis['mata_kuliah']}'),
                          Text('Kode Kuis : ${kuis['kode_kuis']}'),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.qr_code),
                                onPressed: () =>
                                    _showQRCode(kuis['kode_kuis']!),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _hapusKuis(kuis['kode_kuis']!),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuatSoalPage(
                                        kode_kuis: kuis['kode_kuis']!,
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Buat soal'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
