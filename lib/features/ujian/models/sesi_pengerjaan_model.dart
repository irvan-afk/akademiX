import '../../../../core/constants/app_enums.dart';

class SesiPengerjaanModel {
  final int id;
  final int ujianId;
  final int mahasiswaId;
  final PengerjaanStatus statusPengerjaan;
  final DateTime waktuMulaiKlik;
  final DateTime? submittedAt;
  final DateTime? syncedAt;

  SesiPengerjaanModel({
    required this.id,
    required this.ujianId,
    required this.mahasiswaId,
    required this.statusPengerjaan,
    required this.waktuMulaiKlik,
    this.submittedAt,
    this.syncedAt,
  });

  factory SesiPengerjaanModel.fromJson(Map<String, dynamic> json) {
    return SesiPengerjaanModel(
      id: json['id'],
      ujianId: json['ujian_id'],
      mahasiswaId: json['mahasiswa_id'],
      statusPengerjaan: PengerjaanStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status_pengerjaan'].toString().toUpperCase(),
      ),
      waktuMulaiKlik: DateTime.parse(json['waktu_mulai_klik']),
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
    );
  }
}