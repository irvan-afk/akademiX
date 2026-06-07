import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ujian_model.dart';
import '../services/dosen_ujian_service.dart';
import 'package:flutter/foundation.dart';

class DosenUjianController extends ChangeNotifier {
  DosenUjianController({DosenUjianService? service})
    : _service = service ?? DosenUjianService();

  final DosenUjianService _service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<UjianModel> _allUjianDosen = [];
  List<Map<String, dynamic>> _publishedExams = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _detailPengerjaan = [];
  List<Map<String, dynamic>> _rekapNilai = [];
  Map<String, dynamic> _statsRekap = {'avg': '0', 'max': 0, 'passRate': 0};
  bool _isNilaiPublished = false;

  RealtimeChannel? _monitoringChannel;
  int? _currentMonitoringUjianId; // simpan ujianId aktif untuk unlock
  List<Map<String, dynamic>> _onlineStudents = [];
  List<Map<String, dynamic>> get onlineStudents => _onlineStudents;

  List<Map<String, dynamic>> _pesertaUjian = [];

  List<Map<String, dynamic>> get allMonitoringStudents {
    List<Map<String, dynamic>> result = [];

    for (var peserta in _pesertaUjian) {
      final mahasiswa = peserta['MAHASISWA'] as Map<String, dynamic>? ?? {};
      final nim = mahasiswa['nim'] as String?;

      final onlineData = _onlineStudents.firstWhere(
        (element) => element['nim'] == nim,
        orElse: () => <String, dynamic>{},
      );

      result.add({
        'nama': mahasiswa['nama'] ?? 'Unknown',
        'nim': nim ?? '-',
        'avatar_url': mahasiswa['avatar_url'],
        'status_pengerjaan': peserta['status_pengerjaan'],
        'status_live': onlineData.isNotEmpty ? onlineData['status'] : 'OFFLINE',
        'violations': onlineData.isNotEmpty
            ? (onlineData['violations'] ?? 0)
            : 0,
      });
    }

    for (var online in _onlineStudents) {
      bool exists = result.any((element) => element['nim'] == online['nim']);
      if (!exists) {
        result.add({
          'nama': online['nama'] ?? 'Unknown',
          'nim': online['nim'] ?? '-',
          'avatar_url': online['avatar_url'],
          'status_pengerjaan': 'UNKNOWN',
          'status_live': online['status'] ?? 'ONLINE',
          'violations': online['violations'] ?? 0,
        });
      }
    }

    return result;
  }

  List<UjianModel> get allUjianDosen => _allUjianDosen;
  List<Map<String, dynamic>> get publishedExams => _publishedExams;
  List<Map<String, dynamic>> get submissions => _submissions;
  List<Map<String, dynamic>> get detailPengerjaan => _detailPengerjaan;
  List<Map<String, dynamic>> get rekapNilai => _rekapNilai;
  Map<String, dynamic> get statsRekap => _statsRekap;
  bool get isNilaiPublished => _isNilaiPublished;

  Future<void> fetchUjianForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.fetchUjianForDosen(dosenId);
      _allUjianDosen = response.map((e) => UjianModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch Ujian Dosen: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> publishUjian(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _service.publishUjian(ujianId);
    } catch (e) {
      debugPrint("Error Publish: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPublishedExams() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.fetchPublishedExams();
      final now = DateTime.now().toUtc();
      List<Map<String, dynamic>> updatedExams = [];

      for (var ujian in response) {
        var mutableUjian = Map<String, dynamic>.from(ujian);

        if (mutableUjian['status_ujian'] == 'PUBLISHED' &&
            mutableUjian['waktu_selesai'] != null) {
          final waktuSelesai = DateTime.parse(
            mutableUjian['waktu_selesai'],
          ).toUtc();
          if (now.isAfter(waktuSelesai)) {
            await _service.updateUjianStatus(mutableUjian['id'], 'CLOSED');
            mutableUjian['status_ujian'] = 'CLOSED';
          }
        }
        updatedExams.add(mutableUjian);
      }

      _publishedExams = updatedExams;
    } catch (e) {
      debugPrint("Error Fetch Published: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubmissions(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.fetchSubmissions(ujianId);
      _submissions = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetch Submissions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPesertaUjian(int ujianId) async {
    try {
      final response = await _service.fetchPesertaUjian(ujianId);
      _pesertaUjian = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint("Error Fetch Peserta Ujian: $e");
    }
  }

  Future<void> fetchDetailPengerjaan(int ujianId, int sesiId) async {
    _isLoading = true;
    _detailPengerjaan = [];
    notifyListeners();

    try {
      final soalRes = await _service.fetchSoalForUjian(ujianId);
      final jwbRes = await _service.fetchJawabanForSesi(sesiId);

      _detailPengerjaan = soalRes.map((s) {
        return {
          'soal': s,
          'jawaban': jwbRes.firstWhere(
            (j) => j['soal_id'] == s['id'],
            orElse: () => {},
          ),
        };
      }).toList();
    } catch (e) {
      debugPrint("Error Fetch Detail: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEssayGrade(
    int jawabanId,
    int nilai,
    String feedback,
  ) async {
    try {
      final detailItem = _detailPengerjaan.firstWhere(
        (item) => item['jawaban'] != null && item['jawaban']['id'] == jawabanId,
        orElse: () => {},
      );

      final soal = detailItem['soal'];
      final bobotMaksimal = soal is Map<String, dynamic>
          ? (soal['bobot_nilai'] as num? ?? 0).toInt()
          : 0;

      if (bobotMaksimal > 0 && nilai > bobotMaksimal) {
        debugPrint('Nilai essay melebihi bobot maksimal soal.');
        return false;
      }

      await _service.updateEssayGrade(jawabanId, nilai, feedback);

      for (var item in _detailPengerjaan) {
        if (item['jawaban'] != null && item['jawaban']['id'] == jawabanId) {
          item['jawaban']['nilai'] = nilai;
          item['jawaban']['feedback'] = feedback;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error Update Grade: $e");
      return false;
    }
  }

  @visibleForTesting
  void debugSetMonitoringState({
    required List<Map<String, dynamic>> pesertaUjian,
    required List<Map<String, dynamic>> onlineStudents,
  }) {
    _pesertaUjian = pesertaUjian;
    _onlineStudents = onlineStudents;
    notifyListeners();
  }

  Future<void> fetchRekapNilai(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final ujianRes = await _service.fetchUjianTampilkanNilaiStatus(ujianId);
      if (ujianRes != null) {
        _isNilaiPublished = ujianRes['tampilkan_nilai'] ?? false;
      }

      final response = await _service.fetchRekapNilaiData(ujianId);

      _rekapNilai = response.map((sesi) {
        final listJawaban = sesi['JAWABAN_MAHASISWA'] as List;
        int pgScore = 0;
        int essayScore = 0;

        for (var j in listJawaban) {
          String tipe = (j['soal']['tipe_soal'] ?? "").toString().toLowerCase();
          if (tipe == 'pilihan_ganda') {
            pgScore += (j['nilai'] as num? ?? 0).toInt();
          } else if (tipe == 'essai' || tipe == 'essay') {
            essayScore += (j['nilai'] as num? ?? 0).toInt();
          }
        }

        int total = pgScore + essayScore;
        return {
          'nama': sesi['MAHASISWA']['nama'],
          'nim': sesi['MAHASISWA']['nim'],
          'pg': pgScore,
          'essay': essayScore,
          'total': total,
          'isLulus': total >= 70,
        };
      }).toList();

      if (_rekapNilai.isNotEmpty) {
        double sum = _rekapNilai
            .map((m) => m['total'])
            .reduce((a, b) => a + b)
            .toDouble();
        int max = _rekapNilai
            .map((m) => m['total'])
            .reduce((a, b) => a > b ? a : b);
        int lulus = _rekapNilai.where((m) => m['isLulus']).length;

        _statsRekap = {
          'avg': (sum / _rekapNilai.length).toStringAsFixed(1),
          'max': max,
          'passRate': ((lulus / _rekapNilai.length) * 100).toInt(),
        };
      }
    } catch (e) {
      debugPrint("Error Rekap: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTampilkanNilai(int ujianId, bool value) async {
    try {
      await _service.toggleTampilkanNilai(ujianId, value);
      _isNilaiPublished = value;
      notifyListeners();
    } catch (e) {
      debugPrint("Error Toggle Tampilkan Nilai: $e");
    }
  }

  Future<Map<String, dynamic>?> joinPengawasan(String kodePengawasan) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _service.joinPengawasan(kodePengawasan);
    } catch (e) {
      debugPrint("Error Join Pengawasan: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startMonitoring(int ujianId) async {
    if (_monitoringChannel != null) return;

    _currentMonitoringUjianId = ujianId;
    await fetchPesertaUjian(ujianId);

    _monitoringChannel = _service.getMonitoringChannel(ujianId);

    _monitoringChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'SESI_PENGERJAAN',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'ujian_id',
        value: ujianId,
      ),
      callback: (payload) {
        debugPrint("DB Change detected, refetching peserta...");
        fetchPesertaUjian(ujianId);
      },
    );

    _monitoringChannel!.onPresenceSync((payload) {
      final newState = _monitoringChannel!.presenceState();
      List<Map<String, dynamic>> currentOnline = [];

      for (final state in newState) {
        for (final presence in state.presences) {
          currentOnline.add({
            'nama': presence.payload['nama'],
            'nim': presence.payload['nim'],
            'status': presence.payload['status'],
            'violations': presence.payload['violations'] ?? 0,
          });
        }
      }
      _onlineStudents = currentOnline;
      notifyListeners();
    }).subscribe();
  }

  Future<void> unlockStudent(String nim) async {
    if (_monitoringChannel != null) {
      await _monitoringChannel!.sendBroadcastMessage(
        event: 'unlock',
        payload: {'nim': nim},
      );

      final onlineIndex = _onlineStudents.indexWhere((s) => s['nim'] == nim);
      if (onlineIndex != -1) {
        _onlineStudents[onlineIndex]['status'] = 'AMAN';
      }

      final pesertaIndex = _pesertaUjian.indexWhere((p) {
        final m = p['MAHASISWA'] as Map<String, dynamic>?;
        return m != null && m['nim'] == nim;
      });
      if (pesertaIndex != -1) {
        _pesertaUjian[pesertaIndex]['status_pengerjaan'] = 'ACTIVE';
      }

      notifyListeners();

      try {
        final mahasiswaRes = await _service.getMahasiswaByNim(nim);

        if (mahasiswaRes != null && mahasiswaRes.isNotEmpty) {
          final mahasiswaId = mahasiswaRes['id'];
          // Sertakan ujianId agar hanya sesi ujian yang aktif yang diupdate
          if (_currentMonitoringUjianId != null) {
            await _service.updateSesiPengerjaanStatusToActive(
              mahasiswaId,
              _currentMonitoringUjianId!,
            );
          }

          int index = _pesertaUjian.indexWhere(
            (p) => p['MAHASISWA']['id'] == mahasiswaId,
          );
          if (index != -1) {
            _pesertaUjian[index]['status_pengerjaan'] = 'ACTIVE';
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint("Error unlockStudent DB Update: $e");
      }
      debugPrint("DEBUG: Broadcast unlock sent to $nim");
    }
  }

  void stopMonitoring() {
    _monitoringChannel?.unsubscribe();
    _monitoringChannel = null;
    _currentMonitoringUjianId = null;
    _onlineStudents.clear();
    notifyListeners();
  }

  Future<void> refreshMonitoring(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch data peserta terbaru dari DB (setelah unlock, status sudah ACTIVE di sini)
    await fetchPesertaUjian(ujianId);

    // 2. Reset channel tanpa menghapus _onlineStudents terlebih dahulu,
    //    agar data presence yang sudah ada tidak hilang sebelum sync ulang.
    _monitoringChannel?.unsubscribe();
    _monitoringChannel = null;
    _currentMonitoringUjianId = ujianId;

    // 3. Reconnect channel baru
    startMonitoring(ujianId);

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
