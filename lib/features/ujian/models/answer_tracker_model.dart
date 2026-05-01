// Model untuk track jawaban mahasiswa selama mengerjakan (sebelum di-submit)
class AnswerTracker {
  final Map<int, String> selectedAnswers;
  final Map<int, bool> markedAsRagu;
  final Map<int, bool> answered;

  AnswerTracker({
    Map<int, String>? selectedAnswers,
    Map<int, bool>? markedAsRagu,
    Map<int, bool>? answered,
  }) : selectedAnswers = selectedAnswers ?? {},
       markedAsRagu = markedAsRagu ?? {},
       answered = answered ?? {};

  bool isSoalAnswered(int soalId) {
    return answered[soalId] ?? false;
  }

  bool isSoalRagu(int soalId) {
    return markedAsRagu[soalId] ?? false;
  }

  String? getAnswer(int soalId) {
    return selectedAnswers[soalId];
  }

  // Set jawaban
  void setAnswer(int soalId, String answer, {bool isRagu = false}) {
    selectedAnswers[soalId] = answer;
    answered[soalId] = true;
    if (isRagu) {
      markedAsRagu[soalId] = true;
    }
  }

  // Mark as ragu
  void markAsRagu(int soalId) {
    markedAsRagu[soalId] = true;
  }

  // Unmark ragu
  void unmarkRagu(int soalId) {
    markedAsRagu[soalId] = false;
  }

  // Get status string untuk display
  String getStatus(int soalId) {
    if (!isSoalAnswered(soalId)) {
      return 'Belum Dijawab';
    }
    if (isSoalRagu(soalId)) {
      return 'Ragu-ragu';
    }
    return 'Dijawab';
  }

  // Count berapa soal sudah dijawab
  int countAnswered() {
    return answered.values.where((v) => v).length;
  }

  // Count berapa soal di-mark ragu
  int countRagu() {
    return markedAsRagu.values.where((v) => v).length;
  }
}
