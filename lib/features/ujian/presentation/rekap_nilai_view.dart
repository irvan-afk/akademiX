import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/ujian/presentation/controller/recap_controller.dart';
import '../../../core/widgets/akademix_card.dart';

class RekapNilaiView extends StatefulWidget {
  final int ujianId;
  final String judulUjian;
  const RekapNilaiView({
    super.key,
    required this.ujianId,
    required this.judulUjian,
  });

  @override
  State<RekapNilaiView> createState() => _RekapNilaiViewState();
}

class _RekapNilaiViewState extends State<RekapNilaiView> {
  String _query = "";

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<RecapController>().fetchRekapNilai(widget.ujianId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecapController>();
    final filtered = vm.rekapNilai
        .where((m) => m['nama'].toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hasil Rekap : ${widget.judulUjian}",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text(
                    "Publikasi Nilai ke Mahasiswa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Mahasiswa dapat melihat hasil skor akhirnya",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: vm.isNilaiPublished,
                  onChanged: (val) {
                    vm.toggleTampilkanNilai(widget.ujianId, val);
                  },
                  activeColor: const Color(0xFF2962FF),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 15),
                const Text(
                  "STATISTIK SESI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                _buildStatsCard(vm.statsRekap),
                const SizedBox(height: 30),
                const Text(
                  "HASIL AKHIR MAHASISWA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                ...filtered.map((data) => _buildMahasiswaCard(data)),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: "Cari Nama Mahasiswa...",
        prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
        filled: true,
        fillColor: const Color(0xFFF1F4FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map stats) {
    return AkademixCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("RATA RATA", stats['avg'], const Color(0xFF2962FF)),
          _statItem(
            "TERTINGGI",
            stats['max'].toString(),
            const Color(0xFF2962FF),
          ),
          _statItem("LULUS", "${stats['passRate']}%", Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
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
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMahasiswaCard(Map data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: AkademixCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(
                0xFF2962FF,
              ), // Navy untuk avatar[cite: 4]
              child: Text(
                data['nama'][0],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['nama'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    data['nim'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _scoreBox("PG", data['pg']),
                      const SizedBox(width: 20),
                      _scoreBox("ESSAY", data['essay']),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _badgeStatus(data['isLulus']),
                const SizedBox(height: 15),
                const Text(
                  "TOTAL",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "${data['total']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2962FF), // Navy[cite: 4]
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$score",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _badgeStatus(bool isLulus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLulus ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isLulus ? "LULUS" : "REMEDIAL",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
