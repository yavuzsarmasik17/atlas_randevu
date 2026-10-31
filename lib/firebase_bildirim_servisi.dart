import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FirebaseBildirimServisi {
  FirebaseBildirimServisi._();
  static const String _apiBase = String.fromEnvironment('API_URL');
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenAboneligi;
  static StreamSubscription<RemoteMessage>? _tiklamaAboneligi;

  static Future<void> isletmeIcinBaslat({required String jwt}) async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS)) return;
    final ayarlar = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    if (ayarlar.authorizationStatus != AuthorizationStatus.authorized &&
        ayarlar.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('Bildirim izni verilmedi.');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _messaging.getAPNSToken() == null) {
      debugPrint('APNs token hazır değil.');
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _sunucuyaKaydet(jwt: jwt, fcmToken: token);
    await _tokenAboneligi?.cancel();
    _tokenAboneligi = _messaging.onTokenRefresh.listen((yeniToken) async {
      try { await _sunucuyaKaydet(jwt: jwt, fcmToken: yeniToken); }
      catch (e) { debugPrint('FCM token yenileme hatası: $e'); }
    });
  }

  static Future<void> bildirimTiklamalariniDinle({
    required void Function(RemoteMessage mesaj) onBildirimAcildi,
  }) async {
    await _tiklamaAboneligi?.cancel();
    _tiklamaAboneligi = FirebaseMessaging.onMessageOpenedApp.listen(onBildirimAcildi);
    final ilkMesaj = await _messaging.getInitialMessage();
    if (ilkMesaj != null) onBildirimAcildi(ilkMesaj);
  }

  static Future<void> _sunucuyaKaydet({required String jwt, required String fcmToken}) async {
    if (_apiBase.isEmpty) { debugPrint('API_URL tanımlı değil.'); return; }
    final url = Uri.parse('${_apiBase.replaceAll(RegExp(r'/+$'), '')}/api/bildirim/cihaz');
    final yanit = await http.post(url, headers: {
      'Authorization': 'Bearer $jwt', 'Content-Type': 'application/json',
    }, body: jsonEncode({
      'token': fcmToken,
      'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    })).timeout(const Duration(seconds: 10));
    debugPrint(yanit.statusCode >= 200 && yanit.statusCode < 300
        ? 'FCM token API üzerinden kaydedildi.'
        : 'FCM token API kaydı başarısız: HTTP ${yanit.statusCode}');
  }
}
