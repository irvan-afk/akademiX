import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/waiting_room_controller.dart';
import '../view/sesi_ujian_view.dart';

class WaitingRoomView extends StatefulWidget {
  final int ujianId;

  const WaitingRoomView({super.key, required this.ujianId});

  @override
  State<WaitingRoomView> createState() => _WaitingRoomViewState();
}

class _WaitingRoomViewState extends State<WaitingRoomView> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ ONLY DELEGATE TO CONTROLLER
    Future.microtask(() {
      context.read<WaitingRoomController>().loadExamPin(widget.ujianId);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleStartExam() {
    final controller = context.read<WaitingRoomController>();

    if (controller.verifyPin(_pinController.text)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SesiUjianView(ujianId: widget.ujianId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PIN Salah!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaitingRoomController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ruang Tunggu Ujian"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ DISPLAY STATUS ICON
              Icon(
                controller.isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.wifi_rounded,
                size: 80,
                color: controller.isOffline ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),

              // ✅ DISPLAY STATUS TEXT
              Text(
                controller.isOffline
                    ? "Status: OFFLINE (Aman)"
                    : "Status: ONLINE (Matikan Internet)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: controller.isOffline ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 10),

              // ✅ DISPLAY INSTRUCTION
              Text(
                controller.isOffline
                    ? "Bagus! Silakan masukkan PIN ujian yang diberikan oleh Pengawas."
                    : "Soal sudah diunduh. Harap matikan WiFi dan Data Seluler Anda sekarang. Kolom PIN akan terbuka setelah internet mati.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // ✅ PIN INPUT FIELD
              TextField(
                controller: _pinController,
                enabled: controller.isOffline,
                textAlign: TextAlign.center,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "PIN UJIAN",
                  filled: true,
                  fillColor: controller.isOffline
                      ? Colors.blue.shade50
                      : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ START EXAM BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isOffline ? _handleStartExam : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
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
      ),
    );
  }
}
