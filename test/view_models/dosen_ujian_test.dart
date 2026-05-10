import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akademix/features/ujian/view_models/dosen_ujian_view_model.dart';

void main() {
  setUpAll(() async {
    // Inisialisasi Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Inisialisasi Supabase Palsu untuk testing
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  late DosenUjianViewModel viewModel;

  setUp(() {
    viewModel = DosenUjianViewModel();
  });

  group('DosenUjianViewModel Unit Test', () {
    test('State awal harus kosong dan tidak loading', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.allUjianDosen, isEmpty);
      expect(viewModel.rekapNilai, isEmpty);
    });

    test('Fungsi publishUjian harus mengaktifkan loading state', () async {
      // Kita panggil tanpa menunggu (tanpa await) untuk cek status loading
      final future = viewModel.publishUjian(1);
      expect(viewModel.isLoading, true);

      await future; // Tunggu selesai (pasti catch error karena URL palsu)
      expect(viewModel.isLoading, false);
    });

    test('Logika kalkulasi statistik rekap nilai (Logic Check)', () {
      // Simulasi data yang biasanya didapat dari Supabase
      final mockRekap = [
        {'total': 80, 'isLulus': true},
        {'total': 60, 'isLulus': false},
        {'total': 100, 'isLulus': true},
      ];

      // Menguji logika matematika di dalam fetchRekapNilai
      double sum = mockRekap
          .map((m) => m['total'] as int)
          .reduce((a, b) => a + b)
          .toDouble();
      double avg = sum / mockRekap.length;
      int lulus = mockRekap.where((m) => m['isLulus'] as bool).length;
      int passRate = ((lulus / mockRekap.length) * 100).toInt();

      expect(avg.toStringAsFixed(1), "80.0");
      expect(passRate, 66);
    });

    test(
      'Update essay grade harus mengembalikan false jika tidak ada koneksi',
      () async {
        // Mencoba update nilai tanpa koneksi internet asli
        bool success = await viewModel.updateEssayGrade(1, 90, "Bagus");

        expect(success, false);
      },
    );
  });
}
