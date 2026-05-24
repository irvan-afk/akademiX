class BankSoalQuestionDraft {
  final int localId;
  final String tipeSoal;
  final String teksSoal;
  final Map<String, String> opsiJawaban;
  final String kunciJawaban;
  final int poin;
  final String? catatan;

  const BankSoalQuestionDraft({
    required this.localId,
    required this.tipeSoal,
    required this.teksSoal,
    required this.opsiJawaban,
    required this.kunciJawaban,
    required this.poin,
    this.catatan,
  });

  bool get isPilihanGanda => tipeSoal == 'pilihan_ganda';

  factory BankSoalQuestionDraft.fromMap(Map<String, dynamic> map) {
    final opsiRaw = map['opsi_jawaban'];
    final opsi = <String, String>{};

    if (opsiRaw is Map) {
      opsiRaw.forEach((key, value) {
        opsi[key.toString()] = value?.toString() ?? '';
      });
    }

    return BankSoalQuestionDraft(
      localId: map['local_id'] as int? ?? map['id'] as int? ?? 0,
      tipeSoal: (map['tipe_soal'] ?? '').toString(),
      teksSoal: (map['teks_soal'] ?? '').toString(),
      opsiJawaban: opsi,
      kunciJawaban: (map['kunci_jawaban'] ?? '').toString(),
      poin: (map['poin'] as num? ?? 0).toInt(),
      catatan: map['catatan']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'tipe_soal': tipeSoal,
      'teks_soal': teksSoal,
      'opsi_jawaban': opsiJawaban,
      'kunci_jawaban': kunciJawaban,
      'poin': poin,
      'catatan': catatan,
    };
  }

  BankSoalQuestionDraft copyWith({
    int? localId,
    String? tipeSoal,
    String? teksSoal,
    Map<String, String>? opsiJawaban,
    String? kunciJawaban,
    int? poin,
    String? catatan,
  }) {
    return BankSoalQuestionDraft(
      localId: localId ?? this.localId,
      tipeSoal: tipeSoal ?? this.tipeSoal,
      teksSoal: teksSoal ?? this.teksSoal,
      opsiJawaban: opsiJawaban ?? this.opsiJawaban,
      kunciJawaban: kunciJawaban ?? this.kunciJawaban,
      poin: poin ?? this.poin,
      catatan: catatan ?? this.catatan,
    );
  }
}

class BankSoalPengampuOption {
  final int id;
  final int mataKuliahId;
  final int kelasId;
  final String label;

  const BankSoalPengampuOption({
    required this.id,
    required this.mataKuliahId,
    required this.kelasId,
    required this.label,
  });

  factory BankSoalPengampuOption.fromJson(Map<String, dynamic> json) {
    final kelas = json['KELAS'];
    String kelasLabel = 'Kelas ${json['kelas_id'] ?? '-'}';

    if (kelas is Map<String, dynamic>) {
      final nama = kelas['nama']?.toString();
      final angkatan = kelas['angkatan']?.toString();
      final parts = <String>[];
      if (nama != null && nama.isNotEmpty) parts.add(nama);
      if (angkatan != null && angkatan.isNotEmpty)
        parts.add('Angkatan $angkatan');
      if (parts.isNotEmpty) {
        kelasLabel = parts.join(' • ');
      }
    }

    final mataKuliahId = json['mata_kuliah_id'] as int? ?? 0;
    final kelasId = json['kelas_id'] as int? ?? 0;

    return BankSoalPengampuOption(
      id: json['id'] as int? ?? 0,
      mataKuliahId: mataKuliahId,
      kelasId: kelasId,
      label: 'MK $mataKuliahId • $kelasLabel',
    );
  }
}

class BankSoalDraftModel {
  final int? id;
  final int? dosenId;
  final int? pengampuId;
  final String? pengampuLabel;
  final int? remoteUjianId;
  final String? kodeUjian;
  final String? kodePengawasan;
  final String? pinMulai;
  final String mataKuliah;
  final String judulUjian;
  final int durasiMenit;
  final DateTime? waktuMulai;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BankSoalQuestionDraft> questions;

  const BankSoalDraftModel({
    this.id,
    this.dosenId,
    this.pengampuId,
    this.pengampuLabel,
    this.remoteUjianId,
    this.kodeUjian,
    this.kodePengawasan,
    this.pinMulai,
    required this.mataKuliah,
    required this.judulUjian,
    required this.durasiMenit,
    this.waktuMulai,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.questions,
  });

  factory BankSoalDraftModel.empty({int? dosenId}) {
    final now = DateTime.now();
    return BankSoalDraftModel(
      id: null,
      dosenId: dosenId,
      pengampuId: null,
      pengampuLabel: null,
      remoteUjianId: null,
      kodeUjian: null,
      kodePengawasan: null,
      pinMulai: null,
      mataKuliah: '',
      judulUjian: '',
      durasiMenit: 0,
      waktuMulai: null,
      status: 'draft',
      createdAt: now,
      updatedAt: now,
      questions: const [],
    );
  }

  int get totalPoin => questions.fold(0, (sum, item) => sum + item.poin);

  bool get canPublish =>
      mataKuliah.trim().isNotEmpty &&
      judulUjian.trim().isNotEmpty &&
      durasiMenit > 0 &&
      pengampuId != null &&
      questions.isNotEmpty &&
      totalPoin == 100;

  bool get hasValidHeader =>
      mataKuliah.trim().isNotEmpty &&
      judulUjian.trim().isNotEmpty &&
      durasiMenit > 0;

  factory BankSoalDraftModel.fromMap(
    Map<String, dynamic> bankSoal,
    List<Map<String, dynamic>> soal,
  ) {
    return BankSoalDraftModel(
      id: bankSoal['id'] as int?,
      dosenId: bankSoal['dosen_id'] as int?,
      pengampuId: bankSoal['pengampu_id'] as int?,
      pengampuLabel: bankSoal['pengampu_label']?.toString(),
      remoteUjianId: bankSoal['remote_ujian_id'] as int?,
      kodeUjian: bankSoal['kode_ujian']?.toString(),
      kodePengawasan: bankSoal['kode_pengawasan']?.toString(),
      pinMulai: bankSoal['pin_mulai']?.toString(),
      mataKuliah: bankSoal['mata_kuliah']?.toString() ?? '',
      judulUjian: bankSoal['judul_ujian']?.toString() ?? '',
      durasiMenit: (bankSoal['durasi_menit'] as num? ?? 0).toInt(),
      waktuMulai: bankSoal['waktu_mulai'] != null 
          ? DateTime.tryParse(bankSoal['waktu_mulai'].toString()) 
          : null,
      status: bankSoal['status']?.toString() ?? 'draft',
      createdAt:
          DateTime.tryParse(bankSoal['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(bankSoal['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      questions: soal.map(BankSoalQuestionDraft.fromMap).toList(),
    );
  }

  Map<String, dynamic> toBankMap() {
    return {
      'id': id,
      'dosen_id': dosenId,
      'pengampu_id': pengampuId,
      'pengampu_label': pengampuLabel,
      'remote_ujian_id': remoteUjianId,
      'kode_ujian': kodeUjian,
      'kode_pengawasan': kodePengawasan,
      'pin_mulai': pinMulai,
      'mata_kuliah': mataKuliah,
      'judul_ujian': judulUjian,
      'durasi_menit': durasiMenit,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> toQuestionMaps() {
    return questions.map((item) => item.toMap()).toList();
  }

  BankSoalDraftModel copyWith({
    int? id,
    int? dosenId,
    int? pengampuId,
    String? pengampuLabel,
    int? remoteUjianId,
    String? kodeUjian,
    String? kodePengawasan,
    String? pinMulai,
    String? mataKuliah,
    String? judulUjian,
    int? durasiMenit,
    DateTime? waktuMulai,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BankSoalQuestionDraft>? questions,
  }) {
    return BankSoalDraftModel(
      id: id ?? this.id,
      dosenId: dosenId ?? this.dosenId,
      pengampuId: pengampuId ?? this.pengampuId,
      pengampuLabel: pengampuLabel ?? this.pengampuLabel,
      remoteUjianId: remoteUjianId ?? this.remoteUjianId,
      kodeUjian: kodeUjian ?? this.kodeUjian,
      kodePengawasan: kodePengawasan ?? this.kodePengawasan,
      pinMulai: pinMulai ?? this.pinMulai,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      judulUjian: judulUjian ?? this.judulUjian,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      waktuMulai: waktuMulai ?? this.waktuMulai,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questions: questions ?? this.questions,
    );
  }
}
