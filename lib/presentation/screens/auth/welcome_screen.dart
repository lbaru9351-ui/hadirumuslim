import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import 'login_screen.dart';

/// Halaman Selamat Datang (Onboarding) Modern Flat & Minimalis
/// Mengutamakan navigasi yang bersih, ruang kosong lega, dan kartu informasi yang mudah dipindai.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Image.asset(
                'assets/images/logo_almuslim.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'UNIVERSITAS ALMUSLIM',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceXL,
            vertical: AppDimensions.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 1. Badge Logo Resmi di Tengah
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo_almuslim.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // 2. Judul & Deskripsi Aplikasi
              Center(
                child: Column(
                  children: [
                    Text(
                      'Presensi QR Code',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem Presensi Perkuliahan Mahasiswa Resmi',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // 3. Tiga Kartu Fitur Flat (Mudah Dipindai Sekilas)
              _buildFeatureCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'QR Code Dinamis 16 Pertemuan',
                subtitle: 'Kode QR diperbarui berkala untuk mencegah kecurangan dan titip absen.',
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              _buildFeatureCard(
                icon: Icons.location_on_outlined,
                title: 'Verifikasi Geofencing Kampus',
                subtitle: 'Presensi tervalidasi dalam radius ruang kelas resmi Universitas Almuslim.',
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              _buildFeatureCard(
                icon: Icons.phonelink_lock_rounded,
                title: 'Pengikatan 1 Perangkat Mahasiswa',
                subtitle: 'Keamanan Lapis 2 anti-joki dengan pembatasan perangkat tunggal.',
              ),

              const Spacer(),

              // 4. Tombol Aksi Menuju Halaman Masuk
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Lanjut ke Halaman Masuk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
