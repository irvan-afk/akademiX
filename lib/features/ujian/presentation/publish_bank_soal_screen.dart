import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/ujian_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/ujian_model.dart';

class PublishBankSoalScreen extends StatefulWidget {
  const PublishBankSoalScreen({super.key});

  @override
  State<PublishBankSoalScreen> createState() => _PublishBankSoalScreenState();
}

class _PublishBankSoalScreenState extends State<PublishBankSoalScreen> {
  // Variabel untuk menyimpan future agar tidak reload setiap rebuild
  Future<List<UjianModel>>? _ujianFuture;
  int? _lastDosenId;

  // Fungsi untuk inisialisasi ujian (DRAFT + PUBLISHED) berdasarkan ID Dosen
  void _initUjian(int dosenId) {
    if (_lastDosenId != dosenId) {
      _lastDosenId = dosenId;
      _ujianFuture = context.read<UjianViewModel>().fetchAllUjianForDosen(
        dosenId,
      );
    }
  }

  // Fungsi untuk refresh manual (misal setelah publish sukses)
  void _refreshData() {
    if (_lastDosenId != null) {
      setState(() {
        _ujianFuture = context.read<UjianViewModel>().fetchAllUjianForDosen(
          _lastDosenId!,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan watch agar widget rebuild otomatis saat AuthViewModel update
    final authVM = context.watch<AuthViewModel>();
    final userData = authVM.userData;

    // 1. Validasi: Jika userData belum dimuat, tampilkan loading full screen
    if (userData == null || userData['id'] == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Memuat data dosen..."),
            ],
          ),
        ),
      );
    }

    // 2. Ambil ID Dosen dan inisialisasi future jika belum ada
    final int dosenId = userData['id'];
    _initUjian(dosenId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          "Kelola Ujian & Publish",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 25),
            const Text(
              "DAFTAR UJIAN",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<List<UjianModel>>(
                future: _ujianFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Terjadi kesalahan: ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Tidak ada draft soal tersedia."),
                    );
                  }

                  final drafts = snapshot.data!;
                  return ListView.builder(
                    itemCount: drafts.length,
                    itemBuilder: (context, index) =>
                        _buildUjianCard(drafts[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helpers Tetap Sama ---

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: "Cari Bank Soal ...",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUjianCard(UjianModel ujian) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ujian.judulUjian,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "TEKNIK INFORMATIKA",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(ujian.statusUjian.toString().split('.').last),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${ujian.durasiMenit} Menit",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              // Show button hanya jika DRAFT, jika PUBLISHED tampilkan badge
              ujian.statusUjian == 'DRAFT'
                  ? ElevatedButton(
                      onPressed: () => _handlePublish(ujian),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Publish",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "✓ Sudah Dipublis",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isPublished = status == 'PUBLISHED' || status.contains('PUBLISHED');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'DRAFT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPublished ? Colors.green[700] : Colors.orange[700],
        ),
      ),
    );
  }

  Future<void> _handlePublish(UjianModel ujian) async {
    final tokens = await context.read<UjianViewModel>().publishUjian(ujian.id);
    if (tokens != null && mounted) {
      _showSuccessPopup(
        ujian.judulUjian,
        tokens['ujian']!,
        tokens['monitoring']!,
      );
    }
  }

  void _showSuccessPopup(String judul, String tokenUjian, String tokenMonitor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 15),
            const Text(
              "Berhasil Dipublish!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Ujian $judul sekarang aktif.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            _buildTokenDisplay("TOKEN UJIAN", tokenUjian),
            const SizedBox(height: 15),
            _buildTokenDisplay("TOKEN MONITORING", tokenMonitor),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  "Salin Kode",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then(
      (_) => _refreshData(),
    ); // Gunakan _refreshData setelah publish sukses
  }

  Widget _buildTokenDisplay(String label, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2962FF)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            code,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2962FF),
              letterSpacing: 5,
            ),
          ),
        ],
      ),
    );
  }
}
