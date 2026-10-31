import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PlatformAdminRandevularApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> listele({
    String arama = '',
    String durum = 'Tumu',
    DateTime? tarih,
    int sayfa = 1,
  }) async {
    final token = await _storage.read(key: 'atlas_platform_admin_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Platform Admin oturumu bulunamadı.');
    }
    String gun(DateTime t) => '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    final params = <String, String>{
      'sayfa': '$sayfa', 'sayfaBoyutu': '25',
      if (arama.trim().isNotEmpty) 'arama': arama.trim(),
      if (durum != 'Tumu') 'durum': durum,
      if (tarih != null) 'baslangicTarihi': gun(tarih),
      if (tarih != null) 'bitisTarihi': gun(tarih),
    };
    final uri = Uri.parse('$_baseUrl/api/platform-admin/randevular')
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Yönetici oturumu geçersiz veya yetkisiz.');
      }
      throw Exception('Randevular alınamadı (HTTP ${response.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) throw Exception('Sunucudan geçersiz yanıt geldi.');
    return Map<String, dynamic>.from(data);
  }
}
