import 'package:flutter/material.dart';

/// Header dengan kurva gelombang organik dan garis kontur topografis
/// sesuai dengan acuan desain mockup (tema hijau Universitas Almuslim).
class TopographicWaveHeader extends StatelessWidget {
  final double height;
  final Widget? child;

  const TopographicWaveHeader({
    super.key,
    this.height = 280,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // Background dengan Painter Gelombang Topografis
          CustomPaint(
            size: Size(double.infinity, height),
            painter: _TopographicWavePainter(),
          ),
          if (child != null)
            SafeArea(
              bottom: false,
              child: child!,
            ),
        ],
      ),
    );
  }
}

class _TopographicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gradien Dasar Hijau Almuslim
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final baseGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F6B5C), // Hijau Utama Universitas Almuslim
        Color(0xFF148F77), // Emerald Hijau Sedang
        Color(0xFF0B4F44), // Deep Forest Green
      ],
    ).createShader(rect);

    final bgPaint = Paint()..shader = baseGradient;

    // Path dasar gelombang utama di bagian bawah
    final wavePath = Path();
    wavePath.moveTo(0, 0);
    wavePath.lineTo(size.width, 0);
    wavePath.lineTo(size.width, size.height * 0.72);

    // Kurva kurvatur organik bergelombang
    wavePath.cubicTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width * 0.45,
      size.height * 0.55,
      0,
      size.height * 0.88,
    );
    wavePath.close();

    canvas.drawPath(wavePath, bgPaint);

    // 2. Garis Kontur Topografi Organik (Topographic Contour Lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final linePaintAccent = Paint()
      ..color = const Color(0xFF6EE7B7).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Lapisan Kurva Topografi 1
    final contour1 = Path();
    contour1.moveTo(0, size.height * 0.25);
    contour1.cubicTo(
      size.width * 0.35,
      size.height * 0.10,
      size.width * 0.65,
      size.height * 0.40,
      size.width,
      size.height * 0.20,
    );
    canvas.drawPath(contour1, linePaint);

    // Lapisan Kurva Topografi 2
    final contour2 = Path();
    contour2.moveTo(0, size.height * 0.42);
    contour2.cubicTo(
      size.width * 0.40,
      size.height * 0.28,
      size.width * 0.60,
      size.height * 0.58,
      size.width,
      size.height * 0.38,
    );
    canvas.drawPath(contour2, linePaintAccent);

    // Lapisan Kurva Topografi 3 (Pusat Kontur Organik Oval)
    final contourCenter = Path();
    contourCenter.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, size.height * 0.35),
        width: size.width * 0.48,
        height: size.height * 0.36,
      ),
    );
    canvas.drawPath(contourCenter, linePaint);

    // Lapisan Kurva Topografi 4 (Inner Oval)
    final contourInner = Path();
    contourInner.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, size.height * 0.35),
        width: size.width * 0.26,
        height: size.height * 0.20,
      ),
    );
    canvas.drawPath(contourInner, linePaintAccent);

    // Lapisan Kurva Topografi 5 (Bawah Mendekati Gelombang)
    final contour5 = Path();
    contour5.moveTo(0, size.height * 0.68);
    contour5.cubicTo(
      size.width * 0.35,
      size.height * 0.50,
      size.width * 0.70,
      size.height * 0.80,
      size.width,
      size.height * 0.58,
    );
    canvas.drawPath(contour5, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
