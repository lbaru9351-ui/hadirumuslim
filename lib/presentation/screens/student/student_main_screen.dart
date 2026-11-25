import 'package:flutter/material.dart';
import '../../widgets/modern_flat_nav_bar.dart';
import 'student_home_screen.dart';
import 'qr_scanner_screen.dart';
import 'attendance_history_screen.dart';
import 'student_profile_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentHomeScreen(
        onNavigateToScan: () => setState(() => _currentIndex = 1),
        onNavigateToHistory: () => setState(() => _currentIndex = 2),
      ),
      const QrScannerScreen(),
      const AttendanceHistoryScreen(),
      const StudentProfileScreen(),
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
            icon: Icons.qr_code_scanner_outlined,
            activeIcon: Icons.qr_code_scanner_rounded,
            label: 'Pindai',
          ),
          ModernFlatNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Riwayat',
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
