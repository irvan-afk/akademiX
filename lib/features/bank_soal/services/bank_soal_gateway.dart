import '../models/bank_soal_model.dart';

abstract class BankSoalGateway {
  Future<List<Map<String, dynamic>>> getPengampuForDosen(int dosenId);

  Future<Map<String, dynamic>> upsertUjian({
    required int? ujianId,
    required BankSoalModel draft,
    required bool publish,
    required DateTime waktuMulai,
    required DateTime waktuSelesai,
  });

  Future<void> replaceSoalForUjian(
    int ujianId,
    List<Map<String, dynamic>> soalRows,
  );
}
