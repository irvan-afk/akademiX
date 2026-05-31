abstract class LocalDbGateway {
  Future<void> saveUjianLokal(Map<String, dynamic> ujianData);

  Future<Map<String, dynamic>?> getLatestBankSoal({required int? dosenId});

  Future<Map<String, dynamic>?> getBankSoalByRemoteUjianId(int remoteUjianId);

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
  });

  Future<bool> updateBankSoalStatus(int id, String status);

  Future<void> saveSoalLokal(Map<String, dynamic> soal);

  Future<List<Map<String, dynamic>>> getSoalByUjian(int ujianId);

  Future<void> updateUjianStatusLokal(int ujianId, String status);

  Future<void> saveJawabanLokal(int soalId, int sesiId, String jawaban);

  Future<List<Map<String, dynamic>>> getJawabanBySesi(int sesiId);

  Future<void> clearAllLokalData();
}
