import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BildirimMerkeziApi {
  static const _base = String.fromEnvironment('API_URL');
  static const _storage = FlutterSecureStorage();

  static Future<http.Response> _istek(String yol, {bool put = false}) async {
    if (_base.isEmpty) throw Exception('API_URL tanımlanmamış.');
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) throw Exception('İşletme oturumu bulunamadı.');
    final uri = Uri.parse('${_base.replaceAll(RegExp(r'/+$'), '')}$yol');
    final headers = {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
    final response = await (put ? http.put(uri, headers: headers) : http.get(uri, headers: headers))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Oturum geçersiz veya erişim yetkisi yok.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bildirim işlemi başarısız (HTTP ${response.statusCode}).');
    }
    return response;
  }

  static Future<Map<String, dynamic>> listele({int sayfa = 1, int sayfaBoyutu = 20}) async {
    final yanit = await _istek('/api/bildirim-merkezi?sayfa=$sayfa&sayfaBoyutu=$sayfaBoyutu');
    return Map<String, dynamic>.from(jsonDecode(yanit.body) as Map);
  }

  static Future<void> okundu(int id) async => _istek('/api/bildirim-merkezi/$id/okundu', put: true);
  static Future<void> tumunuOkundu() async => _istek('/api/bildirim-merkezi/tumunu-okundu', put: true);
}
