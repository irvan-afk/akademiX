import 'package:akademix/features/ujian/controllers/dosen_ujian_controller.dart';
import 'package:akademix/features/ujian/services/dosen_ujian_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akademix/core/config/debug_config.dart';

class FakeDosenUjianService implements DosenUjianService {
  FakeDosenUjianService({
    this.ujianForDosenResponse = const [],
    this.publishedExamsResponse = const [],
    this.submissionsResponse = const [],
    this.soalResponse = const [],
    this.jawabanResponse = const [],
    this.ujianTampilkanNilaiStatus,
    this.rekapNilaiDataResponse = const [],
  });

  final List<dynamic> ujianForDosenResponse;
  final List<dynamic> publishedExamsResponse;
  final List<dynamic> submissionsResponse;
  final List<dynamic> soalResponse;
  final List<dynamic> jawabanResponse;
  final Map<String, dynamic>? ujianTampilkanNilaiStatus;
  final List<dynamic> rekapNilaiDataResponse;

  final List<Map<String, dynamic>> updatedStatuses = [];
  final List<Map<String, dynamic>> essayGrades = [];

  @override
  Future<List<dynamic>> fetchUjianForDosen(int dosenId) async {
    return ujianForDosenResponse;
  }

  @override
  Future<Map<String, String>> publishUjian(int ujianId) async {
    return {'ujian': 'UJIAN123', 'monitoring': 'MON123', 'pin': '1234'};
  }

  @override
  Future<List<dynamic>> fetchPublishedExams() async {
    return publishedExamsResponse;
  }

  @override
  Future<void> updateUjianStatus(int ujianId, String status) async {
    updatedStatuses.add({'id': ujianId, 'status': status});
  }

  @override
  Future<List<dynamic>> fetchSubmissions(int ujianId) async {
    return submissionsResponse;
  }

  @override
  Future<List<dynamic>> fetchSoalForUjian(int ujianId) async {
    return soalResponse;
  }

  @override
  Future<List<dynamic>> fetchJawabanForSesi(int sesiId) async {
    return jawabanResponse;
  }

  @override
  Future<void> updateEssayGrade(
    int jawabanId,
    int nilai,
    String feedback,
  ) async {
    essayGrades.add({
      'jawabanId': jawabanId,
      'nilai': nilai,
      'feedback': feedback,
    });
  }

  @override
  Future<Map<String, dynamic>?> fetchUjianTampilkanNilaiStatus(
    int ujianId,
  ) async {
    return ujianTampilkanNilaiStatus;
  }

  @override
  Future<List<dynamic>> fetchRekapNilaiData(int ujianId) async {
    return rekapNilaiDataResponse;
  }

  @override
  Future<void> toggleTampilkanNilai(int ujianId, bool value) async {}

  @override
  Future<Map<String, dynamic>?> joinPengawasan(String kodePengawasan) async {
    return {'id': 1, 'judul_ujian': 'UTS', 'pin_mulai': '1234'};
  }

  @override
  Future<List<dynamic>> fetchPesertaUjian(int ujianId) async {
    return const [];
  }

  @override
  Future<Map<String, dynamic>?> getMahasiswaByNim(String nim) async {
    return null;
  }

  @override
  Future<void> updateSesiPengerjaanStatusToActive(int mahasiswaId, int ujianId) async {}

  @override
  RealtimeChannel getMonitoringChannel(int ujianId) {
    throw UnimplementedError();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Silence debug logs during tests
    DebugConfig.enableLogs = false;
  });

  group('DosenUjianController', () {
    test(
      'status ujian published berubah menjadi CLOSED jika sudah lewat waktu',
      () async {
        final now = DateTime.now();
        final service = FakeDosenUjianService(
          publishedExamsResponse: [
            {
              'id': 1,
              'judul_ujian': 'UTS',
              'status_ujian': 'PUBLISHED',
              'waktu_mulai': now
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
              'waktu_selesai': now
                  .subtract(const Duration(minutes: 1))
                  .toIso8601String(),
            },
          ],
        );
        final controller = DosenUjianController(service: service);

        await controller.fetchPublishedExams();

        expect(controller.publishedExams.first['status_ujian'], 'CLOSED');
        expect(service.updatedStatuses, hasLength(1));
        expect(service.updatedStatuses.first['status'], 'CLOSED');
      },
    );

    test(
      'monitoring live getter menggabungkan peserta ujian dan online state',
      () {
        final controller = DosenUjianController(
          service: FakeDosenUjianService(),
        );

        controller.debugSetMonitoringState(
          pesertaUjian: [
            {
              'status_pengerjaan': 'ACTIVE',
              'MAHASISWA': {'nama': 'Andi', 'nim': '123'},
            },
          ],
          onlineStudents: [
            {'nama': 'Andi', 'nim': '123', 'status': 'ONLINE', 'violations': 1},
            {'nama': 'Budi', 'nim': '456', 'status': 'ONLINE', 'violations': 0},
          ],
        );

        final result = controller.allMonitoringStudents;

        expect(result, hasLength(2));
        expect(result.first['nama'], 'Andi');
        expect(result.first['status_live'], 'ONLINE');
        expect(result.first['violations'], 1);
        expect(result.last['nim'], '456');
        expect(result.last['status_pengerjaan'], 'UNKNOWN');
      },
    );

    test('koreksi essai menolak nilai yang melebihi bobot maksimal', () async {
      final service = FakeDosenUjianService(
        soalResponse: [
          <String, dynamic>{
            'id': 10,
            'bobot_nilai': 10,
            'teks_soal': 'Jelaskan',
          },
        ],
        jawabanResponse: [
          <String, dynamic>{
            'id': 99,
            'soal_id': 10,
            'nilai': 0,
            'feedback': null,
          },
        ],
      );
      final controller = DosenUjianController(service: service);

      await controller.fetchDetailPengerjaan(1, 1);
      final result = await controller.updateEssayGrade(99, 15, 'terlalu besar');

      expect(result, isFalse);
      expect(service.essayGrades, isEmpty);
      expect(controller.detailPengerjaan.first['jawaban']['nilai'], 0);
    });

    test('koreksi essai berhasil jika nilai tidak melebihi bobot', () async {
      final service = FakeDosenUjianService(
        soalResponse: [
          <String, dynamic>{
            'id': 20,
            'bobot_nilai': 10,
            'teks_soal': 'Jelaskan',
          },
        ],
        jawabanResponse: [
          <String, dynamic>{
            'id': 199,
            'soal_id': 20,
            'nilai': 0,
            'feedback': null,
          },
        ],
      );
      final controller = DosenUjianController(service: service);

      await controller.fetchDetailPengerjaan(1, 1);
      final result = await controller.updateEssayGrade(199, 8, 'bagus');

      expect(result, isTrue);
      expect(service.essayGrades, hasLength(1));
      expect(controller.detailPengerjaan.first['jawaban']['nilai'], 8);
      expect(controller.detailPengerjaan.first['jawaban']['feedback'], 'bagus');
    });

    test('fetchRekapNilai menghitung statistik avg, max, dan passRate dengan benar',
        () async {
      final service = FakeDosenUjianService(
        ujianTampilkanNilaiStatus: {'tampilkan_nilai': true},
        rekapNilaiDataResponse: [
          // Mahasiswa A: PG=70, Essay=10 => total=80 (lulus, >= 70)
          {
            'MAHASISWA': {'nama': 'Andi', 'nim': '001'},
            'JAWABAN_MAHASISWA': [
              {'nilai': 70, 'soal': {'tipe_soal': 'pilihan_ganda'}},
              {'nilai': 10, 'soal': {'tipe_soal': 'essay'}},
            ],
          },
          // Mahasiswa B: PG=50, Essay=10 => total=60 (tidak lulus, < 70)
          {
            'MAHASISWA': {'nama': 'Budi', 'nim': '002'},
            'JAWABAN_MAHASISWA': [
              {'nilai': 50, 'soal': {'tipe_soal': 'pilihan_ganda'}},
              {'nilai': 10, 'soal': {'tipe_soal': 'essay'}},
            ],
          },
        ],
      );
      final controller = DosenUjianController(service: service);

      await controller.fetchRekapNilai(1);

      // Verifikasi data rekap
      expect(controller.rekapNilai, hasLength(2));
      expect(controller.rekapNilai.first['total'], 80);
      expect(controller.rekapNilai.first['isLulus'], isTrue);
      expect(controller.rekapNilai.last['total'], 60);
      expect(controller.rekapNilai.last['isLulus'], isFalse);

      // Verifikasi statistik: avg=(80+60)/2=70, max=80, passRate=1/2*100=50
      expect(controller.statsRekap['avg'], '70.0');
      expect(controller.statsRekap['max'], 80);
      expect(controller.statsRekap['passRate'], 50);

      // Verifikasi tampilkan_nilai
      expect(controller.isNilaiPublished, isTrue);
    });
  });
}
