import 'dart:io';

import 'package:akademix/core/database/local_db_gateway.dart';
import 'package:akademix/features/ujian/controllers/mahasiswa_ujian_controller.dart';
import 'package:akademix/features/ujian/services/mahasiswa_ujian_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akademix/core/config/debug_config.dart';

class FakeLocalDbGateway implements LocalDbGateway {
  final List<Map<String, dynamic>> savedUjian = [];
  final List<Map<String, dynamic>> savedSoal = [];
  final List<Map<String, dynamic>> savedJawaban = [];
  final List<Map<String, dynamic>> answersBySesi = [];
  List<Map<String, dynamic>> soalByUjian = [];
  bool clearCalled = false;
  String? lastUjianStatus;
  int? lastUpdatedUjianId;

  @override
  Future<void> clearAllLokalData() async {
    clearCalled = true;
    savedUjian.clear();
    savedSoal.clear();
    savedJawaban.clear();
    answersBySesi.clear();
    soalByUjian = [];
  }

  @override
  Future<List<Map<String, dynamic>>> getJawabanBySesi(int sesiId) async {
    return List<Map<String, dynamic>>.from(answersBySesi);
  }

  @override
  Future<List<Map<String, dynamic>>> getSoalByUjian(int ujianId) async {
    return List<Map<String, dynamic>>.from(soalByUjian);
  }

  @override
  Future<void> saveJawabanLokal(int soalId, int sesiId, String jawaban) async {
    savedJawaban.add({
      'soal_id': soalId,
      'sesi_pengerjaan_id': sesiId,
      'jawaban_teks': jawaban,
    });
    answersBySesi.add(savedJawaban.last);
  }

  @override
  Future<void> saveSoalLokal(Map<String, dynamic> soal) async {
    savedSoal.add(Map<String, dynamic>.from(soal));
  }

  @override
  Future<void> saveUjianLokal(Map<String, dynamic> ujianData) async {
    savedUjian.add(Map<String, dynamic>.from(ujianData));
  }

  @override
  Future<void> updateUjianStatusLokal(int ujianId, String status) async {
    lastUpdatedUjianId = ujianId;
    lastUjianStatus = status;
  }

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
    return 1;
  }
}

class FakeMahasiswaUjianService implements MahasiswaUjianService {
  FakeMahasiswaUjianService({
    required this.ujianResponse,
    required this.remoteSoalResponse,
    this.sesiResponse,
    this.createdSesiResponse,
    this.throwOnSubmit = false,
  });

  final Map<String, dynamic>? ujianResponse;
  final List<dynamic> remoteSoalResponse;
  final Map<String, dynamic>? sesiResponse;
  final Map<String, dynamic>? createdSesiResponse;
  final bool throwOnSubmit;

  List<Map<String, dynamic>>? submittedData;
  int? markedSubmittedSesiId;
  String? markedSubmittedTime;

  @override
  Future<Map<String, dynamic>?> getUjianByCode(String code) async {
    return ujianResponse;
  }

  @override
  Future<Map<String, dynamic>?> getSesiPengerjaan(
    int ujianId,
    int mahasiswaId,
  ) async {
    return sesiResponse;
  }

  @override
  Future<Map<String, dynamic>> createSesiPengerjaan(
    int ujianId,
    int mahasiswaId,
  ) async {
    return createdSesiResponse ?? {'id': 999};
  }

  @override
  Future<List<dynamic>> getRemoteSoal(int ujianId) async {
    return remoteSoalResponse;
  }

  @override
  Future<void> submitJawaban(List<Map<String, dynamic>> dataToUpload) async {
    submittedData = dataToUpload;
    if (throwOnSubmit) {
      throw Exception('network error');
    }
  }

  @override
  Future<void> markSesiAsSubmitted(int sesiId, String submitTime) async {
    markedSubmittedSesiId = sesiId;
    markedSubmittedTime = submitTime;
  }

  @override
  Future<String?> checkSesiPengerjaanStatus(
    int ujianId,
    int mahasiswaId,
  ) async {
    return null;
  }

  @override
  Future<void> updateSesiPengerjaanStatus(int sesiId, String status) async {}

  @override
  RealtimeChannel getPresenceChannel(int ujianId) {
    throw UnimplementedError();
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Supabase initialization omitted in tests to avoid external logging
    DebugConfig.enableLogs = false;

    tempDir = await Directory.systemTemp.createTemp('akademix_hive_tests');
    Hive.init(tempDir.path);
    await Hive.openBox('offline_exams');
  });

  tearDownAll(() async {
    await Hive.box('offline_exams').clear();
    await Hive.box('offline_exams').close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('MahasiswaUjianController', () {
    test('join ujian ditolak jika terlalu cepat masuk', () async {
      final now = DateTime.now();
      final controller = MahasiswaUjianController(
        enableTimer: false,
        service: FakeMahasiswaUjianService(
          ujianResponse: {
            'id': 1,
            'pengampu_id': 10,
            'judul_ujian': 'UTS',
            'waktu_mulai': now.add(const Duration(hours: 1)).toIso8601String(),
            'waktu_selesai': now
                .add(const Duration(hours: 2))
                .toIso8601String(),
            'durasi_menit': 60,
            'status_ujian': 'PUBLISHED',
          },
          remoteSoalResponse: const [],
        ),
        localDb: FakeLocalDbGateway(),
      );

      expect(
        () => controller.joinUjian('CODE1', 1),
        throwsA(predicate((e) => e.toString().contains('BELUM_WAKTUNYA'))),
      );
    });

    test('join ujian ditolak jika waktu sudah habis', () async {
      final now = DateTime.now();
      final controller = MahasiswaUjianController(
        enableTimer: false,
        service: FakeMahasiswaUjianService(
          ujianResponse: {
            'id': 2,
            'pengampu_id': 10,
            'judul_ujian': 'UTS',
            'waktu_mulai': now
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'waktu_selesai': now
                .subtract(const Duration(minutes: 1))
                .toIso8601String(),
            'durasi_menit': 60,
            'status_ujian': 'PUBLISHED',
          },
          remoteSoalResponse: const [],
        ),
        localDb: FakeLocalDbGateway(),
      );

      expect(
        () => controller.joinUjian('CODE2', 1),
        throwsA(predicate((e) => e.toString().contains('WAKTU_HABIS'))),
      );
    });

    test('join ujian valid menyimpan ujian dan soal lokal', () async {
      final now = DateTime.now();
      final localDb = FakeLocalDbGateway();
      final service = FakeMahasiswaUjianService(
        ujianResponse: {
          'id': 3,
          'pengampu_id': 10,
          'judul_ujian': 'UTS',
          'waktu_mulai': now
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
          'waktu_selesai': now.add(const Duration(hours: 1)).toIso8601String(),
          'durasi_menit': 60,
          'status_ujian': 'PUBLISHED',
          'pin_mulai': '1234',
        },
        sesiResponse: null,
        createdSesiResponse: {'id': 777},
        remoteSoalResponse: [
          {
            'id': 101,
            'ujian_id': 3,
            'teks_soal': '2 + 2 = ?',
            'tipe_soal': 'pilihan_ganda',
            'opsi_jawaban': {'A': '3', 'B': '4'},
            'bobot_nilai': 50,
            'kunci_jawaban': 'B',
          },
        ],
      );
      final controller = MahasiswaUjianController(
        enableTimer: false,
        service: service,
        localDb: localDb,
      );

      final result = await controller.joinUjian('CODE3', 9);

      expect(result, isNotNull);
      expect(controller.activeUjian?.id, 3);
      expect(controller.currentSesiId, 777);
      expect(localDb.savedUjian, hasLength(1));
      expect(localDb.savedSoal, hasLength(1));
      expect(localDb.savedSoal.first['id'], 101);
    });

    test('trigger lock mengubah status lokal menjadi LOCKED', () async {
      final now = DateTime.now();
      final localDb = FakeLocalDbGateway();
      final controller = MahasiswaUjianController(
        enableTimer: false,
        service: FakeMahasiswaUjianService(
          ujianResponse: {
            'id': 4,
            'pengampu_id': 10,
            'judul_ujian': 'UTS',
            'waktu_mulai': now
                .subtract(const Duration(minutes: 1))
                .toIso8601String(),
            'waktu_selesai': now
                .add(const Duration(hours: 1))
                .toIso8601String(),
            'durasi_menit': 60,
            'status_ujian': 'PUBLISHED',
          },
          remoteSoalResponse: const [],
          createdSesiResponse: {'id': 778},
        ),
        localDb: localDb,
      );

      await controller.joinUjian('CODE4', 9);
      await controller.triggerLock();

      expect(controller.isLockedByViolation, isTrue);
      expect(localDb.lastUpdatedUjianId, 4);
      expect(localDb.lastUjianStatus, 'LOCKED');
    });

    test('timer habis memicu auto submit ujian', () async {
      final now = DateTime.now();
      final localDb = FakeLocalDbGateway();
      final service = FakeMahasiswaUjianService(
        ujianResponse: {
          'id': 6,
          'pengampu_id': 10,
          'judul_ujian': 'UTS',
          'waktu_mulai': now
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
          'waktu_selesai': now.add(const Duration(hours: 1)).toIso8601String(),
          'durasi_menit': 60,
          'status_ujian': 'PUBLISHED',
        },
        createdSesiResponse: {'id': 780},
        remoteSoalResponse: [
          {
            'id': 301,
            'ujian_id': 6,
            'teks_soal': '2 + 2 = ?',
            'tipe_soal': 'pilihan_ganda',
            'opsi_jawaban': {'A': '3', 'B': '4'},
            'bobot_nilai': 50,
            'kunci_jawaban': 'B',
          },
        ],
      );
      final controller = MahasiswaUjianController(
        enableTimer: false,
        service: service,
        localDb: localDb,
      );

      await controller.joinUjian('CODE6', 9);
      await controller.simpanJawaban(301, 'B');
      await controller.debugForceTimerExpired();

      expect(service.submittedData, isNotNull);
      expect(service.markedSubmittedSesiId, 780);
      expect(controller.status, SubmissionStatus.success);
      expect(controller.currentSesiId, isNull);
      expect(localDb.clearCalled, isTrue);
    });

    test(
      'offline saving saat submit gagal mempertahankan data lokal',
      () async {
        final now = DateTime.now();
        final localDb = FakeLocalDbGateway();
        final service = FakeMahasiswaUjianService(
          ujianResponse: {
            'id': 5,
            'pengampu_id': 10,
            'judul_ujian': 'UTS',
            'waktu_mulai': now
                .subtract(const Duration(minutes: 1))
                .toIso8601String(),
            'waktu_selesai': now
                .add(const Duration(hours: 1))
                .toIso8601String(),
            'durasi_menit': 60,
            'status_ujian': 'PUBLISHED',
          },
          createdSesiResponse: {'id': 779},
          remoteSoalResponse: [
            {
              'id': 201,
              'ujian_id': 5,
              'teks_soal': '2 + 2 = ?',
              'tipe_soal': 'pilihan_ganda',
              'opsi_jawaban': {'A': '3', 'B': '4'},
              'bobot_nilai': 50,
              'kunci_jawaban': 'B',
            },
          ],
          throwOnSubmit: true,
        );
        final controller = MahasiswaUjianController(
          enableTimer: false,
          service: service,
          localDb: localDb,
        );

        await controller.joinUjian('CODE5', 9);
        await controller.simpanJawaban(201, 'B');
        await controller.submitUjian();

        final box = Hive.box('offline_exams');
        expect(controller.status, SubmissionStatus.offlineSaved);
        expect(localDb.clearCalled, isFalse);
        expect(box.keys, isNotEmpty);
      },
    );
  });
}
