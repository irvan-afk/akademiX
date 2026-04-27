class OnboardingController {
  int _step = 0;

  int get step => _step;

  set step(int value) {
    _step = value;
  }

  final Map<String, String> splashData = {
    "image": "assets/images/logoUtama.png",
    "title": "akademiX",
    "subtitle": "Menyiapkan Sesi Ujian...",
  };

  final List<String> imagePaths = [
    'assets/images/onboarding1.png',
    'assets/images/onboarding2.png',
    'assets/images/onboarding3.png',
  ];

  final List<String> titles = [
    'Anti-Curang\nReal-time',
    'Mode Terkunci\n(Lockdown)',
    'Kirim Otomatis &\nAman',
  ];

  final List<String> descriptions = [
    'Setiap jawaban disimpan di memori ponsel. Jika internet aktif saat ujian, sistem akan mendeteksi dan secara otomatis mengirimkan jawaban Anda.',
    'Sistem mencatat waktu submit lokal dan waktu sinkronisasi server. Memastikan keamanan dan kendali penuh selama ujian berlangsung.',
    'Data akan terkunci setelah waktu ujian selesai. Pengiriman otomatis saat pengawas mengaktifkan koneksi kembali. Ujian lebih tenang dan aman.',
  ];

  int get totalSteps => titles.length;

  int get totalPageViewSteps => totalSteps + 1;

  bool get isLastPageViewStep => _step == totalPageViewSteps - 1;

  bool get isLastOnboardingStep => (_step - 1) == totalSteps - 1;

  bool nextStep() {
    if (_step < totalSteps - 1) {
      _step++;
      return false;
    }
    return true;
  }

  void previousStep() {
    if (_step > 0) {
      _step--;
    }
  }

  void reset() {
    _step = 0;
  }
}
