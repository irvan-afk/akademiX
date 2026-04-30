import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:akademiX/features/auth/data/auth_repository_impl.dart';
import 'package:akademiX/features/auth/model/auth_usecase.dart';
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
import 'package:akademiX/features/auth/presentation/role_guard.dart';
import 'package:akademiX/features/auth/presentation/login_screen.dart';

import 'package:akademiX/features/dashboard-mahasiswa/presentation/dashboard_screen.dart';
import 'package:akademiX/features/dashboard-dosen/presentation/dashboard_dosen_screen.dart';

import 'package:akademiX/features/ujian/view_models/ujian_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Konfigurasi API
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Inisialisasi Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('offline_exams');

  // 4. Inisialisasi Arsitektur
  final authRepo = AuthRepositoryImpl();
  final authUsecase = AuthUsecase(authRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authUsecase)),
        ChangeNotifierProvider(create: (_) => UjianViewModel()),
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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // RoleGuard sebagai pintu masuk otomatis (Auto-login)
      home: const RoleGuard(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/mahasiswa/home': (context) => const DashboardMahasiswaScreen(),
        '/dosen/home': (context) => const DashboardDosenScreen(),
        // Tambahkan rute lain jika ada di sini
      },
    );
  }
}
