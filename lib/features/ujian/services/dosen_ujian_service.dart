import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DosenUjianService {
  late final _supabase = Supabase.instance.client;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  Future<List<dynamic>> fetchUjianForDosen(int dosenId) async {
    final response = await _supabase
        .from('UJIAN')
        .select('*, PENGAMPU!inner(dosen_id)')
        .eq('PENGAMPU.dosen_id', dosenId)
        .order('id', ascending: false);
    return response as List;
  }

  Future<Map<String, String>> publishUjian(int ujianId) async {
    final tokenUjian = _generateRandomCode();
    final tokenMonitor = _generateRandomCode();
    final pinMulai = (1000 + Random().nextInt(9000)).toString();

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
  }

  Future<List<dynamic>> fetchPublishedExams() async {
    final response = await _supabase
        .from('UJIAN')
        .select('id, judul_ujian, status_ujian, waktu_mulai, waktu_selesai')
        .inFilter('status_ujian', ['PUBLISHED', 'CLOSED'])
        .order('waktu_mulai', ascending: false);
    return response as List;
  }

  Future<void> updateUjianStatus(int ujianId, String status) async {
    await _supabase
        .from('UJIAN')
        .update({'status_ujian': status})
        .eq('id', ujianId);
  }

  Future<List<dynamic>> fetchSubmissions(int ujianId) async {
    final response = await _supabase
        .from('SESI_PENGERJAAN')
        .select(
          'id, ujian_id, mahasiswa_id, status_pengerjaan, MAHASISWA(id, nama, nim, avatar_url)',
        )
        .eq('ujian_id', ujianId)
        .eq('status_pengerjaan', 'SUBMITTED');
    return response as List;
  }

  Future<List<dynamic>> fetchPesertaUjian(int ujianId) async {
    final response = await _supabase
        .from('SESI_PENGERJAAN')
        .select(
          'id, ujian_id, mahasiswa_id, status_pengerjaan, MAHASISWA(id, nama, nim, avatar_url)',
        )
        .eq('ujian_id', ujianId);
    return response as List;
  }

  Future<List<dynamic>> fetchSoalForUjian(int ujianId) async {
    final response = await _supabase
        .from('soal')
        .select()
        .eq('ujian_id', ujianId)
        .order('id');
    return response as List;
  }

  Future<List<dynamic>> fetchJawabanForSesi(int sesiId) async {
    final response = await _supabase
        .from('JAWABAN_MAHASISWA')
        .select()
        .eq('sesi_pengerjaan_id', sesiId);
    return response as List;
  }

  Future<void> updateEssayGrade(
    int jawabanId,
    int nilai,
    String feedback,
  ) async {
    await _supabase
        .from('JAWABAN_MAHASISWA')
        .update({'nilai': nilai, 'feedback': feedback})
        .eq('id', jawabanId);
  }

  Future<Map<String, dynamic>?> fetchUjianTampilkanNilaiStatus(
    int ujianId,
  ) async {
    return await _supabase
        .from('UJIAN')
        .select('tampilkan_nilai')
        .eq('id', ujianId)
        .maybeSingle();
  }

  Future<List<dynamic>> fetchRekapNilaiData(int ujianId) async {
    final response = await _supabase
        .from('SESI_PENGERJAAN')
        .select(
          'id, MAHASISWA(nama, nim), JAWABAN_MAHASISWA(nilai, soal(tipe_soal))',
        )
        .eq('ujian_id', ujianId)
        .eq('status_pengerjaan', 'SUBMITTED');
    return response as List;
  }

  Future<void> toggleTampilkanNilai(int ujianId, bool value) async {
    await _supabase
        .from('UJIAN')
        .update({'tampilkan_nilai': value})
        .eq('id', ujianId);
  }

  Future<Map<String, dynamic>?> joinPengawasan(String kodePengawasan) async {
    return await _supabase
        .from('UJIAN')
        .select('id, judul_ujian, pin_mulai')
        .eq('kode_pengawasan', kodePengawasan)
        .maybeSingle();
  }

  RealtimeChannel getMonitoringChannel(int ujianId) {
    return _supabase.channel('exam_monitoring_$ujianId');
  }

  Future<Map<String, dynamic>?> getMahasiswaByNim(String nim) async {
    return await _supabase
        .from('MAHASISWA')
        .select('id')
        .eq('nim', nim)
        .maybeSingle();
  }

  Future<void> updateSesiPengerjaanStatusToActive(int mahasiswaId, int ujianId) async {
    await _supabase
        .from('SESI_PENGERJAAN')
        .update({'status_pengerjaan': 'ACTIVE'})
        .eq('mahasiswa_id', mahasiswaId)
        .eq('ujian_id', ujianId)
        .inFilter('status_pengerjaan', ['REJECTED']);
  }
}
