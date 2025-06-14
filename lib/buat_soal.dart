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
        .select('*') // Pastikan menggunakan select('*')
        .eq('kode_kuis', widget.kodeKuis)
        .order('created_at', ascending: true);

    if (response != null && response.isNotEmpty) {
      setState(() {
        _soalList = List<Map<String, dynamic>>.from(response);
        print('Data soal loaded: ${_soalList.length} items'); // Debug
      });
    } else {
      setState(() => _soalList = []);
    }
  } catch (e) {
    print('Error loading soal: $e'); // Debug
    _showError('Gagal memuat soal: ${e.toString()}');
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
      _showError('Gagal memperbarui nama kuis: ${e.toString()}');
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
    final soalData = {
      'kode_kuis': widget.kodeKuis,
      'pertanyaan': _pertanyaanController.text,
      'gambar_path': _gambarPath,
      'jawaban_benar': _jawabanBenar,
    };

    if (_soalYangSedangDiedit != null) {
      await Supabase.instance.client
          .from('pertanyaan')
          .update(soalData)
          .eq('id', _soalYangSedangDiedit!)
          .select(); // Tambahkan .select()
    } else {
      await Supabase.instance.client
          .from('pertanyaan')
          .insert(soalData)
          .select(); // Tambahkan .select()
    }

    // Paksa rebuild widget dengan data terbaru
    await _loadSoal();
    _resetFormSoal();
    
    _showSuccess(_soalYangSedangDiedit != null 
        ? 'Soal berhasil diperbarui' 
        : 'Soal berhasil ditambahkan');

  } catch (e) {
    print('Error saving soal: $e'); // Debug
    _showError('Gagal menyimpan soal: ${e.toString()}');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _editSoal(Map<String, dynamic> soal) {
    setState(() {
      _soalYangSedangDiedit = soal['id'];
      _pertanyaanController.text = soal['pertanyaan'] ?? '';
      _jawabanBenar = soal['jawaban_benar'] ?? true;
      _gambarPath = soal['gambar_path'];
    });
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
        title: const Text('Hapus Soal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus soal ini?'),
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
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('pertanyaan')
            .delete()
            .eq('id', id);
        
        await _loadSoal();
        _showSuccess('Soal berhasil dihapus');
      } catch (e) {
        _showError('Gagal menghapus soal: ${e.toString()}');
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Kuis - ${widget.kodeKuis}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_soalYangSedangDiedit != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Colors.blue),
                        onPressed: _updateNamaKuis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _updateNamaKuis(),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            decoration: InputDecoration(
                              labelText: 'Pertanyaan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Jawaban Benar:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: _jawabanBenar,
                                onChanged: (value) =>
                                    setState(() => _jawabanBenar = value!),
                              ),
                              const Text('Benar'),
                              const SizedBox(width: 16),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _simpanAtauUpdateSoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                _soalYangSedangDiedit != null
                                    ? 'Update Soal'
                                    : 'Simpan Soal',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
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
                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/images/empty_questions.png',
                              height: 150),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada soal',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        soal['pertanyaan'] ?? '',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Jawaban benar: ${soal['jawaban_benar'] == true ? 'Benar' : 'Salah'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
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