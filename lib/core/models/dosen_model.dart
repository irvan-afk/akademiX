class DosenModel {
  final int id;
  final int userId;
  final int jurusanId;
  final String nip;
  final String nama;

  DosenModel({
    required this.id,
    required this.userId,
    required this.jurusanId,
    required this.nip,
    required this.nama,
  });

  factory DosenModel.fromJson(Map<String, dynamic> json) {
    return DosenModel(
      id: json['id'],
      userId: json['user_id'],
      jurusanId: json['jurusan_id'],
      nip: json['nip'],
      nama: json['nama'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'jurusan_id': jurusanId,
      'nip': nip,
      'nama': nama,
    };
  }
}