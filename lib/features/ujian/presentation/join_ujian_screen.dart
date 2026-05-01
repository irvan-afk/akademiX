import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Penting untuk akses ViewModel
import '../view_models/ujian_view_model.dart';
import 'sesi_ujian_screen.dart';
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

    final ujian = await context.read<UjianViewModel>().joinUjian(code);

    if (mounted) {
      if (ujian != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UjianScreen(ujianId: ujian.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kode ujian salah atau belum aktif!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UjianViewModel>().isLoading;

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
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'sesi_ujian_screen.dart';

// class JoinUjianScreen extends StatefulWidget {
//   const JoinUjianScreen({super.key});

//   @override
//   State<JoinUjianScreen> createState() => _JoinUjianScreenState();
// }

// class _JoinUjianScreenState extends State<JoinUjianScreen> {
//   final TextEditingController _codeController = TextEditingController();
//   bool _isLoading = false;

//   Future<void> _joinUjian() async {
//     final code = _codeController.text.trim().toUpperCase();
//     if (code.isEmpty) return;

//     setState(() => _isLoading = true);

//     try {
//       // Cek apakah kode ada di tabel UJIAN dan statusnya PUBLISHED (sudah aktif)
//       final response = await Supabase.instance.client
//           .from('UJIAN')
//           .select()
//           .eq('kode_ujian', code)
//           .eq('status_ujian', 'PUBLISHED')
//           .maybeSingle();

//       if (response != null) {
//         // Jika kode benar, pindah ke halaman pengerjaan soal
//         if (mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => UjianScreen(ujianId: response['id']),
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Kode ujian salah atau belum aktif!")),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Error join: $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Masuk Sesi Ujian")),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Masukkan 6 Digit Kode Ujian",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _codeController,
//               textAlign: TextAlign.center,
//               maxLength: 6,
//               style: const TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 10,
//               ),
//               decoration: InputDecoration(
//                 hintText: "000000",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _joinUjian,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text(
//                         "MULAI UJIAN",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



