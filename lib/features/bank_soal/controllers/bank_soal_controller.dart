import 'package:flutter/foundation.dart';
import '../../../core/database/local_db_service.dart';
import '../models/bank_soal_model.dart';
import '../services/bank_soal_service.dart';

class BankSoalController extends ChangeNotifier {
  final LocalDbService _localDbService = LocalDbService.instance;
  final BankSoalService _bankSoalService = BankSoalService();

  bool _isLoading = false;
  String? _lastActionMessage;
  BankSoalModel _draft = BankSoalModel.empty();
  List<BankSoalPengampuOption> _pengampuOptions = [];

  bool get isLoading => _isLoading;
  String? get lastActionMessage => _lastActionMessage;
  BankSoalModel get draft => _draft;
  int get totalPoin => _draft.totalPoin;
  List<BankSoalPengampuOption> get pengampuOptions => _pengampuOptions;

  bool get isReadyToPublish => _draft.canPublish;

  void resetDraft({int? dosenId}) {
    _draft = BankSoalModel.empty(dosenId: dosenId);
    notifyListeners();
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

    final namaMk = item['MATA_KULIAH']?['nama'] ?? 'MK ${item['mata_kuliah_id']}';
    return '$namaMk • $kelasLabel';
  }

  Future<void> loadPengampuForDosen(int dosenId) async {
    try {
      final response = await _bankSoalService.getPengampuForDosen(dosenId);

      _pengampuOptions = response.map((map) {
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
      debugPrint('BankSoalController.loadPengampuForDosen error: $e');
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
      final latest = await _localDbService.getLatestBankSoal(
        dosenId: dosenId,
      );

      if (latest == null) {
        _draft = BankSoalModel.empty(dosenId: dosenId);
        return;
      }

      _draft = BankSoalModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
    } catch (e) {
      debugPrint('BankSoalController.loadLatestDraft error: $e');
      _draft = BankSoalModel.empty(dosenId: dosenId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadDraftForRemoteUjian(int remoteUjianId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final latest = await _localDbService.getBankSoalByRemoteUjianId(
        remoteUjianId,
      );

      if (latest == null) {
        return false;
      }

      _draft = BankSoalModel.fromMap(
        Map<String, dynamic>.from(latest['bank_soal'] as Map),
        List<Map<String, dynamic>>.from(latest['soal'] as List),
      );
      return true;
    } catch (e) {
      debugPrint('BankSoalController.loadDraftForRemoteUjian error: $e');
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
    DateTime? waktuMulai,
    int? dosenId,
  }) {
    _draft = _draft.copyWith(
      dosenId: dosenId ?? _draft.dosenId,
      pengampuId: pengampuId ?? _draft.pengampuId,
      pengampuLabel: pengampuLabel ?? _draft.pengampuLabel,
      mataKuliah: mataKuliah,
      judulUjian: judulUjian,
      durasiMenit: durasiMenit,
      waktuMulai: waktuMulai ?? _draft.waktuMulai,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addQuestion(BankSoalQuestionModel question) {
    _draft = _draft.copyWith(
      questions: [..._draft.questions, question],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateQuestion(BankSoalQuestionModel question) {
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

  Future<bool> saveBankSoal() async {
    if (!_draft.hasValidHeader || _draft.questions.isEmpty) {
      _lastActionMessage = 'Lengkapi data ujian dan minimal 1 soal dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoal(
        id: _draft.id,
        dosenId: _draft.dosenId,
        pengampuId: _draft.pengampuId,
        pengampuLabel: _draft.pengampuLabel,
        remoteUjianId: _draft.remoteUjianId,
        kodeUjian: _draft.kodeUjian,
        kodePengawasan: _draft.kodePengawasan,
        pinMulai: _draft.pinMulai,
        mataKuliah: _draft.mataKuliah,
        judulUjian: _draft.judulUjian,
        durasiMenit: _draft.durasiMenit,
        waktuMulai: _draft.waktuMulai,
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

      if (_draft.remoteUjianId != null && _draft.id != null) {
        await _localDbService.saveBankSoal(
          id: _draft.id,
          dosenId: _draft.dosenId,
          pengampuId: _draft.pengampuId,
          pengampuLabel: _draft.pengampuLabel,
          remoteUjianId: _draft.remoteUjianId,
          kodeUjian: _draft.kodeUjian,
          kodePengawasan: _draft.kodePengawasan,
          pinMulai: _draft.pinMulai,
          mataKuliah: _draft.mataKuliah,
          judulUjian: _draft.judulUjian,
          durasiMenit: _draft.durasiMenit,
          waktuMulai: _draft.waktuMulai,
          status: 'draft',
          soalList: _draft.toQuestionMaps(),
        );
      }

      _lastActionMessage = 'Draft bank soal berhasil disimpan.';
      return true;
    } catch (e) {
      debugPrint('BankSoalController.saveBankSoal error: $e');
      _lastActionMessage = 'Gagal menyimpan draft bank soal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> publishBankSoal() async {
    if (!_draft.canPublish) {
      _lastActionMessage = 'Total poin harus 100 dan soal harus lengkap dulu.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final savedId = await _localDbService.saveBankSoal(
        id: _draft.id,
        dosenId: _draft.dosenId,
        pengampuId: _draft.pengampuId,
        pengampuLabel: _draft.pengampuLabel,
        remoteUjianId: _draft.remoteUjianId,
        kodeUjian: _draft.kodeUjian,
        kodePengawasan: _draft.kodePengawasan,
        pinMulai: _draft.pinMulai,
        mataKuliah: _draft.mataKuliah,
        judulUjian: _draft.judulUjian,
        durasiMenit: _draft.durasiMenit,
        waktuMulai: _draft.waktuMulai,
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
      debugPrint('BankSoalController.publishBankSoal error: $e');
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
      final waktuMulai = _draft.waktuMulai ?? DateTime.now();
      final waktuSelesai = waktuMulai.add(Duration(minutes: _draft.durasiMenit));

      final result = await _bankSoalService.upsertUjian(
        ujianId: _draft.remoteUjianId,
        draft: _draft,
        publish: publish,
        waktuMulai: waktuMulai,
        waktuSelesai: waktuSelesai,
      );

      final savedUjianId = result['id'] as int?;
      if (savedUjianId == null) return false;

      _draft = _draft.copyWith(
        remoteUjianId: savedUjianId,
        kodeUjian: result['kode_ujian']?.toString(),
        kodePengawasan: result['kode_pengawasan']?.toString(),
        pinMulai: result['pin_mulai']?.toString(),
      );

      final soalRows = _draft.questions.map((question) {
        return {
          'ujian_id': savedUjianId,
          'teks_soal': question.teksSoal,
          'tipe_soal': question.tipeSoal,
          'opsi_jawaban': question.opsiJawaban.isEmpty ? null : question.opsiJawaban,
          'bobot_nilai': question.poin,
          'kunci_jawaban': question.kunciJawaban,
        };
      }).toList();

      await _bankSoalService.replaceSoalForUjian(savedUjianId, soalRows);
      
      return true;
    } catch (e) {
      debugPrint('BankSoalController._syncToSupabase error: $e');
      return false;
    }
  }

  Future<Map<String, String>?> publishBankSoalForRemoteUjian(
    int remoteUjianId,
  ) async {
    try {
      final loaded = await loadDraftForRemoteUjian(remoteUjianId);
      if (!loaded) return null;

      final ok = await publishBankSoal();
      if (!ok) return null;

      return {
        'ujian': _draft.kodeUjian ?? '',
        'monitoring': _draft.kodePengawasan ?? '',
        'pin': _draft.pinMulai ?? '',
      };
    } catch (e) {
      debugPrint('BankSoalController.publishBankSoalForRemoteUjian error: $e');
      return null;
    }
  }
}
