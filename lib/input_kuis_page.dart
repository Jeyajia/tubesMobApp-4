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
            'mata_kuliah': row['mata_kuliah'] ?? 'No Name',
            'kode_kuis': row['kode_kuis'] ?? 'NOCODE',
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quizzes: $e')),
      );
    }
  }

  void _tambahKuis() {
    String mata_kuliah = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quiz'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Course Name'),
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
                    SnackBar(content: Text('Failed to save quiz: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateKodeKuis() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return random.toRadixString(36).toUpperCase();
  }

  void _showQRCode(String kodeKuis) {
    if (kodeKuis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid quiz code')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quiz Code: $kodeKuis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: kodeKuis,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveQrCodeToGallery(kodeKuis),
                    child: const Text('Save QR'),
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
      final qrPainter = QrPainter(
        data: kodeKuis,
        version: QrVersions.auto,
        gapless: true,
      );

      final image = await qrPainter.toImageData(300);
      if (image == null) return;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/qr_$kodeKuis.png';
      final file = File(filePath);
      await file.writeAsBytes(image.buffer.asUint8List());

      final success = await GallerySaver.saveImage(filePath);
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save QR Code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _hapusKuis(String kodeKuis) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure to delete quiz "$kodeKuis"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
          SnackBar(content: Text('Failed to delete quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F9),
      appBar: AppBar(
        title: const Text('Quiz Input - Lecturer Only'),
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
                const Text(
                  'Quiz List',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _tambahKuis,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Quiz'),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                          Text('Course: ${kuis['mata_kuliah']}'),
                          Text('Quiz Code: ${kuis['kode_kuis']}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                onPressed: () => _showQRCode(kuis['kode_kuis']!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
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
                                child: const Text('Create Questions'),
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