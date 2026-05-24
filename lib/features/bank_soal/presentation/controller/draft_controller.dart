import 'package:flutter/material.dart';
import 'package:akademix/features/bank_soal/models/bank_soal_draft_model.dart';

/// Manages in-memory draft state and modifications
class DraftController extends ChangeNotifier {
  BankSoalDraftModel _draft = BankSoalDraftModel.empty();

  BankSoalDraftModel get draft => _draft;
  int get totalPoin => _draft.totalPoin;
  bool get isReadyToPublish => _draft.canPublish;

  void resetDraft({int? dosenId}) {
    _draft = BankSoalDraftModel.empty(dosenId: dosenId);
    notifyListeners();
  }

  void setDraft(BankSoalDraftModel draft) {
    _draft = draft;
    notifyListeners();
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
}
