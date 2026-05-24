import 'package:flutter/material.dart';
import 'package:akademix/features/ujian/presentation/controller/mahasiswa_ujian_controller.dart';

/// Controller untuk handle logic join ujian
class JoinUjianController extends ChangeNotifier {
  final MahasiswaUjianViewModel mahasiswaUjianVm;

  bool _isLoading = false;
  String? _errorMessage;

  JoinUjianController(this.mahasiswaUjianVm);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Join ujian dengan kode dan mahasiswa ID
  /// Returns ujian ID jika sukses, null jika gagal
  Future<int?> joinExam(String code, int mahasiswaId) async {
    if (code.trim().isEmpty) {
      _errorMessage = "Kode tidak boleh kosong";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ujian = await mahasiswaUjianVm.joinUjian(code, mahasiswaId);

      _isLoading = false;
      if (ujian != null) {
        _errorMessage = null;
        notifyListeners();
        return ujian.id;
      } else {
        _errorMessage = "Kode ujian salah atau belum aktif";
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;

      if (e.toString().contains('UJIAN_SUDAH_DIKERJAKAN')) {
        _errorMessage = "Anda sudah menyelesaikan ujian ini";
      } else {
        _errorMessage = "Terjadi kesalahan: $e";
        debugPrint('JoinUjianController.joinExam error: $e');
      }

      notifyListeners();
      return null;
    }
  }
}
