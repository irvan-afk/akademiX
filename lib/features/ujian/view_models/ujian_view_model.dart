import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ujian_model.dart';

class UjianViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- STATE MAHASISWA ---
  UjianModel? _activeUjian;
  UjianModel? get activeUjian => _activeUjian;

  // --- STATE DOSEN (KOREKSI) ---
  List<Map<String, dynamic>> _publishedExams = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _detailPengerjaan = [];

  List<Map<String, dynamic>> get publishedExams => _publishedExams;
  List<Map<String, dynamic>> get submissions => _submissions;
  List<Map<String, dynamic>> get detailPengerjaan => _detailPengerjaan;

  List<UjianModel> _allUjianDosen = []; // Simpan data mentah dari DB
  List<UjianModel> get allUjianDosen => _allUjianDosen;

  Map<String, dynamic> _statsRekap = {'avg': '0', 'max': 0, 'passRate': 0};
  Map<String, dynamic> get statsRekap => _statsRekap;

  // 2. Gunakan list rekap yang lebih detail
  List<Map<String, dynamic>> _rekapNilai = [];
  List<Map<String, dynamic>> get rekapNilai => _rekapNilai;

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

  // --- FUNGSI DOSEN (KELOLA & PUBLISH) ---
  Future<List<UjianModel>> fetchAllUjianForDosen(int dosenId) async {
    try {
      final draftResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'DRAFT')
          .eq('PENGAMPU.dosen_id', dosenId);

      final publishedResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'PUBLISHED')
          .eq('PENGAMPU.dosen_id', dosenId);

      final allResponses = [...draftResponse, ...publishedResponse];
      return (allResponses as List).map((e) => UjianModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch All Ujian: $e");
      return [];
    }
  }

  Future<Map<String, String>?> publishUjian(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    final tokenUjian = _generateRandomCode();
    final tokenMonitor = _generateRandomCode();

    try {
      await _supabase
          .from('UJIAN')
          .update({
            'kode_ujian': tokenUjian,
            'kode_pengawasan': tokenMonitor,
            'status_ujian': 'PUBLISHED',
          })
          .eq('id', ujianId);

      return {'ujian': tokenUjian, 'monitoring': tokenMonitor};
    } catch (e) {
      debugPrint("Error Publish: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI MAHASISWA (JOIN UJIAN) ---
  Future<UjianModel?> joinUjian(String code) async {
    _isLoading = true;
    _activeUjian = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('UJIAN')
          .select()
          .eq('kode_ujian', code.toUpperCase())
          .eq('status_ujian', 'PUBLISHED')
          .maybeSingle();

      if (response != null) {
        _activeUjian = UjianModel.fromJson(response);
        return _activeUjian;
      }
      return null;
    } catch (e) {
      debugPrint("Error Join Ujian: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI DOSEN (KOREKSI) ---
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

  Future<void> fetchDetailPengerjaan(int ujianId, int sesiId) async {
    _isLoading = true;
    _detailPengerjaan = [];
    notifyListeners();

    try {
      // Ambil data soal dan jawaban mahasiswa
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

  // Fungsi update nilai yang sudah diperbaiki (tidak duplikat)
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

      // Update data lokal agar UI langsung sinkron
      for (var item in _detailPengerjaan) {
        if (item['jawaban'] != null && item['jawaban']['id'] == jawabanId) {
          item['jawaban']['nilai'] = nilai;
          item['jawaban']['feedback'] = feedback;
        }
      }
      notifyListeners(); // Memberitahu UI untuk update tampilan
      return true;
    } catch (e) {
      debugPrint("Error Update Grade: $e");
      return false;
    }
  }

  Future<void> fetchUjianForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Pindahkan logika fetchAllUjianForDosen Anda ke sini
      final draftResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'DRAFT')
          .eq('PENGAMPU.dosen_id', dosenId);

      final publishedResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'PUBLISHED')
          .eq('PENGAMPU.dosen_id', dosenId);

      final allResponses = [...draftResponse, ...publishedResponse];
      _allUjianDosen = (allResponses as List)
          .map((e) => UjianModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("Error Fetch: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRekapNilai(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Ambil sesi pengerjaan beserta breakdown nilai PG dan Essai
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
          // Tambahkan baris ini untuk mengambil tipe dan membersihkannya
          String tipe = (j['soal']['tipe_soal'] ?? "").toString().toLowerCase();

          // Cek sesuai string di database kamu: 'pilihan_ganda'
          if (tipe == 'pilihan_ganda') {
            pgScore += (j['nilai'] as num? ?? 0).toInt();
          }
          // Cek sesuai string di database kamu: 'essai'
          else if (tipe == 'essai' || tipe == 'essay') {
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

      // Hitung Statistik Global untuk Header
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
}

// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/ujian_model.dart';

// class UjianViewModel extends ChangeNotifier {
//   final _supabase = Supabase.instance.client;
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String _generateRandomCode() {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     return String.fromCharCodes(
//       Iterable.generate(
//         6,
//         (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
//       ),
//     );
//   }

//   // Fetch semua ujian (DRAFT + PUBLISHED) untuk dosen
//   Future<List<UjianModel>> fetchAllUjianForDosen(int dosenId) async {
//     try {
//       // Query DRAFT exams
//       final draftResponse = await _supabase
//           .from('UJIAN')
//           .select('*, PENGAMPU!inner(dosen_id)')
//           .eq('status_ujian', 'DRAFT')
//           .eq('PENGAMPU.dosen_id', dosenId);

//       // Query PUBLISHED exams
//       final publishedResponse = await _supabase
//           .from('UJIAN')
//           .select('*, PENGAMPU!inner(dosen_id)')
//           .eq('status_ujian', 'PUBLISHED')
//           .eq('PENGAMPU.dosen_id', dosenId);

//       // Combine results
//       final allResponses = [...draftResponse, ...publishedResponse];

//       debugPrint("Ditemukan ${allResponses.length} ujian (DRAFT + PUBLISHED)");
//       return (allResponses as List).map((e) => UjianModel.fromJson(e)).toList();
//     } catch (e) {
//       debugPrint("Error Fetch All Ujian: $e");
//       return [];
//     }
//   }

//   // Legacy method: Fetch hanya DRAFT (untuk backward compatibility)
//   Future<List<UjianModel>> fetchDraftUjian(int dosenId) async {
//     try {
//       final response = await _supabase
//           .from('UJIAN')
//           .select('*, PENGAMPU!inner(dosen_id)')
//           .eq('status_ujian', 'DRAFT')
//           .eq('PENGAMPU.dosen_id', dosenId);

//       debugPrint("Data draf ditemukan: ${response.length} baris");
//       return (response as List).map((e) => UjianModel.fromJson(e)).toList();
//     } catch (e) {
//       debugPrint("Error Fetch Draft: $e");
//       return [];
//     }
//   }

//   // UPDATE: Nama tabel diganti jadi UJIAN (Capital)
//   Future<Map<String, String>?> publishUjian(int ujianId) async {
//     _isLoading = true;
//     notifyListeners();

//     final tokenUjian = _generateRandomCode();
//     final tokenMonitor = _generateRandomCode();

//     try {
//       await _supabase
//           .from('UJIAN') // Diubah jadi Kapital
//           .update({
//             'kode_ujian': tokenUjian,
//             'kode_pengawasan': tokenMonitor,
//             'status_ujian':
//                 'PUBLISHED', // Fixed: Changed to uppercase 'PUBLISHED' (enum value in DB)
//           })
//           .eq('id', ujianId);

//       debugPrint("Ujian berhasil dipublish dengan kode: $tokenUjian");
//       return {'ujian': tokenUjian, 'monitoring': tokenMonitor};
//     } catch (e) {
//       debugPrint("Error Publish: $e");
//       return null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
// }
