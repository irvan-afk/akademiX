import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// ViewModels
import 'package:akademiX/features/auth/view_models/auth_view_model.dart';
// import 'package:akademiX/features/ujian/view_models/ujian_view_model.dart';

// Routes & Pages
import 'package:akademiX/core/constants/routes.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');


  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Hive.initFlutter();
  await Hive.openBox('settings'); // Box untuk session/pengaturan
  await Hive.openBox('offline_exams'); // Box untuk simpan soal ujian

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // ChangeNotifierProvider(create: (_) => UjianViewModel()), // Aktifkan jika file sudah siap
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2962FF)),
        useMaterial3: true,
      ),
      
      initialRoute: Routes.onboarding, 
      
      // Memanggil mapping rute yang ada di AppPages
      routes: AppPages.routes, 
    );
  }
}