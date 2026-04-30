import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ujian_model.dart';

class UjianViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }

  // Fetch semua ujian (DRAFT + PUBLISHED) untuk dosen
  Future<List<UjianModel>> fetchAllUjianForDosen(int dosenId) async {
    try {
      // Query DRAFT exams
      final draftResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'DRAFT')
          .eq('PENGAMPU.dosen_id', dosenId);

      // Query PUBLISHED exams
      final publishedResponse = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'PUBLISHED')
          .eq('PENGAMPU.dosen_id', dosenId);

      // Combine results
      final allResponses = [...draftResponse, ...publishedResponse];

      debugPrint("Ditemukan ${allResponses.length} ujian (DRAFT + PUBLISHED)");
      return (allResponses as List).map((e) => UjianModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch All Ujian: $e");
      return [];
    }
  }

  // Legacy method: Fetch hanya DRAFT (untuk backward compatibility)
  Future<List<UjianModel>> fetchDraftUjian(int dosenId) async {
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('*, PENGAMPU!inner(dosen_id)')
          .eq('status_ujian', 'DRAFT')
          .eq('PENGAMPU.dosen_id', dosenId);

      debugPrint("Data draf ditemukan: ${response.length} baris");
      return (response as List).map((e) => UjianModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error Fetch Draft: $e");
      return [];
    }
  }

  // UPDATE: Nama tabel diganti jadi UJIAN (Capital)
  Future<Map<String, String>?> publishUjian(int ujianId) async {
    _isLoading = true;
    notifyListeners();

    final tokenUjian = _generateRandomCode();
    final tokenMonitor = _generateRandomCode();

    try {
      await _supabase
          .from('UJIAN') // Diubah jadi Kapital
          .update({
            'kode_ujian': tokenUjian,
            'kode_pengawasan': tokenMonitor,
            'status_ujian':
                'PUBLISHED', // Fixed: Changed to uppercase 'PUBLISHED' (enum value in DB)
          })
          .eq('id', ujianId);

      debugPrint("Ujian berhasil dipublish dengan kode: $tokenUjian");
      return {'ujian': tokenUjian, 'monitoring': tokenMonitor};
    } catch (e) {
      debugPrint("Error Publish: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
