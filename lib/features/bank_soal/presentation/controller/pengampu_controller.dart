import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akademix/core/constants/supabase_constants.dart';

class BankSoalPengampuOption {
  final int id;
  final int mataKuliahId;
  final int kelasId;
  final String label;

  BankSoalPengampuOption({
    required this.id,
    required this.mataKuliahId,
    required this.kelasId,
    required this.label,
  });
}

/// Manages pengampu (class) selection for exam creation
class PengampuController extends ChangeNotifier {
  final SupabaseClient _supabase = supabase;

  List<BankSoalPengampuOption> _pengampuOptions = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<BankSoalPengampuOption> get pengampuOptions => _pengampuOptions;

  String _buildPengampuLabel(Map<String, dynamic> item) {
    final kelas = item['KELAS'];
    final kelasLabel = kelas is Map<String, dynamic>
        ? [
            kelas['nama']?.toString(),
            kelas['angkatan']?.toString() == null
                ? null
                : 'Angkatan ${kelas['angkatan']}',
          ].whereType<String>().where((v) => v.isNotEmpty).join(' • ')
        : 'Kelas ${item['kelas_id'] ?? '-'}';

    return 'MK ${item['mata_kuliah_id'] ?? '-'} • $kelasLabel';
  }

  Future<void> loadPengampuForDosen(int dosenId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('PENGAMPU')
          .select('id, mata_kuliah_id, kelas_id, KELAS(nama, angkatan)')
          .eq('dosen_id', dosenId)
          .order('id', ascending: false);

      _pengampuOptions = (response as List).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return BankSoalPengampuOption(
          id: map['id'] as int? ?? 0,
          mataKuliahId: map['mata_kuliah_id'] as int? ?? 0,
          kelasId: map['kelas_id'] as int? ?? 0,
          label: _buildPengampuLabel(map),
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('PengampuController.loadPengampuForDosen error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
