class MahasiswaModel {
  final int id;
  final int userId;
  final int kelasId;
  final String nim;
  final String nama;

  MahasiswaModel({
    required this.id,
    required this.userId,
    required this.kelasId,
    required this.nim,
    required this.nama,
  });

  // Pemetaan dari JSON (Supabase/Hive) ke Objek Dart
  factory MahasiswaModel.fromJson(Map<String, dynamic> json) {
    return MahasiswaModel(
      id: json['id'],
      userId: json['user_id'], // Mapping dari snake_case [cite: 203]
      kelasId: json['kelas_id'],
      nim: json['nim'],
      nama: json['nama'],
    );
  }

  // Pemetaan dari Objek Dart ke JSON (untuk Simpan ke Hive/Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kelas_id': kelasId,
      'nim': nim,
      'nama': nama,
    };
  }
}