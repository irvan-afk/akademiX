import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import Auth
import 'package:akademix/features/auth/data/auth_repository_impl.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';
import 'package:akademix/features/auth/view_models/auth_view_model.dart';
import 'package:akademix/features/auth/presentation/role_guard.dart';
import 'package:akademix/features/auth/presentation/login_screen.dart';

// Import Dashboard
import 'package:akademix/features/dashboard-mahasiswa/presentation/dashboard_screen.dart';
import 'package:akademix/features/dashboard-dosen/presentation/dashboard_dosen_screen.dart';

// Import Ujian
import 'package:akademix/features/ujian/view_models/dosen_ujian_view_model.dart';
import 'package:akademix/features/ujian/view_models/mahasiswa_ujian_view_model.dart';
import 'package:akademix/features/ujian/presentation/join_ujian_screen.dart';
import 'package:akademix/features/ujian/presentation/submission_result_screen.dart';
import 'package:akademix/features/ujian/presentation/sesi_ujian_screen.dart';

// Import Bank Soal
import 'package:akademix/features/bank_soal/view_models/bank_soal_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('offline_exams');

  final authRepo = AuthRepositoryImpl();
  final authUsecase = AuthUsecase(authRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authUsecase)),
        ChangeNotifierProvider(create: (_) => MahasiswaUjianViewModel()),
        ChangeNotifierProvider(create: (_) => DosenUjianViewModel()),
        ChangeNotifierProvider(create: (_) => BankSoalViewModel()),
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
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          primary: const Color(0xFF2962FF),
        ),
      ),
      home: const RoleGuard(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/mahasiswa/home': (context) => const DashboardMahasiswaScreen(),
        '/dosen/home': (context) => const DashboardDosenScreen(),
        '/submission-result': (context) => const SubmissionResultScreen(),
        '/join-ujian': (context) => const JoinUjianScreen(),

        '/ujian': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return UjianScreen(ujianId: args);
        },
      },
    );
  }
}
