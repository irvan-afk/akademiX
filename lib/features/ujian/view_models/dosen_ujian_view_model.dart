import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ujian_model.dart';

class DosenUjianViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- STATE DOSEN ---
  List<UjianModel> _allUjianDosen = [];
  List<Map<String, dynamic>> _publishedExams = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _detailPengerjaan = [];
  List<Map<String, dynamic>> _rekapNilai = [];
  Map<String, dynamic> _statsRekap = {'avg': '0', 'max': 0, 'passRate': 0};
  bool _isNilaiPublished = false;

  // --- STATE MONITORING ---
  RealtimeChannel? _monitoringChannel;
  List<Map<String, dynamic>> _onlineStudents = [];
  List<Map<String, dynamic>> get onlineStudents => _onlineStudents;

  List<Map<String, dynamic>> _pesertaUjian = [];
  
  // Menggabungkan data SESI_PENGERJAAN (peserta yang sudah gabung) dengan Presence (Live Status)
  List<Map<String, dynamic>> get allMonitoringStudents {
    List<Map<String, dynamic>> result = [];
    
    for (var peserta in _pesertaUjian) {
      final mahasiswa = peserta['MAHASISWA'] as Map<String, dynamic>? ?? {};
      final nim = mahasiswa['nim'] as String?;
      
      // Cari apakah mahasiswa ini ada di Presence (sedang online/terkunci)
      final onlineData = _onlineStudents.firstWhere(
        (element) => element['nim'] == nim,
        orElse: () => <String, dynamic>{},
      );

      result.add({
        'nama': mahasiswa['nama'] ?? 'Unknown',
        'nim': nim ?? '-',
        'status_pengerjaan': peserta['status_pengerjaan'], // ONGOING, SUBMITTED
        'status_live': onlineData.isNotEmpty ? onlineData['status'] : 'OFFLINE', // LOCKED, WAITING, OFFLINE
        'violations': onlineData.isNotEmpty ? (onlineData['violations'] ?? 0) : 0,
      });
    }

    // Jika ada mahasiswa di Presence yang entah kenapa tidak ada di SESI_PENGERJAAN, tampilkan juga
    for (var online in _onlineStudents) {
      bool exists = result.any((element) => element['nim'] == online['nim']);
      if (!exists) {
        result.add({
          'nama': online['nama'] ?? 'Unknown',
          'nim': online['nim'] ?? '-',
          'status_pengerjaan': 'UNKNOWN',
          'status_live': online['status'] ?? 'ONLINE',
          'violations': online['violations'] ?? 0,
        });
      }
    }

    return result;
  }

  // --- GETTERS ---
  List<UjianModel> get allUjianDosen => _allUjianDosen;
  List<Map<String, dynamic>> get publishedExams => _publishedExams;
  List<Map<String, dynamic>> get submissions => _submissions;
  List<Map<String, dynamic>> get detailPengerjaan => _detailPengerjaan;
  List<Map<String, dynamic>> get rekapNilai => _rekapNilai;
  Map<String, dynamic> get statsRekap => _statsRekap;
  bool get isNilaiPublished => _isNilaiPublished;

  // --- FUNGSI UTILITAS ---
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  // --- LOGIKA MANAJEMEN UJIAN ---

  Future<void> fetchUjianForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('PENGAMPU.dosen_id', dosenId)
          .order('id', ascending: false);

      _allUjianDosen = (response as List)
          .map((e) => UjianModel.fromJson(e))
          .toList();
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

    final tokenUjian = _generateRandomCode();
    final tokenMonitor = _generateRandomCode();
    final pinMulai = (1000 + Random().nextInt(9000)).toString(); // 4 digit PIN

    try {
      await _supabase
          .from('UJIAN')
          .update({
            'kode_ujian': tokenUjian,
            'kode_pengawasan': tokenMonitor,
            'pin_mulai': pinMulai,
            'status_ujian': 'PUBLISHED',
          })
          .eq('id', ujianId);

      return {'ujian': tokenUjian, 'monitoring': tokenMonitor, 'pin': pinMulai};
    } catch (e) {
      debugPrint("Error Publish: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LOGIKA KOREKSI & SUBMISSION ---
  Future<void> fetchPublishedExams() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('id, judul_ujian, status_ujian, waktu_mulai')
          .eq('status_ujian', 'PUBLISHED')
          .order('waktu_mulai', ascending: false);
      _publishedExams = List<Map<String, dynamic>>.from(response);
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
      final response = await _supabase
          .from('SESI_PENGERJAAN')
          .select(
            'id, ujian_id, mahasiswa_id, status_pengerjaan, MAHASISWA(id, nama, nim)',
          )
          .eq('ujian_id', ujianId)
          .eq('status_pengerjaan', 'SUBMITTED');
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
      final response = await _supabase
          .from('SESI_PENGERJAAN')
          .select(
            'id, ujian_id, mahasiswa_id, status_pengerjaan, MAHASISWA(id, nama, nim)',
          )
          .eq('ujian_id', ujianId);
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
      final soalRes = await _supabase
          .from('soal')
          .select()
          .eq('ujian_id', ujianId)
          .order('id');
      final jwbRes = await _supabase
          .from('JAWABAN_MAHASISWA')
          .select()
          .eq('sesi_pengerjaan_id', sesiId);

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

  // Input nilai untuk jawaban essay
  Future<bool> updateEssayGrade(
    int jawabanId,
    int nilai,
    String feedback,
  ) async {
    try {
      await _supabase
          .from('JAWABAN_MAHASISWA')
          .update({'nilai': nilai, 'feedback': feedback})
          .eq('id', jawabanId);

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

  // --- LOGIKA REKAPITULASI ---

  Future<void> fetchRekapNilai(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ambil status tampilkan_nilai dari UJIAN
      final ujianRes = await _supabase
          .from('UJIAN')
          .select('tampilkan_nilai')
          .eq('id', ujianId)
          .maybeSingle();
      if (ujianRes != null) {
        _isNilaiPublished = ujianRes['tampilkan_nilai'] ?? false;
      }

      final response = await _supabase
          .from('SESI_PENGERJAAN')
          .select(
            'id, MAHASISWA(nama, nim), JAWABAN_MAHASISWA(nilai, soal(tipe_soal))',
          )
          .eq('ujian_id', ujianId)
          .eq('status_pengerjaan', 'SUBMITTED');

      _rekapNilai = (response as List).map((sesi) {
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
      await _supabase
          .from('UJIAN')
          .update({'tampilkan_nilai': value})
          .eq('id', ujianId);
      _isNilaiPublished = value;
      notifyListeners();
    } catch (e) {
      debugPrint("Error Toggle Tampilkan Nilai: $e");
    }
  }

  // --- LOGIKA MONITORING REALTIME ---
  Future<Map<String, dynamic>?> joinPengawasan(String kodePengawasan) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('id, judul_ujian, pin_mulai')
          .eq('kode_pengawasan', kodePengawasan)
          .maybeSingle();
      
      return response;
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
    
    // Ambil data awal seluruh peserta yang sudah mendaftar/mengunduh
    await fetchPesertaUjian(ujianId);

    _monitoringChannel = _supabase.channel('exam_monitoring_$ujianId');
    _monitoringChannel!.onPresenceSync((payload) {
      final newState = _monitoringChannel!.presenceState();
      List<Map<String, dynamic>> currentOnline = [];
      
      for (final state in newState) {
        for (final presence in state.presences) {
          if (presence.payload != null) {
             currentOnline.add({
               'nama': presence.payload['nama'],
               'nim': presence.payload['nim'],
               'status': presence.payload['status'],
               'violations': presence.payload['violations'] ?? 0,
             });
          }
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
      
      // Update database agar statusnya kembali ONGOING (hapus efek LOCKED dari DB)
      try {
        final mahasiswaRes = await _supabase
            .from('MAHASISWA')
            .select('id')
            .eq('nim', nim)
            .single();
            
        if (mahasiswaRes.isNotEmpty) {
          final mahasiswaId = mahasiswaRes['id'];
          // Kita butuh ujianId, ambil dari parameter channel atau ambil semua SESI ujian ini
          // Lebih mudah mengupdate semua sesi_pengerjaan milik mhs ini yang statusnya LOCKED
          await _supabase
              .from('SESI_PENGERJAAN')
              .update({'status_pengerjaan': 'ONGOING'})
              .eq('mahasiswa_id', mahasiswaId)
              .eq('status_pengerjaan', 'LOCKED');
              
          // Refresh list lokal agar warna Merah langsung hilang
          int index = _pesertaUjian.indexWhere((p) => p['MAHASISWA']['id'] == mahasiswaId);
          if (index != -1) {
            _pesertaUjian[index]['status_pengerjaan'] = 'ONGOING';
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
    _onlineStudents.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
