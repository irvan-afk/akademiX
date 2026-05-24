import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../view_models/mahasiswa_ujian_view_model.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import 'package:akademix/core/database/local_db_service.dart';
import 'sesi_ujian_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final int ujianId;

  const WaitingRoomScreen({super.key, required this.ujianId});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final TextEditingController _pinController = TextEditingController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;
  String? _pinBenar;

  @override
  void initState() {
    super.initState();
    _loadUjianLokal();
    _initConnectivity();
  }

  Future<void> _loadUjianLokal() async {
    final dataLokal = await LocalDbService.instance.getUjianLokal(widget.ujianId);
    if (dataLokal != null) {
      setState(() {
        _pinBenar = dataLokal['pin_mulai'];
      });
    }
  }

  void _initConnectivity() async {
    final List<ConnectivityResult> initialResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(initialResult);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool isCurrentlyOffline = !result.contains(ConnectivityResult.mobile) && !result.contains(ConnectivityResult.wifi);
    
    setState(() {
      _isOffline = isCurrentlyOffline;
    });

    final vm = context.read<MahasiswaUjianViewModel>();
    final authVm = context.read<AuthViewModel>();

    if (!isCurrentlyOffline) {
      // Jika Online, lapor ke Supabase Presence
      vm.subscribeToPresence(
        widget.ujianId, 
        authVm.userData?['nama'] ?? "Unknown", 
        authVm.userData?['nim'] ?? "000000",
        'WAITING'
      );
    } else {
      // Offline, lepaskan koneksi server
      vm.unsubscribePresence();
    }
  }

  void _verifikasiPin() async {
    final pinInput = _pinController.text.trim();
    if (pinInput == _pinBenar) {
      await LocalDbService.instance.updateUjianStatusLokal(widget.ujianId, 'ACTIVE');
      if (!mounted) return;
      // Pindah ke UjianScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UjianScreen(ujianId: widget.ujianId),
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
  void dispose() {
    _connectivitySubscription.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Icon(
                _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                size: 80,
                color: _isOffline ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                _isOffline ? "Status: OFFLINE (Aman)" : "Status: ONLINE (Matikan Internet)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isOffline ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isOffline 
                  ? "Bagus! Silakan masukkan PIN ujian yang diberikan oleh Pengawas." 
                  : "Soal sudah diunduh. Harap matikan WiFi dan Data Seluler Anda sekarang. Kolom PIN akan terbuka setelah internet mati.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _pinController,
                enabled: _isOffline,
                textAlign: TextAlign.center,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "PIN UJIAN",
                  filled: true,
                  fillColor: _isOffline ? Colors.blue.shade50 : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isOffline ? _verifikasiPin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "MULAI UJIAN",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
