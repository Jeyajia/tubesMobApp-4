import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_application_3/buat_soal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InputKuisPage extends StatefulWidget {
  const InputKuisPage({Key? key}) : super(key: key);

  @override
  State<InputKuisPage> createState() => _InputKuisPageState();
}

class _InputKuisPageState extends State<InputKuisPage> {
  final List<Map<String, dynamic>> _kuisList = [];

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
            'id': row['id'],
            'mata_kuliah': row['mata_kuliah'] ?? 'No Name',
            'kode_kuis': row['kode_kuis'] ?? 'NOCODE',
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kuis: $e')),
      );
    }
  }

  void _tambahKuis() {
    String mata_kuliah = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Nama Mata Kuliah',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => mata_kuliah = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editKuisDanSoal(Map<String, dynamic> kuis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuatSoalPage(
          kodeKuis: kuis['kode_kuis'],
          namaKuis: kuis['mata_kuliah'],
          kuisId: kuis['id'],
        ),
      ),
    ).then((_) => _loadKuisFromSupabase());
  }

  String _generateKodeKuis() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return random.toRadixString(36).toUpperCase();
  }

  void _showQRCode(String kodeKuis) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kode Kuis: $kodeKuis',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: kodeKuis,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _saveQrCodeToGallery(kodeKuis),
                    child: const Text('Simpan QR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQrCodeToGallery(String kodeKuis) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qr_$kodeKuis.png';
      final file = File(filePath);
      
      final qrPainter = QrPainter(
        data: kodeKuis,
        version: QrVersions.auto,
      );
      
      final image = await qrPainter.toImageData(300);
      await file.writeAsBytes(image!.buffer.asUint8List());

      await GallerySaver.saveImage(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code berhasil disimpan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan QR: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _hapusKuis(String kodeKuis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus kuis ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('kelas')
            .delete()
            .eq('kode_kuis', kodeKuis);

        await _loadKuisFromSupabase();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kuis: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kuis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _tambahKuis,
          ),
        ],
      ),
      body: _kuisList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/empty.png', height: 150),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada kuis',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _tambahKuis,
                    child: const Text('Tambah Kuis Baru'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _kuisList.length,
              itemBuilder: (context, index) {
                final kuis = _kuisList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                kuis['mata_kuliah'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editKuisDanSoal(kuis),
                            ),
                          ],
                        ),
                        Text(
                          'Kode: ${kuis['kode_kuis']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: Colors.green),
                              onPressed: () => _showQRCode(kuis['kode_kuis']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusKuis(kuis['kode_kuis']),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _editKuisDanSoal(kuis),
                              child: const Text('Kelola Soal', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}