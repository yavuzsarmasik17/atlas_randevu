import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PersonelIzinApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const _storage = FlutterSecureStorage();
  static Uri _uri([String path = '']) =>
      Uri.parse('$_baseUrl/api/isletme/personel-izinleri$path');

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
    }
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _check(http.Response response) {
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mesaj = data is Map ? (data['mesaj'] ?? data['title']) : null;
      throw Exception(mesaj ?? 'İşlem başarısız (HTTP ${response.statusCode}).');
    }
    return data;
  }

  static Future<List<Map<String, dynamic>>> listele() async {
    final response = await http.get(_uri(), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final data = _check(response) as List;
    return data.map((x) => Map<String, dynamic>.from(x as Map)).toList();
  }

  static Future<void> ekle({
    required int personelId,
    required DateTime baslangic,
    required DateTime bitis,
    required String aciklama,
  }) async {
    final response = await http.post(_uri(), headers: await _headers(), body: jsonEncode({
      'personelId': personelId,
      'baslangic': _yerelTarih(baslangic),
      'bitis': _yerelTarih(bitis),
      'aciklama': aciklama,
    })).timeout(const Duration(seconds: 20));
    _check(response);
  }

  // API DateTime.Now kullandığından yerel saat offset olmadan gönderilir.
  static String _yerelTarih(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:00';

  static Future<void> sil(int id) async {
    final response = await http.delete(_uri('/$id'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    _check(response);
  }
}
