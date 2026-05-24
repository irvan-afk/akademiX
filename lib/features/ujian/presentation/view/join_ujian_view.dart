import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akademix/features/ujian/presentation/controller/join_ujian_controller.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import './waiting_room_view.dart';
import 'package:akademix/core/widgets/curved_header.dart';
import 'package:akademix/core/widgets/akademix_card.dart';

class JoinUjianView extends StatefulWidget {
  const JoinUjianView({super.key});

  @override
  State<JoinUjianView> createState() => _JoinUjianViewState();
}

class _JoinUjianViewState extends State<JoinUjianView> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinExam() async {
    // ✅ Get controllers
    final joinController = context.read<JoinUjianController>();
    final authVm = context.read<AuthViewModel>();

    // ✅ Validate auth session
    final mhsId = authVm.mahasiswaId;
    if (mhsId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sesi login tidak valid. Silakan login ulang."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ✅ Call controller to join exam
    final ujianId = await joinController.joinExam(
      _codeController.text.trim().toUpperCase(),
      mhsId,
    );

    if (!mounted) return;

    // ✅ Handle result
    if (ujianId != null) {
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Soal berhasil diunduh!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to waiting room
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingRoomView(ujianId: ujianId),
        ),
      );
    } else {
      // Error
      final errorMsg = joinController.errorMessage ?? "Terjadi kesalahan";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WATCH controller state only for UI
    final controller = context.watch<JoinUjianController>();

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

                        // ✅ CODE INPUT FIELD
                        TextField(
                          controller: _codeController,
                          enabled: !controller.isLoading,
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

                        // ✅ JOIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: controller.isLoading
                                ? null
                                : _handleJoinExam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2962FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading
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
