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
  final String? statusLokal;
  final bool tampilkanNilai;
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
    this.statusLokal,
    this.tampilkanNilai = false,
    this.daftarSoal,
  });

  factory UjianModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final parsed = value == null ? null : DateTime.tryParse(value.toString());
      return (parsed ?? DateTime.now()).toLocal();
    }

    return UjianModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      pengampuId: (json['pengampu_id'] as num?)?.toInt() ?? 0,
      judulUjian: json['judul_ujian']?.toString() ?? '',
      waktuMulai: parseDate(json['waktu_mulai']),
      waktuSelesai: parseDate(json['waktu_selesai']),
      durasiMenit: (json['durasi_menit'] as num?)?.toInt() ?? 0,
      statusUjian: UjianStatus.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            json['status_ujian'].toString().toUpperCase(),
        orElse: () => UjianStatus.draft,
      ),
      kodeUjian: json['kode_ujian']?.toString(),
      kodePengawasan: json['kode_pengawasan']?.toString(),
      pinMulai: json['pin_mulai']?.toString(),
      statusLokal: json['status_lokal']?.toString(),
      tampilkanNilai:
          json['tampilkan_nilai'] == true ||
          json['tampilkan_nilai']?.toString().toLowerCase() == 'true',
      daftarSoal: json['soal'] != null
          ? (json['soal'] as List).map((i) => SoalModel.fromJson(i)).toList()
          : null,
    );
  }
}
