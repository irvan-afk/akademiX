import 'package:akademix/features/bank_soal/models/bank_soal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BankSoalModel', () {
    test('parses map data and questions correctly', () {
      final model = BankSoalModel.fromMap(
        {
          'id': 5,
          'dosen_id': 7,
          'pengampu_id': 9,
          'pengampu_label': 'MK 1 • Kelas A',
          'remote_ujian_id': 100,
          'kode_ujian': 'UJIAN1',
          'kode_pengawasan': 'MON1',
          'pin_mulai': '1234',
          'mata_kuliah': 'Algoritma',
          'judul_ujian': 'Quiz 1',
          'durasi_menit': 60,
          'waktu_mulai': '2026-05-31T08:00:00.000Z',
          'status': 'draft',
          'created_at': '2026-05-31T01:00:00.000Z',
          'updated_at': '2026-05-31T02:00:00.000Z',
        },
        [
          {
            'local_id': 1,
            'tipe_soal': 'pilihan_ganda',
            'teks_soal': '1 + 1 = ?',
            'opsi_jawaban': {'A': '1', 'B': '2'},
            'kunci_jawaban': 'B',
            'poin': 50,
            'catatan': 'basic math',
          },
          {
            'local_id': 2,
            'tipe_soal': 'essay',
            'teks_soal': 'Jelaskan...',
            'opsi_jawaban': {},
            'kunci_jawaban': '',
            'poin': 50,
          },
        ],
      );

      expect(model.id, 5);
      expect(model.dosenId, 7);
      expect(model.pengampuId, 9);
      expect(model.pengampuLabel, 'MK 1 • Kelas A');
      expect(model.remoteUjianId, 100);
      expect(model.kodeUjian, 'UJIAN1');
      expect(model.kodePengawasan, 'MON1');
      expect(model.pinMulai, '1234');
      expect(model.mataKuliah, 'Algoritma');
      expect(model.judulUjian, 'Quiz 1');
      expect(model.durasiMenit, 60);
      expect(model.status, 'draft');
      expect(model.questions.length, 2);
      expect(model.totalPoin, 100);
      expect(model.hasValidHeader, isTrue);
      expect(model.canPublish, isTrue);
      expect(model.questions.first.isPilihanGanda, isTrue);
    });

    test('canPublish becomes false when total points are not 100', () {
      final model = BankSoalModel.empty(dosenId: 1).copyWith(
        pengampuId: 2,
        mataKuliah: 'Algoritma',
        judulUjian: 'Quiz 2',
        durasiMenit: 45,
        questions: [
          const BankSoalQuestionModel(
            localId: 1,
            tipeSoal: 'pilihan_ganda',
            teksSoal: 'Soal',
            opsiJawaban: {'A': '1'},
            kunciJawaban: 'A',
            poin: 40,
          ),
        ],
      );

      expect(model.totalPoin, 40);
      expect(model.hasValidHeader, isTrue);
      expect(model.canPublish, isFalse);
    });
  });
}
