import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/core/constants/routes.dart';
import '../controllers/mahasiswa_ujian_controller.dart';

class SubmissionResultView extends StatelessWidget {
  const SubmissionResultView({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan status di Controller
    final vm = context.watch<MahasiswaUjianController>();
    final isOffline = vm.status == SubmissionStatus.offlineSaved;
    final isLoading = vm.status == SubmissionStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          if (isOffline) {
            await vm.submitUjian();
            if (context.mounted) {
              if (vm.status == SubmissionStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Jawaban berhasil dikirim ke server!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(vm.lastErrorMessage ?? "Gagal mengirim jawaban. Periksa koneksi internet."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
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
                        const SizedBox(height: 50),

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
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (isOffline) {
                                      await vm.submitUjian();
                                      if (context.mounted) {
                                        if (vm.status == SubmissionStatus.success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Jawaban berhasil dikirim ke server!"),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(vm.lastErrorMessage ?? "Gagal mengirim jawaban. Periksa koneksi internet."),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        Routes.dashboard,
                                        (route) => false,
                                      );
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
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
              ),
            );
          },
        ),
      ),
    );
  }
}
