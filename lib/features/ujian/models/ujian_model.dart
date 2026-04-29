import '../../../../core/constants/app_enums.dart';
import 'soal_model.dart'; // Import model relasinya

class UjianModel {
  final int id;
  final int pengampuId;
  final String judulUjian;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;
  final int durasiMenit;
  final UjianStatus statusUjian;
  
  // Relasi (Opsional, tergantung apakah API mengembalikan data ini sekaligus)
  final List<SoalModel>? daftarSoal; 

  UjianModel({
    required this.id,
    required this.pengampuId,
    required this.judulUjian,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.durasiMenit,
    required this.statusUjian,
    this.daftarSoal,
  });

  factory UjianModel.fromJson(Map<String, dynamic> json) {
    return UjianModel(
      id: json['id'],
      pengampuId: json['pengampu_id'],
      judulUjian: json['judul_ujian'],
      // Parse string tanggal dari database menjadi DateTime Dart
      waktuMulai: DateTime.parse(json['waktu_mulai']),
      waktuSelesai: DateTime.parse(json['waktu_selesai']),
      durasiMenit: json['durasi_menit'],
      statusUjian: UjianStatus.values.firstWhere(
          (e) => e.name.toUpperCase() == json['status_ujian'].toString().toUpperCase()),
      
      // Mapping relasi array JSON ke List of Objects
      daftarSoal: json['soal'] != null 
          ? (json['soal'] as List).map((i) => SoalModel.fromJson(i)).toList() 
          : null,
    );
  }
}