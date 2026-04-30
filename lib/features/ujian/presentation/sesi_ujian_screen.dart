import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import '../models/soal_model.dart';
import '../models/answer_tracker_model.dart';
import '../data/jawaban_repository.dart';

class UjianScreen extends StatefulWidget {
  final int ujianId;

  const UjianScreen({super.key, required this.ujianId});

  @override
  State<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends State<UjianScreen> {
  List<SoalModel> _daftarSoal = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  late AnswerTracker _answerTracker;
  late Timer _timer;
  Duration _timeRemaining = const Duration(hours: 2);
  Map<int, TextEditingController> _essayControllers = {};

  @override
  void initState() {
    super.initState();
    _answerTracker = AnswerTracker();
    _fetchSoal();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining.inSeconds > 0) {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        } else {
          _submitExam();
        }
      });
    });
  }

  Future<void> _fetchSoal() async {
    try {
      final response = await Supabase.instance.client
          .from('soal')
          .select()
          .eq('ujian_id', widget.ujianId);

      debugPrint("Response soal: $response");

      final soalList = <SoalModel>[];

      for (int i = 0; i < response.length; i++) {
        try {
          final item = response[i];
          debugPrint("Item $i: tipeSoal=${item['tipe_soal']}");

          final soal = SoalModel.fromJson(item);
          soalList.add(soal);

          // Initialize essay controller jika essai
          if (soal.tipeSoal == "essai") {
            _essayControllers[soal.id] = TextEditingController();
          }
        } catch (e) {
          debugPrint("Error parsing item $i: $e");
        }
      }

      setState(() {
        _daftarSoal = soalList;
        _isLoading = false;
      });

      debugPrint("Berhasil load ${soalList.length} soal");

      // Debug: print tipe soal yang dimuat
      final tipeSoalCount = <String, int>{};
      for (var soal in soalList) {
        tipeSoalCount[soal.tipeSoal] = (tipeSoalCount[soal.tipeSoal] ?? 0) + 1;
      }
      debugPrint("📊 Tipe soal: $tipeSoalCount");

      // Detail per soal
      for (int i = 0; i < soalList.length; i++) {
        final s = soalList[i];
        debugPrint(
          "  Soal $i: ID=${s.id}, Tipe='${s.tipeSoal}', OpsiEmpty=${s.opsiJawaban.isEmpty}, Teks='${s.teksSoal.substring(0, 30)}...'",
        );
      }
    } catch (e) {
      debugPrint("Error ambil soal: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitExam() async {
    _timer.cancel();

    // Capture essay answers sebelum submit
    // Loop semua essayControllers dan tambahkan ke answerTracker
    for (var entry in _essayControllers.entries) {
      final soalId = entry.key;
      final controller = entry.value;
      final answerText = controller.text.trim();

      if (answerText.isNotEmpty) {
        _answerTracker.setAnswer(soalId, answerText);
        final preview = answerText.substring(0, min(30, answerText.length));
        debugPrint("✏️ Essay answer added: soalId=$soalId, text=$preview");
      }
    }

    // Log all answers before showing dialog
    debugPrint(
      "📊 Total answers tracked: ${_answerTracker.selectedAnswers.length}",
    );
    for (var entry in _answerTracker.selectedAnswers.entries) {
      final preview = entry.value.substring(0, min(20, entry.value.length));
      debugPrint("  - Soal ${entry.key}: $preview");
    }

    if (!mounted) return;

    final answeredCount = _answerTracker.countAnswered();
    final raguCount = _answerTracker.countRagu();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Selesai Ujian"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ringkasan Jawaban:"),
            const SizedBox(height: 8),
            Text(
              "✓ Dijawab: $answeredCount/${_daftarSoal.length}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "⚠ Ragu-ragu: $raguCount",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Pastikan koneksi internet aktif sebelum submit.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text("Kembali"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _uploadAnswers();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAnswers() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get user data dari ViewModel (lebih reliable dari auth session)
      final authVm = context.read<AuthViewModel>();
      final userData = authVm.userData;

      if (userData == null) {
        throw Exception("Session expired. Silakan login ulang.");
      }

      // userData untuk mahasiswa sudah berisi MAHASISWA record dengan field 'id'
      final mahasiswaId = userData['id'] as int?;
      if (mahasiswaId == null) {
        throw Exception("Data mahasiswa tidak lengkap. Hubungi admin.");
      }

      debugPrint("Uploading answers for mahasiswa_id: $mahasiswaId");

      // Submit jawaban ke database
      final repository = JawabanRepository();
      await repository.submitAnswers(
        ujianId: widget.ujianId,
        mahasiswaId: mahasiswaId,
        answers: _answerTracker.selectedAnswers,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text("Terima Kasih!"),
            ],
          ),
          content: const Text(
            "Jawaban anda telah berhasil dikirim. Ujian Anda resmi berakhir.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Kembali ke Beranda"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Gagal Upload"),
          content: Text("Error: $e\n\nPastikan koneksi internet aktif."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_daftarSoal.isEmpty) {
      return const Scaffold(body: Center(child: Text("Soal tidak ditemukan.")));
    }

    final soal = _daftarSoal[_currentIndex];

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pertanyaan ${_currentIndex + 1} dari ${_daftarSoal.length}",
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeRemaining),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pertanyaan
                      Text(
                        soal.teksSoal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pilihan Jawaban - Pilihan Ganda
                      if (soal.tipeSoal == "pilihan_ganda" ||
                          soal.tipeSoal == "pilihan ganda") ...[
                        ...soal.opsiJawaban.entries.map((entry) {
                          final isSelected =
                              _answerTracker.getAnswer(soal.id) ==
                              entry.key.toUpperCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected
                                  ? Colors.blue[50]
                                  : Colors.transparent,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _answerTracker.setAnswer(
                                      soal.id,
                                      entry.key.toUpperCase(),
                                    );
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey[300],
                                        ),
                                        child: Center(
                                          child: Text(
                                            entry.key.toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          entry.value.toString(),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],

                      // Input Essai
                      if (soal.tipeSoal == "essai" ||
                          soal.tipeSoal == "essay") ...[
                        Text(
                          "Tipe: ${soal.tipeSoal}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _essayControllers[soal.id],
                          maxLines: 8,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _answerTracker.setAnswer(soal.id, value);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Ketik jawaban anda di sini...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Status soal dan tombol ragu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          _answerTracker.getStatus(soal.id),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: _answerTracker.isSoalRagu(soal.id)
                            ? Colors.orange[100]
                            : _answerTracker.isSoalAnswered(soal.id)
                            ? Colors.green[100]
                            : Colors.grey[200],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_answerTracker.isSoalRagu(soal.id)) {
                              _answerTracker.unmarkRagu(soal.id);
                            } else {
                              _answerTracker.markAsRagu(soal.id);
                            }
                          });
                        },
                        icon: Icon(
                          _answerTracker.isSoalRagu(soal.id)
                              ? Icons.check
                              : Icons.bookmark_border,
                        ),
                        label: const Text("Ragu-ragu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _answerTracker.isSoalRagu(soal.id)
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Navigasi soal dengan nomor
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...List.generate(_daftarSoal.length, (index) {
                          final status = _answerTracker.getStatus(
                            _daftarSoal[index].id,
                          );
                          Color bgColor = Colors.grey[300]!;
                          if (status == 'Dijawab') {
                            bgColor = Colors.blue;
                          } else if (status == 'Ragu-ragu') {
                            bgColor = Colors.orange;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _currentIndex = index);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? Colors.blue[700]
                                      : bgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      color:
                                          _currentIndex == index ||
                                              status == 'Dijawab'
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _currentIndex > 0
                            ? () => setState(() => _currentIndex--)
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Sebelumnya"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _currentIndex < _daftarSoal.length - 1
                            ? () => setState(() => _currentIndex++)
                            : () => _submitExam(),
                        icon: Icon(
                          _currentIndex == _daftarSoal.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          _currentIndex == _daftarSoal.length - 1
                              ? "Selesai"
                              : "Selanjutnya",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
