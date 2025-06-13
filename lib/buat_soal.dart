import 'package:flutter/material.dart';

class BuatSoalPage extends StatelessWidget {
  final String kode_kuis;

  const BuatSoalPage({Key? key, required this.kode_kuis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buat Soal')),
      body: Center(
        child: Text('Kode Kuis: $kode_kuis'), // tes tampilkan kode
      ),
    );
  }
}
