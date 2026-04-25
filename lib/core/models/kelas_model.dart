class KelasModel {
  final int id;
  final int prodiId;
  final String nama;
  final String angkatan;

  KelasModel({required this.id, required this.prodiId, required this.nama, required this.angkatan});

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['id'],
      prodiId: json['prodi_id'],
      nama: json['nama'],
      angkatan: json['angkatan'],
    );
  }
}