import 'package:akademix/features/ujian/models/soal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoalModel', () {
    test('parses pilihan ganda with normalized type and options', () {
      final model = SoalModel.fromJson({
        'id': 11,
        'ujian_id': 21,
        'teks_soal': '2 + 2 = ?',
        'tipe_soal': ' PILIHAN_GANDA ',
        'opsi_jawaban': {'A': '3', 'B': '4'},
        'bobot_nilai': 25,
        'kunci_jawaban': 'B',
      });

      expect(model.id, 11);
      expect(model.ujianId, 21);
      expect(model.teksSoal, '2 + 2 = ?');
      expect(model.tipeSoal, 'pilihan_ganda');
      expect(model.opsiJawaban['A'], '3');
      expect(model.opsiJawaban['B'], '4');
      expect(model.bobotNilai, 25);
      expect(model.kunciJawaban, 'B');
    });

    test('falls back safely for missing or unexpected fields', () {
      final model = SoalModel.fromJson({
        'id': null,
        'ujian_id': null,
        'teks_soal': null,
        'tipe_soal': null,
        'opsi_jawaban': 'not-a-map',
        'bobot_nilai': null,
        'kunci_jawaban': null,
      });

      expect(model.id, 0);
      expect(model.ujianId, 0);
      expect(model.teksSoal, '');
      expect(model.tipeSoal, '');
      expect(model.opsiJawaban, isEmpty);
      expect(model.bobotNilai, 0);
      expect(model.kunciJawaban, '');
    });
  });
}
