import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/attendance_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/lecturer_session_provider.dart';
import 'presentation/providers/student_attendance_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Portrait untuk kenyamanan mobile scanner
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const HadirAlmuslimApp());
}

class HadirAlmuslimApp extends StatelessWidget {
  final AttendanceRepository? repository;

  const HadirAlmuslimApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? AttendanceRepository();

    return MultiProvider(
      providers: [
        Provider<AttendanceRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => AuthProvider(repo)),
        ChangeNotifierProvider(create: (_) => LecturerSessionProvider(repo)),
        ChangeNotifierProvider(create: (_) => StudentAttendanceProvider(repo)),
      ],
      child: MaterialApp(
        title: 'Absensi QR - Universitas Almuslim',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
