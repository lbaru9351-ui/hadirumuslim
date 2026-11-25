import 'package:flutter/material.dart';
import '../../widgets/modern_flat_nav_bar.dart';
import 'lecturer_home_screen.dart';
import 'lecturer_classes_recap_screen.dart';
import 'lecturer_profile_screen.dart';

/// Shell Navigasi Utama Dosen Modern Flat
/// Menggunakan ModernFlatNavBar dengan 3 tab: Beranda, Rekap Presensi, dan Profil.
class LecturerMainScreen extends StatefulWidget {
  const LecturerMainScreen({super.key});

  @override
  State<LecturerMainScreen> createState() => _LecturerMainScreenState();
}

class _LecturerMainScreenState extends State<LecturerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const LecturerHomeScreen(),
      const LecturerClassesRecapScreen(),
      const LecturerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ModernFlatNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          ModernFlatNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Beranda',
          ),
          ModernFlatNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Rekap Presensi',
          ),
          ModernFlatNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
