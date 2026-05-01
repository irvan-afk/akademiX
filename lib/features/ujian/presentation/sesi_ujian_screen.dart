import 'package:flutter/material.dart';

class UjianScreen extends StatelessWidget {
  const UjianScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sesi Ujian"),
        automaticallyImplyLeading: false, // Biar mahasiswa ga iseng pencet back
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              "Halaman Ujian (Placeholder)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Nanti di sini bakal muncul daftar soal dari Hive atau Supabase. Sekarang fokus tes alur pindah halamannya dulu ya!",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}