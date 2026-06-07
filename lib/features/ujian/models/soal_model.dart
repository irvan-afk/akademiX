import 'package:flutter/foundation.dart';
import 'package:akademix/core/config/debug_config.dart';

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
    try {
      final tipeSoalValue = json['tipe_soal'] ?? json['tipeSoal'];
      if (DebugConfig.enableLogs && kDebugMode) {
        // concise and clear debug message
        // tipeSoalValue may be null
        debugPrint('SoalModel.fromJson: tipe_soal raw="${tipeSoalValue}"');
      }
      String normalizedTipeSoal = '';
      if (tipeSoalValue != null) {
        normalizedTipeSoal = tipeSoalValue.toString().toLowerCase().trim();
        // normalized tipe_soal computed
        if (DebugConfig.enableLogs && kDebugMode) {
          debugPrint(
            'SoalModel.fromJson: normalized tipe_soal="$normalizedTipeSoal"',
          );
        }
      }

      Map<String, dynamic> opsi = {};
      final opsiRaw = json['opsi_jawaban'] ?? json['opsiJawaban'];
      if (opsiRaw != null && opsiRaw is Map) {
        try {
          opsi = Map<String, dynamic>.from(opsiRaw);
        } catch (e) {
          opsi = {};
        }
      }

      return SoalModel(
        id: json['id'] as int? ?? 0,
        ujianId: json['ujian_id'] as int? ?? 0,
        teksSoal:
            json['teks_soal'] as String? ?? json['teksSoal'] as String? ?? '',
        tipeSoal: normalizedTipeSoal,
        opsiJawaban: opsi,
        bobotNilai:
            json['bobot_nilai'] as int? ?? json['bobotNilai'] as int? ?? 0,
        kunciJawaban:
            json['kunci_jawaban'] as String? ??
            json['kunciJawaban'] as String? ??
            '',
      );
    } catch (e) {
      if (DebugConfig.enableLogs && kDebugMode) {
        debugPrint('SoalModel.fromJson error: $e');
      }
      rethrow;
    }
  }
}
