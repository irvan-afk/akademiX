import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 1. Pastikan import merujuk ke DosenUjianViewModel
import '../view_models/dosen_ujian_view_model.dart';
import 'daftar_mahasiswa_view.dart';
import 'rekap_nilai_view.dart';
import '../../../core/widgets/akademix_card.dart';

class PilihUjianView extends StatefulWidget {
  final bool isForRekap;

  const PilihUjianView({super.key, this.isForRekap = false});

  @override
  State<PilihUjianView> createState() => _PilihUjianViewState();
}

class _PilihUjianViewState extends State<PilihUjianView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<DosenUjianViewModel>().fetchPublishedExams(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianViewModel>();

    final filteredExams = vm.publishedExams.where((ujian) {
      final judul = ujian['judul_ujian'].toString().toLowerCase();
      final isMatchSearch = judul.contains(_searchQuery.toLowerCase());
      
      if (widget.isForRekap) {
        // Rekap Nilai shows CLOSED exams (and PUBLISHED if you want, but user asked for CLOSED in rekap)
        return isMatchSearch && (ujian['status_ujian'] == 'CLOSED' || ujian['status_ujian'] == 'PUBLISHED');
      } else {
        // Koreksi Essai shows only PUBLISHED
        return isMatchSearch && ujian['status_ujian'] == 'PUBLISHED';
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isForRekap ? "Pilih Sesi Rekap" : "Pilih Ujian",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Cari judul ujian...",
                // Menggunakan Navy untuk konsistensi desain AkademiX
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
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
          : filteredExams.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredExams.length,
              itemBuilder: (context, index) {
                final ujian = filteredExams[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AkademixCard(
                    onTap: () {
                      if (widget.isForRekap) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RekapNilaiView(
                              ujianId: ujian['id'],
                              judulUjian: ujian['judul_ujian'],
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DaftarMahasiswaView(
                              ujianId: ujian['id'],
                              judulUjian: ujian['judul_ujian'],
                            ),
                          ),
                        );
                      }
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          color: Color(0xFF2962FF), // Navy
                        ),
                      ),
                      title: Text(
                        ujian['judul_ujian'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        "Status: ${ujian['status_ujian']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
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
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? "Belum ada ujian aktif"
                : "Ujian tidak ditemukan",
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