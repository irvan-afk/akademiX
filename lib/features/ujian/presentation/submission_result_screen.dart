import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/mahasiswa_ujian_view_model.dart';

class SubmissionResultScreen extends StatelessWidget {
  const SubmissionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan status di ViewModel
    final vm = context.watch<MahasiswaUjianViewModel>();
    final isOffline = vm.status == SubmissionStatus.offlineSaved;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isOffline
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  isOffline
                      ? Icons.wifi_off_rounded
                      : Icons.check_circle_rounded,
                  size: 100,
                  color: isOffline ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              Text(
                isOffline ? "Ujian Selesai!" : "Terima Kasih!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                isOffline
                    ? "Jawaban Anda telah tersimpan aman di perangkat ini. Silakan nyalakan internet untuk mengirim data ke server."
                    : "Jawaban Anda telah berhasil diverifikasi dan diterima oleh sistem. Ujian Anda resmi berakhir.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 60),

              // Tombol Aksi dinamis
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOffline
                        ? const Color(0xFF2962FF)
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (isOffline) {
                      await vm.submitUjian();
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/mahasiswa/home',
                        (route) => false,
                      );
                    }
                  },
                  child: vm.status == SubmissionStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOffline ? Icons.wifi : Icons.home_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isOffline
                                  ? "Cek Koneksi & Kirim"
                                  : "Kembali ke Beranda",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
