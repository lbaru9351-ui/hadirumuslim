import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/academic_calendar_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter State
  String _selectedFakultasFilter = 'Semua';
  String _selectedProdiFilter = 'Semua';
  String _selectedRoleFilter = 'Semua';

  // Verifikasi Bukti Presensi State
  final TextEditingController _proofVerifyController = TextEditingController();
  Map<String, dynamic>? _proofVerificationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _proofVerifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminUser = auth.currentUser;
    final repo = context.read<AttendanceRepository>();

    if (adminUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final adminScope = adminUser.adminScope ?? AdminScope.prodi;
    final isUniv = adminScope == AdminScope.universitas;
    final isFak = adminScope == AdminScope.fakultas;
    final isProdi = adminScope == AdminScope.prodi;

    // Filter classes and users based on current admin's hierarchy
    final effectiveFakultas = isUniv
        ? _selectedFakultasFilter
        : (isFak ? adminUser.fakultas : adminUser.fakultas);
    final effectiveProdi = isUniv
        ? _selectedProdiFilter
        : (isFak ? _selectedProdiFilter : adminUser.prodi);

    final filteredUsers = repo.getAllUsers().where((u) {
      if (_selectedRoleFilter != 'Semua' && u.role.displayName != _selectedRoleFilter) {
        return false;
      }
      if (!isUniv) {
        if (isFak && u.fakultas != adminUser.fakultas && u.adminScope != AdminScope.universitas) {
          return false;
        }
        if (isProdi &&
            u.prodi != adminUser.prodi &&
            u.adminScope != AdminScope.universitas &&
            u.adminScope != AdminScope.fakultas) {
          return false;
        }
      } else {
        if (effectiveFakultas != 'Semua' && u.fakultas != effectiveFakultas && u.adminScope != AdminScope.universitas) {
          return false;
        }
        if (effectiveProdi != 'Semua' && u.prodi != effectiveProdi && u.adminScope != AdminScope.universitas) {
          return false;
        }
      }
      return true;
    }).toList();

    final filteredClasses = repo.getAllClasses().where((c) {
      if (isProdi && c.prodi != adminUser.prodi) return false;
      if (isFak && c.fakultas != adminUser.fakultas) return false;
      if (isUniv) {
        if (effectiveFakultas != 'Semua' && c.fakultas != effectiveFakultas) return false;
        if (effectiveProdi != 'Semua' && c.prodi != effectiveProdi) return false;
      }
      return true;
    }).toList();

    final events = repo.getAcademicCalendar();
    final pendingDisputes = repo.getPendingDisputes();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUniv
                  ? 'Biro Akademik (BAA)'
                  : (isFak ? 'Dekanat ${adminUser.fakultas}' : 'Program Studi ${adminUser.prodi}'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              adminScope.displayName,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Pengguna (${filteredUsers.length})'),
            Tab(text: 'Matkul & KRS (${filteredClasses.length})'),
            Tab(text: 'Kalender (${events.length})'),
            Tab(text: 'Ruang & Radius'),
            Tab(text: 'Verifikasi & Sanggahan (${pendingDisputes.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Tingkat Wewenang (Modern Flat & Bersih)
          _buildScopeBanner(adminUser, adminScope),

          // Konten Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Akun Pengguna & Filter
                _buildUserManagementTab(context, adminUser, filteredUsers, repo),

                // Tab 2: Mata Kuliah, Dosen Pengampu & KRS
                _buildCourseManagementTab(context, adminUser, filteredClasses, repo),

                // Tab 3: Kalender Akademik Master
                _buildCalendarTab(context, adminUser, events, repo),

                // Tab 4: Pengaturan Lokasi & Radius Ruang
                _buildRoomLocationTab(context, adminUser, filteredClasses, repo),

                // Tab 5: Verifikasi Bukti Digital & Peninjauan Sanggahan Mahasiswa
                _buildDisputesAndVerificationTab(context, adminUser, pendingDisputes, repo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner Identitas & Batas Wewenang Admin
  Widget _buildScopeBanner(UserModel admin, AdminScope scope) {
    Color badgeColor;
    Color badgeBg;
    IconData scopeIcon;
    String scopeDesc;

    switch (scope) {
      case AdminScope.universitas:
        badgeColor = const Color(0xFF0F6B5C);
        badgeBg = const Color(0xFFE6F4EA);
        scopeIcon = Icons.account_balance_rounded;
        scopeDesc = 'Wewenang Penuh: Kelola Kalender Master, Admin Fakultas/Prodi, & Kebijakan Kampus';
        break;
      case AdminScope.fakultas:
        badgeColor = const Color(0xFF6B21A8);
        badgeBg = const Color(0xFFF3E8FF);
        scopeIcon = Icons.domain_rounded;
        scopeDesc = 'Wewenang Fakultas: Ruang Kuliah/Lab, Pemantauan Dosen Fakultas & Monev Kelas';
        break;
      case AdminScope.prodi:
        badgeColor = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
        scopeIcon = Icons.apartment_rounded;
        scopeDesc = 'Wewenang Prodi: Kurikulum, Kelas 16 Pertemuan, Plotting KRS & Reset HP Mahasiswa';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(scopeIcon, size: 20, color: badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        admin.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scope.badgeLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  scopeDesc,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: MANAJEMEN AKUN PENGGUNA DENGAN FILTER HIRARKI
  // ----------------------------------------------------
  Widget _buildUserManagementTab(
    BuildContext context,
    UserModel currentAdmin,
    List<UserModel> users,
    AttendanceRepository repo,
  ) {
    final isUniv = currentAdmin.isAdminUniversitas;
    final isFak = currentAdmin.isAdminFakultas;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: const Text('Buat Akun Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () => _showCreateUserDialog(context, currentAdmin, repo),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        children: [
          // Filter Bar (Jika Admin Univ / Fak)
          if (isUniv || isFak) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text('Filter Data Wilayah & Peran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (_selectedFakultasFilter != 'Semua' || _selectedProdiFilter != 'Semua' || _selectedRoleFilter != 'Semua')
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFakultasFilter = 'Semua';
                              _selectedProdiFilter = 'Semua';
                              _selectedRoleFilter = 'Semua';
                            });
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isUniv) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFakultasFilter,
                                isDense: true,
                                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'Semua', child: Text('Semua Fak')),
                                  DropdownMenuItem(value: 'Fakultas Ilmu Komputer', child: Text('FIK')),
                                  DropdownMenuItem(value: 'FKIP', child: Text('FKIP')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedFakultasFilter = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isUniv || isFak) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedProdiFilter,
                                isDense: true,
                                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'Semua', child: Text('Semua Prodi')),
                                  DropdownMenuItem(value: 'Informatika', child: Text('IF')),
                                  DropdownMenuItem(value: 'Sistem Informasi', child: Text('SI')),
                                  DropdownMenuItem(value: 'Pendidikan Matematika', child: Text('Matematika')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedProdiFilter = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRoleFilter,
                              isDense: true,
                              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              items: const [
                                DropdownMenuItem(value: 'Semua', child: Text('Semua Peran')),
                                DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
                                DropdownMenuItem(value: 'Dosen', child: Text('Dosen')),
                                DropdownMenuItem(value: 'Administrator', child: Text('Admin')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRoleFilter = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMD),
          ],

          // Daftar Akun Pengguna
          ...users.map((user) {
            final isMahasiswa = user.role == UserRole.mahasiswa;
            final isDosen = user.role == UserRole.dosen;
            final isAdmin = user.role == UserRole.admin;

            String roleTag;
            Color roleColor;
            Color roleBg;

            if (isAdmin) {
              final scope = user.adminScope ?? AdminScope.prodi;
              roleTag = scope.badgeLabel;
              roleColor = scope == AdminScope.universitas
                  ? const Color(0xFF0F6B5C)
                  : (scope == AdminScope.fakultas ? const Color(0xFF6B21A8) : const Color(0xFF0284C7));
              roleBg = roleColor.withValues(alpha: 0.12);
            } else if (isDosen) {
              roleTag = 'Dosen Pengampu';
              roleColor = AppColors.info;
              roleBg = AppColors.infoBg;
            } else {
              roleTag = 'Mahasiswa (1 HP)';
              roleColor = AppColors.success;
              roleBg = AppColors.successBg;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isMahasiswa ? "NPM" : isDosen ? "NIDN" : "Username"}: ${user.identifier} • ${user.prodi} (${user.fakultas})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perangkat Terikat (${user.boundDeviceIds.length}/${user.maxAllowedDevices}): ${user.boundDeviceIds.isEmpty ? "Belum Terikat" : user.boundDeviceIds.join(", ")}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                  ),

                  // Tombol Reset Perangkat (Wewenang Admin Prodi/Fak/Univ)
                  if (user.boundDeviceIds.isNotEmpty && !isAdmin) ...[
                    const SizedBox(height: AppDimensions.spaceSM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error, width: 1.0),
                            minimumSize: const Size(110, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.phonelink_erase_rounded, size: 14),
                          label: const Text('Reset Perangkat (Lapis 2)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            repo.resetDeviceBinding(user.id);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pengikatan perangkat ${user.name} berhasil di-reset'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Dialog Buat Akun Baru (Sesuai Hirarki)
  void _showCreateUserDialog(
    BuildContext context,
    UserModel currentAdmin,
    AttendanceRepository repo,
  ) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.mahasiswa;
    AdminScope selectedAdminScope = AdminScope.prodi;
    String selectedProdi = currentAdmin.prodi;
    String selectedFakultas = currentAdmin.fakultas;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
          title: Text(
            'Buat Akun (${currentAdmin.adminScope?.displayName ?? "Admin"})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peran Akun:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SegmentedButton<UserRole>(
                  segments: [
                    const ButtonSegment(value: UserRole.mahasiswa, label: Text('Mhs')),
                    const ButtonSegment(value: UserRole.dosen, label: Text('Dosen')),
                    if (currentAdmin.isAdminUniversitas)
                      const ButtonSegment(value: UserRole.admin, label: Text('Admin')),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (val) {
                    setDialogState(() {
                      selectedRole = val.first;
                    });
                  },
                ),
                if (selectedRole == UserRole.admin && currentAdmin.isAdminUniversitas) ...[
                  const SizedBox(height: 12),
                  const Text('Tingkat Admin:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<AdminScope>(
                    initialValue: selectedAdminScope,
                    items: const [
                      DropdownMenuItem(value: AdminScope.fakultas, child: Text('Admin Fakultas')),
                      DropdownMenuItem(value: AdminScope.prodi, child: Text('Admin Program Studi')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedAdminScope = val);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  selectedRole == UserRole.mahasiswa
                      ? 'NPM Mahasiswa:'
                      : (selectedRole == UserRole.dosen ? 'NIDN/NIP Dosen:' : 'Username Admin:'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    hintText: selectedRole == UserRole.mahasiswa
                        ? '210602004'
                        : (selectedRole == UserRole.dosen ? '0115088202' : 'admin_prodi_si'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Nama Lengkap & Gelar:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Nama lengkap'),
                ),
                const SizedBox(height: 12),
                const Text('Program Studi:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedProdi,
                  items: const [
                    DropdownMenuItem(value: 'Informatika', child: Text('Informatika (FIK)')),
                    DropdownMenuItem(value: 'Sistem Informasi', child: Text('Sistem Informasi (FIK)')),
                    DropdownMenuItem(value: 'Pendidikan Matematika', child: Text('Pendidikan Matematika (FKIP)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedProdi = val;
                        selectedFakultas = val.contains('FKIP') ? 'FKIP' : 'Fakultas Ilmu Komputer';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                if (idController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor induk dan nama wajib diisi'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                repo.createUser(
                  identifier: idController.text.trim(),
                  name: nameController.text.trim(),
                  role: selectedRole,
                  email: emailController.text.trim().isNotEmpty
                      ? emailController.text.trim()
                      : '${idController.text.trim()}@almuslim.ac.id',
                  prodi: selectedProdi,
                  fakultas: selectedFakultas,
                  adminScope: selectedRole == UserRole.admin ? selectedAdminScope : null,
                );

                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Akun ${nameController.text.trim()} berhasil dibuat!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Simpan Akun'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: MATA KULIAH, DOSEN PENGAMPU & KRS
  // ----------------------------------------------------
  Widget _buildCourseManagementTab(
    BuildContext context,
    UserModel currentAdmin,
    List<CourseClassModel> classes,
    AttendanceRepository repo,
  ) {
    final allStudents = repo.getAllStudents();
    final allLecturers = repo.getAllLecturers();
    final isProdi = currentAdmin.isAdminProdi;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: Text(
          isProdi ? 'Tambah Mata Kuliah' : 'Tambah Kelas',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showAddCourseDialog(context, currentAdmin, repo, allLecturers),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];
          final enrolledCount = cls.enrolledStudentIds.length;

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Text(
                        '${cls.courseCode} • ${cls.sks} SKS • ${cls.prodi}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 11),
                      ),
                    ),
                    Text(
                      '$enrolledCount Peserta KRS',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${cls.courseName} (${cls.className})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dosen Pengampu: ${cls.lecturerName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${cls.scheduleDay}, ${cls.scheduleTime} • Ruang: ${cls.roomName}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Tombol Kelola (Admin Prodi yang memiliki wewenang penuh menetapkan dosen & KRS)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.0),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.person_pin_rounded, size: 16),
                        label: const Text('Tugaskan Dosen', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _showAssignLecturerDialog(context, cls, repo, allLecturers);
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(36),
                        ),
                        icon: const Icon(Icons.checklist_rounded, size: 16),
                        label: const Text('Kelola KRS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          _showManageKrsDialog(context, cls, repo, allStudents);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAssignLecturerDialog(
    BuildContext context,
    CourseClassModel cls,
    AttendanceRepository repo,
    List<UserModel> lecturers,
  ) {
    String selectedLecturerId = cls.lecturerId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tugaskan Dosen: ${cls.courseName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Dosen Pengampu Resmi:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedLecturerId,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: lecturers
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text('${d.name} (${d.identifier})', style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedLecturerId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                repo.assignLecturerToClass(cls.id, selectedLecturerId);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dosen pengampu berhasil diperbarui'), backgroundColor: AppColors.primary),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageKrsDialog(
    BuildContext context,
    CourseClassModel cls,
    AttendanceRepository repo,
    List<UserModel> allStudents,
  ) {
    List<String> tempEnrolled = List.from(cls.enrolledStudentIds);
    // Prioritaskan mahasiswa di prodi yang sama
    final relevantStudents = allStudents.where((s) => s.prodi == cls.prodi).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Plotting KRS: ${cls.courseName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: relevantStudents.length,
              itemBuilder: (context, i) {
                final student = relevantStudents[i];
                final isSelected = tempEnrolled.contains(student.id);

                return CheckboxListTile(
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('NPM: ${student.identifier} • ${student.prodi}', style: const TextStyle(fontSize: 11)),
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        tempEnrolled.add(student.id);
                      } else {
                        tempEnrolled.remove(student.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                repo.updateClassKrs(cls.id, tempEnrolled);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('KRS diperbarui: ${tempEnrolled.length} mahasiswa terdaftar'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Simpan KRS'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCourseDialog(
    BuildContext context,
    UserModel currentAdmin,
    AttendanceRepository repo,
    List<UserModel> lecturers,
  ) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final classController = TextEditingController(text: 'Kelas A');
    final roomController = TextEditingController(text: 'Lab Komputer 2');
    String selectedLecturerId = lecturers.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Mata Kuliah Baru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Kode MK (mis. IF-305)')),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Mata Kuliah')),
                const SizedBox(height: 8),
                TextField(controller: classController, decoration: const InputDecoration(labelText: 'Nama Kelas (mis. Kelas A)')),
                const SizedBox(height: 8),
                TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Ruang Kuliah')),
                const SizedBox(height: 12),
                const Text('Dosen Pengampu:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                DropdownButtonFormField<String>(
                  initialValue: selectedLecturerId,
                  items: lecturers
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedLecturerId = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;

                repo.createCourseClass(
                  courseCode: codeController.text.trim(),
                  courseName: nameController.text.trim(),
                  className: classController.text.trim(),
                  sks: 3,
                  lecturerId: selectedLecturerId,
                  roomName: roomController.text.trim(),
                  roomLatitude: 5.197820,
                  roomLongitude: 96.702950,
                  scheduleDay: 'Senin',
                  scheduleTime: '08:00 - 10:30 WIB',
                  prodi: currentAdmin.prodi,
                  fakultas: currentAdmin.fakultas,
                );

                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: KALENDER AKADEMIK (DIKELOLA ADMIN UNIVERSITAS)
  // ----------------------------------------------------
  Widget _buildCalendarTab(
    BuildContext context,
    UserModel currentAdmin,
    List<AcademicEventModel> events,
    AttendanceRepository repo,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isUniv = currentAdmin.isAdminUniversitas;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isUniv
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.event_note_rounded, size: 18),
              label: const Text('Tambah Agenda Master', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () => _showAddEventDialog(context, repo),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUniv ? AppColors.infoBg : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: isUniv ? AppColors.info.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(isUniv ? Icons.admin_panel_settings_rounded : Icons.verified_rounded,
                    color: isUniv ? AppColors.info : AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUniv
                        ? 'Wewenang Admin Universitas: Anda berhak menambah dan mengubah agenda master kalender akademik.'
                        : 'Kalender Akademik Resmi Universitas Almuslim (Mode Pantau / Read-Only).',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUniv ? AppColors.info : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          ...events.map((event) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dateFormat.format(event.startDate)} - ${dateFormat.format(event.endDate)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, AttendanceRepository repo) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Agenda Kalender Akademik Master'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Nama Agenda')),
            const SizedBox(height: 8),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Keterangan Agenda')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              repo.addAcademicEvent(
                AcademicEventModel(
                  id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 14)),
                  category: 'kuliah',
                ),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 4: LOKASI RUANG & RADIUS (DIKELOLA ADMIN FAKULTAS & UNIVERSITAS)
  // ----------------------------------------------------
  Widget _buildRoomLocationTab(
    BuildContext context,
    UserModel currentAdmin,
    List<CourseClassModel> classes,
    AttendanceRepository repo,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cls.courseName} (${cls.className})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      cls.fakultas,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Ruang: ${cls.roomName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),
              _buildCoordItem('Latitude Ruang', '${cls.roomLatitude}'),
              _buildCoordItem('Longitude Ruang', '${cls.roomLongitude}'),
              _buildCoordItem('Radius Maksimal', '${cls.roomRadiusMeters.toInt()} Meter (Default)'),
              const SizedBox(height: AppDimensions.spaceSM),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Catatan Penelitian: Koordinat ruang ditetapkan admin pada data master kelas, bukan dari HP dosen.',
                  style: TextStyle(fontSize: 11, color: AppColors.info),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoordItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 5: Verifikasi Bukti Digital & Peninjauan Sanggahan
  // ----------------------------------------------------
  Widget _buildDisputesAndVerificationTab(
    BuildContext context,
    UserModel adminUser,
    List<AttendanceModel> pendingDisputes,
    AttendanceRepository repo,
  ) {
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm WIB');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Modul Verifikasi Kode Bukti Digital
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Verifikasi Kode Bukti Presensi (Prodi / BAA)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan kode bukti digital mahasiswa untuk memverifikasi keaslian presensi dan integritas rantai hash audit.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _proofVerifyController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: ALM-XXXX-XXXX-XXXX',
                          prefixIcon: Icon(Icons.qr_code_2_rounded, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceSM),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Verifikasi'),
                      onPressed: () {
                        final code = _proofVerifyController.text.trim();
                        if (code.isEmpty) return;
                        setState(() {
                          _proofVerificationResult = repo.verifyAttendanceProofCode(code);
                        });
                      },
                    ),
                  ],
                ),

                // Hasil Verifikasi Kriptografis
                if (_proofVerificationResult != null) ...[
                  const SizedBox(height: AppDimensions.spaceMD),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: _proofVerificationResult!['found'] == true
                          ? (_proofVerificationResult!['isChainValid'] == true ? AppColors.successBg : AppColors.errorBg)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(
                        color: _proofVerificationResult!['found'] == true
                            ? (_proofVerificationResult!['isChainValid'] == true ? AppColors.success : AppColors.error)
                            : AppColors.border,
                      ),
                    ),
                    child: _proofVerificationResult!['found'] == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _proofVerificationResult!['isChainValid'] == true
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_rounded,
                                    color: _proofVerificationResult!['isChainValid'] == true
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _proofVerificationResult!['message'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _proofVerificationResult!['isChainValid'] == true
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              _buildCoordItem('Nama Mahasiswa', _proofVerificationResult!['studentName']),
                              _buildCoordItem('NPM Mahasiswa', _proofVerificationResult!['studentNpm']),
                              _buildCoordItem('Status Saat Ini', _proofVerificationResult!['status']),
                              _buildCoordItem('Status Awal (Pindai)', _proofVerificationResult!['initialStatus']),
                              _buildCoordItem(
                                'Waktu Presensi Server',
                                dateFormatter.format(_proofVerificationResult!['serverTimestamp']),
                              ),
                              _buildCoordItem(
                                'Rantai Hash Audit Log',
                                '${_proofVerificationResult!["auditLogsCount"]} Perubahan (Integritas Terverifikasi)',
                              ),
                              if (_proofVerificationResult!['isFlagged'] == true) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Catatan Anomali: ${_proofVerificationResult!["flagReason"]}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            _proofVerificationResult!['message'],
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceLG),

          // 2. Daftar Sanggahan Kehadiran Mahasiswa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Permohonan Sanggahan Mahasiswa (${pendingDisputes.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (pendingDisputes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Perlu Tinjauan Prodi',
                    style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),

          if (pendingDisputes.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Tidak Ada Sanggahan Tertunda',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seluruh kehadiran dan perubahan status mahasiswa dalam kondisi harmonis tanpa sengketa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...pendingDisputes.map(
              (dispute) => Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${dispute.studentName} (NPM: ${dispute.studentNpm})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dispute.proofCode,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sesi: ${dispute.sessionId.replaceAll("ses_", "").toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 16),
                    Text(
                      'Perubahan oleh Dosen: ${dispute.initialStatus.displayName.toUpperCase()} → ${dispute.status.displayName.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                    Text(
                      'Alasan Dosen: "${dispute.editReason ?? '-'}"',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alasan Sanggahan Mahasiswa:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dispute.disputeReason ?? '-',
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),

                    // Tombol Aksi Admin Prodi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            onPressed: () {
                              _showDisputeResolutionDialog(context, dispute, false, repo, adminUser);
                            },
                            child: const Text('Tolak Sanggahan', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () {
                              _showDisputeResolutionDialog(context, dispute, true, repo, adminUser);
                            },
                            child: const Text('Terima & Pulihkan Hadir', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDisputeResolutionDialog(
    BuildContext context,
    AttendanceModel dispute,
    bool isApproved,
    AttendanceRepository repo,
    UserModel adminUser,
  ) {
    final notesController = TextEditingController(
      text: isApproved ? 'Bukti fisik/surat tugas tervalidasi oleh Prodi.' : 'Dosen pengampu telah mengonfirmasi ketidakhadiran fisik.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApproved ? 'Terima Sanggahan Mahasiswa' : 'Tolak Sanggahan Mahasiswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApproved
                  ? 'Status kehadiran mahasiswa akan dipulihkan kembali ke HADIR dan dicatat ke dalam rantai hash audit.'
                  : 'Status akan tetap dan mahasiswa akan menerima pemberitahuan penolakan.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text('Catatan Keputusan Admin / Prodi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final notes = notesController.text.trim();
              repo.resolveAttendanceDispute(
                attendanceId: dispute.id,
                isApproved: isApproved,
                resolutionNotes: notes,
                adminName: '${adminUser.name} (${adminUser.adminScope?.displayName ?? "Admin"})',
              );
              Navigator.of(ctx).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isApproved ? 'Sanggahan diterima & status dipulihkan!' : 'Sanggahan telah ditolak.'),
                  backgroundColor: isApproved ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: const Text('Simpan Keputusan'),
          ),
        ],
      ),
    );
  }
}
