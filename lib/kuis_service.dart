import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class KuisService {
  // Generate random kode kuis
  static String generateKodeKuis(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  // Create kuis
  static Future<void> createKuis({
    required String mataKuliah,
    required String dosenId,
  }) async {
    final idMk = Random().nextInt(100000); // auto-generate id_mk
    final kodeKuis = generateKodeKuis(6); // auto-generate kode kuis

    final data = {
      'id_mk': idMk,
      'mata_kuliah': mataKuliah,
      'kode_kuis': kodeKuis,
      'dosen_id': dosenId,
    };

    await supabase.from('kelas').insert(data);
  }

  // Read semua kuis berdasarkan dosen
  static Future<List<Map<String, dynamic>>> getKuisByDosen(
    String dosenId,
  ) async {
    final response = await supabase
        .from('kelas')
        .select()
        .eq('dosen_id', dosenId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update kuis (nama matkul / kode kuis)
  static Future<void> updateKuis(int id, Map<String, dynamic> data) async {
    await supabase.from('kelas').update(data).eq('id', id);
  }

  // Delete kuis
  static Future<void> deleteKuis(int id) async {
    await supabase.from('kelas').delete().eq('id', id);
  }

  // Ambil kode kuis untuk ditampilkan (QR generator bisa pakai kode ini)
  static Future<String?> getKodeKuisById(int id) async {
    final response = await supabase
        .from('kelas')
        .select('kode_kuis')
        .eq('id', id)
        .single();
    return response['kode_kuis'];
  }
}

Future<void> hapusKuis(String kode_kuis) async {
  final response = await Supabase.instance.client
      .from('kelas')
      .delete()
      .eq('kode_kuis', kode_kuis);

  if (response == null) throw Exception("Gagal menghapus kuis");
}
