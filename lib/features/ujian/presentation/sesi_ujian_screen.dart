import 'dart:async';
// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import '../models/soal_model.dart';
import '../models/answer_tracker_model.dart';
import '../data/jawaban_repository.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import '../view_models/mahasiswa_ujian_view_model.dart';

class UjianScreen extends StatefulWidget {
  final int ujianId;
  const UjianScreen({super.key, required this.ujianId});

  @override
  State<UjianScreen> createState() => _UjianScreenState();
}

class _UjianScreenState extends State<UjianScreen> with WidgetsBindingObserver {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int _violationCount = 0;
  bool _isWarningDialogShowing = false;
  bool _isInternetDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSecurityFeatures();

    // Memulai ujian saat layar dibuka
    Future.microtask(
      () => context.read<MahasiswaUjianViewModel>().startUjian(widget.ujianId),
    );
  }

  Future<void> _initSecurityFeatures() async {
    // 0. Bersihkan Clipboard di awal
    await Clipboard.setData(const ClipboardData(text: ''));

    // 1. Anti-Screenshot
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageWithBlur(); // For iOS

    // 2. Anti-Internet
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
         _showInternetWarningDialog();
      } else {
         if (_isInternetDialogShowing && mounted) {
           Navigator.of(context, rootNavigator: true).pop();
           _isInternetDialogShowing = false;
         }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageWithBlurOff();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Clipboard.setData(const ClipboardData(text: ''));
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleViolation();
    }
  }

  void _handleViolation() {
    _violationCount++;
    if (_violationCount >= 3) {
      context.read<MahasiswaUjianViewModel>().submitUjian();
      if (mounted) {
         Navigator.pushReplacementNamed(context, '/submission-result');
      }
    } else {
      if (!_isWarningDialogShowing && mounted) {
        _isWarningDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text("Peringatan Pelanggaran!"),
              content: Text("Anda terdeteksi keluar dari aplikasi ujian.\n\nPelanggaran ke-$_violationCount dari maksimal 3.\nJika mencapai 3x, ujian akan otomatis disubmit."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _isWarningDialogShowing = false;
                  },
                  child: const Text("Mengerti", style: TextStyle(color: Colors.red)),
                )
              ]
            ),
          )
        );
      }
    }
  }

  void _showInternetWarningDialog() {
    if (!_isInternetDialogShowing && mounted) {
      _isInternetDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text("Koneksi Internet Terdeteksi!"),
            content: const Text("Harap matikan WiFi atau Data Seluler Anda untuk melanjutkan ujian offline ini."),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final results = await Connectivity().checkConnectivity();
                  if (!results.contains(ConnectivityResult.mobile) && !results.contains(ConnectivityResult.wifi)) {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                      _isInternetDialogShowing = false;
                    }
                  }
                },
                child: const Text("Saya Sudah Mematikan Internet."),
              )
            ]
          )
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MahasiswaUjianViewModel>();
    const brightBlue = Color(0xFF2962FF);

    if (vm.isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (vm.daftarSoal.isEmpty)
      return const Scaffold(body: Center(child: Text("Soal tidak ditemukan.")));

    final soal = vm.daftarSoal[vm.currentIndex];
    final isLastSoal = vm.currentIndex == vm.daftarSoal.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, vm, brightBlue),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (vm.currentIndex + 1) / vm.daftarSoal.length,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(brightBlue),
            minHeight: 2,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pertanyaan ${vm.currentIndex + 1} dari ${vm.daftarSoal.length}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (vm.isRagu(soal.id))
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Ragu-ragu",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Teks Soal
                  Text(
                    soal.teksSoal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),

                  soal.tipeSoal.toLowerCase().contains("essai")
                      ? _buildEssayInput(vm, soal)
                      : _buildMultipleChoice(vm, soal, brightBlue),
                ],
              ),
            ),
          ),

          _buildBottomNav(context, vm, brightBlue, isLastSoal),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  vm.timerString,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => _showPetaSoal(context, vm, color),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN PILIHAN GANDA ---
  Widget _buildMultipleChoice(
    MahasiswaUjianViewModel vm,
    dynamic soal,
    Color color,
  ) {
    return Column(
      children: soal.opsiJawaban.entries.map<Widget>((entry) {
        final isSelected = vm.getJawabanTerpilih(soal.id) == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => vm.simpanJawaban(soal.id, entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? color.withOpacity(0.05)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: isSelected ? color : Colors.white,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- KOMPONEN ESSAY ---
  Widget _buildEssayInput(MahasiswaUjianViewModel vm, dynamic soal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            key: ValueKey("essay_${soal.id}"),
            controller:
                TextEditingController(
                    text: vm.getJawabanTerpilih(soal.id) ?? "",
                  )
                  ..selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: (vm.getJawabanTerpilih(soal.id) ?? "").length,
                    ),
                  ),
            maxLines: 8,
            enableInteractiveSelection: false,
            contextMenuBuilder: (context, editableTextState) {
              return const SizedBox.shrink();
            },
            decoration: const InputDecoration(
              hintText: "Ketik jawaban Anda di sini...",
              border: InputBorder.none,
            ),
            onChanged: (val) => vm.simpanJawaban(soal.id, val),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            // PERBAIKAN: Gunakan Expanded agar teks tidak overflow (pindah baris otomatis)
            Expanded(
              child: Text(
                "Jawaban tersimpan secara otomatis setiap kali Anda mengetik.",
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- KOMPONEN NAVIGASI BAWAH ---
  Widget _buildBottomNav(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
    bool isLast,
  ) {
    final soalId = vm.daftarSoal[vm.currentIndex].id;
    final isRagu = vm.isRagu(soalId);

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      child: Row(
        children: [
          // Tombol Kembali
          _circleNavButton(
            Icons.chevron_left,
            Colors.grey.shade200,
            Colors.black54,
            () {
              if (vm.currentIndex > 0) vm.setIndex(vm.currentIndex - 1);
            },
          ),
          const SizedBox(width: 15),

          // Tombol Ragu-ragu
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => vm.toggleRagu(soalId),
                icon: Icon(
                  Icons.flag_rounded,
                  color: isRagu ? Colors.white : Colors.grey,
                  size: 18,
                ),
                label: Text(
                  "Ragu -ragu",
                  style: TextStyle(
                    color: isRagu ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isRagu ? Colors.orange : Colors.white,
                  side: BorderSide(
                    color: isRagu ? Colors.orange : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // Tombol Selanjutnya / Selesai
          isLast
              ? _actionButton(
                  "Selesai",
                  Colors.green,
                  Icons.send_rounded,
                  () => _showKonfirmasiSelesai(context, vm),
                )
              : _circleNavButton(
                  Icons.chevron_right,
                  Colors.black,
                  Colors.white,
                  () {
                    vm.setIndex(vm.currentIndex + 1);
                  },
                ),
        ],
      ),
    );
  }

  Widget _circleNavButton(
    IconData icon,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color bg,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      label: Icon(icon, color: Colors.white, size: 18),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // --- BOTTOM SHEET PETA SOAL  ---
  void _showPetaSoal(
    BuildContext context,
    MahasiswaUjianViewModel vm,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Peta Soal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
            const SizedBox(height: 25),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(vm.daftarSoal.length, (index) {
                final id = vm.daftarSoal[index].id;
                final isAnswered = vm.getJawabanTerpilih(id) != null;
                final isRagu = vm.isRagu(id);
                final isCurrent = index == vm.currentIndex;

                return GestureDetector(
                  onTap: () {
                    vm.setIndex(index);
                    Navigator.pop(context);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCurrent ? color : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isRagu)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            // Indikator Status di Peta Soal
            Row(
              children: [
                _statusIndicator(color, "Dijawab"),
                const SizedBox(width: 15),
                _statusIndicator(Colors.orange, "Ragu-ragu"),
                const SizedBox(width: 15),
                _statusIndicator(Colors.grey.shade300, "Belum Dijawab"),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Kembali ke Soal",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showKonfirmasiSelesai(
    BuildContext context,
    MahasiswaUjianViewModel vm,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Selesai Ujian?"),
        content: const Text(
          "Pastikan semua jawaban sudah terisi. Jawaban yang sudah dikirim tidak dapat diubah kembali.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              await vm.submitUjian();

              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/submission-result');
              }
            },
            child: const Text(
              "Ya, Kirim",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:akademix/features/auth/view_models/auth_view_model.dart';
// import '../models/soal_model.dart';
// import '../models/answer_tracker_model.dart';
// import '../data/jawaban_repository.dart';

// class UjianScreen extends StatefulWidget {
//   final int ujianId;

//   const UjianScreen({super.key, required this.ujianId});

//   @override
//   State<UjianScreen> createState() => _UjianScreenState();
// }

// class _UjianScreenState extends State<UjianScreen> {
//   List<SoalModel> _daftarSoal = [];
//   int _currentIndex = 0;
//   bool _isLoading = true;
//   late AnswerTracker _answerTracker;
//   late Timer _timer;
//   Duration _timeRemaining = const Duration(hours: 2);
//   Map<int, TextEditingController> _essayControllers = {};

//   @override
//   void initState() {
//     super.initState();
//     _answerTracker = AnswerTracker();
//     _fetchSoal();
//     _startTimer();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_timeRemaining.inSeconds > 0) {
//           _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
//         } else {
//           _submitExam();
//         }
//       });
//     });
//   }

//   Future<void> _fetchSoal() async {
//     try {
//       final response = await Supabase.instance.client
//           .from('soal')
//           .select()
//           .eq('ujian_id', widget.ujianId);

//       debugPrint("Response soal: $response");

//       final soalList = <SoalModel>[];

//       for (int i = 0; i < response.length; i++) {
//         try {
//           final item = response[i];
//           debugPrint("Item $i: tipeSoal=${item['tipe_soal']}");

//           final soal = SoalModel.fromJson(item);
//           soalList.add(soal);

//           // Initialize essay controller jika essai
//           if (soal.tipeSoal == "essai") {
//             _essayControllers[soal.id] = TextEditingController();
//           }
//         } catch (e) {
//           debugPrint("Error parsing item $i: $e");
//         }
//       }

//       setState(() {
//         _daftarSoal = soalList;
//         _isLoading = false;
//       });

//       debugPrint("Berhasil load ${soalList.length} soal");

//       // Debug: print tipe soal yang dimuat
//       final tipeSoalCount = <String, int>{};
//       for (var soal in soalList) {
//         tipeSoalCount[soal.tipeSoal] = (tipeSoalCount[soal.tipeSoal] ?? 0) + 1;
//       }
//       debugPrint("📊 Tipe soal: $tipeSoalCount");

//       // Detail per soal
//       for (int i = 0; i < soalList.length; i++) {
//         final s = soalList[i];
//         debugPrint(
//           "  Soal $i: ID=${s.id}, Tipe='${s.tipeSoal}', OpsiEmpty=${s.opsiJawaban.isEmpty}, Teks='${s.teksSoal.substring(0, 30)}...'",
//         );
//       }
//     } catch (e) {
//       debugPrint("Error ambil soal: $e");
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _submitExam() async {
//     _timer.cancel();

//     // Capture essay answers sebelum submit
//     // Loop semua essayControllers dan tambahkan ke answerTracker
//     for (var entry in _essayControllers.entries) {
//       final soalId = entry.key;
//       final controller = entry.value;
//       final answerText = controller.text.trim();

//       if (answerText.isNotEmpty) {
//         _answerTracker.setAnswer(soalId, answerText);
//         final preview = answerText.substring(0, min(30, answerText.length));
//         debugPrint("✏️ Essay answer added: soalId=$soalId, text=$preview");
//       }
//     }

//     // Log all answers before showing dialog
//     debugPrint(
//       "📊 Total answers tracked: ${_answerTracker.selectedAnswers.length}",
//     );
//     for (var entry in _answerTracker.selectedAnswers.entries) {
//       final preview = entry.value.substring(0, min(20, entry.value.length));
//       debugPrint("  - Soal ${entry.key}: $preview");
//     }

//     if (!mounted) return;

//     final answeredCount = _answerTracker.countAnswered();
//     final raguCount = _answerTracker.countRagu();

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Selesai Ujian"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Ringkasan Jawaban:"),
//             const SizedBox(height: 8),
//             Text(
//               "✓ Dijawab: $answeredCount/${_daftarSoal.length}",
//               style: const TextStyle(fontSize: 16),
//             ),
//             Text(
//               "⚠ Ragu-ragu: $raguCount",
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Pastikan koneksi internet aktif sebelum submit.",
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _startTimer();
//             },
//             child: const Text("Kembali"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _uploadAnswers();
//             },
//             child: const Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _uploadAnswers() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       // Get user data dari ViewModel (lebih reliable dari auth session)
//       final authVm = context.read<AuthViewModel>();
//       final userData = authVm.userData;

//       if (userData == null) {
//         throw Exception("Session expired. Silakan login ulang.");
//       }

//       // userData untuk mahasiswa sudah berisi MAHASISWA record dengan field 'id'
//       final mahasiswaId = userData['id'] as int?;
//       if (mahasiswaId == null) {
//         throw Exception("Data mahasiswa tidak lengkap. Hubungi admin.");
//       }

//       debugPrint("Uploading answers for mahasiswa_id: $mahasiswaId");

//       // Submit jawaban ke database
//       final repository = JawabanRepository();
//       await repository.submitAnswers(
//         ujianId: widget.ujianId,
//         mahasiswaId: mahasiswaId,
//         answers: _answerTracker.selectedAnswers,
//       );

//       if (!mounted) return;
//       Navigator.pop(context); // Close loading dialog

//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle, color: Colors.green, size: 28),
//               SizedBox(width: 12),
//               Text("Terima Kasih!"),
//             ],
//           ),
//           content: const Text(
//             "Jawaban anda telah berhasil dikirim. Ujian Anda resmi berakhir.",
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               },
//               child: const Text("Kembali ke Beranda"),
//             ),
//           ],
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       Navigator.pop(context); // Close loading dialog

//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Gagal Upload"),
//           content: Text("Error: $e\n\nPastikan koneksi internet aktif."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Retry"),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   String _formatTime(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     final seconds = duration.inSeconds.remainder(60);
//     return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     for (var controller in _essayControllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_daftarSoal.isEmpty) {
//       return const Scaffold(body: Center(child: Text("Soal tidak ditemukan.")));
//     }

//     final soal = _daftarSoal[_currentIndex];

//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Pertanyaan ${_currentIndex + 1} dari ${_daftarSoal.length}",
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[100],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.timer, size: 18),
//                     const SizedBox(width: 4),
//                     Text(
//                       _formatTime(_timeRemaining),
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Pertanyaan
//                       Text(
//                         soal.teksSoal,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Pilihan Jawaban - Pilihan Ganda
//                       if (soal.tipeSoal == "pilihan_ganda" ||
//                           soal.tipeSoal == "pilihan ganda") ...[
//                         ...soal.opsiJawaban.entries.map((entry) {
//                           final isSelected =
//                               _answerTracker.getAnswer(soal.id) ==
//                               entry.key.toUpperCase();
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             decoration: BoxDecoration(
//                               border: Border.all(
//                                 color: isSelected ? Colors.blue : Colors.grey,
//                                 width: isSelected ? 2 : 1,
//                               ),
//                               borderRadius: BorderRadius.circular(8),
//                               color: isSelected
//                                   ? Colors.blue[50]
//                                   : Colors.transparent,
//                             ),
//                             child: Material(
//                               color: Colors.transparent,
//                               child: InkWell(
//                                 onTap: () {
//                                   setState(() {
//                                     _answerTracker.setAnswer(
//                                       soal.id,
//                                       entry.key.toUpperCase(),
//                                     );
//                                   });
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: Row(
//                                     children: [
//                                       Container(
//                                         width: 40,
//                                         height: 40,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: isSelected
//                                               ? Colors.blue
//                                               : Colors.grey[300],
//                                         ),
//                                         child: Center(
//                                           child: Text(
//                                             entry.key.toUpperCase(),
//                                             style: TextStyle(
//                                               color: isSelected
//                                                   ? Colors.white
//                                                   : Colors.black,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Text(
//                                           entry.value.toString(),
//                                           style: const TextStyle(fontSize: 16),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ],

//                       // Input Essai
//                       if (soal.tipeSoal == "essai" ||
//                           soal.tipeSoal == "essay") ...[
//                         Text(
//                           "Tipe: ${soal.tipeSoal}",
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         TextField(
//                           controller: _essayControllers[soal.id],
//                           maxLines: 8,
//                           onChanged: (value) {
//                             if (value.isNotEmpty) {
//                               _answerTracker.setAnswer(soal.id, value);
//                             }
//                           },
//                           decoration: InputDecoration(
//                             hintText: "Ketik jawaban anda di sini...",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey[100],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Bottom action bar
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(color: Colors.grey[300]!, width: 1),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   // Status soal dan tombol ragu
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Chip(
//                         label: Text(
//                           _answerTracker.getStatus(soal.id),
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         backgroundColor: _answerTracker.isSoalRagu(soal.id)
//                             ? Colors.orange[100]
//                             : _answerTracker.isSoalAnswered(soal.id)
//                             ? Colors.green[100]
//                             : Colors.grey[200],
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           setState(() {
//                             if (_answerTracker.isSoalRagu(soal.id)) {
//                               _answerTracker.unmarkRagu(soal.id);
//                             } else {
//                               _answerTracker.markAsRagu(soal.id);
//                             }
//                           });
//                         },
//                         icon: Icon(
//                           _answerTracker.isSoalRagu(soal.id)
//                               ? Icons.check
//                               : Icons.bookmark_border,
//                         ),
//                         label: const Text("Ragu-ragu"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _answerTracker.isSoalRagu(soal.id)
//                               ? Colors.orange
//                               : Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Navigasi soal dengan nomor
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         ...List.generate(_daftarSoal.length, (index) {
//                           final status = _answerTracker.getStatus(
//                             _daftarSoal[index].id,
//                           );
//                           Color bgColor = Colors.grey[300]!;
//                           if (status == 'Dijawab') {
//                             bgColor = Colors.blue;
//                           } else if (status == 'Ragu-ragu') {
//                             bgColor = Colors.orange;
//                           }

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 4),
//                             child: GestureDetector(
//                               onTap: () {
//                                 setState(() => _currentIndex = index);
//                               },
//                               child: Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   color: _currentIndex == index
//                                       ? Colors.blue[700]
//                                       : bgColor,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     "${index + 1}",
//                                     style: TextStyle(
//                                       color:
//                                           _currentIndex == index ||
//                                               status == 'Dijawab'
//                                           ? Colors.white
//                                           : Colors.black,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         }),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Navigation buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: _currentIndex > 0
//                             ? () => setState(() => _currentIndex--)
//                             : null,
//                         icon: const Icon(Icons.arrow_back),
//                         label: const Text("Sebelumnya"),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: _currentIndex < _daftarSoal.length - 1
//                             ? () => setState(() => _currentIndex++)
//                             : () => _submitExam(),
//                         icon: Icon(
//                           _currentIndex == _daftarSoal.length - 1
//                               ? Icons.check
//                               : Icons.arrow_forward,
//                         ),
//                         label: Text(
//                           _currentIndex == _daftarSoal.length - 1
//                               ? "Selesai"
//                               : "Selanjutnya",
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
