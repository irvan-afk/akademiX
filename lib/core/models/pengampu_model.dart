class PengampuModel {
  final int id;
  final int dosenId;
  final int mataKuliahId;
  final int kelasId;

  PengampuModel({required this.id, required this.dosenId, required this.mataKuliahId, required this.kelasId});

  factory PengampuModel.fromJson(Map<String, dynamic> json) {
    return PengampuModel(
      id: json['id'],
      dosenId: json['dosen_id'],
      mataKuliahId: json['mata_kuliah_id'],
      kelasId: json['kelas_id'],
    );
  }
}