import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/features/ujian/models/ujian_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UjianModel', () {
    test('parses JSON with UTC date strings into local DateTime safely', () {
      final model = UjianModel.fromJson({
        'id': 1,
        'pengampu_id': 10,
        'judul_ujian': 'Ujian Tengah Semester',
        'waktu_mulai': '2026-05-31T08:00:00.000Z',
        'waktu_selesai': '2026-05-31T10:00:00.000Z',
        'durasi_menit': 120,
        'status_ujian': 'PUBLISHED',
        'kode_ujian': 'ABC123',
        'kode_pengawasan': 'MON123',
        'pin_mulai': '1234',
        'status_lokal': 'WAITING',
        'tampilkan_nilai': true,
      });

      expect(model.id, 1);
      expect(model.pengampuId, 10);
      expect(model.judulUjian, 'Ujian Tengah Semester');
      expect(model.waktuMulai.isUtc, isFalse);
      expect(model.waktuSelesai.isUtc, isFalse);
      expect(model.durasiMenit, 120);
      expect(model.statusUjian, UjianStatus.published);
      expect(model.kodeUjian, 'ABC123');
      expect(model.kodePengawasan, 'MON123');
      expect(model.pinMulai, '1234');
      expect(model.statusLokal, 'WAITING');
      expect(model.tampilkanNilai, isTrue);
    });

    test('falls back safely when nullable fields are missing', () {
      final model = UjianModel.fromJson({
        'id': 2,
        'pengampu_id': null,
        'judul_ujian': null,
        'waktu_mulai': null,
        'waktu_selesai': null,
        'durasi_menit': null,
        'status_ujian': null,
        'kode_ujian': null,
        'kode_pengawasan': null,
        'pin_mulai': null,
        'status_lokal': null,
        'tampilkan_nilai': null,
        'soal': null,
      });

      expect(model.id, 2);
      expect(model.pengampuId, 0);
      expect(model.judulUjian, '');
      expect(model.durasiMenit, 0);
      expect(model.statusUjian, UjianStatus.draft);
      expect(model.kodeUjian, isNull);
      expect(model.kodePengawasan, isNull);
      expect(model.pinMulai, isNull);
      expect(model.statusLokal, isNull);
      expect(model.tampilkanNilai, isFalse);
      expect(model.daftarSoal, isNull);
    });

    test('status CLOSED di-parse ke UjianStatus.closed', () {
      final model = UjianModel.fromJson({
        'id': 3,
        'pengampu_id': 5,
        'judul_ujian': 'Ujian Akhir Semester',
        'waktu_mulai': '2026-05-01T08:00:00.000Z',
        'waktu_selesai': '2026-05-01T10:00:00.000Z',
        'durasi_menit': 120,
        'status_ujian': 'CLOSED',
        'tampilkan_nilai': false,
      });

      expect(model.id, 3);
      expect(model.statusUjian, UjianStatus.closed);
    });
  });
}
