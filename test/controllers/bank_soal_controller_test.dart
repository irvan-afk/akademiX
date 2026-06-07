import 'package:akademix/core/database/local_db_gateway.dart';
import 'package:akademix/features/bank_soal/controllers/bank_soal_controller.dart';
import 'package:akademix/features/bank_soal/models/bank_soal_model.dart';
import 'package:akademix/features/bank_soal/services/bank_soal_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalDbGateway implements LocalDbGateway {
  final List<Map<String, dynamic>> saveBankSoalCalls = [];
  bool updateStatusCalled = false;

  @override
  Future<void> clearAllLokalData() async {}

  @override
  Future<List<Map<String, dynamic>>> getJawabanBySesi(int sesiId) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSoalByUjian(int ujianId) async {
    return const [];
  }

  @override
  Future<void> saveJawabanLokal(int soalId, int sesiId, String jawaban) async {}

  @override
  Future<void> saveSoalLokal(Map<String, dynamic> soal) async {}

  @override
  Future<void> saveUjianLokal(Map<String, dynamic> ujianData) async {}

  @override
  Future<void> updateUjianStatusLokal(int ujianId, String status) async {}

  @override
  Future<Map<String, dynamic>?> getBankSoalByRemoteUjianId(
    int remoteUjianId,
  ) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getLatestBankSoal({
    required int? dosenId,
  }) async {
    return null;
  }

  @override
  Future<bool> updateBankSoalStatus(int id, String status) async {
    updateStatusCalled = true;
    return true;
  }

  @override
  Future<int> saveBankSoal({
    required int? id,
    required int? dosenId,
    required int? pengampuId,
    required String? pengampuLabel,
    required int? remoteUjianId,
    required String? kodeUjian,
    required String? kodePengawasan,
    required String? pinMulai,
    required String mataKuliah,
    required String judulUjian,
    required int? durasiMenit,
    required DateTime? waktuMulai,
    required String status,
    required List<Map<String, dynamic>> soalList,
  }) async {
    saveBankSoalCalls.add({
      'id': id,
      'dosen_id': dosenId,
      'pengampu_id': pengampuId,
      'pengampu_label': pengampuLabel,
      'remote_ujian_id': remoteUjianId,
      'kode_ujian': kodeUjian,
      'kode_pengawasan': kodePengawasan,
      'pin_mulai': pinMulai,
      'mata_kuliah': mataKuliah,
      'judul_ujian': judulUjian,
      'durasi_menit': durasiMenit,
      'waktu_mulai': waktuMulai,
      'status': status,
      'soal_list': soalList,
    });
    return id ?? 100;
  }
}

class FakeBankSoalService implements BankSoalGateway {
  Map<String, dynamic>? upsertResponse = {
    'id': 100,
    'kode_ujian': 'UJIAN100',
    'kode_pengawasan': 'MON100',
    'pin_mulai': '4321',
  };

  bool replaceCalled = false;
  int? replaceUjianId;
  List<Map<String, dynamic>>? replaceRows;

  @override
  Future<List<Map<String, dynamic>>> getPengampuForDosen(int dosenId) async {
    return const [];
  }

  @override
  Future<Map<String, dynamic>> upsertUjian({
    required int? ujianId,
    required BankSoalModel draft,
    required bool publish,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
  }) async {
    return upsertResponse!;
  }

  @override
  Future<void> replaceSoalForUjian(
    int ujianId,
    List<Map<String, dynamic>> soalRows,
  ) async {
    replaceCalled = true;
    replaceUjianId = ujianId;
    replaceRows = soalRows;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BankSoalController', () {
    test('publish ditolak jika total poin belum 100', () async {
      final controller = BankSoalController(
        bankSoalService: FakeBankSoalService(),
        localDb: FakeLocalDbGateway(),
      );

      controller.resetDraft(dosenId: 1);
      controller.setHeader(
        pengampuId: 1,
        pengampuLabel: 'MK 1 • Kelas A',
        mataKuliah: 'Algoritma',
        judulUjian: 'Quiz 1',
        durasiMenit: 60,
      );
      controller.addQuestion(
        const BankSoalQuestionModel(
          localId: 1,
          tipeSoal: 'pilihan_ganda',
          teksSoal: '1 + 1 = ?',
          opsiJawaban: {'A': '1', 'B': '2'},
          kunciJawaban: 'B',
          poin: 40,
        ),
      );

      final result = await controller.publishBankSoal();

      expect(result, isFalse);
      expect(
        controller.lastActionMessage,
        'Total poin harus 100 dan soal harus lengkap dulu.',
      );
    });

    test('save draft menyimpan lokal lalu sinkron ke backend', () async {
      final localDb = FakeLocalDbGateway();
      final service = FakeBankSoalService();
      final controller = BankSoalController(
        bankSoalService: service,
        localDb: localDb,
      );

      controller.resetDraft(dosenId: 1);
      controller.setHeader(
        pengampuId: 2,
        pengampuLabel: 'MK 2 • Kelas B',
        mataKuliah: 'Pemrograman',
        judulUjian: 'UTS',
        durasiMenit: 90,
      );
      controller.addQuestion(
        const BankSoalQuestionModel(
          localId: 1,
          tipeSoal: 'pilihan_ganda',
          teksSoal: '2 + 2 = ?',
          opsiJawaban: {'A': '3', 'B': '4'},
          kunciJawaban: 'B',
          poin: 100,
        ),
      );

      final result = await controller.saveBankSoal();

      expect(result, isTrue);
      expect(localDb.saveBankSoalCalls, hasLength(2));
      expect(localDb.saveBankSoalCalls.first['status'], 'draft');
      expect(localDb.saveBankSoalCalls.last['remote_ujian_id'], 100);
      expect(service.replaceCalled, isTrue);
      expect(service.replaceUjianId, 100);
      expect(
        controller.lastActionMessage,
        'Draft bank soal berhasil disimpan.',
      );
    });

    test('saveBankSoal ditolak jika soal masih kosong', () async {
      final controller = BankSoalController(
        bankSoalService: FakeBankSoalService(),
        localDb: FakeLocalDbGateway(),
      );

      controller.resetDraft(dosenId: 1);
      controller.setHeader(
        pengampuId: 3,
        pengampuLabel: 'MK 3 • Kelas C',
        mataKuliah: 'Basis Data',
        judulUjian: 'UAS',
        durasiMenit: 60,
      );
      // Sengaja tidak addQuestion

      final result = await controller.saveBankSoal();

      expect(result, isFalse);
      expect(
        controller.lastActionMessage,
        'Lengkapi data ujian dan minimal 1 soal dulu.',
      );
    });

    test('publishBankSoal sukses jika poin = 100 dan header valid', () async {
      final localDb = FakeLocalDbGateway();
      final service = FakeBankSoalService();
      final controller = BankSoalController(
        bankSoalService: service,
        localDb: localDb,
      );

      controller.resetDraft(dosenId: 1);
      controller.setHeader(
        pengampuId: 4,
        pengampuLabel: 'MK 4 • Kelas D',
        mataKuliah: 'Jaringan Komputer',
        judulUjian: 'UTS',
        durasiMenit: 90,
      );
      controller.addQuestion(
        const BankSoalQuestionModel(
          localId: 1,
          tipeSoal: 'pilihan_ganda',
          teksSoal: 'Apa itu IP Address?',
          opsiJawaban: {'A': 'Alamat fisik', 'B': 'Alamat logis'},
          kunciJawaban: 'B',
          poin: 100,
        ),
      );

      final result = await controller.publishBankSoal();

      expect(result, isTrue);
      expect(localDb.updateStatusCalled, isTrue);
      expect(service.replaceCalled, isTrue);
      expect(service.replaceUjianId, 100);
      expect(controller.lastActionMessage, 'Bank soal berhasil dipublish.');
    });
  });
}
