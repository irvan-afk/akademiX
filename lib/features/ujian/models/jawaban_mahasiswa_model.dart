class JawabanMahasiswaModel {
  final int id;
  final int sesiPengerjaanId;
  final int soalId;
  final String? jawabanTeks;
  final DateTime lastUpdatedLocal;
  final Map<String, dynamic>? logForensik;

  JawabanMahasiswaModel({
    required this.id,
    required this.sesiPengerjaanId,
    required this.soalId,
    this.jawabanTeks,
    required this.lastUpdatedLocal,
    this.logForensik,
  });

  factory JawabanMahasiswaModel.fromJson(Map<String, dynamic> json) {
    return JawabanMahasiswaModel(
      id: json['id'],
      sesiPengerjaanId: json['sesi_pengerjaan_id'],
      soalId: json['soal_id'],
      jawabanTeks: json['jawaban_teks'],
      lastUpdatedLocal: DateTime.parse(json['last_updated_local']),
      logForensik: json['log_forensik'] != null ? json['log_forensik'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sesi_pengerjaan_id': sesiPengerjaanId,
      'soal_id': soalId,
      'jawaban_teks': jawabanTeks,
      'last_updated_local': lastUpdatedLocal.toIso8601String(),
      'log_forensik': logForensik,
    };
  }
}