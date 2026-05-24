import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecapController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _rekapNilai = [];
  Map<String, dynamic> _statsRekap = {'avg': '0', 'max': 0, 'passRate': 0};
  bool _isNilaiPublished = false;

  List<Map<String, dynamic>> get rekapNilai => _rekapNilai;
  Map<String, dynamic> get statsRekap => _statsRekap;
  bool get isNilaiPublished => _isNilaiPublished;

  // --- FETCH RECAP NILAI ---
  Future<void> fetchRekapNilai(int ujianId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Get tampilkan_nilai status
      final ujianRes = await _supabase
          .from('UJIAN')
          .select('tampilkan_nilai')
          .eq('id', ujianId)
          .maybeSingle();
      if (ujianRes != null) {
        _isNilaiPublished = ujianRes['tampilkan_nilai'] ?? false;
      }

      // Get all submissions with answers
      final response = await _supabase
          .from('SESI_PENGERJAAN')
          .select(
            'id, MAHASISWA(nama, nim), JAWABAN_MAHASISWA(nilai, soal(tipe_soal))',
          )
          .eq('ujian_id', ujianId)
          .eq('status_pengerjaan', 'SUBMITTED');

      // Calculate scores
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

      // Calculate statistics
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

  // --- TOGGLE TAMPILKAN NILAI ---
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
}
