import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JawabanRepository {
  final supabase = Supabase.instance.client;

  /// Simpan jawaban mahasiswa untuk satu ujian
  Future<void> submitAnswers({
    required int ujianId,
    required int mahasiswaId,
    required Map<int, String> answers, // soalId -> jawaban
  }) async {
    try {
      debugPrint(
        "🚀 Starting submitAnswers for ujianId=$ujianId, mahasiswaId=$mahasiswaId",
      );
      debugPrint("📝 Answers to submit: $answers");

      // 1. Create atau update SESI_PENGERJAAN
      final sesiResponse = await supabase
          .from('SESI_PENGERJAAN')
          .upsert({
            'ujian_id': ujianId,
            'mahasiswa_id': mahasiswaId,
            'status_pengerjaan': 'SUBMITTED',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final sesiPengerjaanId = sesiResponse['id'] as int;
      debugPrint("✓ SESI_PENGERJAAN ID: $sesiPengerjaanId");

      // 2. Delete existing jawaban untuk fresh insert (avoid duplicate key errors)
      await supabase
          .from('JAWABAN_MAHASISWA')
          .delete()
          .eq('sesi_pengerjaan_id', sesiPengerjaanId);

      debugPrint("🗑️ Cleared existing jawaban");

      // 3. Insert jawaban untuk setiap soal
      final jawabanList = <Map<String, dynamic>>[];
      for (var entry in answers.entries) {
        jawabanList.add({
          'sesi_pengerjaan_id': sesiPengerjaanId,
          'soal_id': entry.key,
          'jawaban_teks': entry.value,
          'last_updated_local': DateTime.now().toIso8601String(),
        });
      }

      if (jawabanList.isEmpty) {
        throw Exception("Tidak ada jawaban yang akan disimpan!");
      }

      // Batch insert jawaban
      await supabase.from('JAWABAN_MAHASISWA').insert(jawabanList);

      debugPrint("✅ Berhasil menyimpan ${jawabanList.length} jawaban");

      // 4. Auto-score pilihan_ganda answers
      await _autoScorePilihanGanda(ujianId, sesiPengerjaanId);
    } catch (e) {
      debugPrint("❌ Error submit jawaban: $e");
      rethrow;
    }
  }

  /// Hitung skor otomatis untuk soal pilihan_ganda berdasarkan kunci jawaban
  Future<void> _autoScorePilihanGanda(int ujianId, int sesiPengerjaanId) async {
    try {
      debugPrint("🔄 Starting auto-score for pilihan_ganda...");

      // Get all soal pilihan_ganda for this ujian
      final soalResponse = await supabase
          .from('soal')
          .select('id, tipe_soal, kunci_jawaban, bobot_nilai')
          .eq('ujian_id', ujianId)
          .eq('tipe_soal', 'pilihan_ganda');

      for (var soal in soalResponse) {
        final soalId = soal['id'] as int;
        final kunciJawaban = (soal['kunci_jawaban'] as String?)?.toLowerCase();
        final bobotNilai = soal['bobot_nilai'] as int?;

        if (kunciJawaban == null || bobotNilai == null) continue;

        // Get jawaban mahasiswa for this soal
        final jawabanResponse = await supabase
            .from('JAWABAN_MAHASISWA')
            .select('id, jawaban_teks')
            .eq('sesi_pengerjaan_id', sesiPengerjaanId)
            .eq('soal_id', soalId);

        if (jawabanResponse.isEmpty) continue;

        final jawaban = jawabanResponse.first;
        final jawabanId = jawaban['id'] as int;
        final jawabanTeks = (jawaban['jawaban_teks'] as String?)?.toLowerCase();

        // Compare and calculate score
        int nilai = 0;
        if (jawabanTeks != null && jawabanTeks == kunciJawaban) {
          nilai = bobotNilai;
          debugPrint(
            "✅ Soal $soalId correct: $jawabanTeks == $kunciJawaban, nilai=$nilai",
          );
        } else {
          debugPrint("❌ Soal $soalId wrong: $jawabanTeks != $kunciJawaban");
        }

        // Update nilai in JAWABAN_MAHASISWA
        await supabase
            .from('JAWABAN_MAHASISWA')
            .update({'nilai': nilai})
            .eq('id', jawabanId);
      }

      debugPrint("✅ Auto-scoring selesai");
    } catch (e) {
      debugPrint("❌ Error auto-score: $e");
      // Don't rethrow - auto-scoring failure shouldn't block submission
    }
  }

  /// Ambil jawaban mahasiswa untuk satu ujian
  Future<List<Map<String, dynamic>>> getAnswersForExam(
    int ujianId,
    int mahasiswaId,
  ) async {
    try {
      final response = await supabase
          .from('JAWABAN_MAHASISWA')
          .select('''
            id,
            soal_id,
            jawaban_teks,
            last_updated_local,
            SESI_PENGERJAAN(
              id,
              ujian_id,
              status_pengerjaan,
              submitted_at
            )
          ''')
          .eq('SESI_PENGERJAAN.ujian_id', ujianId)
          .eq('SESI_PENGERJAAN.mahasiswa_id', mahasiswaId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error get answers: $e");
      rethrow;
    }
  }

  /// Ambil semua mahasiswa yang sudah submit untuk satu ujian (untuk dosen)
  Future<List<Map<String, dynamic>>> getSubmissionsForExam(int ujianId) async {
    try {
      // Get submissions dengan detail mahasiswa
      final response = await supabase
          .from('SESI_PENGERJAAN')
          .select('id, ujian_id, mahasiswa_id, status_pengerjaan, submitted_at')
          .eq('ujian_id', ujianId)
          .eq('status_pengerjaan', 'SUBMITTED');

      // Fetch mahasiswa details separately
      final submissionsWithMahasiswa = <Map<String, dynamic>>[];
      for (var sesi in response) {
        try {
          final mahasiswaId = sesi['mahasiswa_id'] as int?;
          if (mahasiswaId == null) continue;

          final mahasiswaResp = await supabase
              .from('MAHASISWA')
              .select('id, nama_mahasiswa, nim')
              .eq('id', mahasiswaId)
              .single();

          sesi['MAHASISWA'] = mahasiswaResp;
          submissionsWithMahasiswa.add(sesi);
        } catch (e) {
          debugPrint("Error fetching mahasiswa $e");
          // Add with null MAHASISWA if fetch fails
          sesi['MAHASISWA'] = null;
          submissionsWithMahasiswa.add(sesi);
        }
      }

      return submissionsWithMahasiswa;
    } catch (e) {
      debugPrint("Error get submissions: $e");
      rethrow;
    }
  }

  /// Ambil semua soal dan jawaban mahasiswa untuk review (untuk dosen)
  Future<List<Map<String, dynamic>>> getExamReviewData(
    int ujianId,
    int mahasiswaId,
  ) async {
    try {
      final soalResponse = await supabase
          .from('soal')
          .select(
            'id, teks_soal, tipe_soal, opsi_jawaban, kunci_jawaban, bobot_nilai',
          )
          .eq('ujian_id', ujianId);

      final jawabanResponse = await supabase
          .from('JAWABAN_MAHASISWA')
          .select('soal_id, jawaban_teks')
          .eq(
            'sesi_pengerjaan_id',
            ujianId,
          ); // Note: Perlu join lewat SESI_PENGERJAAN

      return [
        {'soal': soalResponse, 'jawaban': jawabanResponse},
      ];
    } catch (e) {
      debugPrint("Error get exam review: $e");
      rethrow;
    }
  }

  /// Simpan nilai untuk jawaban essai
  Future<void> gradeEssayAnswer({
    required int jawabanId,
    required int nilai,
    required String feedback,
  }) async {
    try {
      await supabase
          .from('JAWABAN_MAHASISWA')
          .update({'nilai': nilai, 'feedback': feedback})
          .eq('id', jawabanId);

      debugPrint("✓ Nilai essai disimpan: nilai=$nilai");
    } catch (e) {
      debugPrint("✗ Error grade answer: $e");
      rethrow;
    }
  }
}
