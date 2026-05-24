import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonitoringController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RealtimeChannel? _monitoringChannel;
  List<Map<String, dynamic>> _onlineStudents = [];
  List<Map<String, dynamic>> get onlineStudents => _onlineStudents;

  // --- JOIN PENGAWASAN ---
  Future<Map<String, dynamic>?> joinPengawasan(String kodePengawasan) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('UJIAN')
          .select('id, judul_ujian, pin_mulai')
          .eq('kode_pengawasan', kodePengawasan)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint("Error Join Pengawasan: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- START MONITORING ---
  void startMonitoring(int ujianId) {
    if (_monitoringChannel != null) return;
    _monitoringChannel = _supabase.channel('exam_monitoring_$ujianId');
    _monitoringChannel!.onPresenceSync((payload) {
      final newState = _monitoringChannel!.presenceState();
      List<Map<String, dynamic>> currentOnline = [];

      for (final state in newState) {
        for (final presence in state.presences) {
          currentOnline.add({
            'nama': presence.payload['nama'],
            'nim': presence.payload['nim'],
            'status': presence.payload['status'],
          });
        }
      }
      _onlineStudents = currentOnline;
      notifyListeners();
    }).subscribe();
  }

  // --- STOP MONITORING ---
  void stopMonitoring() {
    _monitoringChannel?.unsubscribe();
    _monitoringChannel = null;
    _onlineStudents.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
