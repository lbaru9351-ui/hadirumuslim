import 'package:flutter_test/flutter_test.dart';
import 'package:hadirumuslim/main.dart';

void main() {
  testWidgets('App smoke test navigates from splash to login', (WidgetTester tester) async {
    await tester.pumpWidget(const HadirAlmuslimApp());

    // Memverifikasi Splash Screen tampil dengan judul aplikasi
    expect(find.text('Absensi QR'), findsWidgets);
    expect(find.text('Universitas Almuslim'), findsWidgets);

    // Maju setelah durasi splash screen (1.8 detik)
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    // Memverifikasi navigasi otomatis ke Layar Login
    expect(find.text('Masuk ke Akun'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });
}
