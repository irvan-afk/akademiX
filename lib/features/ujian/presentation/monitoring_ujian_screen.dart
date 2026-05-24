import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/dosen_ujian_view_model.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/widgets/akademix_card.dart';

class MonitoringUjianScreen extends StatefulWidget {
  final int ujianId;
  final String judulUjian;
  final String pinMulai;

  const MonitoringUjianScreen({
    super.key,
    required this.ujianId,
    required this.judulUjian,
    required this.pinMulai,
  });

  @override
  State<MonitoringUjianScreen> createState() => _MonitoringUjianScreenState();
}

class _MonitoringUjianScreenState extends State<MonitoringUjianScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DosenUjianViewModel>().startMonitoring(widget.ujianId);
    });
  }

  @override
  void dispose() {
    // Jangan stop monitoring di dispose jika Dosen ingin kembali ke layar ini nanti? 
    // Tapi untuk keamanan, kita stop saja saat keluar.
    context.read<DosenUjianViewModel>().stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianViewModel>();
    final onlineStudents = vm.onlineStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          CurvedHeader(
            title: "Live Monitoring",
            subtitle: widget.judulUjian,
            showBackButton: true,
          ),
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: AkademixCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "PIN UJIAN :",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    widget.pinMulai,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2962FF),
                      letterSpacing: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Status Mahasiswa",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: onlineStudents.isEmpty ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          onlineStudents.isEmpty ? "Aman (Semua Offline)" : "${onlineStudents.length} Online!",
                          style: TextStyle(
                            color: onlineStudents.isEmpty ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mahasiswa yang mengaktifkan internet.",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  
                  Expanded(
                    child: onlineStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
                                const SizedBox(height: 15),
                                const Text(
                                  "Semua mahasiswa sedang offline.\nUjian berjalan aman.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 10),
                            itemCount: onlineStudents.length,
                            itemBuilder: (context, index) {
                              final student = onlineStudents[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: (student['violations'] ?? 0) >= 3 ? Colors.red : Colors.orange, 
                                    width: 1.5
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: CircleAvatar(
                                    backgroundColor: (student['violations'] ?? 0) >= 3 ? Colors.red : Colors.orange,
                                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                  ),
                                  title: Text(
                                    student['nama'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    "NIM: ${student['nim'] ?? '-'}\nStatus: ${(student['violations'] ?? 0) >= 3 ? 'TERKUNCI' : 'PERINGATAN'} (${student['violations'] ?? 1}/3)",
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () {
                                      final nim = student['nim'];
                                      if (nim != null) {
                                        vm.unlockStudent(nim);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Sinyal Buka Kunci dikirim ke ${student['nama']}!")),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.lock_open, size: 16, color: Colors.white),
                                    label: const Text("Unlock", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
