import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/dosen_ujian_controller.dart';
import 'detail_koreksi_view.dart';
import '../../../core/widgets/akademix_card.dart';

class DaftarMahasiswaView extends StatefulWidget {
  final int ujianId;
  final String judulUjian;

  const DaftarMahasiswaView({
    super.key,
    required this.ujianId,
    required this.judulUjian,
  });

  @override
  State<DaftarMahasiswaView> createState() => _DaftarMahasiswaViewState();
}

class _DaftarMahasiswaViewState extends State<DaftarMahasiswaView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () =>
          context.read<DosenUjianController>().fetchSubmissions(widget.ujianId),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianController>();

    final filteredSubmissions = vm.submissions.where((sub) {
      final mhs = sub['MAHASISWA'] ?? {};
      final nama = mhs['nama']?.toString().toLowerCase() ?? "";
      final nim = mhs['nim']?.toString().toLowerCase() ?? "";
      final query = _searchQuery.toLowerCase();
      return nama.contains(query) || nim.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daftar Mahasiswa",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.judulUjian,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari nama atau NIM...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF2962FF),
                ), // Ganti ke Navy
                filled: true,
                fillColor: const Color(0xFFF1F4FB),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredSubmissions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredSubmissions.length,
              itemBuilder: (context, index) {
                final sub = filteredSubmissions[index];
                final mhs = sub['MAHASISWA'] ?? {};
                final nama = mhs['nama'] ?? "Tanpa Nama";
                final nim = mhs['nim'] ?? "-";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AkademixCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailKoreksiView(
                          sesiId: sub['id'],
                          namaMhs: nama,
                          ujianId: widget.ujianId,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF2962FF,
                        ), // Navy sesuai identitas
                        child: Text(
                          nama[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text("NIM: $nim"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "SUBMITTED",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "Belum ada mahasiswa yang mengumpulkan"
                : "Mahasiswa tidak ditemukan",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}