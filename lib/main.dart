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
import 'package:akademix/features/ujian/presentation/controller/mahasiswa_ujian_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/sesi_ujian_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/waiting_room_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/join_ujian_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/publish_exam_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/grading_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/recap_controller.dart';
import 'package:akademix/features/ujian/presentation/controller/monitoring_controller.dart';
import 'package:akademix/features/ujian/presentation/view/join_ujian_view.dart';
import 'package:akademix/features/ujian/presentation/view/submission_result_view.dart';
import 'package:akademix/features/ujian/presentation/view/sesi_ujian_view.dart';
import 'package:akademix/features/ujian/presentation/view/waiting_room_view.dart';

// Import Bank Soal
import 'package:akademix/features/bank_soal/view_models/bank_soal_view_model.dart';
import 'package:akademix/features/bank_soal/presentation/controller/draft_controller.dart';
import 'package:akademix/features/bank_soal/presentation/controller/pengampu_controller.dart';
import 'package:akademix/features/bank_soal/presentation/controller/publish_bank_soal_controller.dart';

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
        ChangeNotifierProvider(create: (_) => SesiUjianController()),
        ChangeNotifierProvider(create: (_) => WaitingRoomController()),
        ChangeNotifierProvider(create: (_) => PublishExamController()),
        ChangeNotifierProvider(create: (_) => GradingController()),
        ChangeNotifierProvider(create: (_) => RecapController()),
        ChangeNotifierProvider(create: (_) => MonitoringController()),
        // Bank Soal Controllers
        ChangeNotifierProvider(create: (_) => DraftController()),
        ChangeNotifierProvider(create: (_) => PengampuController()),
        ChangeNotifierProvider(create: (_) => PublishBankSoalController()),
        // JoinUjianController depends on MahasiswaUjianViewModel
        // ProxyProvider<MahasiswaUjianViewModel, JoinUjianController>(
        //   create: (context) =>
        //       JoinUjianController(context.read<MahasiswaUjianViewModel>()),
        //   update: (context, mahasiswaUjianVm, previous) =>
        //       JoinUjianController(mahasiswaUjianVm),
        // ),
        ChangeNotifierProxyProvider<
          MahasiswaUjianViewModel,
          JoinUjianController
        >(
          create: (context) =>
              JoinUjianController(context.read<MahasiswaUjianViewModel>()),
          update: (context, mahasiswaUjianVm, previous) =>
              previous ?? JoinUjianController(mahasiswaUjianVm),
        ),
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
        '/join-ujian': (context) => const JoinUjianView(),

        '/ujian': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return SesiUjianView(ujianId: args);
        },

        '/waiting-room': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return WaitingRoomView(ujianId: args);
        },
      },
    );
  }
}
