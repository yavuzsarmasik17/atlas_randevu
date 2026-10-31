import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IsletmeRandevuApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Uri _uri([String path = '']) =>
      Uri.parse('$_baseUrl/api/isletme/randevular$path');

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. İşletme hesabınızla yeniden giriş yapın.');
    }
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _parse(http.Response response) {
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); }
    catch (_) { data = null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mesaj = data is Map ? data['mesaj'] : null;
      throw Exception(mesaj ?? 'HTTP ${response.statusCode}: Randevu işlemi başarısız.');
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> listele() async {
    final response = await http.get(_uri(), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final data = _parse(response) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> tamamla(int id) async {
    final response = await http.put(_uri('/$id/tamamla'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    _parse(response);
  }

  static Future<Map<String, dynamic>> gunlukOzet() async {
    final response = await http.get(_uri('/ozet'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    return Map<String, dynamic>.from(_parse(response) as Map);
  }
}
