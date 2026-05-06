import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/database/local_db_service.dart';
import '../models/bank_soal_draft_model.dart';

class BankSoalViewModel extends ChangeNotifier {
  final LocalDbService _localDbService = LocalDbService.instance;
  final SupabaseClient _supabase = supabase;

  bool _isLoading = false;
  String? _lastActionMessage;
  BankSoalDraftModel _draft = BankSoalDraftModel.empty();
  List<BankSoalPengampuOption> _pengampuOptions = [];

  bool get isLoading => _isLoading;
  String? get lastActionMessage => _lastActionMessage;
  BankSoalDraftModel get draft => _draft;
  int get totalPoin => _draft.totalPoin;
  List<BankSoalPengampuOption> get pengampuOptions => _pengampuOptions;

  bool get isReadyToPublish => _draft.canPublish;

  void resetDraft({int? dosenId}) {
    _draft = BankSoalDraftModel.empty(dosenId: dosenId);
    notifyListeners();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

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

      if (_draft.pengampuId == null && _pengampuOptions.length == 1) {
        selectPengampu(_pengampuOptions.first);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('BankSoalViewModel.loadPengampuForDosen error: $e');
    }
  }

  void selectPengampu(BankSoalPengampuOption pengampu) {
    _draft = _draft.copyWith(
      pengampuId: pengampu.id,
      pengampuLabel: pengampu.label,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> loadLatestDraft({int? dosenId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final latest = await _localDbService.getLatestBankSoalDraft(
        dosenId: dosenId,
      );

      if (latest == null) {
        _draft = BankSoalDraftModel.empty(dosenId: dosenId);
        return;
      }

      _draft = BankSoalDraftModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
    } catch (e) {
      debugPrint('BankSoalViewModel.loadLatestDraft error: $e');
      _draft = BankSoalDraftModel.empty(dosenId: dosenId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadDraftForRemoteUjian(int remoteUjianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final latest = await _localDbService.getBankSoalDraftByRemoteUjianId(
        remoteUjianId,
      );

      if (latest == null) {
        return false;
      }

      _draft = BankSoalDraftModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
      return true;
    } catch (e) {
      debugPrint('BankSoalViewModel.loadDraftForRemoteUjian error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setHeader({
    required int? pengampuId,
    required String? pengampuLabel,
    required String mataKuliah,
    required String judulUjian,
    required int durasiMenit,
    int? dosenId,
  }) {
    _draft = _draft.copyWith(
      dosenId: dosenId ?? _draft.dosenId,
      pengampuId: pengampuId ?? _draft.pengampuId,
      pengampuLabel: pengampuLabel ?? _draft.pengampuLabel,
      mataKuliah: mataKuliah,
      judulUjian: judulUjian,
      durasiMenit: durasiMenit,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addQuestion(BankSoalQuestionDraft question) {
    _draft = _draft.copyWith(
      questions: [..._draft.questions, question],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateQuestion(BankSoalQuestionDraft question) {
    final updatedQuestions = _draft.questions.map((item) {
      return item.localId == question.localId ? question : item;
    }).toList();

    _draft = _draft.copyWith(
      questions: updatedQuestions,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void removeQuestion(int localId) {
    _draft = _draft.copyWith(
      questions: _draft.questions
          .where((item) => item.localId != localId)
          .toList(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<bool> saveDraft() async {
    if (!_draft.hasValidHeader || _draft.questions.isEmpty) {
      _lastActionMessage = 'Lengkapi data ujian dan minimal 1 soal dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoalDraft(
        id: _draft.id,
        dosenId: _draft.dosenId,
        pengampuId: _draft.pengampuId,
        pengampuLabel: _draft.pengampuLabel,
        remoteUjianId: _draft.remoteUjianId,
        kodeUjian: _draft.kodeUjian,
        kodePengawasan: _draft.kodePengawasan,
        mataKuliah: _draft.mataKuliah,
        judulUjian: _draft.judulUjian,
        durasiMenit: _draft.durasiMenit,
        status: 'draft',
        soalList: _draft.toQuestionMaps(),
      );

      _draft = _draft.copyWith(
        id: savedId,
        status: 'draft',
        updatedAt: DateTime.now(),
      );

      final synced = await _syncToSupabase(publish: false);
      if (!synced) {
        _lastActionMessage =
            'Draft lokal tersimpan, tetapi sinkronisasi backend gagal.';
        return false;
      }

      // Update local draft with remoteUjianId from Supabase
      if (_draft.remoteUjianId != null && _draft.id != null) {
        await _localDbService.saveBankSoalDraft(
          id: _draft.id,
          dosenId: _draft.dosenId,
          pengampuId: _draft.pengampuId,
          pengampuLabel: _draft.pengampuLabel,
          remoteUjianId: _draft.remoteUjianId,
          kodeUjian: _draft.kodeUjian,
          kodePengawasan: _draft.kodePengawasan,
          mataKuliah: _draft.mataKuliah,
          judulUjian: _draft.judulUjian,
          durasiMenit: _draft.durasiMenit,
          status: 'draft',
          soalList: _draft.toQuestionMaps(),
        );
      }

      _lastActionMessage = 'Draft bank soal berhasil disimpan.';
      return true;
    } catch (e) {
      debugPrint('BankSoalViewModel.saveDraft error: $e');
      _lastActionMessage = 'Gagal menyimpan draft bank soal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> publishDraft() async {
    if (!_draft.canPublish) {
      _lastActionMessage = 'Total poin harus 100 dan soal harus lengkap dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoalDraft(
        id: _draft.id,
        dosenId: _draft.dosenId,
        pengampuId: _draft.pengampuId,
        pengampuLabel: _draft.pengampuLabel,
        remoteUjianId: _draft.remoteUjianId,
        kodeUjian: _draft.kodeUjian,
        kodePengawasan: _draft.kodePengawasan,
        mataKuliah: _draft.mataKuliah,
        judulUjian: _draft.judulUjian,
        durasiMenit: _draft.durasiMenit,
        status: 'published',
        soalList: _draft.toQuestionMaps(),
      );

      final updated = await _localDbService.updateBankSoalStatus(
        savedId,
        'published',
      );

      if (updated) {
        final synced = await _syncToSupabase(publish: true);
        if (!synced) {
          _lastActionMessage =
              'Draft lokal tersimpan, tetapi sinkronisasi backend gagal.';
          return false;
        }

        _draft = _draft.copyWith(
          id: savedId,
          status: 'published',
          updatedAt: DateTime.now(),
        );
        _lastActionMessage = 'Bank soal berhasil dipublish.';
        return true;
      }

      _lastActionMessage = 'Bank soal tersimpan, tetapi status belum berubah.';
      return false;
    } catch (e) {
      debugPrint('BankSoalViewModel.publishDraft error: $e');
      _lastActionMessage = 'Gagal mempublish bank soal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _syncToSupabase({required bool publish}) async {
    if (_draft.pengampuId == null) {
      _lastActionMessage = 'Isi atau pilih pengampu dulu sebelum sinkronisasi.';
      return false;
    }

    try {
      final now = DateTime.now();
      final selesai = now.add(Duration(minutes: _draft.durasiMenit));

      int? ujianId = _draft.remoteUjianId;

      if (ujianId == null) {
        final inserted = await _supabase
            .from('UJIAN')
            .insert({
              'pengampu_id': _draft.pengampuId,
              'judul_ujian': _draft.judulUjian,
              'waktu_mulai': now.toIso8601String(),
              'waktu_selesai': selesai.toIso8601String(),
              'durasi_menit': _draft.durasiMenit,
              'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
              'kode_ujian': publish ? _generateRandomCode() : null,
              'kode_pengawasan': publish ? _generateRandomCode() : null,
            })
            .select('id, kode_ujian, kode_pengawasan')
            .single();

        ujianId = inserted['id'] as int?;
        _draft = _draft.copyWith(
          remoteUjianId: ujianId,
          kodeUjian: inserted['kode_ujian']?.toString(),
          kodePengawasan: inserted['kode_pengawasan']?.toString(),
        );
      } else {
        final payload = <String, dynamic>{
          'pengampu_id': _draft.pengampuId,
          'judul_ujian': _draft.judulUjian,
          'waktu_mulai': now.toIso8601String(),
          'waktu_selesai': selesai.toIso8601String(),
          'durasi_menit': _draft.durasiMenit,
          'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
          'kode_ujian': publish
              ? _draft.kodeUjian ?? _generateRandomCode()
              : _draft.kodeUjian,
          'kode_pengawasan': publish
              ? _draft.kodePengawasan ?? _generateRandomCode()
              : _draft.kodePengawasan,
        };

        await _supabase.from('UJIAN').update(payload).eq('id', ujianId);
      }

      final savedUjianId = ujianId;
      if (savedUjianId == null) {
        return false;
      }

      await _supabase.from('soal').delete().eq('ujian_id', savedUjianId);

      final soalRows = _draft.questions.map((question) {
        return {
          'ujian_id': savedUjianId,
          'teks_soal': question.teksSoal,
          'tipe_soal': question.tipeSoal,
          'opsi_jawaban': question.opsiJawaban.isEmpty
              ? null
              : question.opsiJawaban,
          'bobot_nilai': question.poin,
          'kunci_jawaban': question.kunciJawaban,
        };
      }).toList();

      if (soalRows.isNotEmpty) {
        await _supabase.from('soal').insert(soalRows);
      }

      _draft = _draft.copyWith(remoteUjianId: savedUjianId);
      return true;
    } catch (e) {
      debugPrint('BankSoalViewModel._syncToSupabase error: $e');
      return false;
    }
  }

  /// Load a local draft by its remote UJIAN id and publish it using the
  /// same backend flow. Returns a map of tokens on success, or null.
  Future<Map<String, String>?> publishDraftForRemoteUjian(
    int remoteUjianId,
  ) async {
    try {
      final loaded = await loadDraftForRemoteUjian(remoteUjianId);
      if (!loaded) return null;

      final ok = await publishDraft();
      if (!ok) return null;

      return {
        'ujian': _draft.kodeUjian ?? '',
        'monitoring': _draft.kodePengawasan ?? '',
      };
    } catch (e) {
      debugPrint('BankSoalViewModel.publishDraftForRemoteUjian error: $e');
      return null;
    }
  }
}
