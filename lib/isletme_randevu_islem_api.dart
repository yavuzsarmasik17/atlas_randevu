import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IsletmeRandevuIslemApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const _storage = FlutterSecureStorage();

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

  static Future<void> _put(int id, String action, [Map<String, dynamic>? body]) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/isletme/randevular/$id/$action'),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['mesaj']?.toString() : null;
      throw Exception(message ?? 'HTTP ${response.statusCode}: İşlem başarısız.');
    }
  }

  static Future<void> iptal(int id) => _put(id, 'iptal');

  static Future<void> ertele(int id, DateTime yeniBaslangic) => _put(
    id, 'ertele',
    {'yeniBaslangic': '${yeniBaslangic.year.toString().padLeft(4, '0')}-'
        '${yeniBaslangic.month.toString().padLeft(2, '0')}-'
        '${yeniBaslangic.day.toString().padLeft(2, '0')}T'
        '${yeniBaslangic.hour.toString().padLeft(2, '0')}:'
        '${yeniBaslangic.minute.toString().padLeft(2, '0')}:00'},
  );
}
