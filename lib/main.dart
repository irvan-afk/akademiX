import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';       

// Import ViewModels kamu
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
// import 'package:akademiX/features/ujian/view_models/ujian_view_model.dart';
import 'package:akademiX/features/onboarding/onboarding_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env
  await dotenv.load(fileName: '.env');

  // 2. Init Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Init Hive (Penting untuk Offline-First)
  await Hive.initFlutter();
  
  // Membuka box dasar untuk menyimpan sesi user atau cache soal
  await Hive.openBox('settings');
  await Hive.openBox('offline_exams');

  runApp(
    // 4. Bungkus dengan MultiProvider agar State bisa diakses di semua screen
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // ChangeNotifierProvider(create: (_) => UjianViewModel()),
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
        useMaterial3: true, // Biar tampilan lebih modern sesuai desain Dashboard
      ),
      home: const OnboardingView(),
    );
  }
}