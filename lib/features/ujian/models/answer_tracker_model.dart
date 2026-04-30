// Model untuk track jawaban mahasiswa selama mengerjakan (sebelum di-submit)
class AnswerTracker {
  final Map<int, String>
  selectedAnswers; // soalId -> jawaban (A/B/C/D atau teks essai)
  final Map<int, bool>
  markedAsRagu; // soalId -> true jika user klik "Ragu-ragu"
  final Map<int, bool> answered; // soalId -> true jika sudah dijawab

  AnswerTracker({
    Map<int, String>? selectedAnswers,
    Map<int, bool>? markedAsRagu,
    Map<int, bool>? answered,
  }) : selectedAnswers = selectedAnswers ?? {},
       markedAsRagu = markedAsRagu ?? {},
       answered = answered ?? {};

  // Cek apakah soal sudah dijawab
  bool isSoalAnswered(int soalId) {
    return answered[soalId] ?? false;
  }

  // Cek apakah soal di-mark ragu
  bool isSoalRagu(int soalId) {
    return markedAsRagu[soalId] ?? false;
  }

  // Get jawaban untuk soal tertentu
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
