import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../student/student_main_screen.dart';
import '../lecturer/lecturer_main_screen.dart';
import '../admin/admin_home_screen.dart';

/// Halaman Masuk Akun Modern Flat & Minimalis
/// Sesuai preferensi UI berbasis Navigasi, ruang kosong lega, kartu sederhana, dan tanpa pintasan pengujian.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(text: '210602001'); // Default NPM M Hafizh
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _identifierController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final user = auth.currentUser!;
      Widget nextScreen;
      switch (user.role) {
        case UserRole.mahasiswa:
          nextScreen = const StudentMainScreen();
          break;
        case UserRole.dosen:
          nextScreen = const LecturerMainScreen();
          break;
        case UserRole.admin:
          nextScreen = const AdminHomeScreen();
          break;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_almuslim.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'UNIVERSITAS ALMUSLIM',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sistem Presensi QR Code',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXL,
            vertical: AppDimensions.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1. Header Judul Modern Flat & Minimalis
              Text(
                'Masuk ke Akun',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Masukkan Nomor Induk (NPM untuk Mahasiswa / NIDN untuk Dosen) beserta kata sandi Anda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // 2. Error Banner Bila Login Gagal
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
              ],

              // 3. Form Input NPM/NIP
              Text(
                'Nomor Induk (NPM / NIDN / NIP)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              TextField(
                controller: _identifierController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 210602001',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // 4. Form Input Kata Sandi
              Text(
                'Kata Sandi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Masukkan kata sandi',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceSM),

              // 5. Checkbox Remember Me & Lupa Sandi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ingat Saya',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan hubungi BAA atau Admin Prodi untuk mengatur ulang kata sandi.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // 6. Kartu Informasi Lapis 2: Pengikatan Perangkat
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.phonelink_lock_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kebijakan Multi-Perangkat (Lapis 2)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Akun mahasiswa terikat ketat pada 1 ponsel. ID perangkat saat ini (${auth.currentDeviceId.length > 16 ? auth.currentDeviceId.substring(0, 16) : auth.currentDeviceId}...) diverifikasi otomatis oleh sistem.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // 7. Tombol Masuk Utama
              CustomButton(
                text: 'Masuk Sekarang',
                isLoading: auth.isLoading,
                onPressed: _submitLogin,
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              // 8. Footer Minimalis Resmi Universitas Almuslim
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Universitas Almuslim • Sistem Presensi Resmi',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
            ],
          ),
        ),
      ),
    );
  }
}
