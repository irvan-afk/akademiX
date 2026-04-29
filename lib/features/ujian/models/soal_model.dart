class SoalModel {
  final int id;
  final int ujianId;
  final String teksSoal;
  final String tipeSoal;
  final Map<String, dynamic> opsiJawaban; // json ditangkap sebagai Map
  final int bobotNilai;
  final String kunciJawaban;

  SoalModel({
    required this.id,
    required this.ujianId,
    required this.teksSoal,
    required this.tipeSoal,
    required this.opsiJawaban,
    required this.bobotNilai,
    required this.kunciJawaban,
  });

  factory SoalModel.fromJson(Map<String, dynamic> json) {
    return SoalModel(
      id: json['id'],
      ujianId: json['ujian_id'],
      teksSoal: json['teks_soal'],
      tipeSoal: json['tipe_soal'],
      opsiJawaban: json['opsi_jawaban'] as Map<String, dynamic>,
      bobotNilai: json['bobot_nilai'],
      kunciJawaban: json['kunci_jawaban'],
    );
  }
}