import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akademix/features/ujian/view_models/mahasiswa_ujian_view_model.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  late MahasiswaUjianViewModel viewModel;

  setUp(() {
    viewModel = MahasiswaUjianViewModel();
  });

  group('MahasiswaUjianViewModel Unit Test', () {
    test('Status awal harus idle', () {
      expect(viewModel.status, SubmissionStatus.idle);
    });

    test('simpanJawaban harus memperbarui map jawaban di memory', () async {
      const int soalId = 1;
      const String jawaban = "Jawaban Test";
      await viewModel.simpanJawaban(soalId, jawaban);
      expect(viewModel.getJawabanTerpilih(soalId), jawaban);
    });

    test('submitUjian gagal jika currentSesiId null', () async {
      expect(viewModel.currentSesiId, isNull);
      await viewModel.submitUjian();
      expect(viewModel.status, SubmissionStatus.idle);
    });

    test('Format Timer harus benar (HH:MM:SS)', () {
      expect(viewModel.timerString, "02:00:00");
    });

    test('Toggle ragu-ragu harus berfungsi', () {
      const int soalId = 10;
      expect(viewModel.isRagu(soalId), false);
      viewModel.toggleRagu(soalId);
      expect(viewModel.isRagu(soalId), true);
      viewModel.toggleRagu(soalId);
      expect(viewModel.isRagu(soalId), false);
    });
  });

  test(
    'Data jawaban tidak boleh hilang dari memory saat pengiriman gagal',
    () async {
      const int soalId = 99;
      const String jawabanKu = "Jawaban Penting";

      await viewModel.joinUjian("KODE123", 5);

      await viewModel.simpanJawaban(soalId, jawabanKu);
      await viewModel.submitUjian();

      expect(viewModel.getJawabanTerpilih(soalId), jawabanKu);
    },
  );
}
