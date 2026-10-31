import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class IsletmeRaporApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> getir({
    required String donem,
    required DateTime tarih,
  }) async {
    if (!['gunluk', 'haftalik', 'aylik'].contains(donem)) {
      throw ArgumentError('Geçersiz rapor dönemi.');
    }
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
    }
    final gun = '${tarih.year.toString().padLeft(4, '0')}-'
        '${tarih.month.toString().padLeft(2, '0')}-'
        '${tarih.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_baseUrl/api/isletme/randevular/rapor')
        .replace(queryParameters: {'donem': donem, 'tarih': gun});
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mesaj = data is Map ? data['mesaj'] : null;
      throw Exception(mesaj ?? 'Rapor alınamadı (HTTP ${response.statusCode}).');
    }
    if (data is! Map) throw const FormatException('Geçersiz rapor yanıtı.');
    return Map<String, dynamic>.from(data);
  }
}
