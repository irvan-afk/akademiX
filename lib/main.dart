import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:akademiX/features/auth/data/auth_repository_impl.dart';
import 'package:akademiX/features/auth/model/auth_usecase.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/features/auth/presentation/role_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Konfigurasi API
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Inisialisasi Hive untuk Penyimpanan Lokal (Offline)
  await Hive.initFlutter();

  // Membuka Box untuk Sesi/Pengaturan
  await Hive.openBox('settings');

  // Membuka Box untuk Menyimpan Soal Ujian (Penting untuk Offline Submission)
  await Hive.openBox('offline_exams');

  // 4. Inisialisasi Arsitektur (Dependency Injection Manual)
  final authRepo = AuthRepositoryImpl();
  final authUsecase = AuthUsecase(authRepo);

  runApp(
    MultiProvider(
      providers: [
        // Menyuntikkan Usecase ke dalam ViewModel sesuai prinsip SRP
        ChangeNotifierProvider(create: (_) => AuthViewModel(authUsecase)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AkademiX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3:
            true, // Mengaktifkan Material 3 agar tampilan lebih modern
      ),
      // RoleGuard akan mengecek apakah ada user yang sudah login di memori
      home: const RoleGuard(),
    );
  }
}
