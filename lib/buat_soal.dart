import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatSoalPage extends StatefulWidget {
  final String kodeKuis;
  final String namaKuis;
  final int kuisId;

  const BuatSoalPage({
    Key? key,
    required this.kodeKuis,
    required this.namaKuis,
    required this.kuisId,
  }) : super(key: key);

  @override
  State<BuatSoalPage> createState() => _BuatSoalPageState();
}

class _BuatSoalPageState extends State<BuatSoalPage> {
  final TextEditingController _namaKuisController = TextEditingController();
  final TextEditingController _pertanyaanController = TextEditingController();
  String? _gambarPath;
  bool _jawabanBenar = true;
  List<Map<String, dynamic>> _soalList = [];
  bool _isLoading = false;
  int? _soalYangSedangDiedit;

  @override
  void initState() {
    super.initState();
    _namaKuisController.text = widget.namaKuis;
    _loadSoal();
  }

  Future<void> _loadSoal() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('pertanyaan')
          .select()
          .eq('kode_kuis', widget.kodeKuis)
          .order('created_at', ascending: true);

      setState(() => _soalList = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showError('Gagal memuat soal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNamaKuis() async {
    if (_namaKuisController.text.isEmpty) {
      _showError('Nama kuis tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('kelas')
          .update({'mata_kuliah': _namaKuisController.text})
          .eq('id', widget.kuisId);
      _showSuccess('Nama kuis berhasil diperbarui');
    } catch (e) {
      _showError('Gagal memperbarui nama kuis: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanAtauUpdateSoal() async {
    if (_pertanyaanController.text.isEmpty) {
      _showError('Pertanyaan tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_soalYangSedangDiedit != null) {
        // Update soal yang ada
        await Supabase.instance.client
            .from('pertanyaan')
            .update({
              'pertanyaan': _pertanyaanController.text,
              'gambar_path': _gambarPath,
              'jawaban_benar': _jawabanBenar,
            })
            .eq('id', _soalYangSedangDiedit!);
        _showSuccess('Soal berhasil diperbarui');
      } else {
        // Tambah soal baru
        await Supabase.instance.client.from('pertanyaan').insert({
          'kode_kuis': widget.kodeKuis,
          'pertanyaan': _pertanyaanController.text,
          'gambar_path': _gambarPath,
          'teks_true': 'Benar',
          'teks_false': 'Salah',
          'jawaban_benar': _jawabanBenar,
        });
        _showSuccess('Soal berhasil ditambahkan');
      }

      _resetFormSoal();
      await _loadSoal();
    } catch (e) {
      _showError('Gagal menyimpan soal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editSoal(Map<String, dynamic> soal) {
    setState(() {
      _soalYangSedangDiedit = soal['id'];
      _pertanyaanController.text = soal['pertanyaan'] ?? '';
      _jawabanBenar = soal['jawaban_benar'] ?? true;
      _gambarPath = soal['gambar_path'];
    });
    // Scroll ke form
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _hapusSoal(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: const Text('Apakah Anda yakin ingin menghapus soal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('pertanyaan')
            .delete()
            .eq('id', id);
        _showSuccess('Soal berhasil dihapus');
        await _loadSoal();
      } catch (e) {
        _showError('Gagal menghapus soal: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetFormSoal() {
    setState(() {
      _pertanyaanController.clear();
      _jawabanBenar = true;
      _gambarPath = null;
      _soalYangSedangDiedit = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kuis - ${widget.kodeKuis}'),
        actions: [
          if (_soalYangSedangDiedit != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _resetFormSoal,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _namaKuisController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kuis',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _updateNamaKuis,
                      ),
                    ),
                    onSubmitted: (_) => _updateNamaKuis(),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _soalYangSedangDiedit != null
                                ? 'Edit Soal'
                                : 'Tambah Soal Baru',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pertanyaanController,
                            decoration: const InputDecoration(
                              labelText: 'Pertanyaan',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text('Jawaban Benar:'),
                          Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _jawabanBenar,
                                onChanged: (value) =>
                                    setState(() => _jawabanBenar = value!),
                              ),
                              const Text('Benar'),
                              Radio<bool>(
                                value: false,
                                groupValue: _jawabanBenar,
                                onChanged: (value) =>
                                    setState(() => _jawabanBenar = value!),
                              ),
                              const Text('Salah'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _simpanAtauUpdateSoal,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(_soalYangSedangDiedit != null
                                ? 'Update Soal'
                                : 'Simpan Soal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Daftar Soal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_soalList.isEmpty)
                    const Center(
                      child: Text('Belum ada soal'),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _soalList.length,
                      itemBuilder: (context, index) {
                        final soal = _soalList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  soal['pertanyaan'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Jawaban benar: ${soal['jawaban_benar'] == true ? 'Benar' : 'Salah'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, 
                                          color: Colors.blue),
                                      onPressed: () => _editSoal(soal),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, 
                                          color: Colors.red),
                                      onPressed: () => _hapusSoal(soal['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}