import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../student/student_main_screen.dart';
import '../lecturer/lecturer_main_screen.dart';
import '../admin/admin_home_screen.dart';
import '../../../data/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Durasi 1.8 detik sesuai spesifikasi SKILL.md (1,5 - 2 detik)
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        _navigateByRole(auth.currentUser!);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateByRole(UserModel user) {
    Widget destination;
    switch (user.role) {
      case UserRole.mahasiswa:
        destination = const StudentMainScreen();
        break;
      case UserRole.dosen:
        destination = const LecturerMainScreen();
        break;
      case UserRole.admin:
        destination = const AdminHomeScreen();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Resmi Universitas Almuslim
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo_almuslim.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              // Nama Aplikasi
              Text(
                'Absensi QR',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Universitas Almuslim',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              // Loading indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                'Versi 1.0.0 (Prototype)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
            ],
          ),
        ),
      ),
    );
  }
}
