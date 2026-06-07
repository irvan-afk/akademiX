import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../controllers/dosen_ujian_controller.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/widgets/akademix_card.dart';

class MonitoringUjianView extends StatefulWidget {
  final int ujianId;
  final String judulUjian;
  final String pinMulai;

  const MonitoringUjianView({
    super.key,
    required this.ujianId,
    required this.judulUjian,
    required this.pinMulai,
  });

  @override
  State<MonitoringUjianView> createState() => _MonitoringUjianViewState();
}

class _MonitoringUjianViewState extends State<MonitoringUjianView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DosenUjianController>().startMonitoring(widget.ujianId);
    });
  }

  @override
  void dispose() {
    // Jangan stop monitoring di dispose jika Dosen ingin kembali ke layar ini nanti? 
    // Tapi untuk keamanan, kita stop saja saat keluar.
    context.read<DosenUjianController>().stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianController>();
    final allStudents = vm.allMonitoringStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          CurvedHeader(
            title: "Live Monitoring",
            subtitle: widget.judulUjian,
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                context.read<DosenUjianController>().refreshMonitoring(widget.ujianId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Memperbarui data monitoring..."),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
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
                        "Daftar Peserta Ujian",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Total: ${allStudents.length} Peserta",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mahasiswa yang berwarna MERAH menandakan kecurangan (Terkunci).",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  
                  Expanded(
                    child: allStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 15),
                                const Text(
                                  "Belum ada mahasiswa yang masuk\nke ruangan ujian ini.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                )
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 10),
                            itemCount: allStudents.length,
                            itemBuilder: (context, index) {
                              final student = allStudents[index];
                              
                              bool isLocked = student['status_live'] == 'LOCKED' || 
                                              student['status_pengerjaan'] == 'LOCKED' || 
                                              student['status_pengerjaan'] == 'REJECTED';
                              bool isSubmitted = student['status_pengerjaan'] == 'SUBMITTED';
                              
                              Color cardColor = isLocked ? Colors.red : (isSubmitted ? Colors.green : Colors.grey.shade400);
                              IconData iconData = isLocked ? Icons.warning_amber_rounded : (isSubmitted ? Icons.check_circle : Icons.person);
                              String statusText = isLocked ? "TERKUNCI" : (isSubmitted ? "SELESAI DIKUMPULKAN" : "MENGERJAKAN (AMAN)");

                              final avatarUrl = student['avatar_url']?.toString();
                              final isHttp = avatarUrl != null && avatarUrl.startsWith('http');
                              final isBase64 = avatarUrl != null && avatarUrl.startsWith('data:image');
                              final hasAvatar = isHttp || isBase64;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: cardColor, width: 1.5),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: cardColor,
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.white,
                                      backgroundImage: hasAvatar
                                          ? (isHttp
                                              ? NetworkImage(avatarUrl)
                                              : (isBase64
                                                  ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                                                  : null)) as ImageProvider?
                                          : null,
                                      child: hasAvatar
                                          ? null
                                          : Icon(iconData, color: cardColor, size: 20),
                                    ),
                                  ),
                                  title: Text(
                                    student['nama'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Text("NIM: ${student['nim'] ?? '-'}\nStatus: $statusText"),
                                  trailing: isLocked 
                                    ? ElevatedButton.icon(
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
                                      )
                                    : null,
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
