import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../models/bank_soal_model.dart';
import 'bank_soal_gateway.dart';

class BankSoalService implements BankSoalGateway {
  final SupabaseClient _supabase = supabase;

  String generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<List<Map<String, dynamic>>> getPengampuForDosen(int dosenId) async {
    final response = await _supabase
        .from('PENGAMPU')
        .select(
          'id, mata_kuliah_id, kelas_id, KELAS(nama, angkatan), MATA_KULIAH(nama)',
        )
        .eq('dosen_id', dosenId)
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>> upsertUjian({
    required int? ujianId,
    required BankSoalModel draft,
    required bool publish,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
  }) async {
    if (ujianId == null) {
      final inserted = await _supabase
          .from('UJIAN')
          .insert({
            'pengampu_id': draft.pengampuId,
            'judul_ujian': draft.judulUjian,
            'waktu_mulai': waktuMulai.toUtc().toIso8601String(),
            'waktu_selesai': waktuSelesai.toUtc().toIso8601String(),
            'durasi_menit': draft.durasiMenit,
            'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
            'kode_ujian': publish ? generateRandomCode() : null,
            'kode_pengawasan': publish ? generateRandomCode() : null,
            'pin_mulai': publish
                ? (1000 + Random().nextInt(9000)).toString()
                : null,
          })
          .select('id, kode_ujian, kode_pengawasan, pin_mulai')
          .single();
      return inserted;
    } else {
      final payload = <String, dynamic>{
        'pengampu_id': draft.pengampuId,
        'judul_ujian': draft.judulUjian,
        'waktu_mulai': waktuMulai.toUtc().toIso8601String(),
        'waktu_selesai': waktuSelesai.toUtc().toIso8601String(),
        'durasi_menit': draft.durasiMenit,
        'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
        'kode_ujian': publish
            ? draft.kodeUjian ?? generateRandomCode()
            : draft.kodeUjian,
        'kode_pengawasan': publish
            ? draft.kodePengawasan ?? generateRandomCode()
            : draft.kodePengawasan,
        'pin_mulai': publish
            ? draft.pinMulai ?? (1000 + Random().nextInt(9000)).toString()
            : draft.pinMulai,
      };

      await _supabase.from('UJIAN').update(payload).eq('id', ujianId);
      return payload..['id'] = ujianId;
    }
  }

  Future<void> replaceSoalForUjian(
    int ujianId,
    List<Map<String, dynamic>> soalRows,
  ) async {
    await _supabase.from('soal').delete().eq('ujian_id', ujianId);
    if (soalRows.isNotEmpty) {
      await _supabase.from('soal').insert(soalRows);
    }
  }
}
