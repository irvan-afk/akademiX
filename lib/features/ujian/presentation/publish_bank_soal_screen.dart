// import '../../../../core/constants/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/dosen_ujian_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/ujian_model.dart';
import '../../../core/widgets/akademix_card.dart';
import 'monitoring_ujian_screen.dart';

/// Publish Bank Soal Screen: Shows list of ujian with publish action.
/// Dosen can only view and publish ujian (no add/edit/delete).
/// This is separate from BankSoalListScreen (create & manage view).
class PublishBankSoalScreen extends StatefulWidget {
  const PublishBankSoalScreen({super.key});

  @override
  State<PublishBankSoalScreen> createState() => _PublishBankSoalScreenState();
}

class _PublishBankSoalScreenState extends State<PublishBankSoalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final dosenId = context.read<AuthViewModel>().userData?['id'];
      if (dosenId != null) {
        context.read<DosenUjianViewModel>().fetchUjianForDosen(dosenId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DosenUjianViewModel>();

    final filteredUjian = vm.allUjianDosen.where((u) {
      return u.judulUjian.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Publish Bank Soal',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari bank soal...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
                filled: true,
                fillColor: const Color(0xFFF1F4FB),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUjian.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredUjian.length,
              itemBuilder: (context, index) {
                final ujian = filteredUjian[index];
                final isDraft = ujian.statusUjian.name.toUpperCase() == 'DRAFT';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: AkademixCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDraft
                                    ? Colors.orange[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDraft
                                    ? Icons.edit_document
                                    : Icons.cloud_done,
                                color: isDraft ? Colors.orange : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ujian.judulUjian,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${ujian.durasiMenit} Menit • Informatika',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBadge(
                              isDraft ? 'DRAFT' : 'PUBLISHED',
                              isDraft ? Colors.orange : Colors.green,
                            ),
                            if (isDraft)
                              ElevatedButton(
                                onPressed: () =>
                                    _handlePublishAction(context, ujian),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2962FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Publish Now',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                                    tooltip: "Info Kode",
                                    onPressed: () {
                                      _showSuccessPopup(
                                        ujian.judulUjian,
                                        ujian.kodeUjian ?? '-',
                                        ujian.kodePengawasan ?? '-',
                                        ujian.pinMulai ?? '-',
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MonitoringUjianScreen(
                                                ujianId: ujian.id,
                                                judulUjian: ujian.judulUjian,
                                                pinMulai: ujian.pinMulai ?? '-',
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.monitor_heart,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      "Monitoring",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.green),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada bank soal ditemukan',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublishAction(
    BuildContext context,
    UjianModel ujian,
  ) async {
    final tokens = await context.read<DosenUjianViewModel>().publishUjian(
      ujian.id,
    );
    if (tokens != null && mounted) {
      _showSuccessPopup(
        ujian.judulUjian,
        tokens['ujian']!,
        tokens['monitoring']!,
        tokens['pin']!,
      );
      // Refresh data setelah publish berhasil
      final dosenId = context.read<AuthViewModel>().userData?['id'];
      if (dosenId != null) {
        context.read<DosenUjianViewModel>().fetchUjianForDosen(dosenId);
      }
    }
  }

  void _showSuccessPopup(
    String judul,
    String tokenUjian,
    String tokenMonitor,
    String pinMulai,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTokenBox("KODE UJIAN", tokenUjian),
            const SizedBox(height: 10),
            _buildTokenBox("PIN OFFLINE", pinMulai),
            const SizedBox(height: 10),
            _buildTokenBox('KODE MONITORING', tokenMonitor),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Tutup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2962FF),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// // 1. Update ke ViewModel Dosen
// import '../view_models/dosen_ujian_view_model.dart';
// import '../../auth/view_models/auth_view_model.dart';
// import '../../../core/widgets/akademix_card.dart';

// class PublishBankSoalScreen extends StatefulWidget {
//   const PublishBankSoalScreen({super.key});

//   @override
//   State<PublishBankSoalScreen> createState() => _PublishBankSoalScreenState();
// }

// class _PublishBankSoalScreenState extends State<PublishBankSoalScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = "";

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(() {
//       final dosenId = context.read<AuthViewModel>().userData?['id'];
//       if (dosenId != null) {
//         context.read<DosenUjianViewModel>().fetchUjianForDosen(dosenId);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<DosenUjianViewModel>();

//     final filteredUjian = vm.allUjianDosen.where((u) {
//       return u.judulUjian.toLowerCase().contains(_searchQuery.toLowerCase());
//     }).toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFF),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new,
//             color: Colors.black87,
//             size: 20,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Publish Bank Soal",
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(70),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (val) => setState(() => _searchQuery = val),
//               decoration: InputDecoration(
//                 hintText: "Cari bank soal...",
//                 // Menggunakan Navy untuk konsistensi[cite: 4]
//                 prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
//                 filled: true,
//                 fillColor: const Color(0xFFF1F4FB),
//                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: vm.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : filteredUjian.isEmpty
//           ? _buildEmptyState()
//           : ListView.builder(
//               padding: const EdgeInsets.all(20),
//               itemCount: filteredUjian.length,
//               itemBuilder: (context, index) {
//                 final ujian = filteredUjian[index];
//                 final isDraft = ujian.statusUjian == 'DRAFT';

//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 15),
//                   child: AkademixCard(
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: isDraft
//                                     ? Colors.orange[50]
//                                     : Colors.green[50],
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(
//                                 isDraft
//                                     ? Icons.edit_document
//                                     : Icons.cloud_done,
//                                 color: isDraft ? Colors.orange : Colors.green,
//                               ),
//                             ),
//                             const SizedBox(width: 15),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     ujian.judulUjian,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   Text(
//                                     "${ujian.durasiMenit} Menit • Informatika",
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const Divider(height: 30),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _buildBadge(
//                               isDraft ? "DRAFT" : "PUBLISHED",
//                               isDraft ? Colors.orange : Colors.green,
//                             ),
//                             if (isDraft)
//                               ElevatedButton(
//                                 onPressed: () =>
//                                     _handlePublishAction(context, ujian),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(
//                                     0xFF2962FF,
//                                   ), // Navy
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: const Text(
//                                   "Publish Now",
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               )
//                             else
//                               const Text(
//                                 "Terbit",
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildBadge(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 10,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
//           const SizedBox(height: 16),
//           const Text(
//             "Tidak ada bank soal ditemukan",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- LOGIKA AKSI MENGGUNAKAN DOSEN VIEW MODEL ---
//   Future<void> _handlePublishAction(BuildContext context, dynamic ujian) async {
//     // Memanggil fungsi publish dari DosenUjianViewModel
//     final tokens = await context.read<DosenUjianViewModel>().publishUjian(
//       ujian.id,
//     );
//     if (tokens != null && mounted) {
//       _showSuccessPopup(
//         ujian.judulUjian,
//         tokens['ujian']!,
//         tokens['monitoring']!,
//       );
//     }
//   }

//   void _showSuccessPopup(String judul, String tokenUjian, String tokenMonitor) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle, color: Colors.green, size: 60),
//             const SizedBox(height: 15),
//             const Text(
//               "Berhasil Dipublish!",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             _buildTokenBox("KODE UJIAN", tokenUjian),
//             const SizedBox(height: 10),
//             _buildTokenBox("KODE MONITORING", tokenMonitor),
//             const SizedBox(height: 25),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF2962FF),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   "Tutup",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTokenBox(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F4FB),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
//           Text(
//             value,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF2962FF),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import '../view_models/dosen_ujian_view_model.dart';
// // import '../../auth/view_models/auth_view_model.dart';
// // import '../../../core/widgets/akademix_card.dart';

// // class PublishBankSoalScreen extends StatefulWidget {
// //   const PublishBankSoalScreen({super.key});

// //   @override
// //   State<PublishBankSoalScreen> createState() => _PublishBankSoalScreenState();
// // }

// // class _PublishBankSoalScreenState extends State<PublishBankSoalScreen> {
// //   final TextEditingController _searchController = TextEditingController();
// //   String _searchQuery = "";

// //   @override
// //   void initState() {
// //     super.initState();
// //     // SRP: UI hanya memerintah ViewModel untuk ambil data sekali saja
// //     Future.microtask(() {
// //       final dosenId = context.read<AuthViewModel>().userData?['id'];
// //       if (dosenId != null) {
// //         context.read<UjianViewModel>().fetchUjianForDosen(dosenId);
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     _searchController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final vm = context.watch<UjianViewModel>();

// //     // Logika Filter Pencarian di level UI (Sangat cepat karena data sudah ada di memori)
// //     final filteredUjian = vm.allUjianDosen.where((u) {
// //       return u.judulUjian.toLowerCase().contains(_searchQuery.toLowerCase());
// //     }).toList();

// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF8FAFF),
// //       // APPBAR MINIMALIS (Gaya Mode Kerja)
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(
// //             Icons.arrow_back_ios_new,
// //             color: Colors.black87,
// //             size: 20,
// //           ),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text(
// //           "Publish Bank Soal",
// //           style: TextStyle(
// //             color: Colors.black87,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 18,
// //           ),
// //         ),
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(70),
// //           child: Padding(
// //             padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
// //             child: TextField(
// //               controller: _searchController,
// //               onChanged: (val) => setState(() => _searchQuery = val),
// //               decoration: InputDecoration(
// //                 hintText: "Cari bank soal...",
// //                 prefixIcon: const Icon(Icons.search, color: Color(0xFF2962FF)),
// //                 filled: true,
// //                 fillColor: const Color(0xFFF1F4FB),
// //                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(15),
// //                   borderSide: BorderSide.none,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //       body: vm.isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : filteredUjian.isEmpty
// //           ? _buildEmptyState()
// //           : ListView.builder(
// //               padding: const EdgeInsets.all(20),
// //               itemCount: filteredUjian.length,
// //               itemBuilder: (context, index) {
// //                 final ujian = filteredUjian[index];
// //                 final isDraft = ujian.statusUjian == 'DRAFT';

// //                 return Padding(
// //                   padding: const EdgeInsets.only(bottom: 15),
// //                   child: AkademixCard(
// //                     child: Column(
// //                       children: [
// //                         Row(
// //                           children: [
// //                             Container(
// //                               padding: const EdgeInsets.all(10),
// //                               decoration: BoxDecoration(
// //                                 color: isDraft
// //                                     ? Colors.orange[50]
// //                                     : Colors.green[50],
// //                                 borderRadius: BorderRadius.circular(12),
// //                               ),
// //                               child: Icon(
// //                                 isDraft
// //                                     ? Icons.edit_document
// //                                     : Icons.cloud_done,
// //                                 color: isDraft ? Colors.orange : Colors.green,
// //                               ),
// //                             ),
// //                             const SizedBox(width: 15),
// //                             Expanded(
// //                               child: Column(
// //                                 crossAxisAlignment: CrossAxisAlignment.start,
// //                                 children: [
// //                                   Text(
// //                                     ujian.judulUjian,
// //                                     style: const TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       fontSize: 16,
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     "${ujian.durasiMenit} Menit • Informatika",
// //                                     style: const TextStyle(
// //                                       color: Colors.grey,
// //                                       fontSize: 12,
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                         const Divider(height: 30),
// //                         Row(
// //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                           children: [
// //                             _buildBadge(
// //                               isDraft ? "DRAFT" : "PUBLISHED",
// //                               isDraft ? Colors.orange : Colors.green,
// //                             ),
// //                             if (isDraft)
// //                               ElevatedButton(
// //                                 onPressed: () =>
// //                                     _handlePublishAction(context, ujian),
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: const Color(0xFF2962FF),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(10),
// //                                   ),
// //                                 ),
// //                                 child: const Text(
// //                                   "Publish Now",
// //                                   style: TextStyle(color: Colors.white),
// //                                 ),
// //                               )
// //                             else
// //                               const Text(
// //                                 "Terbit",
// //                                 style: TextStyle(
// //                                   color: Colors.green,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //     );
// //   }

// //   Widget _buildBadge(String label, Color color) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.1),
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       child: Text(
// //         label,
// //         style: TextStyle(
// //           color: color,
// //           fontSize: 10,
// //           fontWeight: FontWeight.bold,
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
// //           const SizedBox(height: 16),
// //           const Text(
// //             "Tidak ada bank soal ditemukan",
// //             style: TextStyle(color: Colors.grey),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // --- LOGIKA AKSI TETAP RAPI ---
// //   Future<void> _handlePublishAction(BuildContext context, dynamic ujian) async {
// //     final tokens = await context.read<UjianViewModel>().publishUjian(ujian.id);
// //     if (tokens != null && mounted) {
// //       // Tampilkan popup sukses (gunakan fungsi popup Anda sebelumnya)
// //       // Setelah popup ditutup, data otomatis refresh karena ViewModel memberitahu UI
// //     }
// //   }
// // }
