import 'package:supabase_flutter/supabase_flutter.dart';

class MahasiswaUjianService {
  late final _supabase = Supabase.instance.client;

  Future<String?> checkSesiPengerjaanStatus(
    int ujianId,
    int mahasiswaId,
  ) async {
    final res = await _supabase
        .from('SESI_PENGERJAAN')
        .select('status_pengerjaan')
        .eq('ujian_id', ujianId)
        .eq('mahasiswa_id', mahasiswaId)
        .maybeSingle();
    return res?['status_pengerjaan']?.toString();
  }

  Future<void> updateSesiPengerjaanStatus(int sesiId, String status) async {
    await _supabase
        .from('SESI_PENGERJAAN')
        .update({'status_pengerjaan': status})
        .eq('id', sesiId);
  }

  RealtimeChannel getPresenceChannel(int ujianId) {
    return _supabase.channel('exam_monitoring_$ujianId');
  }

  Future<Map<String, dynamic>?> getUjianByCode(String code) async {
    return await _supabase
        .from('UJIAN')
        .select()
        .eq('kode_ujian', code.toUpperCase())
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getSesiPengerjaan(
    int ujianId,
    int mahasiswaId,
  ) async {
    return await _supabase
        .from('SESI_PENGERJAAN')
        .select('id, status_pengerjaan')
        .eq('ujian_id', ujianId)
        .eq('mahasiswa_id', mahasiswaId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> createSesiPengerjaan(
    int ujianId,
    int mahasiswaId,
  ) async {
    return await _supabase
        .from('SESI_PENGERJAAN')
        .insert({
          'ujian_id': ujianId,
          'mahasiswa_id': mahasiswaId,
          'status_pengerjaan': 'ACTIVE',
        })
        .select('id')
        .single();
  }

  Future<List<dynamic>> getRemoteSoal(int ujianId) async {
    final response = await _supabase
        .from('soal')
        .select()
        .eq('ujian_id', ujianId);
    return response as List;
  }

  Future<void> submitJawaban(List<Map<String, dynamic>> dataToUpload) async {
    if (dataToUpload.isNotEmpty) {
      await _supabase.from('JAWABAN_MAHASISWA').insert(dataToUpload);
    }
  }

  Future<void> markSesiAsSubmitted(int sesiId, String submitTime) async {
    await _supabase
        .from('SESI_PENGERJAAN')
        .update({'status_pengerjaan': 'SUBMITTED', 'submitted_at': submitTime})
        .eq('id', sesiId);
  }
}
