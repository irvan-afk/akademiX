import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/mahasiswa_ujian_view_model.dart';
// 1. IMPORT AuthViewModel untuk ambil ID Mahasiswa
import '../../auth/view_models/auth_view_model.dart';
import 'waiting_room_screen.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/widgets/akademix_card.dart';

class JoinUjianScreen extends StatefulWidget {
  const JoinUjianScreen({super.key});

  @override
  State<JoinUjianScreen> createState() => _JoinUjianScreenState();
}

class _JoinUjianScreenState extends State<JoinUjianScreen> {
  final TextEditingController _codeController = TextEditingController();

  Future<void> _joinUjian() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final authVm = context.read<AuthViewModel>();
    final mhsId = authVm.mahasiswaId;

    if (mhsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesi login tidak valid. Silakan login ulang."),
        ),
      );
      return;
    }

    //  fungsi join untuk mendapatkan data ujian dan sesi
    final vm = context.read<MahasiswaUjianViewModel>();
    
    try {
      final ujian = await vm.joinUjian(code, mhsId);

      if (mounted) {
        if (ujian != null) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Soal berhasil diunduh!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          //  Beralih ke Waiting Room
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingRoomScreen(ujianId: ujian.id),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kode ujian salah atau belum aktif!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('UJIAN_SUDAH_DIKERJAKAN')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Anda sudah menyelesaikan ujian ini!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terjadi kesalahan saat bergabung ke ujian."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //  Pantau status loading dari MahasiswaUjianViewModel
    final isLoading = context.watch<MahasiswaUjianViewModel>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          const CurvedHeader(
            title: "Join Ujian",
            subtitle: "Masukkan kode dari Dosen",
            showBackButton: true,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  AkademixCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.vpn_key_rounded,
                          size: 60,
                          color: Color(0xFF2962FF),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "KODE UJIAN",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 15,
                            color: Color(0xFF2962FF),
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "000000",
                            hintStyle: TextStyle(color: Colors.grey.shade300),
                            filled: true,
                            fillColor: const Color(0xFFF0F4FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _joinUjian,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2962FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "MULAI UJIAN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Penting untuk akses ViewModel
// import '../view_models/dosen_ujian_view_model.dart';
// import 'sesi_ujian_screen.dart';
// import '../../../core/widgets/curved_header.dart';
// import '../../../core/widgets/akademix_card.dart';

// class JoinUjianScreen extends StatefulWidget {
//   const JoinUjianScreen({super.key});

//   @override
//   State<JoinUjianScreen> createState() => _JoinUjianScreenState();
// }

// class _JoinUjianScreenState extends State<JoinUjianScreen> {
//   final TextEditingController _codeController = TextEditingController();

//   Future<void> _joinUjian() async {
//     final code = _codeController.text.trim().toUpperCase();
//     if (code.isEmpty) return;

//     final ujian = await context.read<UjianViewModel>().joinUjian(code);

//     if (mounted) {
//       if (ujian != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => UjianScreen(ujianId: ujian.id),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Kode ujian salah atau belum aktif!")),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isLoading = context.watch<UjianViewModel>().isLoading;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFF),
//       body: Column(
//         children: [
//           const CurvedHeader(
//             title: "Join Ujian",
//             subtitle: "Masukkan kode dari Dosen",
//             showBackButton: true,
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 40),
//                   AkademixCard(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.vpn_key_rounded,
//                           size: 60,
//                           color: Color(0xFF2962FF),
//                         ),
//                         const SizedBox(height: 20),
//                         const Text(
//                           "KODE UJIAN",
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey,
//                             letterSpacing: 2,
//                           ),
//                         ),
//                         const SizedBox(height: 15),

//                         TextField(
//                           controller: _codeController,
//                           textAlign: TextAlign.center,
//                           maxLength: 6,
//                           style: const TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 15,
//                             color: Color(0xFF2962FF),
//                           ),
//                           decoration: InputDecoration(
//                             counterText: "",
//                             hintText: "000000",
//                             hintStyle: TextStyle(color: Colors.grey.shade300),
//                             filled: true,
//                             fillColor: const Color(0xFFF0F4FF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 30),

//                         SizedBox(
//                           width: double.infinity,
//                           height: 55,
//                           child: ElevatedButton(
//                             onPressed: isLoading ? null : _joinUjian,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF2962FF),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: isLoading
//                                 ? const SizedBox(
//                                     width: 24,
//                                     height: 24,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                       strokeWidth: 2,
//                                     ),
//                                   )
//                                 : const Text(
//                                     "MULAI UJIAN",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
