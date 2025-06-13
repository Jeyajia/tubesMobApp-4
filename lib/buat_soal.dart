import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatSoalPage extends StatefulWidget {
  final String kode_kuis;

  const BuatSoalPage({Key? key, required this.kode_kuis}) : super(key: key);

  @override
  State<BuatSoalPage> createState() => _BuatSoalPageState();
}

class _BuatSoalPageState extends State<BuatSoalPage> {
  final TextEditingController _pertanyaanController = TextEditingController();
  String? _gambarPath;
  bool _jawabanBenar = true;
  List<Map<String, dynamic>> _soalList = [];

  @override
  void initState() {
    super.initState();
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    try {
      final response = await Supabase.instance.client
          .from('pertanyaan')
          .select()
          .eq('kode_kuis', widget.kode_kuis);

      setState(() {
        _soalList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat soal: $e')),
      );
    }
  }

  Future<void> _tambahSoal() async {
    if (_pertanyaanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi pertanyaan')),
      );
      return;
    }

    try {
      // Perubahan utama: Menggunakan .rpc() atau menambahkan header
      await Supabase.instance.client.from('pertanyaan').insert({
        'kode_kuis': widget.kode_kuis,
        'pertanyaan': _pertanyaanController.text,
        'gambar_path': _gambarPath,
        'teks_true': 'True',
        'teks_false': 'False',
        'jawaban_benar': _jawabanBenar,
      }).select();

      // Reset form
      _pertanyaanController.clear();
      setState(() {
        _gambarPath = null;
        _jawabanBenar = true;
      });

      await _loadSoal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan soal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buat Soal - ${widget.kode_kuis}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form tambah soal
            TextField(
              controller: _pertanyaanController,
              decoration: const InputDecoration(
                labelText: 'Pertanyaan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Implementasi upload gambar bisa ditambahkan di sini
              },
              icon: const Icon(Icons.upload),
              label: const Text('Upload Gambar Penyerta'),
            ),
            const SizedBox(height: 16),
            // Opsi Jawaban True/False
            const Text('Pilih Jawaban yang Benar:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('True'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: _jawabanBenar,
                      onChanged: (bool? value) {
                        setState(() {
                          _jawabanBenar = value ?? true;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('False'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: _jawabanBenar,
                      onChanged: (bool? value) {
                        setState(() {
                          _jawabanBenar = value ?? false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _tambahSoal,
              child: const Text('Simpan Soal'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Daftar Soal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // List soal
            Expanded(
              child: ListView.builder(
                itemCount: _soalList.length,
                itemBuilder: (context, index) {
                  final soal = _soalList[index];
                  return Card(
                    child: ListTile(
                      title: Text(soal['pertanyaan'] ?? ''),
                      subtitle: Text(
                        'Jawaban benar: ${soal['jawaban_benar'] == true ? 'True' : 'False'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('pertanyaan')
                              .delete()
                              .eq('id', soal['id']);
                          await _loadSoal();
                        },
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