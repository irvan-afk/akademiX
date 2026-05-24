import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ujian_model.dart';

class PublishExamController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<UjianModel> _allUjianDosen = [];
  List<UjianModel> get allUjianDosen => _allUjianDosen;

  // --- UTILITY ---
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  // --- FETCH UJIAN DOSEN ---
  Future<void> fetchUjianForDosen(int dosenId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('PENGAMPU.dosen_id', dosenId)
          .order('id', ascending: false);

      _allUjianDosen = (response as List)
          .map((e) => UjianModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("Error Fetch Ujian Dosen: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PUBLISH UJIAN ---
  Future<Map<String, String>?> publishUjian(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    final tokenUjian = _generateRandomCode();
    final tokenMonitor = _generateRandomCode();
    final pinMulai = (1000 + Random().nextInt(9000)).toString(); // 4 digit PIN

    try {
      await _supabase
          .from('UJIAN')
          .update({
            'kode_ujian': tokenUjian,
            'kode_pengawasan': tokenMonitor,
            'pin_mulai': pinMulai,
            'status_ujian': 'PUBLISHED',
          })
          .eq('id', ujianId);

      return {'ujian': tokenUjian, 'monitoring': tokenMonitor, 'pin': pinMulai};
    } catch (e) {
      debugPrint("Error Publish: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
