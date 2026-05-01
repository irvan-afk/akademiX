import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 1. Update ke ViewModel Dosen
import '../view_models/dosen_ujian_view_model.dart';
import '../../../core/widgets/akademix_card.dart';
import 'nilai_akhir_view.dart';

class DetailKoreksiView extends StatefulWidget {
  final int sesiId;
  final String namaMhs;
  final int ujianId;

  const DetailKoreksiView({
    super.key,
    required this.sesiId,
    required this.namaMhs,
    required this.ujianId,
  });

  @override
  State<DetailKoreksiView> createState() => _DetailKoreksiViewState();
}

class _DetailKoreksiViewState extends State<DetailKoreksiView> {
  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, TextEditingController> _feedbackControllers = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // 2. Gunakan DosenUjianViewModel
      await context.read<DosenUjianViewModel>().fetchDetailPengerjaan(
        widget.ujianId,
        widget.sesiId,
      );

      if (mounted) {
        for (var item in context.read<DosenUjianViewModel>().detailPengerjaan) {
          final jwbId = item['jawaban']['id'];
          if (jwbId != null) {
            _scoreControllers[jwbId] = TextEditingController(
              text: (item['jawaban']['nilai'] ?? 0).toString(),
            );
            _feedbackControllers[jwbId] = TextEditingController(
              text: item['jawaban']['feedback'] ?? '',
            );
          }
        }
      }
    });
  }

  int _calculateTotal(List<Map<String, dynamic>> data) {
    int total = 0;
    for (var item in data) {
      total += (item['jawaban']['nilai'] as num? ?? 0).toInt();
    }
    return total;
  }

  @override
  void dispose() {
    for (var c in _scoreControllers.values) c.dispose();
    for (var c in _feedbackControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Watch DosenUjianViewModel
    final vm = context.watch<DosenUjianViewModel>();

    final filteredDetail = vm.detailPengerjaan.where((item) {
      final teksSoal = item['soal']['teks_soal'].toString().toLowerCase();
      return teksSoal.contains(_searchQuery.toLowerCase());
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Koreksi Jawaban",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "Mahasiswa: ${widget.namaMhs}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari soal...",
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
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDetail.isEmpty
                ? const Center(
                    child: Text(
                      "Soal tidak ditemukan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDetail.length,
                    itemBuilder: (context, index) {
                      final item = filteredDetail[index];
                      // SRP: Fokus pada essai untuk koreksi manual
                      if (item['soal']['tipe_soal'] != 'essai')
                        return const SizedBox.shrink();

                      final jwbId = item['jawaban']['id'];
                      final bobot = item['soal']['bobot_nilai'] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AkademixCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "PERTANYAAN ESSAI",
                                    style: TextStyle(
                                      color: Color(0xFF2962FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "Bobot Maks: $bobot",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['soal']['teks_soal'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Divider(height: 32),
                              const Text(
                                "JAWABAN MAHASISWA:",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['jawaban']['jawaban_teks'] ??
                                    "Tidak ada jawaban",
                                style: const TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: _scoreControllers[jwbId],
                                      decoration: InputDecoration(
                                        labelText: "Skor",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _feedbackControllers[jwbId],
                                      decoration: InputDecoration(
                                        labelText: "Feedback",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: jwbId == null
                                      ? null
                                      : () async {
                                          final nilai =
                                              int.tryParse(
                                                _scoreControllers[jwbId]!.text,
                                              ) ??
                                              0;
                                          final feedback =
                                              _feedbackControllers[jwbId]!.text;
                                          final sukses = await vm
                                              .updateEssayGrade(
                                                jwbId,
                                                nilai,
                                                feedback,
                                              );
                                          if (mounted && sukses) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "✓ Berhasil Disimpan",
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2962FF),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "SIMPAN NILAI",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL SKOR",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${_calculateTotal(vm.detailPengerjaan)}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2962FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      double pg = 0;
                      double essay = 0;
                      for (var item in vm.detailPengerjaan) {
                        final nilai = (item['jawaban']['nilai'] as num? ?? 0)
                            .toDouble();
                        if (item['soal']['tipe_soal'] == 'pilihan_ganda') {
                          pg += nilai;
                        } else {
                          essay += nilai;
                        }
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NilaiAkhirView(
                            namaMhs: widget.namaMhs,
                            nim: "Mahasiswa",
                            mataKuliah: "Mata Kuliah",
                            skorPg: pg,
                            skorEssay: essay,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "LIHAT HASIL AKHIR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../view_models/dosen_ujian_view_model.dart';
// import '../../../core/widgets/akademix_card.dart';
// import 'nilai_akhir_view.dart';

// class DetailKoreksiView extends StatefulWidget {
//   final int sesiId;
//   final String namaMhs;
//   final int ujianId;

//   const DetailKoreksiView({
//     super.key,
//     required this.sesiId,
//     required this.namaMhs,
//     required this.ujianId,
//   });

//   @override
//   State<DetailKoreksiView> createState() => _DetailKoreksiViewState();
// }

// class _DetailKoreksiViewState extends State<DetailKoreksiView> {
//   final Map<int, TextEditingController> _scoreControllers = {};
//   final Map<int, TextEditingController> _feedbackControllers = {};
//   String _searchQuery = ""; // State untuk pencarian soal

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() async {
//       await context.read<UjianViewModel>().fetchDetailPengerjaan(
//         widget.ujianId,
//         widget.sesiId,
//       );

//       if (mounted) {
//         for (var item in context.read<UjianViewModel>().detailPengerjaan) {
//           final jwbId = item['jawaban']['id'];
//           if (jwbId != null) {
//             _scoreControllers[jwbId] = TextEditingController(
//               text: (item['jawaban']['nilai'] ?? 0).toString(),
//             );
//             _feedbackControllers[jwbId] = TextEditingController(
//               text: item['jawaban']['feedback'] ?? '',
//             );
//           }
//         }
//       }
//     });
//   }

//   int _calculateTotal(List<Map<String, dynamic>> data) {
//     int total = 0;
//     for (var item in data) {
//       total += (item['jawaban']['nilai'] as num? ?? 0).toInt();
//     }
//     return total;
//   }

//   @override
//   void dispose() {
//     for (var c in _scoreControllers.values) c.dispose();
//     for (var c in _feedbackControllers.values) c.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<UjianViewModel>();

//     // Filter soal berdasarkan teks soal yang dicari
//     final filteredDetail = vm.detailPengerjaan.where((item) {
//       final teksSoal = item['soal']['teks_soal'].toString().toLowerCase();
//       return teksSoal.contains(_searchQuery.toLowerCase());
//     }).toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFF),
//       // APPBAR PUTIH BERSIH (Gaya Mode Kerja)
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
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Koreksi Jawaban",
//               style: TextStyle(
//                 color: Colors.black87,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             Text(
//               "Mahasiswa: ${widget.namaMhs}",
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontSize: 12,
//                 fontWeight: FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//         // Search Bar untuk mencari soal tertentu
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(70),
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
//             child: TextField(
//               onChanged: (val) => setState(() => _searchQuery = val),
//               decoration: InputDecoration(
//                 hintText: "Cari soal...",
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
//       body: Column(
//         children: [
//           Expanded(
//             child: vm.isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : filteredDetail.isEmpty
//                 ? const Center(
//                     child: Text(
//                       "Soal tidak ditemukan",
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(20),
//                     itemCount: filteredDetail.length,
//                     itemBuilder: (context, index) {
//                       final item = filteredDetail[index];
//                       if (item['soal']['tipe_soal'] != 'essai')
//                         return const SizedBox.shrink();

//                       final jwbId = item['jawaban']['id'];
//                       final bobot = item['soal']['bobot_nilai'] ?? 0;

//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 20),
//                         child: AkademixCard(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     "PERTANYAAN ${index + 1}",
//                                     style: const TextStyle(
//                                       color: Color(0xFF2962FF),
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                   Text(
//                                     "Bobot: $bobot",
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 item['soal']['teks_soal'],
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15,
//                                 ),
//                               ),
//                               const Divider(height: 32),
//                               const Text(
//                                 "JAWABAN MAHASISWA:",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.grey,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 1,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 item['jawaban']['jawaban_teks'] ??
//                                     "Tidak ada jawaban",
//                                 style: const TextStyle(height: 1.5),
//                               ),
//                               const SizedBox(height: 24),

//                               // Input Skor dan Feedback
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     flex: 1,
//                                     child: TextField(
//                                       controller: _scoreControllers[jwbId],
//                                       decoration: InputDecoration(
//                                         labelText: "Skor",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                       ),
//                                       keyboardType: TextInputType.number,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     flex: 2,
//                                     child: TextField(
//                                       controller: _feedbackControllers[jwbId],
//                                       decoration: InputDecoration(
//                                         labelText: "Feedback",
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             12,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 16),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   onPressed: jwbId == null
//                                       ? null
//                                       : () async {
//                                           final nilai =
//                                               int.tryParse(
//                                                 _scoreControllers[jwbId]!.text,
//                                               ) ??
//                                               0;
//                                           final feedback =
//                                               _feedbackControllers[jwbId]!.text;
//                                           final sukses = await vm
//                                               .updateEssayGrade(
//                                                 jwbId,
//                                                 nilai,
//                                                 feedback,
//                                               );
//                                           if (mounted && sukses) {
//                                             ScaffoldMessenger.of(
//                                               context,
//                                             ).showSnackBar(
//                                               const SnackBar(
//                                                 content: Text("✓ Tersimpan"),
//                                                 backgroundColor: Colors.green,
//                                                 behavior:
//                                                     SnackBarBehavior.floating,
//                                               ),
//                                             );
//                                           }
//                                         },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF2962FF),
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 15,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   child: const Text(
//                                     "SIMPAN NILAI",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),

//           // Ringkasan Total di Bawah
//           Container(
//             padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(30),
//                 topRight: Radius.circular(30),
//               ),
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "TOTAL SKOR SAAT INI",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey,
//                         letterSpacing: 1.1,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Text(
//                       "${_calculateTotal(vm.detailPengerjaan)}",
//                       style: const TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF2962FF),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       // Hitung skor terpisah untuk dikirim ke halaman Nilai Akhir
//                       double pg = 0;
//                       double essay = 0;

//                       for (var item in vm.detailPengerjaan) {
//                         final nilai = (item['jawaban']['nilai'] as num? ?? 0)
//                             .toDouble();
//                         if (item['soal']['tipe_soal'] == 'pilihan_ganda') {
//                           pg += nilai;
//                         } else {
//                           essay += nilai;
//                         }
//                       }

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => NilaiAkhirView(
//                             namaMhs: widget.namaMhs,
//                             nim:
//                                 "241511011", // Idealnya ditarik dari vm.detailPengerjaan
//                             mataKuliah:
//                                 "Basis Data", // Idealnya ditarik dari vm.detailPengerjaan
//                             skorPg: pg,
//                             skorEssay: essay,
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2962FF),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       "SELESAI & LIHAT HASIL AKHIR",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
