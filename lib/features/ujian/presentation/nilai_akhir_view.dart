import 'package:flutter/material.dart';
import '../../../core/widgets/akademix_card.dart';

class NilaiAkhirView extends StatelessWidget {
  final String namaMhs;
  final String nim;
  final String mataKuliah;
  final double skorPg;
  final double skorEssay;

  const NilaiAkhirView({
    super.key,
    required this.namaMhs,
    required this.nim,
    required this.mataKuliah,
    required this.skorPg,
    required this.skorEssay,
  });

  @override
  Widget build(BuildContext context) {
    final int totalNilai = (skorPg + skorEssay).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Ringkasan Nilai",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "IDENTITAS MAHASISWA",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            AkademixCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  _infoRow("Nama", namaMhs),
                  _infoRow("NIM", nim),
                  _infoRow("Mata Kuliah", mataKuliah),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "RINCIAN SKOR",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            _buildScoreCard("PILIHAN GANDA", skorPg.toInt().toString()),
            const SizedBox(height: 10),
            _buildScoreCard("JAWABAN ESSAY", skorEssay.toInt().toString()),

            const SizedBox(height: 20),

            // KARTU HASIL AKHIR (Sudah dikecilkan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2962FF).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "TOTAL NILAI AKHIR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$totalNilai",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // TOMBOL SIMPAN & SELESAI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Kembali ke halaman Daftar Mahasiswa (pop 2x)
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);

                  // Notifikasi sukses
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✓ Nilai berhasil dikunci"),
                      backgroundColor: Color(0xFF2962FF),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "SIMPAN & SELESAI",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value) {
    return AkademixCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2962FF),
            ),
          ),
        ],
      ),
    );
  }
}
