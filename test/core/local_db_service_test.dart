import 'package:akademix/core/database/local_db_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDbService localDbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    localDbService = LocalDbService.instance;
  });

  setUp(() async {
    await localDbService.clearAllLokalData();
  });

  group('LocalDbService', () {
    test('save and get jawaban lokal by session', () async {
      await localDbService.saveJawabanLokal(101, 500, 'B');

      final result = await localDbService.getJawabanBySesi(500);

      expect(result, hasLength(1));
      expect(result.first['soal_id'], 101);
      expect(result.first['sesi_pengerjaan_id'], 500);
      expect(result.first['jawaban_teks'], 'B');
    });

    test('save and get ujian lokal', () async {
      await localDbService.saveUjianLokal({
        'id': 1,
        'judul_ujian': 'UTS',
        'durasi_menit': 60,
        'pin_mulai': '1234',
        'status_lokal': 'WAITING',
      });

      final result = await localDbService.getUjianLokal(1);

      expect(result, isNotNull);
      expect(result?['id'], 1);
      expect(result?['judul_ujian'], 'UTS');
      expect(result?['durasi'], 60);
      expect(result?['pin_mulai'], '1234');
    });

    test('save and get soal lokal decodes opsi_jawaban', () async {
      await localDbService.saveSoalLokal({
        'id': 10,
        'ujian_id': 1,
        'teks_soal': '2 + 2 = ?',
        'tipe_soal': 'pilihan_ganda',
        'opsi_jawaban': {'A': '3', 'B': '4'},
        'bobot_nilai': 50,
        'kunci_jawaban': 'B',
      });

      final result = await localDbService.getSoalByUjian(1);

      expect(result, hasLength(1));
      expect(result.first['id'], 10);
      expect(result.first['opsi_jawaban'], isA<Map>());
      expect(result.first['opsi_jawaban']['B'], '4');
    });

    test('clearAllLokalData removes stored ujian, soal, and jawaban', () async {
      await localDbService.saveUjianLokal({
        'id': 2,
        'judul_ujian': 'UTS',
        'durasi_menit': 60,
      });
      await localDbService.saveSoalLokal({
        'id': 20,
        'ujian_id': 2,
        'teks_soal': 'Contoh',
        'tipe_soal': 'essay',
        'opsi_jawaban': {},
        'bobot_nilai': 100,
        'kunci_jawaban': '',
      });
      await localDbService.saveJawabanLokal(20, 600, 'Jawaban');

      await localDbService.clearAllLokalData();

      expect(await localDbService.getUjianLokal(2), isNull);
      expect(await localDbService.getSoalByUjian(2), isEmpty);
      expect(await localDbService.getJawabanBySesi(600), isEmpty);
    });

    test('jawaban duplikat untuk soal yang sama tersimpan sebagai entri baru', () async {
      // saveJawabanLokal menggunakan AUTOINCREMENT, sehingga
      // panggilan berulang untuk soal yang sama TIDAK melakukan deduplication.
      // Ini adalah behavior yang didokumentasikan secara eksplisit.
      await localDbService.saveJawabanLokal(300, 700, 'A');
      await localDbService.saveJawabanLokal(300, 700, 'B'); // jawaban diubah

      final result = await localDbService.getJawabanBySesi(700);

      // Kedua entri tersimpan (tidak di-dedup) — ini expected behavior
      expect(result, hasLength(2));
      expect(result.map((r) => r['jawaban_teks']).toList(), containsAll(['A', 'B']));
    });
  });
}
