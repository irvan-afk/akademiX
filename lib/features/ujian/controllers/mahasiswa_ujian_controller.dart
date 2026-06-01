import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../models/ujian_model.dart';
import '../models/soal_model.dart';
import 'package:akademix/core/database/local_db_gateway.dart';
import 'package:akademix/core/database/local_db_service.dart';
import 'package:akademix/core/constants/app_enums.dart';
import '../services/mahasiswa_ujian_service.dart';
import 'package:flutter/foundation.dart';

enum SubmissionStatus { idle, loading, offlineSaved, success }

class MahasiswaUjianController extends ChangeNotifier {
  MahasiswaUjianController({
    MahasiswaUjianService? service,
    LocalDbGateway? localDb,
    this.enableTimer = true,
  }) : _service = service ?? MahasiswaUjianService(),
       _localDb = localDb ?? LocalDbService.instance;

  final MahasiswaUjianService _service;
  final LocalDbGateway _localDb;
  final bool enableTimer;
  RealtimeChannel? _presenceChannel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SubmissionStatus _status = SubmissionStatus.idle;
  SubmissionStatus get status => _status;

  UjianModel? _activeUjian;
  UjianModel? get activeUjian => _activeUjian;

  int? _currentSesiId;
  int? get currentSesiId => _currentSesiId;

  List<SoalModel> _daftarSoal = [];
  List<SoalModel> get daftarSoal => _daftarSoal;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Map<int, String> _jawabanMahasiswa = {};
  Set<int> _raguRaguSet = {};

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _timeRemaining = const Duration(hours: 2);
  String get timerString => _formatDuration(_timeRemaining);

  Future<void> checkOfflineSubmission({int? mahasiswaId}) async {
    final db = await LocalDbService.instance.database;
    final exams = await db.query('ujian_lokal');
    if (exams.isNotEmpty) {
      final exam = exams.first;

      if (mahasiswaId != null) {
        try {
          final remoteStatus = await _service.checkSesiPengerjaanStatus(
            exam['id'] as int,
            mahasiswaId,
          );
          if (remoteStatus == 'SUBMITTED') {
            debugPrint(
              "Ujian sudah disubmit di server. Membersihkan data lokal yang nyangkut...",
            );
            await LocalDbService.instance.clearAllLokalData();
            _activeUjian = null;
            _currentSesiId = null;
            _status = SubmissionStatus.idle;
            notifyListeners();
            return;
          }
        } catch (e) {
          debugPrint(
            "Gagal verifikasi status sinkronisasi ke server (Offline): $e",
          );
        }
      }

      final answers = await db.query('jawaban_lokal');
      if (answers.isNotEmpty) {
        _activeUjian = UjianModel(
          id: exam['id'] as int,
          judulUjian: exam['judul_ujian'] as String,
          pengampuId: 0,
          waktuMulai: exam['waktu_mulai'] != null
              ? DateTime.parse(exam['waktu_mulai'] as String)
              : DateTime.now(),
          waktuSelesai: exam['waktu_selesai'] != null
              ? DateTime.parse(exam['waktu_selesai'] as String)
              : DateTime.now().add(Duration(minutes: exam['durasi'] as int)),
          durasiMenit: exam['durasi'] as int,
          statusUjian: UjianStatus.published,
          pinMulai: exam['pin_mulai'] as String?,
          statusLokal: exam['status_lokal'] as String? ?? 'ACTIVE',
        );
        _currentSesiId = answers.first['sesi_pengerjaan_id'] as int;
        _status = SubmissionStatus.offlineSaved;
        notifyListeners();
      } else {
        _activeUjian = UjianModel(
          id: exam['id'] as int,
          judulUjian: exam['judul_ujian'] as String,
          pengampuId: 0,
          waktuMulai: exam['waktu_mulai'] != null
              ? DateTime.parse(exam['waktu_mulai'] as String)
              : DateTime.now(),
          waktuSelesai: exam['waktu_selesai'] != null
              ? DateTime.parse(exam['waktu_selesai'] as String)
              : DateTime.now().add(Duration(minutes: exam['durasi'] as int)),
          durasiMenit: exam['durasi'] as int,
          statusUjian: UjianStatus.published,
          pinMulai: exam['pin_mulai'] as String?,
          statusLokal: exam['status_lokal'] as String? ?? 'WAITING',
        );
        notifyListeners();
      }

      if (_activeUjian?.statusLokal == 'LOCKED') {
        _isLockedByViolation = true;
        notifyListeners();
      }
    } else {
      _activeUjian = null;
      _currentSesiId = null;
      _status = SubmissionStatus.idle;
      notifyListeners();
    }
  }

  bool _isUnlockedByDosen = false;
  bool get isUnlockedByDosen => _isUnlockedByDosen;

  bool _isLockedByViolation = false;
  bool get isLockedByViolation => _isLockedByViolation;

  Future<void> triggerLock() async {
    if (!_isLockedByViolation) {
      _isLockedByViolation = true;
      if (_activeUjian != null) {
        await _localDb.updateUjianStatusLokal(_activeUjian!.id, 'LOCKED');
      }
      notifyListeners();
    }
  }

  Future<void> resetUnlockStatus() async {
    _isUnlockedByDosen = false;
    _isLockedByViolation = false;
    if (_activeUjian != null) {
      await _localDb.updateUjianStatusLokal(_activeUjian!.id, 'ACTIVE');
    }
    notifyListeners();
  }

  void subscribeToPresence(
    int ujianId,
    String namaMahasiswa,
    String nim,
    String status,
  ) async {
    if (_currentSesiId != null) {
      try {
        await _service.updateSesiPengerjaanStatus(
          _currentSesiId!,
          status == 'LOCKED' ? 'REJECTED' : 'ACTIVE',
        );
      } catch (e) {
        debugPrint("Gagal update remote lock status: $e");
      }
    }

    if (_presenceChannel != null) {
      await _presenceChannel!.track({
        'nama': namaMahasiswa,
        'nim': nim,
        'status': status,
        'violations': _isLockedByViolation ? 3 : 0,
      });
      return;
    }

    _presenceChannel = _service.getPresenceChannel(ujianId);
    _presenceChannel!
        .onPresenceJoin((payload) {
          debugPrint("Presence joined: $payload");
        })
        .onPresenceLeave((payload) {
          debugPrint("Presence left: $payload");
        });

    _presenceChannel!.onBroadcast(
      event: 'unlock',
      callback: (payload) {
        if (payload['nim'] == nim) {
          debugPrint("DEBUG: Received unlock signal from Dosen");
          _isUnlockedByDosen = true;
          notifyListeners();
        }
      },
    );

    _presenceChannel!.subscribe((status_event, [error]) async {
      if (status_event == 'SUBSCRIBED') {
        await _presenceChannel!.track({
          'nama': namaMahasiswa,
          'nim': nim,
          'status': status,
          'violations': _isLockedByViolation ? 3 : 0,
        });
      }
    });
  }

  Future<void> updatePresenceStatus(
    String namaMahasiswa,
    String nim,
    String status,
  ) async {
    if (_presenceChannel != null) {
      await _presenceChannel!.track({
        'nama': namaMahasiswa,
        'nim': nim,
        'status': status,
        'violations': _isLockedByViolation ? 3 : 0,
      });
    }
  }

  void unsubscribePresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
  }

  Future<UjianModel?> joinUjian(String code, int mahasiswaId) async {
    _isLoading = true;
    _status = SubmissionStatus.idle;
    notifyListeners();

    try {
      final resUjian = await _service.getUjianByCode(code);

      if (resUjian != null) {
        _activeUjian = UjianModel.fromJson(resUjian);

        final now = DateTime.now();
        if (now.isBefore(_activeUjian!.waktuMulai)) {
          throw Exception(
            'BELUM_WAKTUNYA (Sekarang: $now, Jadwal: ${_activeUjian!.waktuMulai})',
          );
        }
        if (now.isAfter(_activeUjian!.waktuSelesai)) {
          throw Exception('WAKTU_HABIS');
        }

        final resSesi = await _service.getSesiPengerjaan(
          _activeUjian!.id,
          mahasiswaId,
        );

        if (resSesi != null) {
          if (resSesi['status_pengerjaan'] == 'SUBMITTED') {
            throw Exception('UJIAN_SUDAH_DIKERJAKAN');
          }
          _currentSesiId = resSesi['id'];
        } else {
          final newSesi = await _service.createSesiPengerjaan(
            _activeUjian!.id,
            mahasiswaId,
          );
          _currentSesiId = newSesi['id'];
        }

        await _localDb.saveUjianLokal({
          'id': _activeUjian!.id,
          'judul_ujian': _activeUjian!.judulUjian,
          'durasi_menit': _activeUjian!.durasiMenit,
          'waktu_mulai': _activeUjian!.waktuMulai.toUtc().toIso8601String(),
          'waktu_selesai': _activeUjian!.waktuSelesai.toUtc().toIso8601String(),
          'pin_mulai': _activeUjian!.pinMulai,
          'status_lokal': 'WAITING',
        });

        await downloadSoalLokal(_activeUjian!.id);

        return _activeUjian;
      }
      return null;
    } catch (e) {
      debugPrint("ERROR JOIN: $e");
      if (e.toString().contains('UJIAN_SUDAH_DIKERJAKAN') ||
          e.toString().contains('BELUM_WAKTUNYA') ||
          e.toString().contains('WAKTU_HABIS')) {
        rethrow;
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadSoalLokal(int ujianId) async {
    try {
      var dataLokal = await _localDb.getSoalByUjian(ujianId);
      if (dataLokal.isEmpty) {
        final remoteSoal = await _service.getRemoteSoal(ujianId);
        if (remoteSoal.isNotEmpty) {
          for (var s in remoteSoal) {
            await _localDb.saveSoalLokal(s);
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
      var dataLokal = await _localDb.getSoalByUjian(ujianId);

      _daftarSoal = dataLokal.map((s) => SoalModel.fromJson(s)).toList();

      if (_activeUjian != null) {
        final diff = _activeUjian!.waktuSelesai.difference(DateTime.now());
        if (diff.isNegative) {
          _timeRemaining = Duration.zero;
        } else {
          final maxDuration = Duration(minutes: _activeUjian!.durasiMenit);
          _timeRemaining = diff < maxDuration ? diff : maxDuration;
        }
      } else {
        _timeRemaining = const Duration(hours: 2);
      }

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

  Future<void> simpanJawaban(int soalId, String jawaban) async {
    _jawabanMahasiswa[soalId] = jawaban;
    notifyListeners();

    if (_currentSesiId != null) {
      await _localDb.saveJawabanLokal(soalId, _currentSesiId!, jawaban);
    }
  }

  String? lastErrorMessage;

  Future<void> submitUjian() async {
    lastErrorMessage = null;
    if (_currentSesiId == null) {
      debugPrint("DEBUG ERROR: currentSesiId null!");
      lastErrorMessage = "Session ID tidak ditemukan. Silakan login kembali.";
      return;
    }

    try {
      final listJawabanRaw = await _localDb.getJawabanBySesi(_currentSesiId!);

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

      await _service.submitJawaban(dataToUpload);

      final offlineBox = Hive.box('offline_exams');
      final waktuKey = 'waktu_selesai_${_currentSesiId}';

      if (!offlineBox.containsKey(waktuKey)) {
        offlineBox.put(waktuKey, DateTime.now().toIso8601String());
      }

      final submitTime = offlineBox.get(waktuKey);

      await _service.markSesiAsSubmitted(_currentSesiId!, submitTime);

      offlineBox.delete(waktuKey);
      _status = SubmissionStatus.success;

      _activeUjian = null;
      _currentSesiId = null;
      _daftarSoal.clear();
      _jawabanMahasiswa.clear();
      await _localDb.clearAllLokalData();
    } catch (e) {
      debugPrint("DEBUG ERROR SAAT SUBMIT: $e");
      lastErrorMessage = e.toString();

      if (lastErrorMessage!.contains('23503') &&
          lastErrorMessage!.contains('SESI_PENGERJAAN')) {
        lastErrorMessage =
            "Sesi ujian tidak ditemukan di server. Data lokal direset.";
        await _localDb.clearAllLokalData();
        _activeUjian = null;
        _currentSesiId = null;
        _daftarSoal.clear();
        _jawabanMahasiswa.clear();
        _status = SubmissionStatus.idle;
      } else {
        _status = SubmissionStatus.offlineSaved;

        final offlineBox = Hive.box('offline_exams');
        final waktuKey = 'waktu_selesai_${_currentSesiId}';
        if (!offlineBox.containsKey(waktuKey)) {
          offlineBox.put(waktuKey, DateTime.now().toIso8601String());
        }
      }
    } finally {
      notifyListeners();
    }
  }

  Duration _initialDuration = Duration.zero;

  void _startTimer() {
    if (!enableTimer) {
      return;
    }

    _initialDuration = _timeRemaining;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = _stopwatch.elapsed;
      if (elapsed < _initialDuration) {
        _timeRemaining = _initialDuration - elapsed;
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

  @visibleForTesting
  Future<void> debugForceTimerExpired() async {
    _timeRemaining = Duration.zero;
    _timer?.cancel();
    _stopwatch.stop();
    await submitUjian();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    unsubscribePresence();
    super.dispose();
  }
}
