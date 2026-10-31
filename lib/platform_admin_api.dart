import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PlatformAdminApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'atlas_platform_admin_access_token';

  static Future<bool> oturumVarMi() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<void> giris(String email, String sifre) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/platform-admin/auth/giris'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email.trim(), 'sifre': sifre}),
    ).timeout(const Duration(seconds: 20));
    dynamic data;
    try { data = jsonDecode(utf8.decode(response.bodyBytes)); } catch (_) {}
    if (response.statusCode != 200 || data is! Map || data['token'] is! String || (data['token'] as String).isEmpty) {
      final message = data is Map ? data['mesaj']?.toString() : null;
      throw Exception(message ?? 'Yönetici girişi başarısız (HTTP ${response.statusCode}).');
    }
    await _storage.write(key: _tokenKey, value: data['token'] as String);
  }

  static Future<void> cikis() => _storage.delete(key: _tokenKey);

  static Future<Map<String, dynamic>> ozetGetir() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) throw Exception('Yönetici oturumu bulunamadı.');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/platform-admin/ozet'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Oturum süresi dolmuş veya yetkiniz yok. Yeniden giriş yapın.');
    }
    if (response.statusCode != 200) {
      throw Exception('İstatistikler alınamadı (HTTP ${response.statusCode}).');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) throw Exception('Sunucudan geçersiz yanıt alındı.');
    return Map<String, dynamic>.from(data);
  }
}
