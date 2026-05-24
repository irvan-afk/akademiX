import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GradingController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _publishedExams = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _detailPengerjaan = [];

  List<Map<String, dynamic>> get submissions => _submissions;
  List<Map<String, dynamic>> get detailPengerjaan => _detailPengerjaan;
  List<Map<String, dynamic>> get publishedExams => _publishedExams;

  // --- FETCH PUBLISHED EXAMS ---
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

  // --- FETCH SUBMISSIONS ---
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

  // --- FETCH DETAIL PENGERJAAN ---
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

  // --- UPDATE ESSAY GRADE ---
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
}
