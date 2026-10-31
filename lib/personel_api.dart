import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PersonelApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    // Bu anahtar işletme giriş ekraninin JWT'yi sakladığı anahtarla aynı olmalı.
    final token = await _storage.read(
  key: 'atlas_isletme_access_token',
);
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. İşletme hesabınızla yeniden giriş yapın.');
    }
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri([String path = '']) =>
      Uri.parse('$_baseUrl/api/isletme/personeller$path');

  static dynamic _parse(http.Response response) {
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); }
    catch (_) { data = null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mesaj = data is Map ? data['mesaj'] : null;
      throw Exception(mesaj ?? 'HTTP ${response.statusCode}: Personel işlemi başarısız.');
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> listele() async {
    final response = await http.get(_uri(), headers: await _headers());
    final data = _parse(response) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> ekle(Map<String, dynamic> veri) async {
    final response = await http.post(_uri(), headers: await _headers(), body: jsonEncode(veri));
    _parse(response);
  }

  static Future<void> guncelle(int id, Map<String, dynamic> veri) async {
    final response = await http.put(_uri('/$id'), headers: await _headers(), body: jsonEncode(veri));
    _parse(response);
  }

  static Future<void> durumDegistir(int id, bool aktif) async {
    final response = await http.patch(_uri('/$id/durum'),
        headers: await _headers(), body: jsonEncode({'aktifMi': aktif}));
    _parse(response);
  }

  static Future<void> pasiflestir(int id) async {
    final response = await http.delete(_uri('/$id'), headers: await _headers());
    _parse(response);
  }
}
