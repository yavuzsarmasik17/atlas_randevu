import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class HizmetApi {
  static const _base = String.fromEnvironment('API_URL');
  static const _depo = FlutterSecureStorage();

  static Future<http.Response> _istek(String method, {int? id, Map<String, dynamic>? body}) async {
    if (_base.isEmpty) throw Exception('API_URL tanımlanmamış.');
    final token = await _depo.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) throw Exception('Oturum bulunamadı. Tekrar giriş yapın.');
    final uri = Uri.parse('${_base.replaceAll(RegExp(r'/+$'), '')}/api/isletme/hizmetler${id == null ? '' : '/$id'}');
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final payload = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET': return http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      case 'POST': return http.post(uri, headers: headers, body: payload).timeout(const Duration(seconds: 20));
      case 'PUT': return http.put(uri, headers: headers, body: payload).timeout(const Duration(seconds: 20));
      case 'DELETE': return http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
      default: throw Exception('Geçersiz HTTP metodu.');
    }
  }

  static dynamic _kontrol(http.Response cevap) {
    dynamic veri;
    try { veri = jsonDecode(utf8.decode(cevap.bodyBytes)); } catch (_) { veri = null; }
    if (cevap.statusCode >= 200 && cevap.statusCode < 300) return veri;
    final mesaj = veri is Map && veri['mesaj'] is String ? veri['mesaj'] as String : 'HTTP ${cevap.statusCode}';
    if (cevap.statusCode == 401) throw Exception('Oturum geçersiz veya süresi dolmuş. Tekrar giriş yapın.');
    if (cevap.statusCode == 403) throw Exception('Bu işlem için işletme sahibi yetkisi gerekiyor.');
    throw Exception(mesaj);
  }

  static Future<List<Map<String, dynamic>>> listele() async {
    final veri = _kontrol(await _istek('GET'));
    if (veri is! List) throw Exception('Beklenmeyen hizmet listesi yanıtı.');
    return veri.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> ekle(Map<String, dynamic> veri) async { _kontrol(await _istek('POST', body: veri)); }
  static Future<void> guncelle(int id, Map<String, dynamic> veri) async { _kontrol(await _istek('PUT', id: id, body: veri)); }
  static Future<void> pasiflestir(int id) async { _kontrol(await _istek('DELETE', id: id)); }
}
