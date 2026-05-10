import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ujian_model.dart';
import '../models/soal_model.dart';
import 'package:akademix/core/database/local_db_service.dart';

// Status untuk mengontrol tampilan layar hasil (Offline vs Sukses)
enum SubmissionStatus { idle, loading, offlineSaved, success }

class MahasiswaUjianViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SubmissionStatus _status = SubmissionStatus.idle;
  SubmissionStatus get status => _status;

  UjianModel? _activeUjian;
  UjianModel? get activeUjian => _activeUjian;

  int? _currentSesiId;
  int? get currentSesiId => _currentSesiId;

  // --- STATE PENGERJAAN ---
  List<SoalModel> _daftarSoal = [];
  List<SoalModel> get daftarSoal => _daftarSoal;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Map<int, String> _jawabanMahasiswa = {};
  Set<int> _raguRaguSet = {};

  // Manajemen Timer
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  final Duration _durasiUjian = const Duration(hours: 2);
  Duration _timeRemaining = const Duration(hours: 2);
  String get timerString => _formatDuration(_timeRemaining);

  // --- PRESENCE MONITORING ---
  void subscribeToPresence(int ujianId, String namaMahasiswa, String nim) {
    if (_presenceChannel != null) return;
    _presenceChannel = _supabase.channel('exam_monitoring_$ujianId');
    _presenceChannel!.onPresenceSync((payload) {
      // Dosen yang butuh list ini, mahasiswa hanya kirim status
    }).subscribe((status, [error]) async {
      if (status == 'SUBSCRIBED') {
        await _presenceChannel!.track({'nama': namaMahasiswa, 'nim': nim, 'status': 'Online'});
      }
    });
  }

  void unsubscribePresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
  }

  // --- LOGIKA JOIN & INISIALISASI SESI ---
  Future<UjianModel?> joinUjian(String code, int mahasiswaId) async {
    _isLoading = true;
    _status = SubmissionStatus.idle;
    notifyListeners();

    try {
      final resUjian = await _supabase
          .from('UJIAN')
          .select()
          .eq('kode_ujian', code.toUpperCase())
          .maybeSingle();

      if (resUjian != null) {
        _activeUjian = UjianModel.fromJson(resUjian);

        final resSesi = await _supabase
            .from('SESI_PENGERJAAN')
            .select('id')
            .eq('ujian_id', _activeUjian!.id)
            .eq('mahasiswa_id', mahasiswaId)
            .maybeSingle();

        if (resSesi != null) {
          _currentSesiId = resSesi['id'];
        } else {
          final newSesi = await _supabase
              .from('SESI_PENGERJAAN')
              .insert({
                'ujian_id': _activeUjian!.id,
                'mahasiswa_id': mahasiswaId,
                'status_pengerjaan': 'ACTIVE',
              })
              .select('id')
              .single();

          _currentSesiId = newSesi['id'];
        }

        // Simpan info Ujian ke Lokal (termasuk PIN)
        await LocalDbService.instance.saveUjianLokal(resUjian);

        // Pre-download soal
        await downloadSoalLokal(_activeUjian!.id);

        return _activeUjian;
      }
      return null;
    } catch (e) {
      debugPrint("ERROR JOIN: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIKA AMBIL SOAL ---
  Future<void> downloadSoalLokal(int ujianId) async {
    try {
      var dataLokal = await LocalDbService.instance.getSoalByUjian(ujianId);
      if (dataLokal.isEmpty) {
        final response = await _supabase
            .from('soal')
            .select()
            .eq('ujian_id', ujianId);

        final remoteSoal = response as List;
        if (remoteSoal.isNotEmpty) {
          for (var s in remoteSoal) {
            await LocalDbService.instance.saveSoalLokal(s);
          }
        }
      }
    } catch (e) {
      debugPrint("DEBUG ERROR DOWNLOAD SOAL: $e");
    }
  }

  Future<void> startUjian(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      var dataLokal = await LocalDbService.instance.getSoalByUjian(ujianId);

      _daftarSoal = dataLokal.map((s) => SoalModel.fromJson(s)).toList();
      _stopwatch.reset();
      _stopwatch.start();
      _startTimer();
    } catch (e) {
      debugPrint("DEBUG ERROR START: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MANAJEMEN JAWABAN ---
  Future<void> simpanJawaban(int soalId, String jawaban) async {
    _jawabanMahasiswa[soalId] = jawaban;
    notifyListeners();

    if (_currentSesiId != null) {
      await LocalDbService.instance.saveJawabanLokal(
        soalId,
        _currentSesiId!,
        jawaban,
      );
    }
  }

  Future<void> submitUjian() async {
    if (_currentSesiId == null) {
      debugPrint("DEBUG ERROR: currentSesiId null!");
      return;
    }

    try {
      final listJawabanRaw = await LocalDbService.instance.getJawabanBySesi(
        _currentSesiId!,
      );

      if (listJawabanRaw.isEmpty) {
        debugPrint("DEBUG: Tidak ada jawaban di lokal.");
        return;
      }

      final Map<int, Map<String, dynamic>> uniqueJawabanMap = {};
      for (var item in listJawabanRaw) {
        uniqueJawabanMap[item['soal_id']] = item;
      }
      final cleanListJawaban = uniqueJawabanMap.values.toList();

      _status = SubmissionStatus.loading;
      notifyListeners();

      final dataToUpload = cleanListJawaban.map((data) {
        final soalId = data['soal_id'];
        final jawabanMhs = data['jawaban_teks'];
        int nilaiOtomatis = 0;

        try {
          final soalOriginal = _daftarSoal.firstWhere((s) => s.id == soalId);

          if (soalOriginal.tipeSoal == 'pilihan_ganda') {
            if (jawabanMhs.toString().trim().toUpperCase() ==
                soalOriginal.kunciJawaban?.toString().trim().toUpperCase()) {
              nilaiOtomatis = soalOriginal.bobotNilai;
            }
          }
        } catch (e) {
          debugPrint(
            "DEBUG WARNING: Soal ID $soalId tidak ditemukan di memory.",
          );
        }

        return {
          'soal_id': soalId,
          'sesi_pengerjaan_id': _currentSesiId,
          'jawaban_teks': jawabanMhs,
          'nilai': nilaiOtomatis,
        };
      }).toList();

      await _supabase
          .from('JAWABAN_MAHASISWA')
          .upsert(dataToUpload, onConflict: 'sesi_pengerjaan_id, soal_id');

      debugPrint("DEBUG: Berhasil kirim ${dataToUpload.length} jawaban.");

      await _supabase
          .from('SESI_PENGERJAAN')
          .update({
            'status_pengerjaan': 'SUBMITTED',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSesiId!);

      _status = SubmissionStatus.success;
      
      // BERSIHKAN STATE UI & SQLITE SETELAH SUKSES MENGIRIM
      _activeUjian = null;
      _currentSesiId = null;
      _daftarSoal.clear();
      _jawabanMahasiswa.clear();
      await LocalDbService.instance.clearAllLokalData();

    } catch (e) {
      debugPrint("DEBUG ERROR SAAT SUBMIT: $e");

      _status = SubmissionStatus.offlineSaved;
    } finally {
      notifyListeners();
    }
  }

  // --- KONTROL UI & HELPER ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = _stopwatch.elapsed;
      if (elapsed < _durasiUjian) {
        _timeRemaining = _durasiUjian - elapsed;
        notifyListeners();
      } else {
        _timeRemaining = Duration.zero;
        notifyListeners();
        _timer?.cancel();
        _stopwatch.stop();
        submitUjian();
      }
    });
  }

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void toggleRagu(int soalId) {
    if (_raguRaguSet.contains(soalId)) {
      _raguRaguSet.remove(soalId);
    } else {
      _raguRaguSet.add(soalId);
    }
    notifyListeners();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  String? getJawabanTerpilih(int soalId) => _jawabanMahasiswa[soalId];
  bool isRagu(int soalId) => _raguRaguSet.contains(soalId);

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    unsubscribePresence();
    super.dispose();
  }
}

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/ujian_model.dart';
// import '../models/soal_model.dart';
// import 'package:akademix/core/database/local_db_service.dart';

// enum SubmissionStatus { idle, loading, offlineSaved, success }

// class MahasiswaUjianViewModel extends ChangeNotifier {
//   final _supabase = Supabase.instance.client;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   UjianModel? _activeUjian;
//   UjianModel? get activeUjian => _activeUjian;

//   // --- STATE PENGERJAAN ---
//   List<SoalModel> _daftarSoal = [];
//   List<SoalModel> get daftarSoal => _daftarSoal;

//   int _currentIndex = 0;
//   int get currentIndex => _currentIndex;

//   // Manajemen Jawaban & Ragu
//   Map<int, String> _jawabanMahasiswa = {};
//   Set<int> _raguRaguSet = {};

//   // Manajemen Timer
//   Timer? _timer;
//   Duration _timeRemaining = const Duration(hours: 2); // Default
//   String get timerString => _formatDuration(_timeRemaining);

//   // --- LOGIKA UTAMA ---

//   // Future<void> startUjian(int ujianId) async {
//   //   _isLoading = true;
//   //   notifyListeners();

//   //   try {
//   //     // 1. Ambil soal dari database lokal (Offline-First)
//   //     final dataLokal = await LocalDbService.instance.getSoalByUjian(ujianId);
//   //     _daftarSoal = dataLokal.map((s) => SoalModel.fromJson(s)).toList();

//   //     // 2. Mulai Timer
//   //     _startTimer();

//   //     debugPrint("Ujian dimulai dengan ${_daftarSoal.length} soal.");
//   //   } catch (e) {
//   //     debugPrint("Error Start Ujian: $e");
//   //   } finally {
//   //     _isLoading = false;
//   //     notifyListeners();
//   //   }
//   // }

//   Future<void> startUjian(int ujianId) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       // 1. Cek dulu di Lokal (SQLite)
//       var dataLokal = await LocalDbService.instance.getSoalByUjian(ujianId);

//       // 2. JIKA KOSONG, Ambil dari Supabase (Cloud)
//       if (dataLokal.isEmpty) {
//         print("DEBUG: Lokal kosong, mengambil soal dari Supabase...");
//         final response = await _supabase
//             .from('soal')
//             .select()
//             .eq('ujian_id', ujianId);

//         final remoteSoal = response as List;

//         if (remoteSoal.isNotEmpty) {
//           // 3. Simpan hasil dari Supabase ke Lokal agar besok bisa Offline
//           for (var s in remoteSoal) {
//             await LocalDbService.instance.saveSoalLokal(s);
//           }
//           // Ambil ulang dari lokal setelah disimpan
//           dataLokal = await LocalDbService.instance.getSoalByUjian(ujianId);
//         }
//       }

//       _daftarSoal = dataLokal.map((s) => SoalModel.fromJson(s)).toList();
//       _startTimer();

//       print("DEBUG: Berhasil memuat ${_daftarSoal.length} soal.");
//     } catch (e) {
//       print("DEBUG ERROR: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void _startTimer() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_timeRemaining.inSeconds > 0) {
//         _timeRemaining -= const Duration(seconds: 1);
//         notifyListeners();
//       } else {
//         _timer?.cancel();
//         // Tambahkan fungsi auto-submit di sini jika waktu habis
//       }
//     });
//   }

//   void setIndex(int index) {
//     _currentIndex = index;
//     notifyListeners();
//   }

//   void toggleRagu(int soalId) {
//     if (_raguRaguSet.contains(soalId)) {
//       _raguRaguSet.remove(soalId);
//     } else {
//       _raguRaguSet.add(soalId);
//     }
//     notifyListeners();
//   }

//   Future<void> simpanJawaban(int soalId, String jawaban) async {
//     _jawabanMahasiswa[soalId] = jawaban;
//     notifyListeners();
//     // Simpan ke SQLite secara background
//     await LocalDbService.instance.saveJawabanLokal(soalId, 1, jawaban);
//   }

//   // --- HELPER ---
//   String _formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
//   }

//   String? getJawabanTerpilih(int soalId) => _jawabanMahasiswa[soalId];
//   bool isRagu(int soalId) => _raguRaguSet.contains(soalId);

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   // --- LOGIKA JOIN (SUPABASE) ---
//   Future<UjianModel?> joinUjian(String code) async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       final res = await _supabase
//           .from('UJIAN')
//           .select()
//           .eq('kode_ujian', code.toUpperCase())
//           .maybeSingle();
//       if (res != null) {
//         _activeUjian = UjianModel.fromJson(res);
//         return _activeUjian;
//       }
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> submitUjian() async {
//     try {
//       // 1. Ambil data dari SQLite (gunakan angka 1 sesuai simpanJawaban kamu)
//       final listJawaban = await LocalDbService.instance.getJawabanBySesi(1);

//       for (var data in listJawaban) {
//         // 2. Kirim ke JAWABAN_MAHASISWA sesuai kolom di screenshot
//         await _supabase.from('JAWABAN_MAHASISWA').insert({
//           'soal_id': data['soal_id'],
//           'sesi_pengerjaan_id':
//               1, // SESUAIKAN: Gunakan ID sesi pengerjaan yang aktif
//           'jawaban_teks': data['jawaban_teks'],
//           // 'mahasiswa_id' dihapus karena tidak ada di tabel ini
//         });
//       }

//       print("DEBUG: Berhasil kirim semua ke JAWABAN_MAHASISWA");
//     } catch (e) {
//       print("DEBUG ERROR: $e");
//     }
//   }
// }
