// class Kelas {
//   final int id;
//   final int idMk;
//   final String mataKuliah;
//   final String kodeKuis;
//   final String dosenId; // Jika Anda hubungkan ke auth_id

//   Kelas({
//     required this.id,
//     required this.idMk,
//     required this.mataKuliah,
//     required this.kodeKuis,
//     required this.dosenId,
//   });

//   // Konversi dari JSON (Supabase row) ke objek Kelas
//   factory Kelas.fromJson(Map<String, dynamic> json) {
//     return Kelas(
//       id: json['id'],
//       idMk: json['id_mk'],
//       mataKuliah: json['mata_kuliah'],
//       kodeKuis: json['kode_kuis'],
//       dosenId: json['dosen_id'], // Pastikan ini ada di tabel Supabase
//     );
//   }

//   // Konversi ke JSON (jika perlu insert/update)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'id_mk': idMk,
//       'mata_kuliah': mataKuliah,
//       'kode_kuis': kodeKuis,
//       'dosen_id': dosenId,
//     };
//   }
// }
