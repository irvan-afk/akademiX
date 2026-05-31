import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import Auth
import 'package:akademix/features/auth/data/auth_repository_impl.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/features/auth/views/role_guard.dart';
import 'package:akademix/features/auth/views/login_view.dart';

// Import Dashboard
import 'package:akademix/features/dashboard/views/dashboard_view.dart';

// Import Ujian
import 'package:akademix/features/ujian/controllers/dosen_ujian_controller.dart';
import 'package:akademix/features/ujian/controllers/mahasiswa_ujian_controller.dart';
import 'package:akademix/features/ujian/views/join_ujian_view.dart';
import 'package:akademix/features/ujian/views/submission_result_view.dart';
import 'package:akademix/features/ujian/views/sesi_ujian_view.dart';

// Import Bank Soal
import 'package:akademix/features/bank_soal/controllers/bank_soal_controller.dart';

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
        ChangeNotifierProvider(create: (_) => AuthController(authUsecase)),
        ChangeNotifierProvider(create: (_) => MahasiswaUjianController()),
        ChangeNotifierProvider(create: (_) => DosenUjianController()),
        ChangeNotifierProvider(create: (_) => BankSoalController()),
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
        '/login': (context) => const LoginView(),
        '/dashboard': (context) => const DashboardView(),
        '/submission-result': (context) => const SubmissionResultView(),
        '/join-ujian': (context) => const JoinUjianView(),
        '/ujian': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return UjianView(ujianId: args);
        },
      },
    );
  }
}
