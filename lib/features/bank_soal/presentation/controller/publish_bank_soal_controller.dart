import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akademix/core/constants/supabase_constants.dart';
import 'package:akademix/core/database/local_db_service.dart';
import 'package:akademix/features/bank_soal/models/bank_soal_draft_model.dart';

/// Manages saving, publishing, and syncing bank soal drafts to backend
class PublishBankSoalController extends ChangeNotifier {
  final LocalDbService _localDbService = LocalDbService.instance;
  final SupabaseClient _supabase = supabase;

  bool _isLoading = false;
  String? _lastActionMessage;

  bool get isLoading => _isLoading;
  String? get lastActionMessage => _lastActionMessage;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<BankSoalDraftModel?> loadLatestDraft({int? dosenId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final latest = await _localDbService.getLatestBankSoalDraft(
        dosenId: dosenId,
      );

      if (latest == null) {
        return BankSoalDraftModel.empty(dosenId: dosenId);
      }

      return BankSoalDraftModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
    } catch (e) {
      debugPrint('PublishBankSoalController.loadLatestDraft error: $e');
      return BankSoalDraftModel.empty(dosenId: dosenId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BankSoalDraftModel?> loadDraftForRemoteUjian(int remoteUjianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final latest = await _localDbService.getBankSoalDraftByRemoteUjianId(
        remoteUjianId,
      );

      if (latest == null) {
        return null;
      }

      return BankSoalDraftModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
    } catch (e) {
      debugPrint('PublishBankSoalController.loadDraftForRemoteUjian error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDraft(BankSoalDraftModel draft) async {
    if (!draft.hasValidHeader || draft.questions.isEmpty) {
      _lastActionMessage = 'Lengkapi data ujian dan minimal 1 soal dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoalDraft(
        id: draft.id,
        dosenId: draft.dosenId,
        pengampuId: draft.pengampuId,
        pengampuLabel: draft.pengampuLabel,
        remoteUjianId: draft.remoteUjianId,
        kodeUjian: draft.kodeUjian,
        kodePengawasan: draft.kodePengawasan,
        mataKuliah: draft.mataKuliah,
        judulUjian: draft.judulUjian,
        durasiMenit: draft.durasiMenit,
        status: 'draft',
        soalList: draft.toQuestionMaps(),
      );

      final syncedDraft = draft.copyWith(
        id: savedId,
        status: 'draft',
        updatedAt: DateTime.now(),
      );

      final synced = await _syncToSupabase(syncedDraft, publish: false);
      if (!synced) {
        _lastActionMessage =
            'Draft lokal tersimpan, tetapi sinkronisasi backend gagal.';
        return false;
      }

      if (syncedDraft.remoteUjianId != null && syncedDraft.id != null) {
        await _localDbService.saveBankSoalDraft(
          id: syncedDraft.id,
          dosenId: syncedDraft.dosenId,
          pengampuId: syncedDraft.pengampuId,
          pengampuLabel: syncedDraft.pengampuLabel,
          remoteUjianId: syncedDraft.remoteUjianId,
          kodeUjian: syncedDraft.kodeUjian,
          kodePengawasan: syncedDraft.kodePengawasan,
          mataKuliah: syncedDraft.mataKuliah,
          judulUjian: syncedDraft.judulUjian,
          durasiMenit: syncedDraft.durasiMenit,
          status: 'draft',
          soalList: syncedDraft.toQuestionMaps(),
        );
      }

      _lastActionMessage = 'Draft bank soal berhasil disimpan.';
      return true;
    } catch (e) {
      debugPrint('PublishBankSoalController.saveDraft error: $e');
      _lastActionMessage = 'Gagal menyimpan draft bank soal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> publishDraft(BankSoalDraftModel draft) async {
    if (!draft.canPublish) {
      _lastActionMessage = 'Total poin harus 100 dan soal harus lengkap dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoalDraft(
        id: draft.id,
        dosenId: draft.dosenId,
        pengampuId: draft.pengampuId,
        pengampuLabel: draft.pengampuLabel,
        remoteUjianId: draft.remoteUjianId,
        kodeUjian: draft.kodeUjian,
        kodePengawasan: draft.kodePengawasan,
        mataKuliah: draft.mataKuliah,
        judulUjian: draft.judulUjian,
        durasiMenit: draft.durasiMenit,
        status: 'published',
        soalList: draft.toQuestionMaps(),
      );

      final updated = await _localDbService.updateBankSoalStatus(
        savedId,
        'published',
      );

      if (updated) {
        final publishedDraft = draft.copyWith(
          id: savedId,
          status: 'published',
          updatedAt: DateTime.now(),
        );

        final synced = await _syncToSupabase(publishedDraft, publish: true);
        if (!synced) {
          _lastActionMessage =
              'Draft lokal tersimpan, tetapi sinkronisasi backend gagal.';
          return false;
        }

        _lastActionMessage = 'Bank soal berhasil dipublish.';
        return true;
      }

      _lastActionMessage = 'Bank soal tersimpan, tetapi status belum berubah.';
      return false;
    } catch (e) {
      debugPrint('PublishBankSoalController.publishDraft error: $e');
      _lastActionMessage = 'Gagal mempublish bank soal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> publishDraftForRemoteUjian(
    int remoteUjianId,
    BankSoalDraftModel draft,
  ) async {
    try {
      final loaded = await loadDraftForRemoteUjian(remoteUjianId);
      if (loaded == null) return null;

      final ok = await publishDraft(loaded);
      if (!ok) return null;

      return {
        'ujian': loaded.kodeUjian ?? '',
        'monitoring': loaded.kodePengawasan ?? '',
      };
    } catch (e) {
      debugPrint(
        'PublishBankSoalController.publishDraftForRemoteUjian error: $e',
      );
      return null;
    }
  }

  Future<bool> _syncToSupabase(
    BankSoalDraftModel draft, {
    required bool publish,
  }) async {
    if (draft.pengampuId == null) {
      _lastActionMessage = 'Isi atau pilih pengampu dulu sebelum sinkronisasi.';
      return false;
    }

    try {
      final now = DateTime.now();
      final selesai = now.add(Duration(minutes: draft.durasiMenit));

      int? ujianId = draft.remoteUjianId;

      if (ujianId == null) {
        final inserted = await _supabase
            .from('UJIAN')
            .insert({
              'pengampu_id': draft.pengampuId,
              'judul_ujian': draft.judulUjian,
              'waktu_mulai': now.toIso8601String(),
              'waktu_selesai': selesai.toIso8601String(),
              'durasi_menit': draft.durasiMenit,
              'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
              'kode_ujian': publish ? _generateRandomCode() : null,
              'kode_pengawasan': publish ? _generateRandomCode() : null,
            })
            .select('id, kode_ujian, kode_pengawasan')
            .single();

        ujianId = inserted['id'] as int?;
      } else {
        final payload = <String, dynamic>{
          'pengampu_id': draft.pengampuId,
          'judul_ujian': draft.judulUjian,
          'waktu_mulai': now.toIso8601String(),
          'waktu_selesai': selesai.toIso8601String(),
          'durasi_menit': draft.durasiMenit,
          'status_ujian': publish ? 'PUBLISHED' : 'DRAFT',
          'kode_ujian': publish
              ? draft.kodeUjian ?? _generateRandomCode()
              : draft.kodeUjian,
          'kode_pengawasan': publish
              ? draft.kodePengawasan ?? _generateRandomCode()
              : draft.kodePengawasan,
        };

        await _supabase.from('UJIAN').update(payload).eq('id', ujianId);
      }

      final savedUjianId = ujianId;
      if (savedUjianId == null) {
        return false;
      }

      await _supabase.from('soal').delete().eq('ujian_id', savedUjianId);

      final soalRows = draft.questions.map((question) {
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

      return true;
    } catch (e) {
      debugPrint('PublishBankSoalController._syncToSupabase error: $e');
      return false;
    }
  }
}
