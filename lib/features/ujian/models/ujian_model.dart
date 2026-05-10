import '../../../../core/constants/app_enums.dart';
import 'soal_model.dart';

class UjianModel {
  final int id;
  final int pengampuId;
  final String judulUjian;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;
  final int durasiMenit;
  final UjianStatus statusUjian;
  final String? kodeUjian;
  final String? kodePengawasan;
  final String? pinMulai;
  final List<SoalModel>? daftarSoal;

  UjianModel({
    required this.id,
    required this.pengampuId,
    required this.judulUjian,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.durasiMenit,
    required this.statusUjian,
    this.kodeUjian,
    this.kodePengawasan,
    this.pinMulai,
    this.daftarSoal,
  });

  factory UjianModel.fromJson(Map<String, dynamic> json) {
    return UjianModel(
      id: json['id'],
      pengampuId: json['pengampu_id'],
      judulUjian: json['judul_ujian'],
      waktuMulai: DateTime.parse(json['waktu_mulai']),
      waktuSelesai: DateTime.parse(json['waktu_selesai']),
      durasiMenit: json['durasi_menit'],
      statusUjian: UjianStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            json['status_ujian'].toString().toUpperCase(),
      ),
      kodeUjian: json['kode_ujian'],
      kodePengawasan: json['kode_pengawasan'],
      pinMulai: json['pin_mulai'],
      daftarSoal: json['soal'] != null
          ? (json['soal'] as List).map((i) => SoalModel.fromJson(i)).toList()
          : null,
    );
  }
}
