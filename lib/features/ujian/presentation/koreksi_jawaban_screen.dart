import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/jawaban_repository.dart';

// Screen 1: Pilih Ujian
class PilihUjianScreen extends StatefulWidget {
  const PilihUjianScreen({super.key});

  @override
  State<PilihUjianScreen> createState() => _PilihUjianScreenState();
}

class _PilihUjianScreenState extends State<PilihUjianScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ujianList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUjian();
  }

  Future<void> _loadUjian() async {
    try {
      final response = await supabase
          .from('UJIAN')
          .select('id, judul_ujian, status_ujian, waktu_mulai')
          .eq('status_ujian', 'PUBLISHED')
          .order('waktu_mulai', ascending: false);

      setState(() {
        _ujianList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      debugPrint("Loaded ${_ujianList.length} published ujian");
    } catch (e) {
      debugPrint("Error load ujian: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Sesi Ujian & Matakauliah")),
      body: _ujianList.isEmpty
          ? const Center(child: Text("Belum ada ujian"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _ujianList.length,
              itemBuilder: (context, index) {
                final ujian = _ujianList[index];
                final namaUjian = ujian['judul_ujian'] ?? 'N/A';
                final statusUjian = ujian['status_ujian'] ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(namaUjian),
                    subtitle: Text("Status: $statusUjian"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              KoreksiJawabanScreen(ujianId: ujian['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Screen 2: Koreksi Jawaban (List Mahasiswa)
class KoreksiJawabanScreen extends StatefulWidget {
  final int ujianId;

  const KoreksiJawabanScreen({super.key, required this.ujianId});

  @override
  State<KoreksiJawabanScreen> createState() => _KoreksiJawabanScreenState();
}

class _KoreksiJawabanScreenState extends State<KoreksiJawabanScreen> {
  final repository = JawabanRepository();
  List<Map<String, dynamic>> _submissions = [];
  String _ujianName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint("🔍 Loading data for ujianId: ${widget.ujianId}");

      // Get ujian name
      final ujianResp = await repository.supabase
          .from('UJIAN')
          .select('judul_ujian')
          .eq('id', widget.ujianId)
          .single();

      _ujianName = ujianResp['judul_ujian'] ?? 'Ujian';
      debugPrint("✓ Ujian name: $_ujianName");

      // Get submissions
      final submissions = await repository.getSubmissionsForExam(
        widget.ujianId,
      );

      debugPrint(
        "📊 Found ${submissions.length} submissions for ujianId=${widget.ujianId}",
      );
      for (int i = 0; i < submissions.length; i++) {
        final sub = submissions[i];
        debugPrint(
          "  [$i] Sesi ID=${sub['id']}, Mahasiswa=${sub['MAHASISWA']?['nama_mahasiswa']}, Status=${sub['status_pengerjaan']}",
        );
      }

      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error load data: $e");
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Koreksi Essai: $_ujianName")),
      body: _submissions.isEmpty
          ? const Center(child: Text("Belum ada mahasiswa yang submit"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _submissions.length,
              itemBuilder: (context, index) {
                final submission = _submissions[index];
                final mahasiswaName =
                    submission['MAHASISWA']?['nama_mahasiswa'] ?? 'N/A';
                final nim = submission['MAHASISWA']?['nim'] ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(mahasiswaName.substring(0, 1)),
                    ),
                    title: Text(mahasiswaName),
                    subtitle: Text("NIM: $nim"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailKoreksiScreen(
                            sesiPengerjaanId: submission['id'],
                            mahasiswaName: mahasiswaName,
                            ujianId: widget.ujianId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Screen 3: Detail Koreksi (Grade Essai)
// Screen 3: Detail Koreksi (Grade Essai)
class DetailKoreksiScreen extends StatefulWidget {
  final int sesiPengerjaanId;
  final String mahasiswaName;
  final int ujianId;

  const DetailKoreksiScreen({
    super.key,
    required this.sesiPengerjaanId,
    required this.mahasiswaName,
    required this.ujianId,
  });

  @override
  State<DetailKoreksiScreen> createState() => _DetailKoreksiScreenState();
}

class _DetailKoreksiScreenState extends State<DetailKoreksiScreen> {
  final repository = JawabanRepository();
  List<Map<String, dynamic>> _soalDanJawaban = [];
  bool _isLoading = true;
  int _totalNilai = 0;
  Map<int, TextEditingController> _nilaiControllers = {};
  Map<int, TextEditingController> _feedbackControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSoalDanJawaban();
  }

  Future<void> _loadSoalDanJawaban() async {
    try {
      // Get semua soal untuk ujian ini
      final soalResponse = await repository.supabase
          .from('soal')
          .select()
          .eq('ujian_id', widget.ujianId)
          .order('id', ascending: true);

      // Get semua jawaban mahasiswa
      final jawabanResponse = await repository.supabase
          .from('JAWABAN_MAHASISWA')
          .select('soal_id, jawaban_teks, nilai, feedback, id')
          .eq('sesi_pengerjaan_id', widget.sesiPengerjaanId);

      // Merge soal dengan jawaban
      final soalDanJawaban = <Map<String, dynamic>>[];
      int totalNilai = 0;

      for (var soal in soalResponse) {
        final jawaban = jawabanResponse.firstWhere(
          (j) => j['soal_id'] == soal['id'],
          orElse: () => {},
        );

        soalDanJawaban.add({'soal': soal, 'jawaban': jawaban});

        // Initialize controllers
        final jawabanId = jawaban['id'];
        if (jawaban.isNotEmpty && jawabanId != null) {
          _nilaiControllers[jawabanId] = TextEditingController(
            text: (jawaban['nilai'] ?? 0).toString(),
          );
          _feedbackControllers[jawabanId] = TextEditingController(
            text: jawaban['feedback'] ?? '',
          );
          totalNilai += ((jawaban['nilai'] as num?)?.toInt() ?? 0);
        }

        // Calculate total from all answers
      }

      setState(() {
        _soalDanJawaban = soalDanJawaban;
        _totalNilai = totalNilai;
        _isLoading = false;
      });

      debugPrint("Loaded ${soalDanJawaban.length} soal dengan jawaban");
    } catch (e) {
      debugPrint("Error load soal dan jawaban: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNilai(int jawabanId, int soalBobot) async {
    try {
      final nilaiStr = _nilaiControllers[jawabanId]?.text ?? '0';
      final nilai = int.tryParse(nilaiStr) ?? 0;
      final feedback = _feedbackControllers[jawabanId]?.text ?? '';

      if (nilai < 0 || nilai > soalBobot) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nilai harus antara 0 - $soalBobot")),
        );
        return;
      }

      await repository.gradeEssayAnswer(
        jawabanId: jawabanId,
        nilai: nilai,
        feedback: feedback,
      );

      // Recalculate total
      int total = 0;
      for (var controller in _nilaiControllers.values) {
        total += int.tryParse(controller.text) ?? 0;
      }
      setState(() {
        _totalNilai = total;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✓ Nilai tersimpan")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _nilaiControllers.values) {
      controller.dispose();
    }
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Jawaban Essai 1/2")),
      body: Column(
        children: [
          // Score summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                const Text(
                  "IDENTITAS MAHASISWA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nama Siswa",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.mahasiswaName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "NIM",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Text(
                          "2415311011",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Soal list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _soalDanJawaban.length,
              itemBuilder: (context, index) {
                final item = _soalDanJawaban[index];
                final soal = item['soal'] as Map<String, dynamic>;
                final jawaban = item['jawaban'] as Map<String, dynamic>;

                final tipeSoal = soal['tipe_soal'] as String;
                final teksSoal = soal['teks_soal'] as String;
                final jawabanText = jawaban['jawaban_teks'] as String?;
                final jawabanId = jawaban['id'] as int?;
                final bobotNilai = soal['bobot_nilai'] as int? ?? 0;

                // Skip pilihan ganda
                if (tipeSoal.toLowerCase() != 'essai') {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soal Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Soal ${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pertanyaan
                        Text(
                          teksSoal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Jawaban mahasiswa
                        if (jawabanText != null) ...[
                          Text(
                            "Jawaban Mahasiswa:",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(jawabanText),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              "Mahasiswa tidak menjawab soal ini",
                              style: TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Input Skor
                        Text(
                          "INPUT SKOR:",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: jawabanId != null
                                    ? _nilaiControllers[jawabanId]
                                    : null,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "MAKSIMAL: $bobotNilai POIN",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Button Simpan & Lanjut
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: jawabanId != null
                                ? () => _saveNilai(jawabanId, bobotNilai)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Simpan & Lanjut",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Total score button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "HASIL AKHIR KALKULASI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$_totalNilai",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Screen untuk Riwayat Mahasiswa
class RiwayatMahasiswaScreen extends StatefulWidget {
  final int mahasiswaId;

  const RiwayatMahasiswaScreen({super.key, required this.mahasiswaId});

  @override
  State<RiwayatMahasiswaScreen> createState() => _RiwayatMahasiswaScreenState();
}

class _RiwayatMahasiswaScreenState extends State<RiwayatMahasiswaScreen> {
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
          .select('''
            id,
            ujian_id,
            status_pengerjaan,
            submitted_at,
            UJIAN(
              id,
              judul_ujian,
              durasi_menit
            )
          ''')
          .eq('mahasiswa_id', widget.mahasiswaId)
          .order('submitted_at', ascending: false);

      setState(() {
        _riwayat = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      debugPrint("Loaded ${_riwayat.length} sesi ujian untuk mahasiswa");
    } catch (e) {
      debugPrint("Error load riwayat: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: _riwayat.isEmpty
          ? const Center(
              child: Text(
                "Belum ada riwayat ujian",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _riwayat.length,
              itemBuilder: (context, index) {
                final item = _riwayat[index];
                final ujian = item['UJIAN'] as Map<String, dynamic>?;
                final judulUjian = ujian?['judul_ujian'] ?? 'Ujian';
                final submittedAt = item['submitted_at'];
                final statusPengerjaan = item['status_pengerjaan'] ?? 'UNKNOWN';

                final submissionDate = submittedAt != null
                    ? DateTime.parse(submittedAt).toLocal()
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assessment, color: Colors.blue),
                    ),
                    title: Text(
                      judulUjian,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: submissionDate != null
                        ? Text(
                            "Selesai: ${submissionDate.day}/${submissionDate.month}/${submissionDate.year} ${submissionDate.hour.toString().padLeft(2, '0')}:${submissionDate.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 12),
                          )
                        : const Text("Belum submit"),
                    trailing: _buildStatusChip(statusPengerjaan),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        label = 'Selesai';
        break;
      case 'IN_PROGRESS':
        bgColor = Colors.yellow[100]!;
        textColor = Colors.yellow[700]!;
        label = 'Sedang Berlangsung';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
