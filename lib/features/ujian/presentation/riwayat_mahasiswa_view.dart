import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/akademix_card.dart';

class RiwayatMahasiswaView extends StatefulWidget {
  final int mahasiswaId;

  const RiwayatMahasiswaView({super.key, required this.mahasiswaId});

  @override
  State<RiwayatMahasiswaView> createState() => _RiwayatMahasiswaViewState();
}

class _RiwayatMahasiswaViewState extends State<RiwayatMahasiswaView> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final response = await supabase
          .from('SESI_PENGERJAAN')
          .select('*, UJIAN(judul_ujian, durasi_menit, tampilkan_nilai), JAWABAN_MAHASISWA(nilai)')
          .eq('mahasiswa_id', widget.mahasiswaId)
          .order('submitted_at', ascending: false);

      setState(() {
        _riwayat = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error load riwayat: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return _riwayat.isEmpty
        ? const Center(
            child: Text(
              "Belum ada riwayat ujian",
              style: TextStyle(color: Colors.grey),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadRiwayat,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _riwayat.length,
              itemBuilder: (context, index) {
                final item = _riwayat[index];
                final ujian = item['UJIAN'] as Map<String, dynamic>?;
                final tampilkanNilai = ujian?['tampilkan_nilai'] == true;

                int totalSkor = 0;
                if (item['JAWABAN_MAHASISWA'] != null) {
                  for (var j in item['JAWABAN_MAHASISWA']) {
                    totalSkor += (j['nilai'] as num?)?.toInt() ?? 0;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AkademixCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                      title: Text(
                        ujian?['judul_ujian'] ?? 'Ujian',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Selesai: ${item['submitted_at'] != null ? DateTime.parse(item['submitted_at']).toLocal().toString().substring(0, 16) : '-'}",
                      ),
                      trailing: tampilkanNilai
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "SKOR",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "$totalSkor",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2962FF),
                                  ),
                                ),
                              ],
                            )
                          : const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
