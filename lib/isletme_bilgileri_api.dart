import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IsletmeBilgileriApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const _storage = FlutterSecureStorage();
  static Uri get _uri => Uri.parse('$_baseUrl/api/isletme/bilgiler');

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. İşletme hesabınızla giriş yapın.');
    }
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response response) {
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) { data = null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mesaj = data is Map ? data['mesaj'] : null;
      throw Exception(mesaj ?? 'HTTP ${response.statusCode}: İşletme işlemi başarısız.');
    }
    if (data is! Map) throw Exception('Sunucudan geçersiz yanıt alındı.');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getir() async {
    final yanit = await http.get(_uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    return _parse(yanit);
  }

  static Future<Map<String, dynamic>> guncelle(Map<String, String> bilgiler) async {
    final yanit = await http.put(_uri, headers: await _headers(),
      body: jsonEncode(bilgiler)).timeout(const Duration(seconds: 20));
    return _parse(yanit);
  }
}
