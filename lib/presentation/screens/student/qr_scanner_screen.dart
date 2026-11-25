import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_attendance_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/validation_result_sheet.dart';
import 'attendance_history_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final String? preferredClassId;
  const QrScannerScreen({super.key, this.preferredClassId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = context.read<StudentAttendanceProvider>();
      studentProvider.startScan();
      studentProvider.initLocation();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _handleBarcodePayload(rawValue);
  }

  void _handleBarcodePayload(String payload) async {
    final studentProvider = context.read<StudentAttendanceProvider>();
    final auth = context.read<AuthProvider>();

    if (studentProvider.isProcessingScan) return;

    final user = auth.currentUser;
    if (user == null) return;

    final result = await studentProvider.submitScannedPayload(
      student: user,
      currentDeviceId: auth.currentDeviceId,
      qrPayload: payload,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValidationResultSheet(
        result: result,
        onDismiss: () {
          Navigator.of(context).pop();
          studentProvider.resetScanState();
        },
        onViewHistory: () {
          Navigator.of(context).pop();
          studentProvider.resetScanState();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AttendanceHistoryScreen(),
            ),
          );
        },
      ),
    );
  }

  // Simulasi pemindaian untuk lingkungan Emulator/Desktop yang tidak memiliki kamera fisik
  void _simulateScanDialog() {
    final controller = TextEditingController(text: 'ses_rpl_p7|TESTTOKEN|7');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulasi Pindai Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan simulasi ini untuk menguji 7 lapis validasi tanpa kamera fisik:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Payload QR (sessionId|token|meeting)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleBarcodePayload(controller.text.trim());
            },
            child: const Text('Uji Validasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentAttendanceProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Pindai QR Presensi',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Scanner Camera Feed
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 56),
                      const SizedBox(height: AppDimensions.spaceMD),
                      const Text(
                        'Kamera tidak aktif atau izin ditolak.\nSilakan aktifkan izin kamera atau gunakan tombol simulasi pengujian di bawah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.science_outlined, size: 18),
                        label: const Text('Simulasi Pindai QR'),
                        onPressed: _simulateScanDialog,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Scanner Viewfinder Overlay Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                    )),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                    )),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        left: BorderSide(color: Colors.white, width: 4),
                      ),
                    )),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 4),
                        right: BorderSide(color: Colors.white, width: 4),
                      ),
                    )),
                  ),
                  if (studentProvider.isProcessingScan)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Status Sensor Lapis 2 (Device) & Lapis 5 (Lokasi GPS)
          Positioned(
            top: AppDimensions.spaceMD,
            left: AppDimensions.spaceMD,
            right: AppDimensions.spaceMD,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Expanded(
                        child: Text(
                          studentProvider.locationStatusMessage ?? 'Menyiapkan GPS...',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const StatusBadge(
                        label: '<= 30m',
                        type: BadgeType.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_android, color: Colors.white70, size: 16),
                      const SizedBox(width: AppDimensions.spaceXS),
                      Expanded(
                        child: Text(
                          'HP: ${auth.deviceModel} (Terikat)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Petunjuk & Tombol Bantuan Uji Coba di Bawah
          Positioned(
            bottom: AppDimensions.spaceXL,
            left: AppDimensions.spaceMD,
            right: AppDimensions.spaceMD,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Text(
                    'Arahkan kamera ke layar QR Dosen yang sedang aktif',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  icon: const Icon(Icons.developer_mode, size: 18),
                  label: const Text('Mode Uji Coba / Simulasi'),
                  onPressed: _simulateScanDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
