import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'musteri_ana_sayfa.dart';
import 'firebase_bildirim_servisi.dart';
import 'isletme_randevu_api.dart';
import 'isletme_panel_sayfasi.dart';
import 'isletme_giris_sayfasi.dart';
import 'platform_admin_giris_sayfasi.dart';

final GlobalKey<NavigatorState> atlasNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AtlasRandevuApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FirebaseBildirimServisi.bildirimTiklamalariniDinle(
      onBildirimAcildi: _bildirimdenAc,
    );
  });
}

bool _bildirimYonlendiriliyor = false;
Future<void> _bildirimdenAc(dynamic mesaj) async {
  if (_bildirimYonlendiriliyor) return;
  final veri = mesaj.data;
  if (veri['tur'] != 'yeni_randevu') return;
  final randevuId = int.tryParse(veri['randevuId']?.toString() ?? '');
  if (randevuId == null || randevuId <= 0) return;
  _bildirimYonlendiriliyor = true;
  try {
    const depo = FlutterSecureStorage();
    final jwt = await depo.read(key: 'atlas_isletme_access_token');
    bool yetkili = false;
    if (jwt != null && jwt.isNotEmpty) {
      try {
        final liste = await IsletmeRandevuApi.listele();
        yetkili = liste.any((r) => r['id']?.toString() == '$randevuId');
      } catch (e) {
        debugPrint('Bildirim randevusu doğrulanamadı: $e');
      }
    }
    final navigator = atlasNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(
      builder: (_) => yetkili
          ? IsletmePanelSayfasi(bildirimRandevuId: randevuId)
          : IsletmeGirisSayfasi(bildirimRandevuId: randevuId),
    ));
  } finally {
    _bildirimYonlendiriliyor = false;
  }
}

class AtlasRandevuApp extends StatelessWidget {
  const AtlasRandevuApp({super.key});
  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: atlasNavigatorKey,
      title: 'OvoRandevu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: mavi, primary: mavi, brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: lacivert),
          bodyLarge: TextStyle(color: lacivert),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, foregroundColor: lacivert,
          centerTitle: false, elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const MusteriAnaSayfa(),
      routes: {
        '/platform-admin-giris': (_) => const PlatformAdminGirisSayfasi(),
      },
    );
  }
}
